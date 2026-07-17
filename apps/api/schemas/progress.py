"""Progress schemas — game results, mastery, daily plan."""

from datetime import datetime
from pydantic import BaseModel, Field


class ProgressResponse(BaseModel):
    id: str
    lesson_id: str
    status: str
    mastery_score: float
    total_attempts: int
    last_played_at: str | None


class SkillReport(BaseModel):
    subject_id: str
    skill_name: str
    correct_count: int
    total_attempts: int
    accuracy_pct: float
    strength: str  # "strong" | "weak" | "developing"


class DailyPlanItem(BaseModel):
    lesson_id: str
    title: str
    subject: str
    estimated_minutes: int
    type: str = "lesson"  # lesson | game | review
    is_required: bool = True


# ─── Game Result (MiGameResult contract) ──────────────────────────────────────

class AccessibilityPreferencesSchema(BaseModel):
    high_contrast: bool = False
    large_text: bool = False
    reduce_motion: bool = False
    screen_reader: bool = False
    font_size: float = 1.0


class AudioPreferencesSchema(BaseModel):
    music_volume: float = Field(default=0.8, ge=0.0, le=1.0)
    sfx_volume: float = Field(default=1.0, ge=0.0, le=1.0)
    speech_enabled: bool = True


class SaveGameResultRequest(BaseModel):
    """Platform receives MiGameResult from the game layer."""
    attempt_id: str = Field(..., description="UUID idempotency key")
    child_profile_id: str
    game_id: str
    level_id: str
    started_at: datetime
    completed_at: datetime
    attempt_count: int = Field(..., ge=0)
    correct_count: int = Field(..., ge=0)
    incorrect_count: int = Field(..., ge=0)
    hint_count: int = Field(default=0, ge=0)
    duration_seconds: int = Field(..., ge=0)
    completed: bool = False
    mastery_evidence: float = Field(default=0.0, ge=0.0, le=1.0)
    skill_evidence: dict = Field(default_factory=dict)
    metadata: dict = Field(default_factory=dict)
