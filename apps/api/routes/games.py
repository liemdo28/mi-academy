"""Games routes — list, detail, start session, attempt, complete."""

import json
import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from apps.api.database import get_db
from apps.api.dependencies import get_parent_profile
from apps.api.models import (
    Game,
    Attempt,
    Lesson,
    Progress,
    Reward,
    ChildReward,
    ParentProfile,
)
from apps.api.time import utc_now
from apps.api.schemas import (
    GameListItem,
    GameDetail,
    GameStartRequest,
    GameAttemptRequest,
    GameCompleteRequest,
    SaveGameResultRequest,
)

router = APIRouter()


def _child_belongs_to_parent(profile: ParentProfile, child_id: str):
    if child_id not in [c.id for c in profile.children]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "error": {"code": "FORBIDDEN", "message": "Child not owned by parent"}
            },
        )


def _compare_datetimes(left: datetime, right: datetime) -> int:
    """Compare datetimes after normalizing timezone metadata for SQLite tests."""
    left_cmp = left.replace(tzinfo=None)
    right_cmp = right.replace(tzinfo=None)
    return (left_cmp > right_cmp) - (left_cmp < right_cmp)


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


async def _unlock_reward_once(db: AsyncSession, child_id: str, reward: Reward) -> bool:
    existing = await db.execute(
        select(ChildReward).where(
            ChildReward.child_id == child_id,
            ChildReward.reward_id == reward.id,
        )
    )
    if existing.scalar_one_or_none() is not None:
        return False

    db.add(
        ChildReward(
            id=str(uuid.uuid4()),
            child_id=child_id,
            reward_id=reward.id,
            unlocked_at=utc_now(),
        )
    )
    return True


async def _check_first_star_badge(
    db: AsyncSession,
    child_id: str,
    game_id: str,
    *,
    already_confirmed_first_attempt: bool = False,
) -> list[str]:
    """Award the "first star" badge the first time a child attempts a game."""
    if not already_confirmed_first_attempt:
        result = await db.execute(
            select(Attempt)
            .where(Attempt.child_id == child_id, Attempt.game_id == game_id)
            .limit(1)
        )
        existing = result.scalar_one_or_none()
        if existing is not None:
            return []

    badge_result = await db.execute(select(Reward).where(Reward.name == "Sao đầu tiên"))
    badge = badge_result.scalar_one_or_none()
    if badge is None:
        return []

    return [badge.name] if await _unlock_reward_once(db, child_id, badge) else []


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

    unlocked_badges = await _check_first_star_badge(db, body.child_id, game_id)

    await db.commit()
    return {
        "total_stars": body.total_stars,
        "badges_unlocked": body.badges_unlocked + unlocked_badges,
        "rewards_unlocked": body.rewards_unlocked,
        "completed": True,
    }


async def _idempotent_replay_response(db: AsyncSession, attempt_id: str) -> dict | None:
    """If `attempt_id` was already saved, return the idempotent-replay
    response for it; otherwise None."""
    existing_result = await db.execute(
        select(Attempt).where(Attempt.client_attempt_id == attempt_id)
    )
    existing_attempt = existing_result.scalar_one_or_none()
    if existing_attempt is None:
        return None

    progress_score = None
    if existing_attempt.lesson_id:
        progress_row = await db.execute(
            select(Progress).where(
                Progress.child_id == existing_attempt.child_id,
                Progress.lesson_id == existing_attempt.lesson_id,
            )
        )
        progress = progress_row.scalar_one_or_none()
        progress_score = progress.mastery_score if progress else None
    return {
        "attempt_id": existing_attempt.id,
        "idempotent_replay": True,
        "mastery_score": progress_score,
    }


@router.post("/{game_id}/result")
async def save_game_result(
    game_id: str,
    body: SaveGameResultRequest,
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    """Save a full MiGameResult: idempotent attempt log + server-side mastery update.

    This is the real endpoint for the game-finish → mastery → reward → sync
    pipeline. `/complete` (above) is kept for the older stars/badges-only
    payload; this endpoint additionally persists the richer session evidence
    (correct/incorrect counts, mastery_evidence, skill_evidence) and computes
    mastery on the server instead of trusting a client-sent score.
    """
    _child_belongs_to_parent(profile, body.child_profile_id)

    if game_id != body.game_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "error": {
                    "code": "GAME_ID_MISMATCH",
                    "message": "Path and body game_id must match",
                }
            },
        )

    game_result = await db.execute(select(Game).where(Game.id == game_id))
    if game_result.scalar_one_or_none() is None:
        raise HTTPException(status_code=404, detail="Game not found")

    prior_attempt_result = await db.execute(
        select(Attempt)
        .where(Attempt.child_id == body.child_profile_id, Attempt.game_id == game_id)
        .limit(1)
    )
    is_first_game_attempt = prior_attempt_result.scalar_one_or_none() is None

    # Idempotency: replaying the same attempt_id returns the original outcome
    # instead of double-counting attempts/rewards/mastery.
    replay = await _idempotent_replay_response(db, body.attempt_id)
    if replay is not None:
        return replay

    attempt = Attempt(
        id=str(uuid.uuid4()),
        client_attempt_id=body.attempt_id,
        child_id=body.child_profile_id,
        lesson_id=body.lesson_id,
        game_id=game_id,
        answer_json=json.dumps(
            {
                "attempt_count": body.attempt_count,
                "correct_count": body.correct_count,
                "incorrect_count": body.incorrect_count,
                "skill_evidence": body.skill_evidence,
                "metadata": body.metadata,
            },
            ensure_ascii=False,
            sort_keys=True,
        ),
        is_correct=body.completed and body.correct_count >= body.incorrect_count,
        response_time_ms=body.duration_seconds * 1000,
        hint_count=body.hint_count,
    )

    try:
        db.add(attempt)

        mastery_score = None
        if body.lesson_id:
            lesson_result = await db.execute(
                select(Lesson).where(Lesson.id == body.lesson_id)
            )
            if lesson_result.scalar_one_or_none() is not None:
                correct_rate = (
                    body.correct_count / body.attempt_count
                    if body.attempt_count
                    else 0.0
                )
                # Blend this session's accuracy with the game's own mastery signal,
                # then average against prior mastery so one weak session doesn't
                # erase established progress.
                session_evidence = max(
                    0.0, min(1.0, 0.6 * correct_rate + 0.4 * body.mastery_evidence)
                )

                progress_row = await db.execute(
                    select(Progress).where(
                        Progress.child_id == body.child_profile_id,
                        Progress.lesson_id == body.lesson_id,
                    )
                )
                progress = progress_row.scalar_one_or_none()
                if progress is None:
                    progress = Progress(
                        child_id=body.child_profile_id,
                        lesson_id=body.lesson_id,
                        mastery_score=session_evidence,
                        total_attempts=0,
                    )
                    db.add(progress)
                elif (
                    progress.last_played_at
                    and _compare_datetimes(body.completed_at, progress.last_played_at)
                    <= 0
                ):
                    mastery_score = progress.mastery_score

                    await db.commit()
                    await db.refresh(attempt)
                    return {
                        "attempt_id": attempt.id,
                        "idempotent_replay": False,
                        "out_of_order": True,
                        "mastery_score": mastery_score,
                        "badges_unlocked": [],
                    }
                else:
                    progress.mastery_score = max(
                        0.0,
                        min(1.0, 0.5 * progress.mastery_score + 0.5 * session_evidence),
                    )

                progress.total_attempts += 1
                progress.last_played_at = utc_now()
                progress.status = (
                    "completed"
                    if progress.mastery_score >= 0.7
                    else ("needs_practice" if body.completed else "learning")
                )
                mastery_score = progress.mastery_score

        unlocked_badges = await _check_first_star_badge(
            db,
            body.child_profile_id,
            game_id,
            already_confirmed_first_attempt=is_first_game_attempt,
        )

        await db.commit()
    except IntegrityError:
        # A concurrent request with the same attempt_id committed first
        # (client_attempt_id is unique at the DB level — the final backstop
        # the select-then-insert check above can't fully rule out under
        # concurrency). Roll back this attempt and return the same
        # idempotent-replay response as if we'd seen it up front.
        await db.rollback()
        replay = await _idempotent_replay_response(db, body.attempt_id)
        if replay is not None:
            return replay
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "error": {
                    "code": "ATTEMPT_CONFLICT",
                    "message": "Concurrent submission for this attempt_id",
                }
            },
        )

    await db.refresh(attempt)
    return {
        "attempt_id": attempt.id,
        "idempotent_replay": False,
        "mastery_score": mastery_score,
        "badges_unlocked": unlocked_badges,
    }
