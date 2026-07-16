"""Parent routes — profile, PIN, reports."""

from datetime import date
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
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
    ChildResponse,
)

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
    db: AsyncSession = get_db,
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
    db: AsyncSession = get_db,
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
    db: AsyncSession = get_db,
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

    # Count completed lessons today from sessions
    lessons_completed = sum(s.lessons_completed for s in sessions)
    games_completed = sum(s.games_completed for s in sessions)
    total_seconds = sum(s.duration_seconds for s in sessions)

    return ParentReportSummary(
        total_children=len(child_ids),
        total_stars_today=lessons_completed,  # Simplified — stars tracked via rewards
        total_games_today=games_completed,
        total_lessons_today=lessons_completed,
        total_time_minutes_today=total_seconds // 60,
    )


@router.get("/reports/weekly", response_model=list[WeeklyReportEntry])
async def get_weekly_report(
    child_id: str,
    week: int = 0,  # 0 = current week, -1 = last week, etc.
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = get_db,
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
