"""Tests for the parent PIN server-side brute-force lockout.

Covers a previously-untested gap: the mobile app's 3-attempt PIN lockout is
client-side UI only (apps/mobile/lib/screens/parent_pin_screen.dart) --
calling the API directly bypassed it entirely, with only the generic
per-IP rate limiter (100 req/min by default) standing between an attacker
and a 4-6 digit PIN's full keyspace.
"""

import asyncio

import pytest
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from apps.api.database import Base
from apps.api.dependencies import hash_password, verify_parent_pin
from apps.api.models import ParentProfile, User


async def _session_maker():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", future=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    return async_sessionmaker(engine, expire_on_commit=False, autoflush=False), engine


async def _seed_profile(db, pin="1234"):
    user = User(role="parent", email="parent@example.test", password_hash="not-used")
    profile = ParentProfile(
        user=user,
        display_name="Parent",
        language="vi",
        timezone="Asia/Ho_Chi_Minh",
        pin_hash=hash_password(pin),
    )
    db.add_all([user, profile])
    await db.commit()
    return profile


def test_correct_pin_succeeds_and_resets_attempt_counter():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                profile = await _seed_profile(db)

                result = await verify_parent_pin(
                    x_parent_pin="1234", profile=profile, db=db
                )

                assert result is profile
                assert profile.pin_failed_attempts == 0
                assert profile.pin_locked_until is None
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_locks_out_after_three_wrong_attempts():
    async def run():
        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                profile = await _seed_profile(db)

                for _ in range(2):
                    with pytest.raises(HTTPException) as exc:
                        await verify_parent_pin(
                            x_parent_pin="0000", profile=profile, db=db
                        )
                    assert exc.value.detail["error"]["code"] == "INVALID_PIN"

                # The 3rd wrong attempt trips the lockout.
                with pytest.raises(HTTPException) as exc:
                    await verify_parent_pin(x_parent_pin="0000", profile=profile, db=db)
                assert exc.value.detail["error"]["code"] == "INVALID_PIN"
                assert profile.pin_locked_until is not None

                # Even the CORRECT pin is rejected while locked out --
                # otherwise lockout would only ever block guaranteed-wrong
                # guesses, not a lucky one during the lockout window.
                with pytest.raises(HTTPException) as exc:
                    await verify_parent_pin(x_parent_pin="1234", profile=profile, db=db)
                assert exc.value.status_code == 429
                assert exc.value.detail["error"]["code"] == "PIN_LOCKED"
        finally:
            await engine.dispose()

    asyncio.run(run())


def test_lockout_expires_and_allows_retry():
    async def run():
        from datetime import timedelta
        from apps.api.time import utc_now

        session_maker, engine = await _session_maker()
        try:
            async with session_maker() as db:
                profile = await _seed_profile(db)
                profile.pin_locked_until = utc_now() - timedelta(
                    seconds=1
                )  # already expired

                result = await verify_parent_pin(
                    x_parent_pin="1234", profile=profile, db=db
                )

                assert result is profile
        finally:
            await engine.dispose()

    asyncio.run(run())
