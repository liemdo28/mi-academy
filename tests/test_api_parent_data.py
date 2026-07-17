import asyncio
from datetime import date

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from apps.api.database import Base
from apps.api.models import (
    Attempt,
    ChildProfile,
    ChildReward,
    DailySession,
    Lesson,
    ParentProfile,
    Progress,
    Reward,
    Subject,
    User,
)
from apps.api.routes.children import delete_child
from apps.api.routes.parent import export_parent_data, get_reports, get_weekly_report
from apps.api.time import utc_now


def test_parent_reports_summarize_child_activity_without_scores_pressure():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                profile, child = await _seed_parent_child_activity(db)

                summary = await get_reports(profile=profile, db=db)
                weekly = await get_weekly_report(child_id=child.id, profile=profile, db=db)

                assert summary.total_children == 1
                assert summary.total_lessons_today == 2
                assert summary.total_games_today == 3
                assert summary.total_time_minutes_today == 25
                assert summary.total_stars_today == 2
                assert len(weekly) == 1
                assert weekly[0].lessons_completed == 2
                assert weekly[0].games_completed == 3
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_delete_child_removes_child_owned_data():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                profile, child = await _seed_parent_child_activity(db)

                await delete_child(child_id=child.id, profile=profile, db=db)
                await db.commit()

                assert await _count(db, ChildProfile) == 0
                assert await _count(db, DailySession) == 0
                assert await _count(db, Progress) == 0
                assert await _count(db, Attempt) == 0
                assert await _count(db, ChildReward) == 0
                assert await _count(db, Reward) == 1
                assert await _count(db, ParentProfile) == 1
                assert await _count(db, User) == 1
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_parent_export_is_privacy_safe_and_reviewable():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                profile, child = await _seed_parent_child_activity(db)

                exported = await export_parent_data(profile=profile, db=db)
                payload = exported.model_dump(mode="json")

                assert payload["schema_version"] == "mi-academy-parent-export-v1"
                assert payload["parent"]["display_name"] == "Parent"
                assert payload["children"] == [
                    {
                        "id": child.id,
                        "nickname": "Mi",
                        "age_group": "junior",
                        "preferred_language": "vi",
                        "daily_time_limit": 30,
                        "created_at": child.created_at.isoformat().replace("+00:00", "Z"),
                    }
                ]
                assert payload["daily_sessions"][0]["lessons_completed"] == 2
                assert payload["progress"][0]["status"] == "completed"
                assert payload["rewards"][0]["name"] == "First Steps"
                assert payload["attempts_summary"] == [
                    {
                        "child_id": child.id,
                        "total_attempts": 1,
                        "correct_attempts": 1,
                        "hint_count": 0,
                    }
                ]
                assert payload["privacy"] == {
                    "contains_child_contact_info": False,
                    "contains_location_data": False,
                    "contains_raw_answers": False,
                    "shared_with_third_parties": False,
                }
                assert "answer_json" not in str(payload)
        finally:
            await engine.dispose()

    asyncio.run(run())


async def _session_maker():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", future=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    return async_sessionmaker(engine, expire_on_commit=False, autoflush=False), engine


async def _seed_parent_child_activity(db):
    user = User(
        role="parent",
        email="parent@example.test",
        password_hash="not-used",
    )
    profile = ParentProfile(
        user=user,
        display_name="Parent",
        language="vi",
        timezone="Asia/Ho_Chi_Minh",
    )
    child = ChildProfile(
        parent=profile,
        nickname="Mi",
        age_group="junior",
        preferred_language="vi",
        daily_time_limit=30,
    )
    subject = Subject(name="Language", code="language")
    lesson = Lesson(
        subject=subject,
        title="Word Builder",
        age_group="junior",
        language="vi",
        estimated_minutes=5,
    )
    reward = Reward(
        reward_type="badge",
        name="First Steps",
        description="Completed a gentle learning step",
    )
    db.add_all([user, profile, child, subject, lesson, reward])
    await db.flush()

    db.add_all(
        [
            DailySession(
                child_id=child.id,
                session_date=date.today(),
                duration_seconds=25 * 60,
                lessons_completed=2,
                games_completed=3,
            ),
            Progress(
                child_id=child.id,
                lesson_id=lesson.id,
                status="completed",
                mastery_score=0.8,
                total_attempts=4,
                last_played_at=utc_now(),
            ),
            Attempt(
                child_id=child.id,
                lesson_id=lesson.id,
                is_correct=True,
                response_time_ms=1200,
                hint_count=0,
            ),
            ChildReward(
                child_id=child.id,
                reward_id=reward.id,
            ),
        ]
    )
    await db.commit()
    profile.children = [child]
    return profile, child


async def _count(db, model):
    result = await db.execute(select(func.count(model.id)))
    return result.scalar_one()
