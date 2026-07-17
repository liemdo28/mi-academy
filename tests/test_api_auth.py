import asyncio

import pytest
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from apps.api.database import Base
from apps.api.models import ParentProfile, User
from apps.api.routes.auth import login
from apps.api.schemas import LoginRequest


def test_parent_login_returns_parent_profile(monkeypatch):
    async def run():
        _stub_password_verifier(monkeypatch)
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                await _seed_users(db)

                response = await login(
                    LoginRequest(email="parent@example.com", password="correct-password"),
                    db=db,
                )

                assert response.user.role == "parent"
                assert response.parent_profile is not None
                assert response.parent_profile.display_name == "Parent"
                assert response.access_token
                assert response.refresh_token
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_admin_login_succeeds_without_parent_profile(monkeypatch):
    async def run():
        _stub_password_verifier(monkeypatch)
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                await _seed_users(db)

                response = await login(
                    LoginRequest(email="admin@example.com", password="correct-password"),
                    db=db,
                )

                assert response.user.role == "admin"
                assert response.parent_profile is None
                assert response.access_token
                assert response.refresh_token
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_login_rejects_bad_credentials(monkeypatch):
    async def run():
        _stub_password_verifier(monkeypatch)
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                await _seed_users(db)

                with pytest.raises(HTTPException) as exc:
                        await login(
                        LoginRequest(email="admin@example.com", password="wrong-password"),
                        db=db,
                    )

                assert exc.value.status_code == 401
        finally:
            await engine.dispose()

    asyncio.run(run())


async def _session_maker():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", future=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    return async_sessionmaker(engine, expire_on_commit=False, autoflush=False), engine


async def _seed_users(db):
    parent = User(
        role="parent",
        email="parent@example.com",
        password_hash="correct-password",
    )
    admin = User(
        role="admin",
        email="admin@example.com",
        password_hash="correct-password",
    )
    profile = ParentProfile(
        user=parent,
        display_name="Parent",
        language="vi",
        timezone="Asia/Ho_Chi_Minh",
    )
    db.add_all([parent, admin, profile])
    await db.commit()


def _stub_password_verifier(monkeypatch):
    monkeypatch.setattr(
        "apps.api.routes.auth.verify_password",
        lambda plain, hashed: plain == hashed,
    )
