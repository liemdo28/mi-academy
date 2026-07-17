import pytest
from starlette.applications import Starlette

from apps.api.config import DEFAULT_SECRET_KEY, Settings, get_settings
from apps.api.middleware.rate_limit import InMemoryRateLimiter, RateLimitMiddleware


def test_production_settings_require_redis(monkeypatch):
    get_settings.cache_clear()
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("SECRET_KEY", "not-the-default-secret")
    monkeypatch.delenv("REDIS_URL", raising=False)

    with pytest.raises(RuntimeError, match="REDIS_URL is required in production"):
        get_settings()

    get_settings.cache_clear()


def test_production_secret_validation_still_runs_before_redis(monkeypatch):
    get_settings.cache_clear()
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("SECRET_KEY", DEFAULT_SECRET_KEY)
    monkeypatch.delenv("REDIS_URL", raising=False)

    with pytest.raises(RuntimeError, match="SECRET_KEY is still the default"):
        get_settings()

    get_settings.cache_clear()


def test_rate_limit_middleware_allows_in_memory_limiter_outside_production():
    middleware = RateLimitMiddleware(Starlette(), app_env="test", redis_url=None)

    assert isinstance(middleware.limiter, InMemoryRateLimiter)


def test_rate_limit_middleware_rejects_in_memory_limiter_in_production():
    with pytest.raises(RuntimeError, match="REDIS_URL is required in production"):
        RateLimitMiddleware(Starlette(), app_env="production", redis_url=None)
