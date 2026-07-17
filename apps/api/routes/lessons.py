"""Lessons routes."""

import json
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from apps.api.database import get_db
from apps.api.dependencies import get_parent_profile
from apps.api.models import ChildProfile, Lesson, ParentProfile, Progress, Question
from apps.api.time import utc_now
from apps.api.schemas import (
    LessonListItem,
    LessonDetail,
    LessonStartRequest,
    LessonCompleteRequest,
    QuestionResponse,
)

router = APIRouter()


def _child_belongs_to_parent(profile: ParentProfile, child_id: str):
    if child_id not in [c.id for c in profile.children]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"error": {"code": "FORBIDDEN", "message": "Child not owned by parent"}},
        )


@router.get("", response_model=list[LessonListItem])
async def list_lessons(
    age_group: str = Query(None),
    language: str = Query(None),
    db: AsyncSession = Depends(get_db),
):
    query = select(Lesson).where(Lesson.is_active == True)
    if age_group:
        query = query.where(Lesson.age_group == age_group)
    if language:
        query = query.where(Lesson.language == language)

    result = await db.execute(query.order_by(Lesson.difficulty))
    lessons = result.scalars().all()

    return [
        LessonListItem(
            id=l.id,
            subject_id=l.subject_id,
            title=l.title,
            description=l.description,
            age_group=l.age_group,
            difficulty=l.difficulty,
            language=l.language,
            estimated_minutes=l.estimated_minutes,
            is_active=l.is_active,
            subject_name=l.subject.name if l.subject else None,
        )
        for l in lessons
    ]


@router.get("/{lesson_id}", response_model=LessonDetail)
async def get_lesson(
    lesson_id: str,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Lesson).where(Lesson.id == lesson_id)
    )
    lesson = result.scalar_one_or_none()
    if not lesson:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Lesson not found"}},
        )

    # Load questions
    q_result = await db.execute(
        select(Question).where(Question.lesson_id == lesson_id)
    )
    questions = q_result.scalars().all()

    content_json = None
    if lesson.content_json:
        try:
            content_json = json.loads(lesson.content_json)
        except Exception:
            content_json = None

    return LessonDetail(
        id=lesson.id,
        title=lesson.title,
        description=lesson.description,
        age_group=lesson.age_group,
        difficulty=lesson.difficulty,
        language=lesson.language,
        estimated_minutes=lesson.estimated_minutes,
        content_json=content_json,
        questions=[
            QuestionResponse(
                id=q.id,
                question_type=q.question_type,
                prompt=q.prompt,
                options_json=json.loads(q.options_json) if q.options_json else None,
                media_url=q.media_url,
                difficulty=q.difficulty,
            )
            for q in questions
        ],
        subject_name=lesson.subject.name if lesson.subject else None,
    )


@router.get("/recommended")
async def get_recommended(
    child_id: str,
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    _child_belongs_to_parent(profile, child_id)

    # Get the child's age group
    child = next(c for c in profile.children if c.id == child_id)

    result = await db.execute(
        select(Lesson)
        .where(
            Lesson.is_active == True,
            Lesson.age_group == child.age_group,
        )
        .order_by(Lesson.difficulty)
    )
    lessons = result.scalars().all()

    # Return first 3 — in production this would use adaptive algorithm
    return [
        LessonListItem(
            id=l.id,
            subject_id=l.subject_id,
            title=l.title,
            description=l.description,
            age_group=l.age_group,
            difficulty=l.difficulty,
            language=l.language,
            estimated_minutes=l.estimated_minutes,
            is_active=l.is_active,
            subject_name=l.subject.name if l.subject else None,
        )
        for l in lessons[:3]
    ]


@router.post("/{lesson_id}/start")
async def start_lesson(
    lesson_id: str,
    body: LessonStartRequest,
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    _child_belongs_to_parent(profile, body.child_id)

    # Upsert progress — mark as learning
    result = await db.execute(
        select(Progress).where(
            Progress.child_id == body.child_id,
            Progress.lesson_id == lesson_id,
        )
    )
    progress = result.scalar_one_or_none()

    if progress:
        progress.status = "learning"
        progress.last_played_at = utc_now()
    else:
        progress = Progress(
            child_id=body.child_id,
            lesson_id=lesson_id,
            status="learning",
            mastery_score=0.0,
            total_attempts=0,
            last_played_at=utc_now(),
        )
        db.add(progress)

    await db.flush()
    return {"status": "started", "lesson_id": lesson_id, "child_id": body.child_id}


@router.post("/{lesson_id}/complete")
async def complete_lesson(
    lesson_id: str,
    body: LessonCompleteRequest,
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    _child_belongs_to_parent(profile, body.child_id)

    result = await db.execute(
        select(Progress).where(
            Progress.child_id == body.child_id,
            Progress.lesson_id == lesson_id,
        )
    )
    progress = result.scalar_one_or_none()

    if not progress:
        progress = Progress(
            child_id=body.child_id,
            lesson_id=lesson_id,
        )
        db.add(progress)

    progress.status = "completed" if body.mastery_score >= 0.7 else "needs_practice"
    progress.mastery_score = body.mastery_score
    progress.total_attempts += 1
    progress.last_played_at = utc_now()

    await db.flush()
    return {"status": progress.status, "mastery_score": progress.mastery_score}
