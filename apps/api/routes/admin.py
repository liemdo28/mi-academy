"""Admin routes — lesson CRUD, question CRUD, game CRUD, analytics."""

from fastapi import APIRouter, HTTPException, status, Depends
from sqlalchemy import Integer, select, func
from sqlalchemy.ext.asyncio import AsyncSession
import uuid
import json

from apps.api.database import get_db
from apps.api.dependencies import require_role
from apps.api.models import (
    Lesson,
    Question,
    Game,
    Attempt,
    Progress,
    ChildProfile,
)
from apps.api.schemas import (
    AdminLessonCreate,
    AdminLessonUpdate,
    AdminQuestionCreate,
    AdminGameCreate,
)
from apps.api.models import User as AuthUser

router = APIRouter()


def _require_admin():
    return require_role("admin", "content_admin")


# ── Lessons ─────────────────────────────────────────────────────────────────────


@router.post("/lessons", status_code=status.HTTP_201_CREATED)
async def create_lesson(
    body: AdminLessonCreate,
    _: AuthUser = Depends(_require_admin()),
    db: AsyncSession = Depends(get_db),
):
    lesson = Lesson(
        id=str(uuid.uuid4()),
        subject_id=body.subject_id,
        title=body.title,
        description=body.description,
        age_group=body.age_group,
        difficulty=body.difficulty,
        language=body.language,
        estimated_minutes=body.estimated_minutes,
        content_json=json.dumps(body.content_json) if body.content_json else None,
    )
    db.add(lesson)
    await db.commit()
    return {"id": lesson.id, "created": True}


@router.put("/lessons/{lesson_id}")
async def update_lesson(
    lesson_id: str,
    body: AdminLessonUpdate,
    _: AuthUser = Depends(_require_admin()),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Lesson).where(Lesson.id == lesson_id))
    lesson = result.scalar_one_or_none()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found")
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(lesson, field, value)
    if body.content_json:
        lesson.content_json = json.dumps(body.content_json)
    await db.commit()
    return {"updated": True}


@router.delete("/lessons/{lesson_id}")
async def delete_lesson(
    lesson_id: str,
    _: AuthUser = Depends(_require_admin()),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Lesson).where(Lesson.id == lesson_id))
    lesson = result.scalar_one_or_none()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found")
    lesson.is_active = False
    await db.commit()
    return {"deleted": True, "soft": True}


# ── Questions ───────────────────────────────────────────────────────────────────


@router.post("/questions", status_code=status.HTTP_201_CREATED)
async def create_question(
    body: AdminQuestionCreate,
    _: AuthUser = Depends(_require_admin()),
    db: AsyncSession = Depends(get_db),
):
    question = Question(
        id=str(uuid.uuid4()),
        lesson_id=body.lesson_id,
        question_type=body.question_type,
        prompt=body.prompt,
        options_json=json.dumps(body.options_json) if body.options_json else None,
        correct_answer_json=json.dumps(body.correct_answer_json)
        if body.correct_answer_json
        else None,
        explanation=body.explanation,
        media_url=body.media_url,
        difficulty=body.difficulty,
    )
    db.add(question)
    await db.commit()
    return {"id": question.id, "created": True}


@router.get("/questions/high-error-rate")
async def high_error_questions(
    threshold: float = 0.5,
    _: AuthUser = Depends(_require_admin()),
    db: AsyncSession = Depends(get_db),
):
    """Return questions with >threshold error rate."""
    sub = (
        select(
            Attempt.question_id,
            func.count(Attempt.id).label("total"),
            func.sum(func.cast(Attempt.is_correct == False, Integer)).label("errors"),
        )
        .where(Attempt.question_id != None)
        .group_by(Attempt.question_id)
        .subquery()
    )
    result = await db.execute(
        select(
            Question,
            (sub.c.errors / sub.c.total).label("error_rate"),
            sub.c.total,
        )
        .join(sub, sub.c.question_id == Question.id)
        .where((sub.c.errors / sub.c.total) > threshold)
    )
    rows = result.all()
    return [
        {
            "question_id": q.id,
            "prompt": q.prompt,
            "error_rate": round(er, 3),
            "total_attempts": t,
        }
        for q, er, t in rows
    ]


# ── Games ───────────────────────────────────────────────────────────────────────


@router.post("/games", status_code=status.HTTP_201_CREATED)
async def create_game(
    body: AdminGameCreate,
    _: AuthUser = Depends(_require_admin()),
    db: AsyncSession = Depends(get_db),
):
    game = Game(
        id=str(uuid.uuid4()),
        name=body.name,
        game_type=body.game_type,
        age_min=body.age_min,
        age_max=body.age_max,
        config_json=json.dumps(body.config_json) if body.config_json else None,
    )
    db.add(game)
    await db.commit()
    return {"id": game.id, "created": True}


@router.put("/games/{game_id}")
async def update_game(
    game_id: str,
    body: dict,
    _: AuthUser = Depends(_require_admin()),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Game).where(Game.id == game_id))
    game = result.scalar_one_or_none()
    if not game:
        raise HTTPException(status_code=404, detail="Game not found")
    if "name" in body:
        game.name = body["name"]
    if "is_active" in body:
        game.is_active = body["is_active"]
    if "config_json" in body:
        game.config_json = json.dumps(body["config_json"])
    await db.commit()
    return {"updated": True}


# ── Analytics ───────────────────────────────────────────────────────────────────


@router.get("/analytics")
async def analytics(
    _: AuthUser = Depends(_require_admin()),
    db: AsyncSession = Depends(get_db),
):
    """Aggregate usage stats for admin dashboard."""
    total_children = await db.execute(select(func.count(ChildProfile.id)))
    total_attempts = await db.execute(select(func.count(Attempt.id)))
    total_lessons = await db.execute(select(func.count(Lesson.id)))
    active_games = await db.execute(
        select(func.count(Game.id)).where(Game.is_active == True)
    )
    return {
        "total_children": total_children.scalar_one(),
        "total_attempts": total_attempts.scalar_one(),
        "total_lessons": total_lessons.scalar_one(),
        "active_games": active_games.scalar_one(),
    }


@router.get("/analytics/completion-rate")
async def completion_rate(
    lesson_id: str | None = None,
    _: AuthUser = Depends(_require_admin()),
    db: AsyncSession = Depends(get_db),
):
    """Return completion rate for lessons."""
    query = select(
        Progress.lesson_id,
        func.count(Progress.id).label("total"),
        func.sum(
            func.cast(Progress.status.in_(["completed", "mastered"]), Integer)
        ).label("done"),
    ).group_by(Progress.lesson_id)
    if lesson_id:
        query = query.where(Progress.lesson_id == lesson_id)
    result = await db.execute(query)
    rows = result.all()
    return [
        {
            "lesson_id": r.lesson_id,
            "total": r.total,
            "completed": r.done or 0,
            "rate": round((r.done or 0) / r.total * 100, 1) if r.total else 0,
        }
        for r in rows
    ]
