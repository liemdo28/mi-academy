import asyncio

from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from apps.api.database import Base
from apps.api.models import (
    Attempt,
    ChildProfile,
    Lesson,
    ParentProfile,
    Question,
    Subject,
    User,
)
from apps.api.routes.admin import high_error_questions


def test_high_error_questions_returns_error_rate_and_total_attempts():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                admin = await _seed_question_attempts(db)

                rows = await high_error_questions(threshold=0.5, _=admin, db=db)

                assert rows == [
                    {
                        "question_id": "question-hard",
                        "prompt": "Which word starts with m?",
                        "error_rate": 0.75,
                        "total_attempts": 4,
                    }
                ]
        finally:
            await engine.dispose()

    asyncio.run(run())


async def _session_maker():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", future=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    return async_sessionmaker(engine, expire_on_commit=False, autoflush=False), engine


async def _seed_question_attempts(db):
    admin = User(
        role="admin",
        email="admin@example.test",
        password_hash="not-used",
    )
    parent_user = User(
        role="parent",
        email="parent@example.test",
        password_hash="not-used",
    )
    profile = ParentProfile(
        user=parent_user,
        display_name="Parent",
        language="vi",
        timezone="Asia/Ho_Chi_Minh",
    )
    child = ChildProfile(
        parent=profile,
        nickname="Mi",
        age_group="junior",
        preferred_language="vi",
    )
    subject = Subject(name="Language", code="language")
    lesson = Lesson(
        id="lesson-language",
        subject=subject,
        title="Word Builder",
        age_group="junior",
        language="vi",
        estimated_minutes=5,
    )
    hard = Question(
        id="question-hard",
        lesson=lesson,
        question_type="multiple_choice",
        prompt="Which word starts with m?",
        difficulty=2,
    )
    moderate = Question(
        id="question-moderate",
        lesson=lesson,
        question_type="multiple_choice",
        prompt="Which word starts with s?",
        difficulty=1,
    )
    db.add_all([admin, parent_user, profile, child, subject, lesson, hard, moderate])
    await db.flush()

    db.add_all(
        [
            Attempt(
                child_id=child.id,
                lesson_id=lesson.id,
                question_id=hard.id,
                is_correct=False,
            ),
            Attempt(
                child_id=child.id,
                lesson_id=lesson.id,
                question_id=hard.id,
                is_correct=False,
            ),
            Attempt(
                child_id=child.id,
                lesson_id=lesson.id,
                question_id=hard.id,
                is_correct=False,
            ),
            Attempt(
                child_id=child.id,
                lesson_id=lesson.id,
                question_id=hard.id,
                is_correct=True,
            ),
            Attempt(
                child_id=child.id,
                lesson_id=lesson.id,
                question_id=moderate.id,
                is_correct=False,
            ),
            Attempt(
                child_id=child.id,
                lesson_id=lesson.id,
                question_id=moderate.id,
                is_correct=True,
            ),
            Attempt(
                child_id=child.id,
                lesson_id=lesson.id,
                game_id="game-only",
                is_correct=False,
            ),
        ]
    )
    await db.commit()
    return admin
