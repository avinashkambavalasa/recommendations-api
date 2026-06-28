from dataclasses import dataclass
from datetime import time

from app.models.errors import NotFoundError
from app.models.restaurant import Restaurant
from app.repository.restaurant_repository import RestaurantRepository


@dataclass(frozen=True)
class RecommendationCriteria:
    style: str | None = None
    vegetarian: bool | None = None
    deliveries: bool | None = None
    open_at: time | None = None


class RecommendationService:
    def __init__(self, repository: RestaurantRepository) -> None:
        self._repository = repository

    def recommend(self, criteria: RecommendationCriteria) -> Restaurant:
        restaurants = self._repository.list_restaurants(style=criteria.style)

        matches = [
            restaurant
            for restaurant in restaurants
            if self._matches(restaurant=restaurant, criteria=criteria)
        ]
        if not matches:
            raise NotFoundError("no restaurant matched the requested criteria")

        return sorted(matches, key=lambda restaurant: restaurant.name.casefold())[0]

    @staticmethod
    def _matches(
        restaurant: Restaurant,
        criteria: RecommendationCriteria,
    ) -> bool:
        if (
            criteria.style is not None
            and restaurant.style.casefold() != criteria.style.casefold()
        ):
            return False
        if (
            criteria.vegetarian is not None
            and restaurant.vegetarian is not criteria.vegetarian
        ):
            return False
        if criteria.deliveries is not None and restaurant.deliveries is not criteria.deliveries:
            return False
        if criteria.open_at is not None and not restaurant.is_open_at(criteria.open_at):
            return False
        return True
