"""Rate limiting middleware for MI Academy API.

Uses a Redis-backed fixed-window counter in production so limits hold
across multiple API processes/replicas. Falls back to an in-memory limiter
only for local dev and tests where no Redis is available.
"""

import time
from collections import defaultdict
from typing import Dict, Optional

from fastapi import Request, HTTPException, status
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.responses import Response


class InMemoryRateLimiter:
    """Per-process sliding-window rate limiter. Dev/test fallback only."""

    def __init__(self):
        self._requests: Dict[str, list] = defaultdict(list)

    async def is_allowed(self, key: str, limit: int, window_seconds: int = 60) -> bool:
        now = time.time()
        self._requests[key] = [
            ts for ts in self._requests[key] if now - ts < window_seconds
        ]
        if len(self._requests[key]) >= limit:
            return False
        self._requests[key].append(now)
        return True


class RedisRateLimiter:
    """Fixed-window rate limiter backed by Redis, shared across processes."""

    def __init__(self, redis_url: str):
        import redis.asyncio as redis

        self._client = redis.from_url(redis_url, decode_responses=True)

    async def is_allowed(self, key: str, limit: int, window_seconds: int = 60) -> bool:
        window = int(time.time() // window_seconds)
        redis_key = f"ratelimit:{key}:{window}"
        count = await self._client.incr(redis_key)
        if count == 1:
            await self._client.expire(redis_key, window_seconds)
        return count <= limit


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Apply rate limits to specific endpoint groups."""

    def __init__(
        self,
        app,
        auth_limit: int = 10,
        sync_limit: int = 60,
        default_limit: int = 100,
        redis_url: Optional[str] = None,
        app_env: str = "development",
    ):
        super().__init__(app)
        if app_env.lower() == "production" and not redis_url:
            raise RuntimeError(
                "REDIS_URL is required in production so rate limits are shared across API replicas."
            )
        self.limiter = RedisRateLimiter(redis_url) if redis_url else InMemoryRateLimiter()
        self.auth_limit = auth_limit
        self.sync_limit = sync_limit
        self.default_limit = default_limit

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        # Get client identifier
        client_id = self._get_client_id(request)
        path = request.url.path

        # Determine limit based on path
        if path.startswith("/api/v1/auth"):
            limit = self.auth_limit
        elif path.startswith("/api/v1/sync"):
            limit = self.sync_limit
        else:
            limit = self.default_limit

        # Check rate limit
        key = f"{client_id}:{path.split('/')[2] if len(path.split('/')) > 2 else 'root'}"
        if not await self.limiter.is_allowed(key, limit):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail={
                    "error": {
                        "code": "RATE_LIMIT_EXCEEDED",
                        "message": "Too many requests. Please wait.",
                    }
                },
            )

        return await call_next(request)

    def _get_client_id(self, request: Request) -> str:
        """Get a client identifier from headers or IP."""
        # Prefer X-Forwarded-For (behind proxy)
        forwarded = request.headers.get("x-forwarded-for")
        if forwarded:
            return forwarded.split(",")[0].strip()
        if request.client:
            return request.client.host
        return "unknown"
