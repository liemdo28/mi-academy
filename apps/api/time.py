"""Time helpers for API models and responses."""

from datetime import UTC, datetime


def utc_now() -> datetime:
    return datetime.now(UTC)
