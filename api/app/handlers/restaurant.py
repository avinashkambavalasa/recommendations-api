from typing import Any

from app.config.settings import Settings
from app.logger.logger import log_event, log_exception
from app.models.errors import BadRequestError, NotFoundError
from app.repository.restaurant_repository import DynamoDBRestaurantRepository
from app.services.recommendation_service import (
    RecommendationCriteria,
    RecommendationService,
)
from app.utils.http import response
from app.utils.request import parse_bool, query_parameters, requested_time


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    settings = Settings.from_environment()
    repository = DynamoDBRestaurantRepository(settings.restaurant_table_name)
    service = RecommendationService(repository)
    return handle_request(event=event, service=service, settings=settings)


def handle_request(
    event: dict[str, Any],
    service: RecommendationService,
    settings: Settings,
) -> dict[str, Any]:
    params = query_parameters(event)
    request_id = (event.get("requestContext") or {}).get("requestId", "unknown")

    try:
        criteria = _criteria_from_params(params, settings.service_timezone)
        recommendation = service.recommend(criteria)
    except BadRequestError as exc:
        log_event("restaurant_recommendation_rejected", request_id=request_id, reason=str(exc))
        return response(400, {"message": str(exc)})
    except NotFoundError as exc:
        log_event("restaurant_recommendation_not_found", request_id=request_id)
        return response(404, {"message": str(exc)})
    except Exception as exc:
        log_exception(
            "restaurant_recommendation_failed",
            request_id=request_id,
            error_type=exc.__class__.__name__,
        )
        return response(500, {"message": "internal server error"})

    log_event(
        "restaurant_recommendation_served",
        request_id=request_id,
        style=criteria.style,
        vegetarian=criteria.vegetarian,
        deliveries=criteria.deliveries,
        open_at=criteria.open_at.isoformat() if criteria.open_at else None,
        restaurant_id=recommendation.restaurant_id,
    )
    return response(200, {"restaurantRecommendation": recommendation.to_response()})


def _criteria_from_params(
    params: dict[str, str],
    timezone_name: str,
) -> RecommendationCriteria:
    allowed_params = {"style", "vegetarian", "deliveries", "open_now", "open_at"}
    unknown_params = sorted(set(params) - allowed_params)
    if unknown_params:
        raise BadRequestError(f"unsupported query parameter: {unknown_params[0]}")

    open_at = None
    if "open_now" in params:
        if not parse_bool(params["open_now"], "open_now"):
            raise BadRequestError("open_now can only be true when provided")
        open_at = requested_time(params, timezone_name)
    elif "open_at" in params:
        open_at = requested_time(params, timezone_name)

    return RecommendationCriteria(
        style=params.get("style"),
        vegetarian=(
            parse_bool(params["vegetarian"], "vegetarian")
            if "vegetarian" in params
            else None
        ),
        deliveries=(
            parse_bool(params["deliveries"], "deliveries")
            if "deliveries" in params
            else None
        ),
        open_at=open_at,
    )
