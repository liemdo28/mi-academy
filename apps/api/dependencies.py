"""Shared FastAPI dependencies — auth, PIN, rate-limiting."""

import uuid
from datetime import timedelta
from typing import Optional

from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from apps.api.config import settings
from apps.api.database import get_db
from apps.api.models import ParentProfile, RefreshToken, User
from apps.api.time import utc_now

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
bearer_scheme = HTTPBearer(auto_error=False)


# ── Password helpers ────────────────────────────────────────────────────────────

def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


# ── JWT helpers ────────────────────────────────────────────────────────────────

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = utc_now() + (
        expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


async def create_refresh_token(db: AsyncSession, user_id: str) -> str:
    """Issues a refresh token and records its `jti` server-side so it can be
    revoked (on logout, or in the future rotated on use) instead of
    remaining valid purely because it hasn't expired yet."""
    jti = str(uuid.uuid4())
    expire = utc_now() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    db.add(RefreshToken(jti=jti, user_id=user_id, expires_at=expire))
    await db.flush()
    to_encode = {"sub": user_id, "jti": jti, "exp": expire, "type": "refresh"}
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


async def redeem_refresh_token(db: AsyncSession, payload: dict) -> None:
    """Validates that a decoded refresh token's `jti` is still live (issued,
    not revoked, not expired server-side), then revokes it -- refresh
    tokens are single-use (rotated on every `/auth/refresh` call), so a
    captured-and-replayed old refresh token is rejected even if the JWT
    signature itself is still valid.
    """
    jti = payload.get("jti")
    if not jti:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "INVALID_TOKEN", "message": "Refresh token missing jti"}},
        )
    result = await db.execute(select(RefreshToken).where(RefreshToken.jti == jti))
    record = result.scalar_one_or_none()
    if (
        record is None
        or record.revoked_at is not None
        or record.expires_at.replace(tzinfo=None) < utc_now().replace(tzinfo=None)
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "REFRESH_TOKEN_REVOKED", "message": "Refresh token is no longer valid"}},
        )
    record.revoked_at = utc_now()


async def revoke_all_refresh_tokens(db: AsyncSession, user_id: str) -> None:
    """Ends every active session for a user -- called on logout, since a
    stateless-JWT logout can't otherwise stop a stolen refresh token from
    remaining valid until it naturally expires."""
    result = await db.execute(
        select(RefreshToken).where(
            RefreshToken.user_id == user_id,
            RefreshToken.revoked_at.is_(None),
        )
    )
    for record in result.scalars().all():
        record.revoked_at = utc_now()


def decode_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except JWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "INVALID_TOKEN", "message": str(exc)}},
        ) from exc


# ── Auth dependency ─────────────────────────────────────────────────────────────

async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Return the authenticated parent/admin user from the JWT."""
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "MISSING_TOKEN", "message": "Authorization header required"}},
        )
    payload = decode_token(credentials.credentials)
    if payload.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "INVALID_TOKEN_TYPE", "message": "Not an access token"}},
        )
    user_id: str = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "INVALID_TOKEN", "message": "Token missing subject"}},
        )
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "USER_NOT_FOUND", "message": "User no longer exists"}},
        )
    return user


async def get_parent_profile(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ParentProfile:
    """Return the parent profile attached to the authenticated user."""
    result = await db.execute(
        select(ParentProfile)
        .options(selectinload(ParentProfile.children))
        .where(ParentProfile.user_id == user.id)
    )
    profile = result.scalar_one_or_none()
    if profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "PROFILE_NOT_FOUND", "message": "Parent profile not found"}},
        )
    return profile


# ── PIN dependency ─────────────────────────────────────────────────────────────

PIN_MAX_FAILED_ATTEMPTS = 3
PIN_LOCKOUT_SECONDS = 30


async def verify_parent_pin(
    x_parent_pin: str = Header(..., alias="X-Parent-PIN"),
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
) -> ParentProfile:
    """Verify the parent's PIN header against their stored bcrypt hash.

    Enforces a server-side lockout after repeated failures -- the mobile
    app's own 3-attempt lockout is client-side UI only, so calling this
    endpoint directly (bypassing the app) would otherwise face no real
    limit beyond the generic per-IP rate limiter.
    """
    if not profile.pin_hash:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"error": {"code": "PIN_NOT_SET", "message": "Parent PIN has not been set"}},
        )
    if profile.pin_locked_until and profile.pin_locked_until.replace(tzinfo=None) > utc_now().replace(tzinfo=None):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={"error": {"code": "PIN_LOCKED", "message": "Too many incorrect attempts. Try again shortly."}},
        )
    if not verify_password(x_parent_pin, profile.pin_hash):
        profile.pin_failed_attempts += 1
        if profile.pin_failed_attempts >= PIN_MAX_FAILED_ATTEMPTS:
            profile.pin_locked_until = utc_now() + timedelta(seconds=PIN_LOCKOUT_SECONDS)
            profile.pin_failed_attempts = 0
        await db.commit()
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"error": {"code": "INVALID_PIN", "message": "Incorrect parent PIN"}},
        )
    profile.pin_failed_attempts = 0
    profile.pin_locked_until = None
    await db.commit()
    return profile


# ── Admin-only dependency ────────────────────────────────────────────────────────

def require_role(*roles: str):
    """Factory — returns a dependency that checks user.role is in roles."""
    async def checker(user: User = Depends(get_current_user)) -> User:
        if user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={"error": {"code": "FORBIDDEN", "message": f"Requires one of: {roles}"}},
            )
        return user
    return checker
