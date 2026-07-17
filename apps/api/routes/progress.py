"""Progress routes — per-child progress, skills, daily plan."""

from datetime import date, timedelta
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import Integer, select, func
from sqlalchemy.ext.asyncio import AsyncSession

from apps.api.database import get_db
from apps.api.dependencies import get_current_user
from apps.api.models import ChildProfile, Progress, Attempt, Lesson, DailySession
from apps.api.schemas import ProgressResponse, SkillReport, DailyPlanItem
from apps.api.models import User

router = APIRouter()


@router.get("/children/{child_id}/progress", response_model=list[ProgressResponse])
async def get_child_progress(
    child_id: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Return per-lesson progress for a child."""
    result = await db.execute(
        select(Progress).where(Progress.child_id == child_id)
    )
    rows = result.scalars().all()
    return [
        ProgressResponse(
            id=r.id,
            lesson_id=r.lesson_id,
            status=r.status,
            mastery_score=r.mastery_score,
            total_attempts=r.total_attempts,
            last_played_at=r.last_played_at,
        )
        for r in rows
    ]


@router.get("/children/{child_id}/skills", response_model=list[SkillReport])
async def get_child_skills(
    child_id: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Analyze attempts to report strong and weak skills."""
    result = await db.execute(
        select(
            Lesson.subject_id,
            func.count(Attempt.id).label("total"),
            func.sum(func.cast(Attempt.is_correct, Integer)).label("correct"),
        )
        .join(Attempt, Attempt.lesson_id == Lesson.id)
        .where(Attempt.child_id == child_id)
        .group_by(Lesson.subject_id)
    )
    rows = result.all()
    reports = []
    for row in rows:
        total = row.total or 1
        correct = row.correct or 0
        pct = correct / total * 100
        reports.append(
            SkillReport(
                subject_id=row.subject_id,
                skill_name=row.subject_id,  # resolved later
                correct_count=correct,
                total_attempts=total,
                accuracy_pct=round(pct, 1),
                strength="strong" if pct >= 70 else "weak",
            )
        )
    return reports


@router.get("/children/{child_id}/daily-plan", response_model=list[DailyPlanItem])
async def get_daily_plan(
    child_id: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Return today's recommended learning plan (up to 4 items)."""
    child_result = await db.execute(
        select(ChildProfile).where(ChildProfile.id == child_id)
    )
    child = child_result.scalar_one_or_none()
    if not child:
        raise HTTPException(status_code=404, detail="Child not found")

    # Recommend one lesson from each subject area for this age group
    lessons_result = await db.execute(
        select(Lesson)
        .where(
            Lesson.age_group == child.age_group,
            Lesson.is_active == True,
        )
        .limit(4)
    )
    lessons = lessons_result.scalars().all()
    items = []
    for lesson in lessons:
        items.append(
            DailyPlanItem(
                lesson_id=lesson.id,
                title=lesson.title,
                subject=lesson.subject_id,
                estimated_minutes=lesson.estimated_minutes,
                type="lesson",
                is_required=True,
            )
        )
    return items
