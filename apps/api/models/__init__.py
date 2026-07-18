"""SQLAlchemy models — mirrors docs/DATABASE_SCHEMA.md exactly."""

from datetime import datetime
from typing import Optional
import uuid

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    Index,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from apps.api.database import Base
from apps.api.time import utc_now


def _uuid() -> str:
    return str(uuid.uuid4())


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    role: Mapped[str] = mapped_column(String(20), nullable=False)  # parent | admin | content_admin
    email: Mapped[Optional[str]] = mapped_column(String(255), unique=True, nullable=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now
    )

    parent_profile: Mapped[Optional["ParentProfile"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
    )


class ParentProfile(Base):
    __tablename__ = "parent_profiles"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    display_name: Mapped[str] = mapped_column(String(100), nullable=False)
    language: Mapped[str] = mapped_column(String(10), default="vi")
    timezone: Mapped[str] = mapped_column(String(50), default="Asia/Ho_Chi_Minh")
    pin_hash: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    # Server-side PIN brute-force lockout. The PIN is only 4-6 digits
    # (10,000-1,000,000 combinations) and the mobile app's own 3-attempt
    # lockout is client-side only -- calling the API directly bypasses it
    # entirely, so this must be enforced here too.
    pin_failed_attempts: Mapped[int] = mapped_column(Integer, default=0)
    pin_locked_until: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    user: Mapped["User"] = relationship(back_populates="parent_profile")
    children: Mapped[list["ChildProfile"]] = relationship(
        back_populates="parent",
        cascade="all, delete-orphan",
    )


class ChildProfile(Base):
    __tablename__ = "child_profiles"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    parent_id: Mapped[str] = mapped_column(String(36), ForeignKey("parent_profiles.id"), nullable=False)
    nickname: Mapped[str] = mapped_column(String(50), nullable=False)
    birth_year: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    age_group: Mapped[str] = mapped_column(String(20), nullable=False)  # junior | explorer | master
    grade_level: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    avatar_id: Mapped[str] = mapped_column(String(50), default="avatar_01")
    preferred_language: Mapped[str] = mapped_column(String(10), default="vi")
    daily_time_limit: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)  # minutes
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    parent: Mapped["ParentProfile"] = relationship(back_populates="children")
    attempts: Mapped[list["Attempt"]] = relationship(
        back_populates="child",
        cascade="all, delete-orphan",
    )
    progress: Mapped[list["Progress"]] = relationship(
        back_populates="child",
        cascade="all, delete-orphan",
    )
    rewards: Mapped[list["ChildReward"]] = relationship(
        back_populates="child",
        cascade="all, delete-orphan",
    )
    daily_sessions: Mapped[list["DailySession"]] = relationship(
        back_populates="child",
        cascade="all, delete-orphan",
    )


class Subject(Base):
    __tablename__ = "subjects"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    icon: Mapped[str] = mapped_column(String(100), nullable=True)
    order_index: Mapped[int] = mapped_column(Integer, default=0)

    lessons: Mapped[list["Lesson"]] = relationship(back_populates="subject")


class Lesson(Base):
    __tablename__ = "lessons"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    subject_id: Mapped[str] = mapped_column(String(36), ForeignKey("subjects.id"), nullable=False)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    age_group: Mapped[str] = mapped_column(String(20), nullable=False)
    difficulty: Mapped[int] = mapped_column(Integer, default=1)  # 1-5
    language: Mapped[str] = mapped_column(String(10), default="vi")
    estimated_minutes: Mapped[int] = mapped_column(Integer, default=5)
    content_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True)  # JSON
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    subject: Mapped["Subject"] = relationship(back_populates="lessons")
    questions: Mapped[list["Question"]] = relationship(back_populates="lesson")
    progress: Mapped[list["Progress"]] = relationship(back_populates="lesson")


class Game(Base):
    __tablename__ = "games"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    game_type: Mapped[str] = mapped_column(String(50), nullable=False)
    # game_type: word_builder | sound_match | math_race | math_supermarket | memory_cards | robot_commands
    age_min: Mapped[int] = mapped_column(Integer, default=5)
    age_max: Mapped[int] = mapped_column(Integer, default=12)
    config_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True)  # JSON
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    attempts: Mapped[list["Attempt"]] = relationship(back_populates="game")


class Question(Base):
    __tablename__ = "questions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    lesson_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("lessons.id"), nullable=True)
    question_type: Mapped[str] = mapped_column(String(50), nullable=False)
    prompt: Mapped[str] = mapped_column(Text, nullable=False)
    options_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True)  # JSON array
    correct_answer_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True)  # JSON
    explanation: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    media_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    difficulty: Mapped[int] = mapped_column(Integer, default=1)  # 1-5

    lesson: Mapped[Optional["Lesson"]] = relationship(back_populates="questions")
    attempts: Mapped[list["Attempt"]] = relationship(back_populates="question")


class Attempt(Base):
    __tablename__ = "attempts"
    __table_args__ = (
        Index("idx_attempts_child_created", "child_id", "created_at"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    client_attempt_id: Mapped[Optional[str]] = mapped_column(String(64), unique=True, nullable=True)
    child_id: Mapped[str] = mapped_column(String(36), ForeignKey("child_profiles.id"), nullable=False)
    lesson_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("lessons.id"), nullable=True)
    game_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("games.id"), nullable=True)
    question_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("questions.id"), nullable=True)
    answer_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True)  # JSON
    is_correct: Mapped[bool] = mapped_column(Boolean, default=False)
    response_time_ms: Mapped[int] = mapped_column(Integer, default=0)
    hint_count: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    child: Mapped["ChildProfile"] = relationship(back_populates="attempts")
    game: Mapped[Optional["Game"]] = relationship(back_populates="attempts")
    question: Mapped[Optional["Question"]] = relationship(back_populates="attempts")


class Progress(Base):
    __tablename__ = "progress"
    __table_args__ = (
        Index("idx_progress_child", "child_id"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    child_id: Mapped[str] = mapped_column(String(36), ForeignKey("child_profiles.id"), nullable=False)
    lesson_id: Mapped[str] = mapped_column(String(36), ForeignKey("lessons.id"), nullable=False)
    status: Mapped[str] = mapped_column(
        String(30),
        default="not_started"
    )  # not_started | learning | completed | needs_practice | mastered
    mastery_score: Mapped[float] = mapped_column(Float, default=0.0)  # 0-1
    total_attempts: Mapped[int] = mapped_column(Integer, default=0)
    last_played_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    child: Mapped["ChildProfile"] = relationship(back_populates="progress")
    lesson: Mapped["Lesson"] = relationship(back_populates="progress")


class Reward(Base):
    __tablename__ = "rewards"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    reward_type: Mapped[str] = mapped_column(String(30), nullable=False)  # star | badge | sticker | avatar_item
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    asset_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    unlock_requirement_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True)  # JSON

    child_rewards: Mapped[list["ChildReward"]] = relationship(back_populates="reward")


class ChildReward(Base):
    __tablename__ = "child_rewards"
    __table_args__ = (
        UniqueConstraint("child_id", "reward_id", name="uq_child_reward_once"),
        # The (child_id, reward_id) unique constraint's index only helps
        # child_id-prefixed lookups, not the child_id + unlocked_at range
        # scan get_reports()'s "rewards today" count does on every parent
        # dashboard load.
        Index("idx_child_rewards_child_unlocked", "child_id", "unlocked_at"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    child_id: Mapped[str] = mapped_column(String(36), ForeignKey("child_profiles.id"), nullable=False)
    reward_id: Mapped[str] = mapped_column(String(36), ForeignKey("rewards.id"), nullable=False)
    unlocked_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    child: Mapped["ChildProfile"] = relationship(back_populates="rewards")
    reward: Mapped["Reward"] = relationship(back_populates="child_rewards")


class DailySession(Base):
    __tablename__ = "daily_sessions"
    __table_args__ = (
        # Every parent dashboard/report load filters by child_id (single or
        # in_(child_ids)) with no index at all otherwise -- a full table
        # scan that only gets worse as sessions accumulate.
        Index("idx_daily_sessions_child", "child_id"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    child_id: Mapped[str] = mapped_column(String(36), ForeignKey("child_profiles.id"), nullable=False)
    session_date: Mapped[datetime] = mapped_column(Date, nullable=False)
    duration_seconds: Mapped[int] = mapped_column(Integer, default=0)
    lessons_completed: Mapped[int] = mapped_column(Integer, default=0)
    games_completed: Mapped[int] = mapped_column(Integer, default=0)

    child: Mapped["ChildProfile"] = relationship(back_populates="daily_sessions")


class ContentVersion(Base):
    __tablename__ = "content_versions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    content_type: Mapped[str] = mapped_column(String(30), nullable=False)  # lessons | questions | games
    version: Mapped[int] = mapped_column(Integer, default=1)
    checksum: Mapped[str] = mapped_column(String(64), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)


class RefreshToken(Base):
    """Server-side record of every issued refresh token, keyed by its JWT
    `jti` claim -- without this, refresh JWTs are self-validating forever
    up to their expiry and `/auth/logout` cannot actually end a session
    (a stolen refresh token would remain valid until it naturally expired,
    regardless of "logout")."""
    __tablename__ = "refresh_tokens"
    __table_args__ = (
        Index("idx_refresh_tokens_user", "user_id"),
    )

    jti: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoked_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
