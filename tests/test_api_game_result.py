"""Tests for POST /games/{game_id}/result — the SaveGameResultRequest endpoint.

Covers the previously-dead contract: MiGameResult -> Attempt -> server-side
mastery -> Progress, with attempt_id idempotency.
"""
import asyncio
from datetime import timedelta
from unittest import mock

import pytest
from fastapi import HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

import apps.api.routes.games as games
from apps.api.database import Base
from apps.api.models import (
    Attempt,
    ChildReward,
    ChildProfile,
    Game,
    Lesson,
    ParentProfile,
    Progress,
    Reward,
    Subject,
    User,
)
from apps.api.routes.games import save_game_result
from apps.api.schemas import SaveGameResultRequest
from apps.api.time import utc_now


def _result_body(child_id, game_id, lesson_id, *, attempt_id="attempt-1", correct=4, incorrect=1, mastery_evidence=0.8):
    started = utc_now()
    return SaveGameResultRequest(
        attempt_id=attempt_id,
        child_profile_id=child_id,
        game_id=game_id,
        level_id="level_1",
        lesson_id=lesson_id,
        started_at=started,
        completed_at=started + timedelta(seconds=60),
        attempt_count=correct + incorrect,
        correct_count=correct,
        incorrect_count=incorrect,
        hint_count=1,
        duration_seconds=60,
        completed=True,
        mastery_evidence=mastery_evidence,
        skill_evidence={"math": ["addition"]},
    )


def test_save_game_result_creates_attempt_and_updates_mastery():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                data = await _seed_world(db)
                profile, child, lesson, game = data["profile"], data["child"], data["lesson"], data["game"]

                response = await save_game_result(
                    game_id=game.id,
                    body=_result_body(child.id, game.id, lesson.id),
                    profile=profile,
                    db=db,
                )

                assert response["idempotent_replay"] is False
                assert response["mastery_score"] is not None
                assert 0.0 <= response["mastery_score"] <= 1.0

                progress_row = await db.execute(
                    select(Progress).where(Progress.child_id == child.id, Progress.lesson_id == lesson.id)
                )
                progress = progress_row.scalar_one()
                assert progress.total_attempts == 1
                assert progress.mastery_score == response["mastery_score"]

                attempt_row = await db.execute(select(Attempt).where(Attempt.client_attempt_id == "attempt-1"))
                attempt = attempt_row.scalar_one()
                assert attempt.lesson_id == lesson.id
                assert attempt.game_id == game.id
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_save_game_result_is_idempotent_on_duplicate_attempt_id():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                data = await _seed_world(db)
                profile, child, lesson, game = data["profile"], data["child"], data["lesson"], data["game"]

                first = await save_game_result(
                    game_id=game.id, body=_result_body(child.id, game.id, lesson.id), profile=profile, db=db
                )
                second = await save_game_result(
                    game_id=game.id, body=_result_body(child.id, game.id, lesson.id), profile=profile, db=db
                )

                assert first["idempotent_replay"] is False
                assert second["idempotent_replay"] is True
                assert second["attempt_id"] == first["attempt_id"]
                assert await _count(db, Attempt) == 1

                progress_row = await db.execute(
                    select(Progress).where(Progress.child_id == child.id, Progress.lesson_id == lesson.id)
                )
                progress = progress_row.scalar_one()
                assert progress.total_attempts == 1  # not double-counted
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_save_game_result_survives_concurrent_duplicate_submission():
    """Simulates two requests racing on the same attempt_id: both pass the
    pre-check (SELECT finds nothing) before either commits. The second one
    to reach the database must hit the client_attempt_id unique constraint
    and gracefully return an idempotent-replay response, not a raw 500 --
    the select-then-insert pre-check alone cannot rule this out."""

    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                data = await _seed_world(db)
                profile, child, lesson, game = data["profile"], data["child"], data["lesson"], data["game"]
                body = _result_body(child.id, game.id, lesson.id, attempt_id="race-1")

                real_replay_lookup = games._idempotent_replay_response
                call_count = {"n": 0}

                async def racy_replay_lookup(db_arg, attempt_id):
                    call_count["n"] += 1
                    if call_count["n"] == 1:
                        # This request's own pre-check: pretend the racing
                        # request hasn't committed yet, so nothing is found.
                        return None
                    return await real_replay_lookup(db_arg, attempt_id)

                with mock.patch.object(games, "_idempotent_replay_response", racy_replay_lookup):
                    # The "other" request actually commits first, in between
                    # this request's pre-check and its own insert.
                    other_attempt = Attempt(
                        client_attempt_id="race-1",
                        child_id=child.id,
                        lesson_id=lesson.id,
                        game_id=game.id,
                        answer_json="{}",
                    )
                    db.add(other_attempt)
                    await db.commit()

                    response = await save_game_result(
                        game_id=game.id, body=body, profile=profile, db=db
                    )

                assert response["idempotent_replay"] is True
                assert response["attempt_id"] == other_attempt.id
                assert await _count(db, Attempt) == 1
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_save_game_result_awards_first_badge_once_across_distinct_attempts():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                data = await _seed_world(db)
                profile, child, lesson, game = data["profile"], data["child"], data["lesson"], data["game"]

                first = await save_game_result(
                    game_id=game.id,
                    body=_result_body(child.id, game.id, lesson.id, attempt_id="attempt-1"),
                    profile=profile,
                    db=db,
                )
                second = await save_game_result(
                    game_id=game.id,
                    body=_result_body(child.id, game.id, lesson.id, attempt_id="attempt-2"),
                    profile=profile,
                    db=db,
                )

                assert first["badges_unlocked"] == ["Sao đầu tiên"]
                assert second["badges_unlocked"] == []
                assert await _count(db, Attempt) == 2
                assert await _count(db, ChildReward) == 1
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_save_game_result_does_not_rewrite_mastery_for_out_of_order_attempt():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                data = await _seed_world(db)
                profile, child, lesson, game = data["profile"], data["child"], data["lesson"], data["game"]
                started = utc_now()
                progress = Progress(
                    child_id=child.id,
                    lesson_id=lesson.id,
                    status="completed",
                    mastery_score=0.9,
                    total_attempts=3,
                    last_played_at=started + timedelta(minutes=10),
                )
                db.add(progress)
                await db.commit()

                older_body = _result_body(
                    child.id,
                    game.id,
                    lesson.id,
                    attempt_id="older-attempt",
                    correct=1,
                    incorrect=4,
                    mastery_evidence=0.1,
                )
                older_body.completed_at = started + timedelta(minutes=1)

                response = await save_game_result(
                    game_id=game.id,
                    body=older_body,
                    profile=profile,
                    db=db,
                )

                assert response["idempotent_replay"] is False
                assert response["out_of_order"] is True
                assert response["mastery_score"] == 0.9
                assert await _count(db, Attempt) == 1

                progress_row = await db.execute(
                    select(Progress).where(Progress.child_id == child.id, Progress.lesson_id == lesson.id)
                )
                saved_progress = progress_row.scalar_one()
                assert saved_progress.mastery_score == 0.9
                assert saved_progress.total_attempts == 3
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_save_game_result_rejects_unowned_child():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                data = await _seed_world(db)
                other_user = User(role="parent", email="other@example.com", password_hash="not-used")
                other_profile = ParentProfile(user=other_user, display_name="Other", language="vi", timezone="Asia/Ho_Chi_Minh")
                # Give it an unrelated child via back_populates so `.children`
                # is populated in-memory (avoids a lazy-load under asyncio).
                ChildProfile(parent=other_profile, nickname="Unrelated", age_group="junior", preferred_language="vi")
                db.add_all([other_user, other_profile])
                await db.flush()

                with pytest.raises(HTTPException) as exc:
                    await save_game_result(
                        game_id=data["game"].id,
                        body=_result_body(data["child"].id, data["game"].id, data["lesson"].id),
                        profile=other_profile,
                        db=db,
                    )
                assert exc.value.status_code == 403
        finally:
            await engine.dispose()

    asyncio.run(run())


async def _session_maker():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", future=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    return async_sessionmaker(engine, expire_on_commit=False, autoflush=False), engine


async def _seed_world(db):
    user = User(role="parent", email="owner@example.test", password_hash="not-used")
    profile = ParentProfile(user=user, display_name="Owner Parent", language="vi", timezone="Asia/Ho_Chi_Minh")
    child = ChildProfile(parent=profile, nickname="Child", age_group="junior", preferred_language="vi")
    subject = Subject(name="Math", code="math")
    lesson = Lesson(
        subject=subject,
        title="Addition Basics",
        age_group="junior",
        language="vi",
        estimated_minutes=5,
        is_active=True,
    )
    game = Game(name="Memory Cards", game_type="memory_cards", age_min=5, age_max=12, is_active=True)
    reward = Reward(reward_type="badge", name="Sao đầu tiên", description="First star")
    db.add_all([user, profile, child, subject, lesson, game, reward])
    await db.flush()
    await db.commit()
    profile.children = [child]
    return {"profile": profile, "child": child, "lesson": lesson, "game": game}


async def _count(db, model):
    result = await db.execute(select(func.count(model.id)))
    return result.scalar_one()
