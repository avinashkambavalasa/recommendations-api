from dataclasses import asdict, dataclass
from datetime import time
from typing import Any


@dataclass(frozen=True)
class Restaurant:
    restaurant_id: str
    name: str
    style: str
    address: str
    open_hour: str
    close_hour: str
    vegetarian: bool
    deliveries: bool

    @classmethod
    def from_item(cls, item: dict[str, Any]) -> "Restaurant":
        return cls(
            restaurant_id=str(item["restaurant_id"]),
            name=str(item["name"]),
            style=str(item["style"]),
            address=str(item["address"]),
            open_hour=str(item["open_hour"]),
            close_hour=str(item["close_hour"]),
            vegetarian=_coerce_bool(item.get("vegetarian", False)),
            deliveries=_coerce_bool(item.get("deliveries", False)),
        )

    def to_response(self) -> dict[str, Any]:
        data = asdict(self)
        data.pop("restaurant_id", None)
        return data

    def is_open_at(self, requested_time: time) -> bool:
        opens = _parse_time(self.open_hour)
        closes = _parse_time(self.close_hour)

        if opens == closes:
            return True
        if opens < closes:
            return opens <= requested_time < closes
        return requested_time >= opens or requested_time < closes

