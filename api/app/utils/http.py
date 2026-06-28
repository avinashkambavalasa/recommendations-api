import json
from typing import Any


DEFAULT_HEADERS = {
    "Content-Type": "application/json",
    "Cache-Control": "no-store",
}


def response(
    status_code: int,
    body: dict[str, Any],
    headers: dict[str, str] | None = None,
) -> dict[str, Any]:
    return {
        "statusCode": status_code,
        "headers": {**DEFAULT_HEADERS, **(headers or {})},
        "body": json.dumps(body, separators=(",", ":"), sort_keys=True),
    }
