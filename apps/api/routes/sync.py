"""Sync routes — content delta, progress upsert, attempts, status."""

from datetime import datetime
from fastapi import APIRouter, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from apps.api.database import get_db
from apps.api.models import (
    Attempt,
    Progress,
    Lesson,
    Question,
    Game,
    ContentVersion,
)
from apps.api.schemas import (
    SyncContentResponse,
    SyncProgressItem,
    SyncAttemptItem,
    SyncStatusResponse,
)

router = APIRouter()


@router.get("/status", response_model=SyncStatusResponse)
async def sync_status(db: AsyncSession = get_db):
    """Return current server content versions."""
    result = await db.execute(select(ContentVersion))
    versions = {v.content_type: v.version for v in result.scalars().all()}
    return SyncStatusResponse(
        lessons_version=versions.get("lessons", 1),
        questions_version=versions.get("questions", 1),
        games_version=versions.get("games", 1),
        server_time=datetime.utcnow(),
    )


@router.get("/content", response_model=SyncContentResponse)
async def get_content(
    since_version: int = Query(0),
    content_type: str = Query(...),  # lessons | questions | games
    db: AsyncSession = get_db,
):
    """Return content delta (or full snapshot if since_version=0)."""
    if content_type == "lessons":
        model = Lesson
        version_field = ContentVersion.version
        result = await db.execute(
            select(model).where(model.is_active == True)
        )
        items = result.scalars().all()
        import json
        return SyncContentResponse(
            content_type="lessons",
            version=1,
            items=[{"id": i.id, "title": i.title, "content_json": json.loads(i.content_json) if i.content_json else None} for i in items],
            deleted_ids=[],
        )
    elif content_type == "questions":
        model = Question
        result = await db.execute(select(model))
        items = result.scalars().all()
        import json
        return SyncContentResponse(
            content_type="questions",
            version=1,
            items=[{"id": i.id, "prompt": i.prompt, "options_json": json.loads(i.options_json) if i.options_json else [], "correct_answer_json": json.loads(i.correct_answer_json) if i.correct_answer_json else None} for i in items],
            deleted_ids=[],
        )
    elif content_type == "games":
        result = await db.execute(select(Game).where(Game.is_active == True))
        items = result.scalars().all()
        import json
        return SyncContentResponse(
            content_type="games",
            version=1,
            items=[{"id": i.id, "name": i.name, "game_type": i.game_type, "config_json": json.loads(i.config_json) if i.config_json else None} for i in items],
            deleted_ids=[],
        )
    raise HTTPException(status_code=400, detail="Invalid content_type")


@router.post("/progress")
async def sync_progress(
    items: list[SyncProgressItem],
    db: AsyncSession = get_db,
):
    """Bulk upsert progress records from client."""
    import uuid
    for item in items:
        existing = await db.execute(
            select(Progress).where(Progress.id == item.id)
        )
        row = existing.scalar_one_or_none()
        if row:
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
    db: AsyncSession = get_db,
):
    """Bulk insert attempts from client (idempotent by id)."""
    accepted = 0
    for item in items:
        existing = await db.execute(
            select(Attempt).where(Attempt.id == item.id)
        )
        if existing.scalar_one_or_none():
            continue  # already synced
        attempt = Attempt(
            id=item.id,
            child_id=item.child_id,
            lesson_id=item.lesson_id,
            game_id=item.game_id,
            question_id=item.question_id,
            answer_json=str(item.answer_json),
            is_correct=item.is_correct,
            response_time_ms=item.response_time_ms,
            hint_count=item.hint_count,
            created_at=item.created_at,
        )
        db.add(attempt)
        accepted += 1
    await db.commit()
    return {"accepted": accepted, "total": len(items)}
