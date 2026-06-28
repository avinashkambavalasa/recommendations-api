from typing import Any, Iterable

from app.models.restaurant import Restaurant

DYNAMODB_CLIENT_CONFIG = {
    "connect_timeout": 2,
    "read_timeout": 3,
    "retries": {"max_attempts": 3, "mode": "standard"},
}


class RestaurantRepository:
    def list_restaurants(self, style: str | None = None) -> list[Restaurant]:
        raise NotImplementedError


class DynamoDBRestaurantRepository(RestaurantRepository):
    def __init__(self, table_name: str, dynamodb_resource: Any | None = None) -> None:
        if dynamodb_resource is None:
            import boto3
            from botocore.config import Config

            dynamodb_resource = boto3.resource(
                "dynamodb", config=Config(**DYNAMODB_CLIENT_CONFIG)
            )
        self._table = dynamodb_resource.Table(table_name)

    def list_restaurants(self, style: str | None = None) -> list[Restaurant]:
        if style:
            response = self._table.query(
                IndexName="style-index",
                KeyConditionExpression="#style = :style",
                ExpressionAttributeNames={"#style": "style"},
                ExpressionAttributeValues={":style": style},
            )
        else:
            response = self._table.scan()

        items = list(response.get("Items", []))
        while "LastEvaluatedKey" in response:
            request: dict[str, Any] = {"ExclusiveStartKey": response["LastEvaluatedKey"]}
            if style:
                request.update(
                    {
                        "IndexName": "style-index",
                        "KeyConditionExpression": "#style = :style",
                        "ExpressionAttributeNames": {"#style": "style"},
                        "ExpressionAttributeValues": {":style": style},
                    }
                )
                response = self._table.query(**request)
            else:
                response = self._table.scan(**request)
            items.extend(response.get("Items", []))

        return [Restaurant.from_item(item) for item in items]


class InMemoryRestaurantRepository(RestaurantRepository):
    def __init__(self, restaurants: Iterable[Restaurant]) -> None:
        self._restaurants = list(restaurants)

    def list_restaurants(self, style: str | None = None) -> list[Restaurant]:
        if style is None:
            return list(self._restaurants)
        return [
            restaurant
            for restaurant in self._restaurants
            if restaurant.style.casefold() == style.casefold()
        ]
