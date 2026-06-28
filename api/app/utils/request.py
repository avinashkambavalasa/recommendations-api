from datetime import datetime, time
from typing import Any
from zoneinfo import ZoneInfo

from app.models.errors import BadRequestError


def query_parameters(event: dict[str, Any]) -> dict[str, str]:
    params = event.get("queryStringParameters") or {}
    if not isinstance(params, dict):
        return {}
    return {
        str(key): str(value).strip()
        for key, value in params.items()
        if value is not None and str(value).strip() != ""
    }


def parse_bool(value: str, name: str) -> bool:
    normalized = value.lower()
    if normalized in {"true", "1", "yes", "y"}:
        return True
    if normalized in {"false", "0", "no", "n"}:
        return False
    raise BadRequestError(f"{name} must be a boolean")


def requested_time(params: dict[str, str], timezone_name: str) -> time:
    if "open_at" in params:
        try:
            return datetime.strptime(params["open_at"], "%H:%M").time()
        except ValueError as exc:
            raise BadRequestError("open_at must use HH:MM format") from exc
    return datetime.now(ZoneInfo(timezone_name)).time().replace(second=0, microsecond=0)
