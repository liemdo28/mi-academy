"""Progress routes — per-child progress, skills, daily plan."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import Integer, select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from apps.api.adaptive_ranking import rank_lessons
from apps.api.database import get_db
from apps.api.dependencies import get_parent_profile
from apps.api.models import ParentProfile, Progress, Attempt, Lesson
from apps.api.schemas import ProgressResponse, SkillReport, DailyPlanItem

router = APIRouter()

# There is no explicit lesson/subject -> game data-model link, so this maps
# each subject taxonomy code (see infrastructure/seed/seed_data.py) to the
# game engine that best fits it. A content-modeling heuristic, not a
# fabricated 1:1 mapping: subjects without a dedicated game (science,
# life_skills) fall back to memory_cards rather than inventing a mismatch.
_SUBJECT_TO_GAME_TYPE = {
    "letters": "word_builder",
    "math": "math_race",
    "logic": "robot_commands",
}
_DEFAULT_GAME_TYPE = "memory_cards"


def _game_type_for_lesson(lesson: Lesson) -> str:
    if not lesson.subject:
        return _DEFAULT_GAME_TYPE
    return _SUBJECT_TO_GAME_TYPE.get(lesson.subject.code, _DEFAULT_GAME_TYPE)


def _child_belongs_to_parent(profile: ParentProfile, child_id: str):
    if child_id not in [c.id for c in profile.children]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "error": {"code": "FORBIDDEN", "message": "Child not owned by parent"}
            },
        )


@router.get("/children/{child_id}/progress", response_model=list[ProgressResponse])
async def get_child_progress(
    child_id: str,
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    """Return per-lesson progress for a child."""
    _child_belongs_to_parent(profile, child_id)

    result = await db.execute(select(Progress).where(Progress.child_id == child_id))
    rows = result.scalars().all()
    return [
        ProgressResponse(
            id=r.id,
            lesson_id=r.lesson_id,
            status=r.status,
            mastery_score=r.mastery_score,
            total_attempts=r.total_attempts,
            last_played_at=r.last_played_at.isoformat() if r.last_played_at else None,
        )
        for r in rows
    ]


@router.get("/children/{child_id}/skills", response_model=list[SkillReport])
async def get_child_skills(
    child_id: str,
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    """Analyze attempts to report strong and weak skills."""
    _child_belongs_to_parent(profile, child_id)

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
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    """Return today's recommended learning plan (up to 4 items), ranked by
    the child's own Progress -- see adaptive_ranking.rank_lessons. This is
    the endpoint the child home screen's hero CTA and "today's mission"
    list actually consume, so this ranking is what a child sees next, not
    just an unused parallel recommendation."""
    _child_belongs_to_parent(profile, child_id)
    child = next(c for c in profile.children if c.id == child_id)

    lessons_result = await db.execute(
        select(Lesson)
        .options(selectinload(Lesson.subject))
        .where(
            Lesson.age_group == child.age_group,
            Lesson.is_active == True,
        )
    )
    all_lessons = lessons_result.scalars().all()

    progress_result = await db.execute(
        select(Progress).where(Progress.child_id == child_id)
    )
    progress_by_lesson = {p.lesson_id: p for p in progress_result.scalars().all()}
    lessons = rank_lessons(all_lessons, progress_by_lesson)[:4]
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
                game_type=_game_type_for_lesson(lesson),
            )
        )
    return items
