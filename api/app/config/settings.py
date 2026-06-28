from dataclasses import dataclass
import os


@dataclass(frozen=True)
class Settings:
    restaurant_table_name: str
    service_timezone: str
    cors_allowed_origins: tuple[str, ...]

    @classmethod
    def from_environment(cls) -> "Settings":
        origins = os.getenv("CORS_ALLOWED_ORIGINS", "*")
        return cls(
            restaurant_table_name=os.environ["RESTAURANT_TABLE_NAME"],
            service_timezone=os.getenv("SERVICE_TIMEZONE", "UTC"),
            cors_allowed_origins=tuple(
                origin.strip() for origin in origins.split(",") if origin.strip()
            ),
        )
