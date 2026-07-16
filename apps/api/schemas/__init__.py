"""Pydantic DTOs — shared across all routes."""

from datetime import datetime, date
from typing import Any, Generic, List, Optional, TypeVar
from pydantic import BaseModel, EmailStr, Field

# ── Generic paginated response ──────────────────────────────────────────────────

T = TypeVar("T")


class PaginatedResponse(BaseModel, Generic[T]):
    items: List[T]
    total: int
    page: int
    page_size: int


class ErrorDetail(BaseModel):
    code: str
    message: str


class ErrorResponse(BaseModel):
    error: ErrorDetail


# ── Auth ───────────────────────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    email: str
    password: str
    display_name: str
    language: str = "vi"


class LoginRequest(BaseModel):
    email: str
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class AuthResponse(BaseModel):
    user: "UserResponse"
    parent_profile: "ParentProfileResponse"
    access_token: str
    refresh_token: str


# ── User / Parent ───────────────────────────────────────────────────────────────

class UserResponse(BaseModel):
    id: str
    role: str
    email: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


class ParentProfileResponse(BaseModel):
    id: str
    display_name: str
    language: str
    timezone: str
    pin_is_set: bool = False

    class Config:
        from_attributes = True

    @classmethod
    def from_model(cls, model) -> "ParentProfileResponse":
        return cls(
            id=model.id,
            display_name=model.display_name,
            language=model.language,
            timezone=model.timezone,
            pin_is_set=model.pin_hash is not None,
        )


class ParentProfileUpdate(BaseModel):
    display_name: Optional[str] = None
    language: Optional[str] = None
    timezone: Optional[str] = None


class SetPinRequest(BaseModel):
    pin: str = Field(..., min_length=4, max_length=4, pattern=r"^\d{4}$")


class VerifyPinRequest(BaseModel):
    pin: str = Field(..., min_length=4, max_length=4, pattern=r"^\d{4}$")


class VerifyPinResponse(BaseModel):
    verified: bool
    parent_session_token: Optional[str] = None


class ParentReportSummary(BaseModel):
    total_children: int
    total_stars_today: int
    total_games_today: int
    total_lessons_today: int
    total_time_minutes_today: int


class WeeklyReportEntry(BaseModel):
    date: date
    duration_seconds: int
    lessons_completed: int
    games_completed: int


# ── Children ────────────────────────────────────────────────────────────────────

class ChildCreate(BaseModel):
    nickname: str = Field(..., max_length=20)
    birth_year: Optional[int] = None
    age_group: str  # junior | explorer | master
    grade_level: Optional[str] = None
    avatar_id: str = "avatar_01"
    preferred_language: str = "vi"
    daily_time_limit: Optional[int] = None


class ChildUpdate(BaseModel):
    nickname: Optional[str] = None
    birth_year: Optional[int] = None
    age_group: Optional[str] = None
    grade_level: Optional[str] = None
    avatar_id: Optional[str] = None
    preferred_language: Optional[str] = None
    daily_time_limit: Optional[int] = None


class ChildResponse(BaseModel):
    id: str
    nickname: str
    birth_year: Optional[int]
    age_group: str
    grade_level: Optional[str]
    avatar_id: str
    preferred_language: str
    daily_time_limit: Optional[int]
    created_at: datetime

    class Config:
        from_attributes = True


# ── Lessons ────────────────────────────────────────────────────────────────────

class LessonListItem(BaseModel):
    id: str
    title: str
    description: Optional[str]
    age_group: str
    difficulty: int
    language: str
    estimated_minutes: int
    is_active: bool
    subject_name: Optional[str] = None

    class Config:
        from_attributes = True


class LessonDetail(BaseModel):
    id: str
    title: str
    description: Optional[str]
    age_group: str
    difficulty: int
    language: str
    estimated_minutes: int
    content_json: Optional[dict]
    questions: List["QuestionResponse"] = []
    subject_name: Optional[str] = None

    class Config:
        from_attributes = True


class LessonStartRequest(BaseModel):
    child_id: str


class LessonCompleteRequest(BaseModel):
    child_id: str
    mastery_score: float = Field(..., ge=0.0, le=1.0)


# ── Games ───────────────────────────────────────────────────────────────────────

class GameListItem(BaseModel):
    id: str
    name: str
    game_type: str
    age_min: int
    age_max: int
    is_active: bool

    class Config:
        from_attributes = True


class GameDetail(BaseModel):
    id: str
    name: str
    game_type: str
    age_min: int
    age_max: int
    config_json: Optional[dict]
    is_active: bool

    class Config:
        from_attributes = True


class GameStartRequest(BaseModel):
    child_id: str


class GameAttemptRequest(BaseModel):
    child_id: str
    answer_json: dict
    response_time_ms: int = 0
    hint_count: int = 0


class GameCompleteRequest(BaseModel):
    child_id: str
    total_stars: int = Field(..., ge=0)
    badges_unlocked: List[str] = []
    rewards_unlocked: List[str] = []


# ── Questions ───────────────────────────────────────────────────────────────────

class QuestionResponse(BaseModel):
    id: str
    question_type: str
    prompt: str
    options_json: Optional[List[Any]] = None
    media_url: Optional[str]
    difficulty: int

    class Config:
        from_attributes = True


# ── Progress ───────────────────────────────────────────────────────────────────

class ProgressResponse(BaseModel):
    id: Optional[str] = None
    lesson_id: str
    status: str
    mastery_score: float
    total_attempts: int
    last_played_at: Optional[datetime]

    class Config:
        from_attributes = True


class SkillReport(BaseModel):
    subject_id: str
    skill_name: Optional[str] = None
    correct_count: int = 0
    total_attempts: int = 0
    accuracy_pct: float = 0.0
    strength: str = "unknown"  # strong | weak | unknown


class SkillScore(BaseModel):
    skill_name: str
    score: float  # 0-1
    attempts: int


class DailyPlanItem(BaseModel):
    lesson_id: Optional[str] = None
    title: str
    subject: Optional[str] = None
    age_group: str = "junior"
    estimated_minutes: int = 5
    game_type: Optional[str] = None
    type: str = "lesson"  # lesson | game
    is_required: bool = True


class DailyPlanResponse(BaseModel):
    items: List[DailyPlanItem]
    date: date


# ── Rewards ─────────────────────────────────────────────────────────────────────

class RewardResponse(BaseModel):
    id: str
    reward_type: str
    name: str
    description: Optional[str]
    asset_url: Optional[str]
    is_unlocked: bool = False
    unlocked_at: Optional[datetime]

    class Config:
        from_attributes = True


class UnlockRewardRequest(BaseModel):
    reward_id: str


class RewardCatalog(BaseModel):
    unlocked: List[RewardResponse]
    locked: List[RewardResponse]


# ── Sync ───────────────────────────────────────────────────────────────────────

class ContentDelta(BaseModel):
    content_type: str
    version: int
    checksum: str
    items: List[dict]


class SyncContentResponse(BaseModel):
    content_type: str
    version: int
    items: List[dict]
    deleted_ids: List[str] = []


class SyncProgressItem(BaseModel):
    id: Optional[str] = None
    child_id: str
    lesson_id: str
    status: str
    mastery_score: float
    total_attempts: int
    last_played_at: Optional[datetime] = None


class SyncAttemptItem(BaseModel):
    id: str
    child_id: str
    lesson_id: Optional[str]
    game_id: Optional[str]
    question_id: Optional[str]
    answer_json: dict
    is_correct: bool
    response_time_ms: int
    hint_count: int
    created_at: datetime


class SyncStatusResponse(BaseModel):
    lessons_version: int
    questions_version: int
    games_version: int
    server_time: datetime


# ── Admin ───────────────────────────────────────────────────────────────────────

class AdminLessonCreate(BaseModel):
    subject_id: str
    title: str
    description: Optional[str] = None
    age_group: str
    difficulty: int = 1
    language: str = "vi"
    estimated_minutes: int = 5
    content_json: Optional[dict] = None


class AdminLessonUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    age_group: Optional[str] = None
    difficulty: Optional[int] = None
    content_json: Optional[dict] = None
    is_active: Optional[bool] = None


class AdminQuestionCreate(BaseModel):
    lesson_id: Optional[str] = None
    question_type: str
    prompt: str
    options_json: Optional[List[Any]] = None
    correct_answer_json: Optional[dict] = None
    explanation: Optional[str] = None
    media_url: Optional[str] = None
    difficulty: int = 1


class AdminGameCreate(BaseModel):
    name: str
    game_type: str
    age_min: int = 5
    age_max: int = 12
    config_json: Optional[dict] = None


# Update forward refs
LessonDetail.model_rebuild()
