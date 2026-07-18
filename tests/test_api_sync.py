import asyncio
import json
from datetime import date

import pytest
from fastapi import HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from apps.api.database import Base
from apps.api.models import (
    Attempt,
    ChildProfile,
    DailySession,
    Game,
    Lesson,
    ParentProfile,
    Progress,
    Subject,
    User,
)
from apps.api.routes.sync import sync_attempts, sync_progress, sync_sessions
from apps.api.schemas.sync import SyncAttemptItem, SyncProgressItem, SyncSessionItem
from apps.api.time import utc_now


def test_sync_progress_upserts_existing_record():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                profile, child, lesson, _ = await _seed_sync_entities(db)

                first = await sync_progress(
                    [
                        SyncProgressItem(
                            id="progress-1",
                            child_id=child.id,
                            lesson_id=lesson.id,
                            status="learning",
                            mastery_score=0.35,
                            total_attempts=2,
                            last_played_at=utc_now(),
                        )
                    ],
                    profile=profile,
                    db=db,
                )
                second = await sync_progress(
                    [
                        SyncProgressItem(
                            id="progress-1",
                            child_id=child.id,
                            lesson_id=lesson.id,
                            status="completed",
                            mastery_score=0.9,
                            total_attempts=4,
                            last_played_at=utc_now(),
                        )
                    ],
                    profile=profile,
                    db=db,
                )

                assert first == {"accepted": 1}
                assert second == {"accepted": 1}
                assert await _count(db, Progress) == 1

                result = await db.execute(
                    select(Progress).where(Progress.id == "progress-1")
                )
                row = result.scalar_one()
                assert row.status == "completed"
                assert row.mastery_score == 0.9
                assert row.total_attempts == 4
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_sync_attempts_are_idempotent_and_store_valid_json():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                profile, child, lesson, game = await _seed_sync_entities(db)
                attempt = SyncAttemptItem(
                    id="attempt-1",
                    child_id=child.id,
                    lesson_id=lesson.id,
                    game_id=game.id,
                    answer_json={
                        "choice_id": "b",
                        "locale": "vi",
                        "raw_answer": "5 đồng",
                    },
                    is_correct=True,
                    response_time_ms=1800,
                    hint_count=1,
                    created_at=utc_now(),
                )

                first = await sync_attempts([attempt], profile=profile, db=db)
                second = await sync_attempts([attempt], profile=profile, db=db)

                assert first == {"accepted": 1, "total": 1}
                assert second == {"accepted": 0, "total": 1}
                assert await _count(db, Attempt) == 1

                result = await db.execute(
                    select(Attempt).where(Attempt.id == "attempt-1")
                )
                row = result.scalar_one()
                decoded = json.loads(row.answer_json)
                assert decoded == {
                    "choice_id": "b",
                    "locale": "vi",
                    "raw_answer": "5 đồng",
                }
                assert row.is_correct is True
                assert row.response_time_ms == 1800
                assert row.hint_count == 1
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_sync_attempt_without_answer_stays_privacy_minimal():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                profile, child, lesson, game = await _seed_sync_entities(db)
                result = await sync_attempts(
                    [
                        SyncAttemptItem(
                            id="attempt-no-answer",
                            child_id=child.id,
                            lesson_id=lesson.id,
                            game_id=game.id,
                            answer_json=None,
                            is_correct=False,
                            response_time_ms=900,
                            hint_count=0,
                            created_at=utc_now(),
                        )
                    ],
                    profile=profile,
                    db=db,
                )

                assert result == {"accepted": 1, "total": 1}
                stored = await db.get(Attempt, "attempt-no-answer")
                assert stored is not None
                assert stored.answer_json is None
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_sync_sessions_upsert_daily_activity_by_child_and_date():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                profile, child, _, _ = await _seed_sync_entities(db)
                first = await sync_sessions(
                    [
                        SyncSessionItem(
                            child_id=child.id,
                            session_date=date(2026, 7, 17),
                            duration_seconds=900,
                            lessons_completed=1,
                            games_completed=2,
                        )
                    ],
                    profile=profile,
                    db=db,
                )
                second = await sync_sessions(
                    [
                        SyncSessionItem(
                            child_id=child.id,
                            session_date=date(2026, 7, 17),
                            duration_seconds=1200,
                            lessons_completed=2,
                            games_completed=3,
                        )
                    ],
                    profile=profile,
                    db=db,
                )

                assert first == {"accepted": 1}
                assert second == {"accepted": 1}
                assert await _count(db, DailySession) == 1

                result = await db.execute(
                    select(DailySession).where(DailySession.child_id == child.id)
                )
                row = result.scalar_one()
                assert row.session_date == date(2026, 7, 17)
                assert row.duration_seconds == 1200
                assert row.lessons_completed == 2
                assert row.games_completed == 3
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_sync_rejects_progress_for_child_not_owned_by_parent():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                owner, _, lesson, _, other_child = await _seed_two_parent_sync_entities(
                    db
                )

                with pytest.raises(HTTPException) as exc:
                    await sync_progress(
                        [
                            SyncProgressItem(
                                id="cross-progress",
                                child_id=other_child.id,
                                lesson_id=lesson.id,
                                status="learning",
                                mastery_score=0.2,
                                total_attempts=1,
                                last_played_at=utc_now(),
                            )
                        ],
                        profile=owner,
                        db=db,
                    )

                assert exc.value.status_code == 403
                assert await _count(db, Progress) == 0
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_sync_rejects_cross_child_progress_id_reuse():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                (
                    owner,
                    child,
                    lesson,
                    _,
                    other_child,
                ) = await _seed_two_parent_sync_entities(db)
                db.add(
                    Progress(
                        id="shared-progress-id",
                        child_id=other_child.id,
                        lesson_id=lesson.id,
                        status="learning",
                        mastery_score=0.1,
                        total_attempts=1,
                        last_played_at=utc_now(),
                    )
                )
                await db.commit()

                with pytest.raises(HTTPException) as exc:
                    await sync_progress(
                        [
                            SyncProgressItem(
                                id="shared-progress-id",
                                child_id=child.id,
                                lesson_id=lesson.id,
                                status="completed",
                                mastery_score=1.0,
                                total_attempts=5,
                                last_played_at=utc_now(),
                            )
                        ],
                        profile=owner,
                        db=db,
                    )

                assert exc.value.status_code == 403
                stored = await db.get(Progress, "shared-progress-id")
                assert stored.child_id == other_child.id
                assert stored.status == "learning"
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_sync_rejects_attempt_for_child_not_owned_by_parent():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                (
                    owner,
                    _,
                    lesson,
                    game,
                    other_child,
                ) = await _seed_two_parent_sync_entities(db)

                with pytest.raises(HTTPException) as exc:
                    await sync_attempts(
                        [
                            SyncAttemptItem(
                                id="cross-attempt",
                                child_id=other_child.id,
                                lesson_id=lesson.id,
                                game_id=game.id,
                                answer_json={"choice_id": "x"},
                                is_correct=False,
                                response_time_ms=500,
                                hint_count=0,
                                created_at=utc_now(),
                            )
                        ],
                        profile=owner,
                        db=db,
                    )

                assert exc.value.status_code == 403
                assert await _count(db, Attempt) == 0
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_sync_rejects_session_for_child_not_owned_by_parent():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                owner, _, _, _, other_child = await _seed_two_parent_sync_entities(db)

                with pytest.raises(HTTPException) as exc:
                    await sync_sessions(
                        [
                            SyncSessionItem(
                                child_id=other_child.id,
                                session_date=date(2026, 7, 17),
                                duration_seconds=600,
                                lessons_completed=1,
                                games_completed=1,
                            )
                        ],
                        profile=owner,
                        db=db,
                    )

                assert exc.value.status_code == 403
                assert await _count(db, DailySession) == 0
        finally:
            await engine.dispose()

    asyncio.run(run())


async def _session_maker():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", future=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    return async_sessionmaker(engine, expire_on_commit=False, autoflush=False), engine


async def _seed_sync_entities(db):
    user = User(
        role="parent",
        email="sync-parent@example.test",
        password_hash="not-used",
    )
    profile = ParentProfile(
        user=user,
        display_name="Sync Parent",
        language="vi",
        timezone="Asia/Ho_Chi_Minh",
    )
    child = ChildProfile(
        parent=profile,
        nickname="Mi",
        age_group="junior",
        preferred_language="vi",
    )
    subject = Subject(name="Math", code="math")
    lesson = Lesson(
        subject=subject,
        title="Math Supermarket",
        age_group="junior",
        language="vi",
        estimated_minutes=5,
    )
    game = Game(
        name="Math Supermarket",
        game_type="math_supermarket",
    )
    db.add_all([user, profile, child, subject, lesson, game])
    await db.commit()
    profile.children = [child]
    return profile, child, lesson, game


async def _seed_two_parent_sync_entities(db):
    owner_user = User(
        role="parent",
        email="sync-owner@example.test",
        password_hash="not-used",
    )
    other_user = User(
        role="parent",
        email="sync-other@example.test",
        password_hash="not-used",
    )
    owner = ParentProfile(
        user=owner_user,
        display_name="Sync Owner",
        language="vi",
        timezone="Asia/Ho_Chi_Minh",
    )
    other = ParentProfile(
        user=other_user,
        display_name="Sync Other",
        language="vi",
        timezone="Asia/Ho_Chi_Minh",
    )
    child = ChildProfile(
        parent=owner,
        nickname="Mi",
        age_group="junior",
        preferred_language="vi",
    )
    other_child = ChildProfile(
        parent=other,
        nickname="Not Mi",
        age_group="junior",
        preferred_language="vi",
    )
    subject = Subject(name="Math", code="math")
    lesson = Lesson(
        subject=subject,
        title="Math Supermarket",
        age_group="junior",
        language="vi",
        estimated_minutes=5,
    )
    game = Game(
        name="Math Race",
        game_type="math_race",
        age_min=5,
        age_max=12,
    )
    db.add_all(
        [
            owner_user,
            other_user,
            owner,
            other,
            child,
            other_child,
            subject,
            lesson,
            game,
        ]
    )
    await db.commit()
    owner.children = [child]
    other.children = [other_child]
    return owner, child, lesson, game, other_child


async def _count(db, model):
    result = await db.execute(select(func.count(model.id)))
    return result.scalar_one()
