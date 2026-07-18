"""Tests for GET /lessons/recommended — the real adaptive recommendation.

Covers the previously-dead contract: this used to always return the first 3
lessons ordered by static difficulty, ignoring the child's actual Progress
history. It now ranks by Progress.status (struggling content resurfaces
first, mastered content is deprioritized) and targets difficulty to the
child's demonstrated mastery level.
"""

import asyncio

from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from apps.api.database import Base
from apps.api.models import (
    ChildProfile,
    Lesson,
    ParentProfile,
    Progress,
    Subject,
    User,
)
from apps.api.routes.lessons import get_recommended


async def _session_maker():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", future=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    return async_sessionmaker(engine, expire_on_commit=False, autoflush=False), engine


async def _seed_world(db, *, lesson_count=5):
    user = User(role="parent", email="owner@example.test", password_hash="not-used")
    profile = ParentProfile(
        user=user,
        display_name="Owner Parent",
        language="vi",
        timezone="Asia/Ho_Chi_Minh",
    )
    child = ChildProfile(
        parent=profile, nickname="Child", age_group="junior", preferred_language="vi"
    )
    subject = Subject(name="Math", code="math")
    lessons = [
        Lesson(
            subject=subject,
            title=f"Lesson {i}",
            age_group="junior",
            language="vi",
            estimated_minutes=5,
            difficulty=i,
            is_active=True,
        )
        for i in range(1, lesson_count + 1)
    ]
    db.add_all([user, profile, child, subject, *lessons])
    await db.flush()
    await db.commit()
    profile.children = [child]
    return {"profile": profile, "child": child, "lessons": lessons}


def test_recommends_by_difficulty_when_child_has_no_history():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                data = await _seed_world(db)
                profile, child = data["profile"], data["child"]

                recommended = await get_recommended(
                    child_id=child.id, profile=profile, db=db
                )

                # No track record -- start at the easiest content, same as
                # the old static-difficulty behavior when nothing else is
                # known about the child.
                assert [lesson.difficulty for lesson in recommended] == [1, 2, 3]
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_struggling_lesson_outranks_new_content():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                data = await _seed_world(db)
                profile, child, lessons = (
                    data["profile"],
                    data["child"],
                    data["lessons"],
                )

                # The child struggled with the hardest lesson -- it must
                # resurface first even though its difficulty is far from
                # "start easy".
                db.add(
                    Progress(
                        child_id=child.id,
                        lesson_id=lessons[-1].id,
                        status="needs_practice",
                        mastery_score=0.3,
                        total_attempts=2,
                    )
                )
                await db.commit()

                recommended = await get_recommended(
                    child_id=child.id, profile=profile, db=db
                )

                assert recommended[0].id == lessons[-1].id
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_mastered_lesson_is_deprioritized():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                data = await _seed_world(db, lesson_count=4)
                profile, child, lessons = (
                    data["profile"],
                    data["child"],
                    data["lessons"],
                )

                # Mastering lesson 1 shouldn't keep it at the top forever --
                # once mastered, new/continuing content should outrank it.
                db.add(
                    Progress(
                        child_id=child.id,
                        lesson_id=lessons[0].id,
                        status="mastered",
                        mastery_score=0.95,
                        total_attempts=3,
                    )
                )
                await db.commit()

                recommended = await get_recommended(
                    child_id=child.id, profile=profile, db=db
                )

                assert lessons[0].id not in [lesson.id for lesson in recommended]
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_target_difficulty_rises_with_demonstrated_mastery():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                data = await _seed_world(db, lesson_count=5)
                profile, child, lessons = (
                    data["profile"],
                    data["child"],
                    data["lessons"],
                )

                # High mastery on an easy lesson -- new-content recommendations
                # should now aim higher than difficulty 1.
                db.add(
                    Progress(
                        child_id=child.id,
                        lesson_id=lessons[0].id,
                        status="mastered",
                        mastery_score=1.0,
                        total_attempts=3,
                    )
                )
                await db.commit()

                recommended = await get_recommended(
                    child_id=child.id, profile=profile, db=db
                )

                assert all(lesson.difficulty > 1 for lesson in recommended)
        finally:
            await engine.dispose()

    asyncio.run(run())
