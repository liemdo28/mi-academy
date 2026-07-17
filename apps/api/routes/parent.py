"""Parent routes — profile, PIN, reports."""

from datetime import date, datetime, time
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import Integer, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from apps.api.database import get_db
from apps.api.dependencies import (
    create_access_token,
    get_parent_profile,
    get_current_user,
    hash_password,
    verify_password,
    verify_parent_pin,
)
from apps.api.models import (
    ChildProfile,
    DailySession,
    Attempt,
    ParentProfile,
    Progress,
    Reward,
    ChildReward,
    User,
)
from apps.api.schemas import (
    ParentProfileResponse,
    ParentProfileUpdate,
    SetPinRequest,
    VerifyPinRequest,
    VerifyPinResponse,
    ParentReportSummary,
    WeeklyReportEntry,
    ParentDataExport,
    ParentExportProfile,
    ChildExportProfile,
    ProgressExportItem,
    RewardExportItem,
    AttemptExportSummary,
)
from apps.api.time import utc_now

router = APIRouter()


@router.get("/profile", response_model=ParentProfileResponse)
async def get_profile(
    profile: ParentProfile = Depends(get_parent_profile),
):
    return ParentProfileResponse.from_model(profile)


@router.put("/profile", response_model=ParentProfileResponse)
async def update_profile(
    body: ParentProfileUpdate,
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    if body.display_name is not None:
        profile.display_name = body.display_name
    if body.language is not None:
        profile.language = body.language
    if body.timezone is not None:
        profile.timezone = body.timezone
    await db.flush()
    return ParentProfileResponse.from_model(profile)


@router.put("/pin")
async def set_pin(
    body: SetPinRequest,
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    profile.pin_hash = hash_password(body.pin)
    await db.flush()
    return {"message": "PIN set successfully"}


@router.post("/pin/verify", response_model=VerifyPinResponse)
async def verify_pin(
    body: VerifyPinRequest,
    profile: ParentProfile = Depends(verify_parent_pin),
):
    # Generate a short-lived parent session token
    parent_token = create_access_token(
        {"sub": profile.user_id, "parent_pin_verified": "true"}
    )
    return VerifyPinResponse(verified=True, parent_session_token=parent_token)


@router.get("/reports", response_model=ParentReportSummary)
async def get_reports(
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    child_ids = [c.id for c in profile.children]

    if not child_ids:
        return ParentReportSummary(
            total_children=0,
            total_stars_today=0,
            total_games_today=0,
            total_lessons_today=0,
            total_time_minutes_today=0,
        )

    sessions_result = await db.execute(
        select(DailySession).where(
            DailySession.child_id.in_(child_ids),
            DailySession.session_date == today,
        )
    )
    sessions = sessions_result.scalars().all()

    # Count completed lessons from sessions and rewards from persisted unlocks.
    # This keeps the dashboard honest: no fabricated star totals.
    lessons_completed = sum(s.lessons_completed for s in sessions)
    games_completed = sum(s.games_completed for s in sessions)
    total_seconds = sum(s.duration_seconds for s in sessions)
    start_of_day = datetime.combine(today, time.min)
    end_of_day = datetime.combine(today, time.max)
    rewards_today_result = await db.execute(
        select(func.count(ChildReward.id)).where(
            ChildReward.child_id.in_(child_ids),
            ChildReward.unlocked_at >= start_of_day,
            ChildReward.unlocked_at <= end_of_day,
        )
    )
    rewards_today = rewards_today_result.scalar_one() or 0

    return ParentReportSummary(
        total_children=len(child_ids),
        total_stars_today=rewards_today,
        total_games_today=games_completed,
        total_lessons_today=lessons_completed,
        total_time_minutes_today=total_seconds // 60,
    )


@router.get("/reports/weekly", response_model=list[WeeklyReportEntry])
async def get_weekly_report(
    child_id: str,
    week: int = 0,  # 0 = current week, -1 = last week, etc.
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    # Verify child belongs to this parent
    if child_id not in [c.id for c in profile.children]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"error": {"code": "FORBIDDEN", "message": "Child not owned by this parent"}},
        )

    # Simple weekly: last 7 days from today
    sessions_result = await db.execute(
        select(DailySession)
        .where(DailySession.child_id == child_id)
        .order_by(DailySession.session_date)
    )
    sessions = sessions_result.scalars().all()

    return [
        WeeklyReportEntry(
            date=s.session_date,
            duration_seconds=s.duration_seconds,
            lessons_completed=s.lessons_completed,
            games_completed=s.games_completed,
        )
        for s in sessions[-7:]
    ]


@router.get("/export", response_model=ParentDataExport)
async def export_parent_data(
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    """Return a privacy-safe parent export without raw answers or contact data."""
    child_ids = [c.id for c in profile.children]

    if child_ids:
        sessions_result = await db.execute(
            select(DailySession)
            .where(DailySession.child_id.in_(child_ids))
            .order_by(DailySession.session_date)
        )
        progress_result = await db.execute(
            select(Progress)
            .where(Progress.child_id.in_(child_ids))
            .order_by(Progress.last_played_at)
        )
        rewards_result = await db.execute(
            select(ChildReward, Reward)
            .join(Reward, Reward.id == ChildReward.reward_id)
            .where(ChildReward.child_id.in_(child_ids))
            .order_by(ChildReward.unlocked_at)
        )
        attempts_result = await db.execute(
            select(
                Attempt.child_id,
                func.count(Attempt.id).label("total_attempts"),
                func.sum(func.cast(Attempt.is_correct, Integer)).label("correct_attempts"),
                func.sum(Attempt.hint_count).label("hint_count"),
            )
            .where(Attempt.child_id.in_(child_ids))
            .group_by(Attempt.child_id)
        )
        sessions = sessions_result.scalars().all()
        progress_rows = progress_result.scalars().all()
        reward_rows = rewards_result.all()
        attempt_rows = attempts_result.all()
    else:
        sessions = []
        progress_rows = []
        reward_rows = []
        attempt_rows = []

    return ParentDataExport(
        generated_at=utc_now(),
        parent=ParentExportProfile(
            id=profile.id,
            display_name=profile.display_name,
            language=profile.language,
            timezone=profile.timezone,
        ),
        children=[
            ChildExportProfile(
                id=child.id,
                nickname=child.nickname,
                age_group=child.age_group,
                preferred_language=child.preferred_language,
                daily_time_limit=child.daily_time_limit,
                created_at=child.created_at,
            )
            for child in profile.children
        ],
        daily_sessions=[
            WeeklyReportEntry(
                date=session.session_date,
                duration_seconds=session.duration_seconds,
                lessons_completed=session.lessons_completed,
                games_completed=session.games_completed,
            )
            for session in sessions
        ],
        progress=[
            ProgressExportItem(
                child_id=row.child_id,
                lesson_id=row.lesson_id,
                status=row.status,
                mastery_score=row.mastery_score,
                total_attempts=row.total_attempts,
                last_played_at=row.last_played_at,
            )
            for row in progress_rows
        ],
        rewards=[
            RewardExportItem(
                child_id=child_reward.child_id,
                reward_type=reward.reward_type,
                name=reward.name,
                unlocked_at=child_reward.unlocked_at,
            )
            for child_reward, reward in reward_rows
        ],
        attempts_summary=[
            AttemptExportSummary(
                child_id=row.child_id,
                total_attempts=row.total_attempts or 0,
                correct_attempts=row.correct_attempts or 0,
                hint_count=row.hint_count or 0,
            )
            for row in attempt_rows
        ],
    )
