import asyncio
import json

import pytest
from fastapi import HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from apps.api.database import Base
from apps.api.models import (
    Attempt,
    ChildProfile,
    ChildReward,
    Game,
    Lesson,
    ParentProfile,
    Progress,
    Reward,
    Subject,
    User,
)
from apps.api.routes.games import complete_game, start_game, submit_attempt
from apps.api.routes.progress import get_child_progress, get_child_skills, get_daily_plan
from apps.api.routes.rewards import get_child_rewards, unlock_reward
from apps.api.schemas import GameAttemptRequest, GameCompleteRequest, GameStartRequest, UnlockRewardRequest
from apps.api.time import utc_now


def test_child_progress_routes_require_parent_ownership():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                data = await _seed_two_parent_world(db)
                owner = data["owner"]
                other_child = data["other_child"]

                with pytest.raises(HTTPException) as progress_exc:
                    await get_child_progress(child_id=other_child.id, profile=owner, db=db)
                with pytest.raises(HTTPException) as skills_exc:
                    await get_child_skills(child_id=other_child.id, profile=owner, db=db)
                with pytest.raises(HTTPException) as plan_exc:
                    await get_daily_plan(child_id=other_child.id, profile=owner, db=db)

                assert progress_exc.value.status_code == 403
                assert skills_exc.value.status_code == 403
                assert plan_exc.value.status_code == 403
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_owned_child_progress_and_daily_plan_still_work():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                data = await _seed_two_parent_world(db)
                owner = data["owner"]
                child = data["owner_child"]

                progress = await get_child_progress(child_id=child.id, profile=owner, db=db)
                skills = await get_child_skills(child_id=child.id, profile=owner, db=db)
                plan = await get_daily_plan(child_id=child.id, profile=owner, db=db)

                assert len(progress) == 1
                assert progress[0].status == "learning"
                assert len(skills) == 1
                assert skills[0].accuracy_pct == 100.0
                assert len(plan) == 1
                assert plan[0].title == "Word Builder"
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_reward_routes_require_parent_ownership():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                data = await _seed_two_parent_world(db)
                owner = data["owner"]
                other_child = data["other_child"]
                reward = data["reward"]

                with pytest.raises(HTTPException) as list_exc:
                    await get_child_rewards(child_id=other_child.id, profile=owner, db=db)
                with pytest.raises(HTTPException) as unlock_exc:
                    await unlock_reward(
                        child_id=other_child.id,
                        body=UnlockRewardRequest(reward_id=reward.id),
                        profile=owner,
                        db=db,
                    )

                assert list_exc.value.status_code == 403
                assert unlock_exc.value.status_code == 403
                assert await _count(db, ChildReward) == 0
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_owned_child_reward_unlock_still_works():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                data = await _seed_two_parent_world(db)
                owner = data["owner"]
                child = data["owner_child"]
                reward = data["reward"]

                unlocked = await unlock_reward(
                    child_id=child.id,
                    body=UnlockRewardRequest(reward_id=reward.id),
                    profile=owner,
                    db=db,
                )
                rewards = await get_child_rewards(child_id=child.id, profile=owner, db=db)

                assert unlocked == {"message": "Reward unlocked", "unlocked": True}
                assert await _count(db, ChildReward) == 1
                assert rewards[0].is_unlocked is True
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_game_routes_require_parent_ownership_without_writing_attempts():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                data = await _seed_two_parent_world(db)
                owner = data["owner"]
                other_child = data["other_child"]
                game = data["game"]

                with pytest.raises(HTTPException) as start_exc:
                    await start_game(
                        game_id=game.id,
                        body=GameStartRequest(child_id=other_child.id),
                        profile=owner,
                        db=db,
                    )
                with pytest.raises(HTTPException) as attempt_exc:
                    await submit_attempt(
                        game_id=game.id,
                        body=GameAttemptRequest(
                            child_id=other_child.id,
                            answer_json={"choice_id": "a", "is_correct": True},
                        ),
                        profile=owner,
                        db=db,
                    )
                with pytest.raises(HTTPException) as complete_exc:
                    await complete_game(
                        game_id=game.id,
                        body=GameCompleteRequest(child_id=other_child.id, total_stars=2),
                        profile=owner,
                        db=db,
                    )

                assert start_exc.value.status_code == 403
                assert attempt_exc.value.status_code == 403
                assert complete_exc.value.status_code == 403
                assert await _count(db, Attempt) == 1
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_owned_child_game_attempt_stores_valid_json():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                data = await _seed_two_parent_world(db)
                owner = data["owner"]
                child = data["owner_child"]
                game = data["game"]

                started = await start_game(
                    game_id=game.id,
                    body=GameStartRequest(child_id=child.id),
                    profile=owner,
                    db=db,
                )
                recorded = await submit_attempt(
                    game_id=game.id,
                    body=GameAttemptRequest(
                        child_id=child.id,
                        answer_json={"is_correct": True, "locale": "vi", "choice_id": "b"},
                        response_time_ms=900,
                        hint_count=1,
                    ),
                    profile=owner,
                    db=db,
                )

                assert started == {"session_id": game.id, "child_id": child.id, "started": True}
                assert recorded["recorded"] is True
                result = await db.execute(
                    select(Attempt).where(Attempt.id == recorded["attempt_id"])
                )
                attempt = result.scalar_one()
                assert json.loads(attempt.answer_json) == {
                    "choice_id": "b",
                    "is_correct": True,
                    "locale": "vi",
                }
                assert attempt.is_correct is True
                assert attempt.response_time_ms == 900
                assert attempt.hint_count == 1
        finally:
            await engine.dispose()

    asyncio.run(run())


async def _session_maker():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", future=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    return async_sessionmaker(engine, expire_on_commit=False, autoflush=False), engine


async def _seed_two_parent_world(db):
    owner_user = User(
        role="parent",
        email="owner@example.test",
        password_hash="not-used",
    )
    other_user = User(
        role="parent",
        email="other@example.test",
        password_hash="not-used",
    )
    owner = ParentProfile(
        user=owner_user,
        display_name="Owner Parent",
        language="vi",
        timezone="Asia/Ho_Chi_Minh",
    )
    other = ParentProfile(
        user=other_user,
        display_name="Other Parent",
        language="vi",
        timezone="Asia/Ho_Chi_Minh",
    )
    owner_child = ChildProfile(
        parent=owner,
        nickname="Owner Child",
        age_group="junior",
        preferred_language="vi",
    )
    other_child = ChildProfile(
        parent=other,
        nickname="Other Child",
        age_group="junior",
        preferred_language="vi",
    )
    subject = Subject(name="Language", code="language")
    lesson = Lesson(
        subject=subject,
        title="Word Builder",
        age_group="junior",
        language="vi",
        estimated_minutes=5,
        is_active=True,
    )
    game = Game(
        name="Robot Commands",
        game_type="robot_commands",
        age_min=5,
        age_max=12,
        is_active=True,
    )
    reward = Reward(
        reward_type="badge",
        name="Sao đầu tiên",
        description="Completed a gentle learning step",
    )
    db.add_all(
        [
            owner_user,
            other_user,
            owner,
            other,
            owner_child,
            other_child,
            subject,
            lesson,
            game,
            reward,
        ]
    )
    await db.flush()

    db.add_all(
        [
            Progress(
                child_id=owner_child.id,
                lesson_id=lesson.id,
                status="learning",
                mastery_score=0.5,
                total_attempts=1,
                last_played_at=utc_now(),
            ),
            Attempt(
                child_id=owner_child.id,
                lesson_id=lesson.id,
                game_id=game.id,
                answer_json=json.dumps({"choice_id": "seed"}),
                is_correct=True,
                response_time_ms=1000,
                hint_count=0,
            ),
        ]
    )
    await db.commit()

    owner.children = [owner_child]
    other.children = [other_child]
    return {
        "owner": owner,
        "other": other,
        "owner_child": owner_child,
        "other_child": other_child,
        "lesson": lesson,
        "game": game,
        "reward": reward,
    }


async def _count(db, model):
    result = await db.execute(select(func.count(model.id)))
    return result.scalar_one()
