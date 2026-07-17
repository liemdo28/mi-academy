"""Games routes — list, detail, start session, attempt, complete."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from apps.api.database import get_db
from apps.api.dependencies import get_current_user
from apps.api.models import ChildProfile, Game, Attempt, Progress, Reward, ChildReward
from apps.api.time import utc_now
from apps.api.schemas import (
    GameListItem,
    GameDetail,
    GameStartRequest,
    GameAttemptRequest,
    GameCompleteRequest,
)
from apps.api.models import User

router = APIRouter()


@router.get("", response_model=list[GameListItem])
async def list_games(
    age_group: str | None = None,
    language: str | None = None,
    db: AsyncSession = Depends(get_db),
):
    """List active games, optionally filtered by age_group or language."""
    query = select(Game).where(Game.is_active == True)
    if age_group:
        query = query.where(Game.age_min != None)
    result = await db.execute(query)
    games = result.scalars().all()
    return games


@router.get("/{game_id}", response_model=GameDetail)
async def get_game(game_id: str, db: AsyncSession = Depends(get_db)):
    """Get a single game's full config."""
    result = await db.execute(select(Game).where(Game.id == game_id))
    game = result.scalar_one_or_none()
    if game is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "GAME_NOT_FOUND", "message": "Game not found"}},
        )
    import json
    config = None
    if game.config_json:
        try:
            config = json.loads(game.config_json)
        except Exception:
            config = None
    return GameDetail(
        id=game.id,
        name=game.name,
        game_type=game.game_type,
        age_min=game.age_min,
        age_max=game.age_max,
        config_json=config,
        is_active=game.is_active,
    )


@router.post("/{game_id}/start")
async def start_game(
    game_id: str,
    body: GameStartRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Mark a game session as started for a child."""
    result = await db.execute(select(Game).where(Game.id == game_id))
    game = result.scalar_one_or_none()
    if game is None:
        raise HTTPException(status_code=404, detail="Game not found")

    result2 = await db.execute(
        select(ChildProfile).where(
            ChildProfile.id == body.child_id,
            ChildProfile.parent_id == None,  # TODO: validate parent ownership
        )
    )
    child = result2.scalar_one_or_none()
    if child is None:
        raise HTTPException(status_code=404, detail="Child not found")

    return {"session_id": game_id, "child_id": body.child_id, "started": True}


@router.post("/{game_id}/attempt")
async def submit_attempt(
    game_id: str,
    body: GameAttemptRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Record an answer attempt within a game session."""
    import uuid

    attempt = Attempt(
        id=str(uuid.uuid4()),
        child_id=body.child_id,
        game_id=game_id,
        answer_json=str(body.answer_json),
        is_correct=body.answer_json.get("is_correct", False),
        response_time_ms=body.response_time_ms,
        hint_count=body.hint_count,
    )
    db.add(attempt)
    await db.flush()
    return {"attempt_id": attempt.id, "recorded": True}


@router.post("/{game_id}/complete")
async def complete_game(
    game_id: str,
    body: GameCompleteRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Mark game complete, award stars and check badge unlocks."""
    # Award rewards
    unlocked_badges = []
    unlocked_rewards = []

    # Check first-star badge
    result = await db.execute(
        select(Attempt)
        .where(Attempt.child_id == body.child_id, Attempt.game_id == game_id)
        .limit(1)
    )
    existing = result.scalar_one_or_none()
    if existing is None:
        badge_result = await db.execute(
            select(Reward).where(Reward.name == "Sao đầu tiên")
        )
        badge = badge_result.scalar_one_or_none()
        if badge:
            import uuid
            cr = ChildReward(
                id=str(uuid.uuid4()),
                child_id=body.child_id,
                reward_id=badge.id,
                unlocked_at=utc_now(),
            )
            db.add(cr)
            unlocked_badges.append(badge.name)

    await db.commit()
    return {
        "total_stars": body.total_stars,
        "badges_unlocked": body.badges_unlocked + unlocked_badges,
        "rewards_unlocked": body.rewards_unlocked + unlocked_rewards,
        "completed": True,
    }
