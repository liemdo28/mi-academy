"""Lesson and game schemas."""

from pydantic import BaseModel


class GameLevelResponse(BaseModel):
    id: str
    game_id: str
    level_index: int
    difficulty: int
    content_json: dict | None


class LessonResponse(BaseModel):
    id: str
    subject_id: str
    title: str
    description: str | None
    age_group: str
    difficulty: int
    language: str
    estimated_minutes: int
    is_active: bool


class LessonDetailResponse(LessonResponse):
    content_json: dict | None = None
    levels: list[GameLevelResponse] = []


class LessonListResponse(BaseModel):
    items: list[LessonResponse]
    total: int
