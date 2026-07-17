"""Rate limiting middleware for MI Academy API."""

import time
from collections import defaultdict
from typing import Dict, Tuple

from fastapi import Request, HTTPException, status
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.responses import Response


class InMemoryRateLimiter:
    """Simple in-memory rate limiter using sliding window."""

    def __init__(self):
        # key -> list of request timestamps
        self._requests: Dict[str, list] = defaultdict(list)

    def is_allowed(self, key: str, limit: int, window_seconds: int = 60) -> bool:
        now = time.time()
        # Remove old requests outside the window
        self._requests[key] = [
            ts for ts in self._requests[key] if now - ts < window_seconds
        ]
        if len(self._requests[key]) >= limit:
            return False
        self._requests[key].append(now)
        return True


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Apply rate limits to specific endpoint groups."""

    def __init__(
        self,
        app,
        auth_limit: int = 10,
        sync_limit: int = 60,
        default_limit: int = 100,
    ):
        super().__init__(app)
        self.limiter = InMemoryRateLimiter()
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
        if not self.limiter.is_allowed(key, limit):
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