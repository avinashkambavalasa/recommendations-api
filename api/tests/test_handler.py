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

