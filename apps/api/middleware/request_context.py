"""Assigns a correlation ID to every request and logs request completion."""

import logging
import time
import uuid

from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response

from apps.api.logging_config import log_event

logger = logging.getLogger("mi_api.request")


class RequestContextMiddleware(BaseHTTPMiddleware):
    """Generates/propagates X-Request-ID and logs one structured event per request."""

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        request_id = request.headers.get("x-request-id") or str(uuid.uuid4())
        request.state.request_id = request_id
        start = time.monotonic()

        try:
            response = await call_next(request)
        except Exception:
            duration_ms = int((time.monotonic() - start) * 1000)
            log_event(
                logger,
                logging.ERROR,
                "request_failed",
                request_id,
                method=request.method,
                path=request.url.path,
                durationMs=duration_ms,
            )
            raise

        duration_ms = int((time.monotonic() - start) * 1000)
        response.headers["X-Request-ID"] = request_id
        log_event(
            logger,
            logging.INFO,
            "request_completed",
            request_id,
            method=request.method,
            path=request.url.path,
            status=response.status_code,
            durationMs=duration_ms,
        )
        return response
