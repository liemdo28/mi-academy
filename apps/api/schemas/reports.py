"""Report schemas — parent dashboard summaries and parent data export."""

from datetime import date, datetime
from pydantic import BaseModel, Field


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


class ParentExportProfile(BaseModel):
    id: str
    display_name: str
    language: str
    timezone: str


class ChildExportProfile(BaseModel):
    id: str
    nickname: str
    age_group: str
    preferred_language: str
    daily_time_limit: int | None
    created_at: datetime


class ProgressExportItem(BaseModel):
    child_id: str
    lesson_id: str
    status: str
    mastery_score: float
    total_attempts: int
    last_played_at: datetime | None


class RewardExportItem(BaseModel):
    child_id: str
    reward_type: str
    name: str
    unlocked_at: datetime


class AttemptExportSummary(BaseModel):
    child_id: str
    total_attempts: int
    correct_attempts: int
    hint_count: int


class ParentDataExport(BaseModel):
    schema_version: str = "mi-academy-parent-export-v1"
    generated_at: datetime
    parent: ParentExportProfile
    children: list[ChildExportProfile]
    daily_sessions: list[WeeklyReportEntry]
    progress: list[ProgressExportItem]
    rewards: list[RewardExportItem]
    attempts_summary: list[AttemptExportSummary]
    privacy: dict[str, bool] = Field(
        default_factory=lambda: {
            "contains_child_contact_info": False,
            "contains_location_data": False,
            "contains_raw_answers": False,
            "shared_with_third_parties": False,
        }
    )
