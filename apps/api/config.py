"""Application configuration — all settings from environment variables."""

from functools import lru_cache
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # App
    APP_ENV: str = "development"  # development | production
    DEBUG: bool = True

    # Database
    DATABASE_URL: str = "sqlite+aiosqlite:///./mi_academy.db"
    CREATE_TABLES_ON_STARTUP: bool = True

    # JWT
    SECRET_KEY: str = "CHANGE_ME_IN_PRODUCTION_USE_64_CHARS_RANDOM"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # CORS
    CORS_ORIGINS: List[str] = []  # Empty = no cross-origin unless set in env

    # Security
    BCRYPT_ROUNDS: int = 12

    # Sync
    SYNC_RATE_LIMIT_PER_MIN: int = 60
    AUTH_RATE_LIMIT_PER_MIN: int = 10
    # Parent PIN verify -- deliberately stricter than AUTH_RATE_LIMIT_PER_MIN
    # since a PIN is only 4-6 digits (far smaller keyspace than a password).
    PIN_RATE_LIMIT_PER_MIN: int = 5

    # Redis (required in production for shared rate limiting across API replicas)
    REDIS_URL: str | None = None

    # Only honor a client-supplied X-Forwarded-For header when the API is
    # actually deployed behind a reverse proxy/load balancer that sets (and
    # overwrites, not appends to) this header itself. Without a trusted
    # proxy in front, any caller can spoof a new value on every request and
    # get a fresh rate-limit bucket each time -- defeating the limiter
    # entirely for brute-force endpoints (login, PIN verify).
    TRUST_PROXY_HEADERS: bool = False


DEFAULT_SECRET_KEY = "CHANGE_ME_IN_PRODUCTION_USE_64_CHARS_RANDOM"


@lru_cache
def get_settings() -> Settings:
    loaded = Settings()
    is_production = loaded.APP_ENV.lower() == "production"
    if is_production and loaded.SECRET_KEY == DEFAULT_SECRET_KEY:
        raise RuntimeError(
            "SECRET_KEY is still the default placeholder value. "
            "Set a real secret via the SECRET_KEY environment variable before running in production."
        )
    if is_production and not loaded.REDIS_URL:
        raise RuntimeError(
            "REDIS_URL is required in production so rate limits are enforced across API replicas."
        )
    return loaded


settings = get_settings()
