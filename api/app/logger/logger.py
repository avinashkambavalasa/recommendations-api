import json
import logging
from typing import Any


logger = logging.getLogger("recommendations_api")
logger.setLevel(logging.INFO)


def log_event(event_type: str, **fields: Any) -> None:
    logger.info(
        json.dumps(
            {"event_type": event_type, **fields},
            default=str,
            separators=(",", ":"),
            sort_keys=True,
        )
    )


def log_exception(event_type: str, **fields: Any) -> None:
    logger.exception(
        json.dumps(
            {"event_type": event_type, **fields},
            default=str,
            separators=(",", ":"),
            sort_keys=True,
        )
    )
