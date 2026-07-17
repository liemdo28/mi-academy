"""Sync schemas — content delta, progress upsert, attempt sync."""

from datetime import datetime
from pydantic import BaseModel


class SyncStatusResponse(BaseModel):
    lessons_version: int
    questions_version: int
    games_version: int
    server_time: datetime


class SyncContentItem(BaseModel):
    id: str
    data: dict


class SyncContentResponse(BaseModel):
    content_type: str  # lessons | questions | games
    version: int
    items: list[dict]
    deleted_ids: list[str]


class SyncProgressItem(BaseModel):
    id: str | None = None
    child_id: str
    lesson_id: str
    status: str
    mastery_score: float
    total_attempts: int
    last_played_at: datetime | None = None


class SyncAttemptItem(BaseModel):
    id: str
    child_id: str
    lesson_id: str | None = None
    game_id: str | None = None
    question_id: str | None = None
    answer_json: dict | None = None
    is_correct: bool
    response_time_ms: int = 0
    hint_count: int = 0
    created_at: datetime
