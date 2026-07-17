"""Admin schemas — lesson, question, game CRUD."""

from datetime import datetime
from pydantic import BaseModel, Field


class AdminLessonCreate(BaseModel):
    subject_id: str
    title: str = Field(..., max_length=200)
    description: str | None = None
    age_group: str = Field(..., pattern="^(junior|explorer|master)$")
    difficulty: int = Field(default=1, ge=1, le=5)
    language: str = Field(default="vi", pattern="^(vi|en)$")
    estimated_minutes: int = Field(default=5, ge=1, le=120)
    content_json: dict | None = None


class AdminLessonUpdate(BaseModel):
    title: str | None = Field(None, max_length=200)
    description: str | None = None
    age_group: str | None = Field(None, pattern="^(junior|explorer|master)$")
    difficulty: int | None = Field(None, ge=1, le=5)
    estimated_minutes: int | None = Field(None, ge=1, le=120)
    content_json: dict | None = None
    is_active: bool | None = None


class AdminQuestionCreate(BaseModel):
    lesson_id: str | None = None
    question_type: str = Field(..., pattern="^(multiple_choice|text|image|audio)$")
    prompt: str
    options_json: list[dict] | None = None
    correct_answer_json: dict | None = None
    explanation: str | None = None
    media_url: str | None = None
    difficulty: int = Field(default=1, ge=1, le=5)


class AdminQuestionUpdate(BaseModel):
    question_type: str | None = None
    prompt: str | None = None
    options_json: list[dict] | None = None
    correct_answer_json: dict | None = None
    explanation: str | None = None
    media_url: str | None = None
    difficulty: int | None = Field(None, ge=1, le=5)


class AdminGameUpdate(BaseModel):
    name: str | None = None
    config_json: dict | None = None
    is_active: bool | None = None


class AdminContentVersionResponse(BaseModel):
    id: str
    content_type: str
    version: int
    checksum: str | None
    created_at: datetime
