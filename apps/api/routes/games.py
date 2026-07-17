"""Games routes — list, detail, start session, attempt, complete."""

import json
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from apps.api.database import get_db
from apps.api.dependencies import get_parent_profile
from apps.api.models import Game, Attempt, Reward, ChildReward, ParentProfile
from apps.api.time import utc_now
from apps.api.schemas import (
    GameListItem,
    GameDetail,
    GameStartRequest,
    GameAttemptRequest,
    GameCompleteRequest,
)

router = APIRouter()


def _child_belongs_to_parent(profile: ParentProfile, child_id: str):
    if child_id not in [c.id for c in profile.children]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"error": {"code": "FORBIDDEN", "message": "Child not owned by parent"}},
        )


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
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    """Mark a game session as started for a child."""
    _child_belongs_to_parent(profile, body.child_id)

    result = await db.execute(select(Game).where(Game.id == game_id))
    game = result.scalar_one_or_none()
    if game is None:
        raise HTTPException(status_code=404, detail="Game not found")

    return {"session_id": game_id, "child_id": body.child_id, "started": True}


@router.post("/{game_id}/attempt")
async def submit_attempt(
    game_id: str,
    body: GameAttemptRequest,
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    """Record an answer attempt within a game session."""
    _child_belongs_to_parent(profile, body.child_id)

    result = await db.execute(select(Game).where(Game.id == game_id))
    if result.scalar_one_or_none() is None:
        raise HTTPException(status_code=404, detail="Game not found")

    attempt = Attempt(
        id=str(uuid.uuid4()),
        child_id=body.child_id,
        game_id=game_id,
        answer_json=json.dumps(body.answer_json, ensure_ascii=False, sort_keys=True),
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
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    """Mark game complete, award stars and check badge unlocks."""
    _child_belongs_to_parent(profile, body.child_id)

    result = await db.execute(select(Game).where(Game.id == game_id))
    if result.scalar_one_or_none() is None:
        raise HTTPException(status_code=404, detail="Game not found")

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
