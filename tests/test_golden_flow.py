"""End-to-end golden flow: register -> create child -> list lessons ->
save game result -> mastery updated -> session synced -> parent reports
reflect it.

Calls route handlers directly (same style as the other tests in this
directory) rather than going through HTTP, since there is no ASGI test
client wired up in this suite yet.
"""
import asyncio
from datetime import date, timedelta

from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from apps.api.database import Base
from apps.api.models import Game, Lesson, ParentProfile, Progress, Subject
from apps.api.routes.auth import register
from apps.api.routes.children import create_child
from apps.api.routes.games import save_game_result
from apps.api.routes.lessons import list_lessons
from apps.api.routes.parent import get_weekly_report, get_reports
from apps.api.routes.sync import sync_sessions
from apps.api.schemas import CreateChildRequest, RegisterRequest, SaveGameResultRequest
from apps.api.schemas.sync import SyncSessionItem
from apps.api.time import utc_now


def test_golden_flow_parent_login_to_weekly_report():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                # Seed a lesson + game the way content sync normally would.
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
                db.add_all([subject, lesson, game])
                await db.flush()
                await db.commit()

                # 1. Parent registers (login flow covered separately in test_api_auth.py).
                auth = await register(
                    RegisterRequest(
                        email="golden@example.com",
                        password="supersecret1",
                        display_name="Golden Parent",
                        language="vi",
                    ),
                    db=db,
                )

                profile = await _load_profile(db, auth.user.id)

                # 2. Create a child.
                child = await create_child(
                    CreateChildRequest(nickname="Golden Child", age_group="junior"),
                    profile=profile,
                    db=db,
                )
                profile = await _load_profile(db, auth.user.id)

                # 3. Choose a lesson.
                lessons = await list_lessons(age_group="junior", language=None, db=db)
                assert any(l.id == lesson.id for l in lessons)

                # 4. Launch + play + finish the game, save the result.
                started = utc_now()
                result = await save_game_result(
                    game_id=game.id,
                    body=SaveGameResultRequest(
                        attempt_id="golden-attempt-1",
                        child_profile_id=child.id,
                        game_id=game.id,
                        level_id="level_1",
                        lesson_id=lesson.id,
                        started_at=started,
                        completed_at=started + timedelta(seconds=90),
                        attempt_count=5,
                        correct_count=5,
                        incorrect_count=0,
                        hint_count=0,
                        duration_seconds=90,
                        completed=True,
                        mastery_evidence=1.0,
                        skill_evidence={"math": ["addition"]},
                    ),
                    profile=profile,
                    db=db,
                )

                # 5. Mastery updated on the server.
                progress_row = await db.execute(
                    select(Progress).where(Progress.child_id == child.id, Progress.lesson_id == lesson.id)
                )
                progress = progress_row.scalar_one()
                assert progress.mastery_score == result["mastery_score"]
                assert progress.mastery_score > 0.5

                # 6. Session end syncs to the daily summary (what the offline
                # queue's sessionEnd item does once connectivity returns).
                await sync_sessions(
                    [
                        SyncSessionItem(
                            child_id=child.id,
                            session_date=date.today(),
                            duration_seconds=90,
                            lessons_completed=1,
                            games_completed=1,
                        )
                    ],
                    profile=profile,
                    db=db,
                )

                # 7. Parent dashboard + weekly report reflect the session.
                reports = await get_reports(profile=profile, db=db)
                assert reports.total_games_today == 1
                assert reports.total_lessons_today == 1

                weekly = await get_weekly_report(child_id=child.id, week=0, profile=profile, db=db)
                assert len(weekly) == 1
                assert weekly[0].games_completed == 1
        finally:
            await engine.dispose()

    asyncio.run(run())


async def _session_maker():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", future=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    return async_sessionmaker(engine, expire_on_commit=False, autoflush=False), engine


async def _load_profile(db, user_id):
    result = await db.execute(
        select(ParentProfile)
        .options(selectinload(ParentProfile.children))
        .where(ParentProfile.user_id == user_id)
        .execution_options(populate_existing=True)
    )
    return result.scalar_one()
