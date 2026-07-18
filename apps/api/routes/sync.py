"""Sync routes — content delta, progress upsert, attempts, status."""

import json
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from apps.api.database import get_db
from apps.api.dependencies import get_parent_profile
from apps.api.time import utc_now
from apps.api.models import (
    Attempt,
    DailySession,
    Progress,
    Lesson,
    Question,
    Game,
    ContentVersion,
    ParentProfile,
)
from apps.api.schemas import (
    SyncContentResponse,
    SyncProgressItem,
    SyncAttemptItem,
    SyncSessionItem,
    SyncStatusResponse,
)

router = APIRouter()


def _ensure_children_owned(profile: ParentProfile, child_ids: set[str]) -> None:
    owned_ids = {child.id for child in profile.children}
    if not child_ids.issubset(owned_ids):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "error": {"code": "FORBIDDEN", "message": "Child not owned by parent"}
            },
        )


@router.get("/status", response_model=SyncStatusResponse)
async def sync_status(db: AsyncSession = Depends(get_db)):
    """Return current server content versions."""
    result = await db.execute(select(ContentVersion))
    versions = {v.content_type: v.version for v in result.scalars().all()}
    return SyncStatusResponse(
        lessons_version=versions.get("lessons", 1),
        questions_version=versions.get("questions", 1),
        games_version=versions.get("games", 1),
        server_time=utc_now(),
    )


@router.get("/content", response_model=SyncContentResponse)
async def get_content(
    since_version: int = Query(0),
    content_type: str = Query(...),  # lessons | questions | games
    db: AsyncSession = Depends(get_db),
):
    """Return content delta (or full snapshot if since_version=0)."""
    if content_type == "lessons":
        lesson_result = await db.execute(select(Lesson).where(Lesson.is_active == True))
        lessons = lesson_result.scalars().all()
        return SyncContentResponse(
            content_type="lessons",
            version=1,
            items=[
                {
                    "id": lesson.id,
                    "title": lesson.title,
                    "content_json": json.loads(lesson.content_json)
                    if lesson.content_json
                    else None,
                }
                for lesson in lessons
            ],
            deleted_ids=[],
        )
    elif content_type == "questions":
        question_result = await db.execute(select(Question))
        questions = question_result.scalars().all()
        return SyncContentResponse(
            content_type="questions",
            version=1,
            items=[
                {
                    "id": question.id,
                    "prompt": question.prompt,
                    "options_json": json.loads(question.options_json)
                    if question.options_json
                    else [],
                    "correct_answer_json": json.loads(question.correct_answer_json)
                    if question.correct_answer_json
                    else None,
                }
                for question in questions
            ],
            deleted_ids=[],
        )
    elif content_type == "games":
        game_result = await db.execute(select(Game).where(Game.is_active == True))
        games = game_result.scalars().all()
        return SyncContentResponse(
            content_type="games",
            version=1,
            items=[
                {
                    "id": game.id,
                    "name": game.name,
                    "game_type": game.game_type,
                    "config_json": json.loads(game.config_json)
                    if game.config_json
                    else None,
                }
                for game in games
            ],
            deleted_ids=[],
        )
    raise HTTPException(status_code=400, detail="Invalid content_type")


@router.post("/progress")
async def sync_progress(
    items: list[SyncProgressItem],
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    """Bulk upsert progress records from client."""
    _ensure_children_owned(profile, {item.child_id for item in items})

    for item in items:
        existing = await db.execute(select(Progress).where(Progress.id == item.id))
        row = existing.scalar_one_or_none()
        if row:
            _ensure_children_owned(profile, {row.child_id})
            if row.child_id != item.child_id:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail={
                        "error": {
                            "code": "FORBIDDEN",
                            "message": "Progress record child mismatch",
                        }
                    },
                )
            row.status = item.status
            row.mastery_score = item.mastery_score
            row.total_attempts = item.total_attempts
            row.last_played_at = item.last_played_at
        else:
            row = Progress(
                id=item.id or str(uuid.uuid4()),
                child_id=item.child_id,
                lesson_id=item.lesson_id,
                status=item.status,
                mastery_score=item.mastery_score,
                total_attempts=item.total_attempts,
                last_played_at=item.last_played_at,
            )
            db.add(row)
    await db.commit()
    return {"accepted": len(items)}


@router.post("/attempts")
async def sync_attempts(
    items: list[SyncAttemptItem],
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    """Bulk insert attempts from client (idempotent by id)."""
    _ensure_children_owned(profile, {item.child_id for item in items})

    accepted = 0
    for item in items:
        existing = await db.execute(select(Attempt).where(Attempt.id == item.id))
        existing_attempt = existing.scalar_one_or_none()
        if existing_attempt:
            _ensure_children_owned(profile, {existing_attempt.child_id})
            if existing_attempt.child_id != item.child_id:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail={
                        "error": {
                            "code": "FORBIDDEN",
                            "message": "Attempt record child mismatch",
                        }
                    },
                )
            continue  # already synced
        attempt = Attempt(
            id=item.id,
            child_id=item.child_id,
            lesson_id=item.lesson_id,
            game_id=item.game_id,
            question_id=item.question_id,
            answer_json=_encode_answer(item.answer_json),
            is_correct=item.is_correct,
            response_time_ms=item.response_time_ms,
            hint_count=item.hint_count,
            created_at=item.created_at,
        )
        db.add(attempt)
        accepted += 1
    await db.commit()
    return {"accepted": accepted, "total": len(items)}


@router.post("/sessions")
async def sync_sessions(
    items: list[SyncSessionItem],
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    """Bulk upsert daily session summaries from offline clients."""
    _ensure_children_owned(profile, {item.child_id for item in items})

    for item in items:
        row = None
        if item.id:
            existing = await db.execute(
                select(DailySession).where(DailySession.id == item.id)
            )
            row = existing.scalar_one_or_none()
        if row is None:
            existing = await db.execute(
                select(DailySession).where(
                    DailySession.child_id == item.child_id,
                    DailySession.session_date == item.session_date,
                )
            )
            row = existing.scalar_one_or_none()

        if row:
            _ensure_children_owned(profile, {row.child_id})
            if row.child_id != item.child_id:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail={
                        "error": {
                            "code": "FORBIDDEN",
                            "message": "Session record child mismatch",
                        }
                    },
                )
            row.duration_seconds = item.duration_seconds
            row.lessons_completed = item.lessons_completed
            row.games_completed = item.games_completed
        else:
            row = DailySession(
                id=item.id or str(uuid.uuid4()),
                child_id=item.child_id,
                session_date=item.session_date,
                duration_seconds=item.duration_seconds,
                lessons_completed=item.lessons_completed,
                games_completed=item.games_completed,
            )
            db.add(row)
    await db.commit()
    return {"accepted": len(items)}


def _encode_answer(answer_json: dict | None) -> str | None:
    if answer_json is None:
        return None
    return json.dumps(answer_json, ensure_ascii=False, sort_keys=True)
