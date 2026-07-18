"""Tests for GET /progress/children/{id}/daily-plan's game_type field.

Covers a previously-dead gap: DailyPlanItem had no way to tell the mobile
client which game engine a lesson launches into, so ChildHomeScreen's "Tiep
tuc hoc" CTA and mission list always hardcoded /game/memory_cards regardless
of which lesson was actually next -- see apps.api.routes.progress's
_SUBJECT_TO_GAME_TYPE mapping.
"""
import asyncio

from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from apps.api.database import Base
from apps.api.models import ChildProfile, Lesson, ParentProfile, Subject, User
from apps.api.routes.progress import get_daily_plan


async def _session_maker():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", future=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    return async_sessionmaker(engine, expire_on_commit=False, autoflush=False), engine


async def _seed_world(db):
    user = User(role="parent", email="owner@example.test", password_hash="not-used")
    profile = ParentProfile(user=user, display_name="Owner Parent", language="vi", timezone="Asia/Ho_Chi_Minh")
    child = ChildProfile(parent=profile, nickname="Child", age_group="junior", preferred_language="vi")
    letters = Subject(name="Letters", code="letters")
    math = Subject(name="Math", code="math")
    logic = Subject(name="Logic", code="logic")
    science = Subject(name="Science", code="science")
    lessons = [
        Lesson(subject=letters, title="Letters Lesson", age_group="junior", language="vi",
               estimated_minutes=5, is_active=True),
        Lesson(subject=math, title="Math Lesson", age_group="junior", language="vi",
               estimated_minutes=5, is_active=True),
        Lesson(subject=logic, title="Logic Lesson", age_group="junior", language="vi",
               estimated_minutes=5, is_active=True),
        Lesson(subject=science, title="Science Lesson", age_group="junior", language="vi",
               estimated_minutes=5, is_active=True),
    ]
    db.add_all([user, profile, child, letters, math, logic, science, *lessons])
    await db.flush()
    await db.commit()
    profile.children = [child]
    return {"profile": profile, "child": child}


def test_daily_plan_maps_each_subject_to_its_game_type():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                data = await _seed_world(db)
                profile, child = data["profile"], data["child"]

                plan = await get_daily_plan(child_id=child.id, profile=profile, db=db)

                by_title = {item.title: item.game_type for item in plan}
                assert by_title["Letters Lesson"] == "word_builder"
                assert by_title["Math Lesson"] == "math_race"
                assert by_title["Logic Lesson"] == "robot_commands"
                # No dedicated game exists for science -- must fall back
                # rather than fabricate a mismatched mapping.
                assert by_title["Science Lesson"] == "memory_cards"
        finally:
            await engine.dispose()

    asyncio.run(run())
