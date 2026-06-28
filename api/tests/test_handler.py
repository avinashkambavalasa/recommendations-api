import json
from datetime import time

from app.config.settings import Settings
from app.handlers.restaurant import handle_request
from app.models.restaurant import Restaurant
from app.repository.restaurant_repository import InMemoryRestaurantRepository
from app.services.recommendation_service import RecommendationService


def _service() -> RecommendationService:
    return RecommendationService(
        InMemoryRestaurantRepository(
            [
                Restaurant(
                    restaurant_id="1",
                    name="Bella Roma",
                    style="Italian",
                    address="1 Main Street",
                    open_hour="09:00",
                    close_hour="23:00",
                    vegetarian=True,
                    deliveries=True,
                )
            ]
        )
    )


def test_handler_returns_restaurant_recommendation() -> None:
    result = handle_request(
        event={
            "requestContext": {"requestId": "request-1"},
            "queryStringParameters": {
                "style": "Italian",
                "vegetarian": "true",
                "open_at": "12:00",
            },
        },
        service=_service(),
        settings=Settings(
            restaurant_table_name="restaurants",
            service_timezone="UTC",
            cors_allowed_origins=("*",),
        ),
    )

    assert result["statusCode"] == 200
    body = json.loads(result["body"])
    assert body["restaurantRecommendation"]["name"] == "Bella Roma"
    assert body["restaurantRecommendation"]["open_hour"] == "09:00"
    assert "restaurant_id" not in body["restaurantRecommendation"]


def test_handler_rejects_invalid_boolean() -> None:
    result = handle_request(
        event={
            "requestContext": {"requestId": "request-1"},
            "queryStringParameters": {"vegetarian": "sometimes"},
        },
        service=_service(),
        settings=Settings(
            restaurant_table_name="restaurants",
            service_timezone="UTC",
            cors_allowed_origins=("*",),
        ),
    )

    assert result["statusCode"] == 400


def test_handler_returns_safe_500_for_unexpected_error() -> None:
    class BrokenService:
        def recommend(self, criteria):  # type: ignore[no-untyped-def]
            raise RuntimeError("dynamodb is unhappy")

    result = handle_request(
        event={"requestContext": {"requestId": "request-1"}},
        service=BrokenService(),  # type: ignore[arg-type]
        settings=Settings(
            restaurant_table_name="restaurants",
            service_timezone="UTC",
            cors_allowed_origins=("*",),
        ),
    )

    assert result["statusCode"] == 500
    body = json.loads(result["body"])
    assert body == {"message": "internal server error"}


def test_restaurant_open_hours_exclude_close_minute() -> None:
    restaurant = Restaurant(
        restaurant_id="1",
        name="Bella Roma",
        style="Italian",
        address="1 Main Street",
        open_hour="09:00",
        close_hour="23:00",
        vegetarian=True,
        deliveries=True,
    )

    assert restaurant.is_open_at(time(22, 59))
    assert not restaurant.is_open_at(time(23, 0))
