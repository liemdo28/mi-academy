"""Pydantic request/response schemas for all API routes."""

# ─── Auth ────────────────────────────────────────────────────────────────────

from pydantic import BaseModel, EmailStr, Field


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    display_name: str = Field(..., min_length=1, max_length=100)
    language: str = Field(default="vi", pattern="^(vi|en)$")


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: str
    role: str
    email: str | None
    created_at: str


class AuthResponse(BaseModel):
    user: UserResponse
    parent_profile: "ParentProfileResponse"
    access_token: str
    refresh_token: str


# ─── Parent Profile ────────────────────────────────────────────────────────────

from datetime import datetime


class ParentProfileResponse(BaseModel):
    id: str
    display_name: str
    language: str
    timezone: str
    has_pin: bool = False

    @classmethod
    def from_model(cls, model) -> "ParentProfileResponse":
        return cls(
            id=model.id,
            display_name=model.display_name,
            language=model.language,
            timezone=model.timezone,
            has_pin=model.pin_hash is not None,
        )


class ParentProfileUpdate(BaseModel):
    display_name: str | None = Field(None, min_length=1, max_length=100)
    language: str | None = Field(None, pattern="^(vi|en)$")
    timezone: str | None = None


class SetPinRequest(BaseModel):
    pin: str = Field(..., min_length=4, max_length=6, pattern=r"^\d+$")


class VerifyPinRequest(BaseModel):
    pin: str = Field(..., min_length=4, max_length=6, pattern=r"^\d+$")


class VerifyPinResponse(BaseModel):
    verified: bool
    parent_session_token: str | None = None


# ─── Child Profile ─────────────────────────────────────────────────────────────

from datetime import date
from pydantic import ConfigDict

from .admin import (
    AdminGameUpdate,
    AdminLessonCreate,
    AdminLessonUpdate,
    AdminQuestionCreate,
    AdminQuestionUpdate,
)
from .child import ChildResponse, CreateChildRequest, UpdateChildRequest
from .lesson import GameLevelResponse, LessonDetailResponse, LessonResponse
from .progress import DailyPlanItem, ProgressResponse, SaveGameResultRequest, SkillReport
from .reports import (
    AttemptExportSummary,
    ChildExportProfile,
    ParentDataExport,
    ParentExportProfile,
    ParentReportSummary,
    ProgressExportItem,
    RewardExportItem,
    WeeklyReportEntry,
)
from .reward import ChildRewardResponse, RewardResponse
from .sync import (
    SyncAttemptItem,
    SyncContentResponse,
    SyncProgressItem,
    SyncStatusResponse,
)


ChildCreate = CreateChildRequest
ChildUpdate = UpdateChildRequest


class LessonListItem(LessonResponse):
    subject_name: str | None = None


class QuestionResponse(BaseModel):
    id: str
    question_type: str
    prompt: str
    options_json: list[dict] | None = None
    media_url: str | None = None
    difficulty: int


class LessonDetail(LessonResponse):
    content_json: dict | None = None
    questions: list[QuestionResponse] = Field(default_factory=list)
    subject_name: str | None = None


class LessonStartRequest(BaseModel):
    child_id: str


class LessonCompleteRequest(BaseModel):
    child_id: str
    mastery_score: float = Field(..., ge=0.0, le=1.0)


class GameListItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    game_type: str
    age_min: int
    age_max: int
    is_active: bool


class GameDetail(GameListItem):
    config_json: dict | None = None


class GameStartRequest(BaseModel):
    child_id: str


class GameAttemptRequest(BaseModel):
    child_id: str
    answer_json: dict = Field(default_factory=dict)
    response_time_ms: int = Field(default=0, ge=0)
    hint_count: int = Field(default=0, ge=0)


class GameCompleteRequest(BaseModel):
    child_id: str
    total_stars: int = Field(default=0, ge=0)
    badges_unlocked: list[str] = Field(default_factory=list)
    rewards_unlocked: list[str] = Field(default_factory=list)


class UnlockRewardRequest(BaseModel):
    reward_id: str


class AdminGameCreate(BaseModel):
    name: str = Field(..., max_length=100)
    game_type: str = Field(..., max_length=50)
    age_min: int = Field(default=5, ge=5, le=12)
    age_max: int = Field(default=12, ge=5, le=12)
    config_json: dict | None = None

__all__ = [
    # Auth
    "RegisterRequest",
    "LoginRequest",
    "RefreshRequest",
    "TokenResponse",
    "UserResponse",
    "AuthResponse",
    # Parent
    "ParentProfileResponse",
    "ParentProfileUpdate",
    "SetPinRequest",
    "VerifyPinRequest",
    "VerifyPinResponse",
    # Child
    "ChildResponse",
    "CreateChildRequest",
    "UpdateChildRequest",
    "ChildCreate",
    "ChildUpdate",
    # Lesson
    "LessonResponse",
    "LessonDetailResponse",
    "GameLevelResponse",
    "LessonListItem",
    "QuestionResponse",
    "LessonDetail",
    "LessonStartRequest",
    "LessonCompleteRequest",
    # Progress
    "ProgressResponse",
    "SkillReport",
    "DailyPlanItem",
    "SaveGameResultRequest",
    # Reward
    "RewardResponse",
    "ChildRewardResponse",
    "UnlockRewardRequest",
    # Games
    "GameListItem",
    "GameDetail",
    "GameStartRequest",
    "GameAttemptRequest",
    "GameCompleteRequest",
    # Sync
    "SyncStatusResponse",
    "SyncContentResponse",
    "SyncProgressItem",
    "SyncAttemptItem",
    # Reports
    "ParentReportSummary",
    "WeeklyReportEntry",
    "ParentDataExport",
    "ParentExportProfile",
    "ChildExportProfile",
    "ProgressExportItem",
    "RewardExportItem",
    "AttemptExportSummary",
    # Admin
    "AdminLessonCreate",
    "AdminLessonUpdate",
    "AdminQuestionCreate",
    "AdminQuestionUpdate",
    "AdminGameCreate",
    "AdminGameUpdate",
]
