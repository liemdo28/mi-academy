import pytest
from starlette.applications import Starlette
from starlette.requests import Request

from apps.api.config import DEFAULT_SECRET_KEY, Settings, get_settings
from apps.api.middleware.rate_limit import InMemoryRateLimiter, RateLimitMiddleware


def _make_request(path: str = "/", headers: dict | None = None, client_host: str = "1.2.3.4") -> Request:
    headers = headers or {}
    scope = {
        "type": "http",
        "path": path,
        "headers": [(k.lower().encode(), v.encode()) for k, v in headers.items()],
        "client": (client_host, 12345),
    }
    return Request(scope)


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


def test_client_id_ignores_spoofed_forwarded_header_by_default():
    """Without an explicitly-trusted proxy in front, a caller can set
    X-Forwarded-For to anything -- honoring it would let an attacker get a
    fresh rate-limit bucket on every request, defeating brute-force
    protection on login/PIN-verify entirely."""
    middleware = RateLimitMiddleware(Starlette(), app_env="test", redis_url=None)
    request = _make_request(headers={"X-Forwarded-For": "9.9.9.9"}, client_host="1.2.3.4")

    assert middleware._get_client_id(request) == "1.2.3.4"


def test_client_id_honors_forwarded_header_when_proxy_is_trusted():
    middleware = RateLimitMiddleware(
        Starlette(), app_env="test", redis_url=None, trust_proxy_headers=True
    )
    request = _make_request(headers={"X-Forwarded-For": "9.9.9.9"}, client_host="1.2.3.4")

    assert middleware._get_client_id(request) == "9.9.9.9"


def test_pin_verify_path_uses_the_stricter_pin_limit_not_the_default():
    middleware = RateLimitMiddleware(
        Starlette(), app_env="test", redis_url=None, pin_limit=5, default_limit=100
    )
    pin_request = _make_request(path="/api/v1/parent/pin/verify")
    other_parent_request = _make_request(path="/api/v1/parent/profile")

    for _ in range(5):
        assert await_allowed(middleware, pin_request)
    assert not await_allowed(middleware, pin_request), (
        "PIN verify must trip its stricter limit, not silently fall back to default_limit"
    )
    # A different /api/v1/parent/* route is unaffected by the PIN limit.
    assert await_allowed(middleware, other_parent_request)


def await_allowed(middleware: RateLimitMiddleware, request: Request) -> bool:
    import asyncio

    client_id = middleware._get_client_id(request)
    path = request.url.path
    limit = middleware.pin_limit if path.startswith("/api/v1/parent/pin") else middleware.default_limit
    key = f"{client_id}:{path.split('/')[2] if len(path.split('/')) > 2 else 'root'}"
    return asyncio.run(middleware.limiter.is_allowed(key, limit))
