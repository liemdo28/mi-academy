"""Structured JSON logging for the MI Academy API.

Emits one JSON object per log line (CloudWatch/Loki/GlitchTip-friendly).
Known-sensitive field names are redacted before serialization so a stray
`extra={"password": ...}` at a call site can't leak a secret into logs.
"""

import json
import logging
import sys
from typing import Any, Mapping, Optional

from apps.api.config import settings

SERVICE_NAME = "mi-api"

# Field names that must never appear in plaintext in logs, per docs/security.md.
REDACTED_KEYS = {
    "password",
    "pin",
    "pin_hash",
    "password_hash",
    "token",
    "access_token",
    "refresh_token",
    "authorization",
    "jwt",
    "secret_key",
    "encryption_key",
    "database_url",
    "email",
    "child_name",
    "full_name",
}


def _redact(value: Any) -> Any:
    if isinstance(value, Mapping):
        return {
            k: ("[REDACTED]" if k.lower() in REDACTED_KEYS else _redact(v))
            for k, v in value.items()
        }
    if isinstance(value, list):
        return [_redact(v) for v in value]
    return value


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "timestamp": self.formatTime(record, "%Y-%m-%dT%H:%M:%SZ"),
            "level": record.levelname,
            "service": SERVICE_NAME,
            "environment": settings.APP_ENV,
            "message": record.getMessage(),
        }
        request_id = getattr(record, "requestId", None)
        if request_id:
            payload["requestId"] = request_id
        event_data = getattr(record, "event_data", None)
        if event_data:
            payload.update(_redact(event_data))
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json.dumps(payload, default=str)


def configure_logging() -> None:
    """Replace default handlers with a single JSON stdout handler."""
    root = logging.getLogger()
    root.handlers.clear()
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    root.addHandler(handler)
    root.setLevel(logging.DEBUG if settings.DEBUG else logging.INFO)


def log_event(
    logger: logging.Logger,
    level: int,
    event: str,
    request_id: Optional[str] = None,
    **fields: Any,
) -> None:
    """Log a structured event. Extra fields are redacted before serialization."""
    logger.log(
        level,
        event,
        extra={"event_data": {"event": event, **fields}, "requestId": request_id},
    )
