import asyncio
import importlib

import sqlalchemy as sa
from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from apps.api.database import Base
from apps.api.game_catalog import BUILT_GAME_CATALOG, BUILT_GAME_TYPES
from apps.api.models import Game, Subject
import infrastructure.seed.seed_data as seed_data
from infrastructure.seed.seed_data import seed_built_games


def test_built_game_catalog_includes_games_1_through_15():
    assert BUILT_GAME_TYPES == (
        "word_builder",
        "sound_match",
        "alphabet_explorer",
        "missing_letter",
        "math_race",
        "math_supermarket",
        "memory_cards",
        "robot_commands",
        "category_collector",
        "pattern_parade",
        "shape_builder",
        "word_sorter",
        "number_balance",
        "logic_detective",
        "story_steps",
    )
    assert len({entry.id for entry in BUILT_GAME_CATALOG}) == 15
    assert len(set(BUILT_GAME_TYPES)) == 15
    assert all(entry.supported_skills for entry in BUILT_GAME_CATALOG)


def test_seed_built_games_is_idempotent():
    async def run():
        engine = create_async_engine("sqlite+aiosqlite:///:memory:", future=True)
        try:
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            session_maker = async_sessionmaker(
                engine, expire_on_commit=False, autoflush=False
            )
            async with session_maker() as db:
                first = await seed_built_games(db)
                await db.commit()
                second = await seed_built_games(db)
                await db.commit()

                result = await db.execute(select(Game.game_type))
                game_types = sorted(result.scalars().all())

                assert len(first) == 15
                assert second == []
                assert game_types == sorted(BUILT_GAME_TYPES)
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_full_seed_transaction_persists_rows_across_new_session(monkeypatch):
    async def run():
        engine = create_async_engine("sqlite+aiosqlite:///:memory:", future=True)
        try:
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            session_maker = async_sessionmaker(
                engine, expire_on_commit=False, autoflush=False
            )
            monkeypatch.setattr(seed_data, "async_session_maker", session_maker)

            await seed_data.seed()

            async with session_maker() as db:
                subject_count = (
                    await db.execute(sa.select(sa.func.count(Subject.id)))
                ).scalar_one()
                game_types = (
                    (
                        await db.execute(
                            sa.select(Game.game_type).order_by(Game.game_type)
                        )
                    )
                    .scalars()
                    .all()
                )

            assert subject_count == 5
            assert sorted(game_types) == sorted(BUILT_GAME_TYPES)
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_full_seed_transaction_rolls_back_on_failure(monkeypatch):
    async def run():
        engine = create_async_engine("sqlite+aiosqlite:///:memory:", future=True)
        try:
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            session_maker = async_sessionmaker(
                engine, expire_on_commit=False, autoflush=False
            )

            async def fail_after_subjects(db):
                db.add(
                    Game(
                        id="forced-failure-game",
                        name="Forced failure",
                        game_type="forced_failure",
                        age_min=5,
                        age_max=10,
                        config_json=None,
                        is_active=True,
                    )
                )
                raise RuntimeError("forced seed failure")

            monkeypatch.setattr(seed_data, "async_session_maker", session_maker)
            monkeypatch.setattr(seed_data, "seed_built_games", fail_after_subjects)

            try:
                await seed_data.seed()
            except RuntimeError:
                pass
            else:
                raise AssertionError("seed() should propagate failures")

            async with session_maker() as db:
                subject_count = (
                    await db.execute(sa.select(sa.func.count(Subject.id)))
                ).scalar_one()
                game_count = (
                    await db.execute(sa.select(sa.func.count(Game.id)))
                ).scalar_one()

            assert subject_count == 0
            assert game_count == 0
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_games_7_8_migration_inserts_rows_for_fresh_and_existing_databases():
    migration = importlib.import_module(
        "apps.api.alembic.versions.b4f7c2d9e801_seed_games_7_8"
    )
    engine = sa.create_engine("sqlite:///:memory:", future=True)
    games = sa.Table(
        "games",
        sa.MetaData(),
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("game_type", sa.String(length=50), nullable=False),
        sa.Column("age_min", sa.Integer(), nullable=False),
        sa.Column("age_max", sa.Integer(), nullable=False),
        sa.Column("config_json", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False),
    )
    games.create(engine)

    with engine.begin() as conn:
        original_get_bind = migration.op.get_bind
        migration.op.get_bind = lambda: conn
        try:
            migration.upgrade()
            migration.upgrade()
        finally:
            migration.op.get_bind = original_get_bind

        rows = conn.execute(
            sa.select(games.c.game_type, games.c.config_json).order_by(
                games.c.game_type
            )
        ).all()

    assert [row.game_type for row in rows] == ["alphabet_explorer", "missing_letter"]
    assert all("supportedSkills" in row.config_json for row in rows)

    engine = sa.create_engine("sqlite:///:memory:", future=True)
    games.create(engine)
    with engine.begin() as conn:
        conn.execute(
            games.insert().values(
                id="legacy-word-builder",
                name="Ghép chữ tạo từ",
                game_type="word_builder",
                age_min=5,
                age_max=10,
                config_json=None,
                is_active=True,
            )
        )
        original_get_bind = migration.op.get_bind
        migration.op.get_bind = lambda: conn
        try:
            migration.upgrade()
        finally:
            migration.op.get_bind = original_get_bind
        game_types = conn.execute(sa.select(games.c.game_type)).scalars().all()

    assert sorted(game_types) == [
        "alphabet_explorer",
        "missing_letter",
        "word_builder",
    ]


def test_games_9_15_migration_inserts_rows_idempotently():
    migration = importlib.import_module(
        "apps.api.alembic.versions.c9f1a7b2d615_seed_games_9_15"
    )
    engine = sa.create_engine("sqlite:///:memory:", future=True)
    games = sa.Table(
        "games",
        sa.MetaData(),
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("game_type", sa.String(length=50), nullable=False),
        sa.Column("age_min", sa.Integer(), nullable=False),
        sa.Column("age_max", sa.Integer(), nullable=False),
        sa.Column("config_json", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False),
    )
    games.create(engine)

    with engine.begin() as conn:
        original_get_bind = migration.op.get_bind
        migration.op.get_bind = lambda: conn
        try:
            migration.upgrade()
            migration.upgrade()
        finally:
            migration.op.get_bind = original_get_bind

        rows = conn.execute(
            sa.select(games.c.game_type, games.c.config_json).order_by(
                games.c.game_type
            )
        ).all()

    assert [row.game_type for row in rows] == sorted(migration.GAME_TYPES)
    assert all("supportedSkills" in row.config_json for row in rows)
