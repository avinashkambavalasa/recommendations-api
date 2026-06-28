from datetime import time

import pytest

from app.models.errors import NotFoundError
from app.models.restaurant import Restaurant
from app.repository.restaurant_repository import InMemoryRestaurantRepository
from app.services.recommendation_service import (
    RecommendationCriteria,
    RecommendationService,
)


@pytest.fixture
def service() -> RecommendationService:
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
                ),
                Restaurant(
                    restaurant_id="2",
                    name="Night Noodles",
                    style="Korean",
                    address="2 Main Street",
                    open_hour="18:00",
                    close_hour="02:00",
                    vegetarian=False,
                    deliveries=False,
                ),
            ]
        )
    )


def test_recommends_restaurant_matching_all_criteria(service: RecommendationService) -> None:
    recommendation = service.recommend(
        RecommendationCriteria(
            style="Italian",
            vegetarian=True,
            deliveries=True,
            open_at=time(12, 0),
        )
    )

    assert recommendation.name == "Bella Roma"
