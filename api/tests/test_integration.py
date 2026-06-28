from app.models.restaurant import Restaurant
from app.repository.restaurant_repository import InMemoryRestaurantRepository
from app.services.recommendation_service import (
    RecommendationCriteria,
    RecommendationService,
)


def test_repository_service_integration_returns_sorted_first_match() -> None:
    service = RecommendationService(
        InMemoryRestaurantRepository(
            [
                Restaurant(
                    restaurant_id="2",
                    name="Ziti House",
                    style="Italian",
                    address="2 Main Street",
                    open_hour="09:00",
                    close_hour="23:00",
                    vegetarian=True,
                    deliveries=True,
                ),
                Restaurant(
                    restaurant_id="1",
                    name="Bella Roma",
                    style="Italian",
                    address="1 Main Street",
                    open_hour="09:00",
                    close_hour="23:00",
                    vegetarian=True,
                    deliveries=False,
                ),
            ]
        )
    )

    recommendation = service.recommend(RecommendationCriteria(style="Italian"))

    assert recommendation.name == "Bella Roma"
