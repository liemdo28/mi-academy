"""Auth routes — register, login, logout, refresh."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from apps.api.database import get_db
from apps.api.dependencies import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from apps.api.models import ParentProfile, User
from apps.api.schemas import (
    AuthResponse,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    TokenResponse,
    UserResponse,
    ParentProfileResponse,
)

router = APIRouter()


@router.post("/register", response_model=AuthResponse)
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    # Check email uniqueness
    existing = await db.execute(select(User).where(User.email == body.email))
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error": {"code": "EMAIL_EXISTS", "message": "Email already registered"}},
        )

    # Create user
    user = User(
        role="parent",
        email=body.email,
        password_hash=hash_password(body.password),
    )
    db.add(user)
    await db.flush()

    # Create parent profile
    profile = ParentProfile(
        user_id=user.id,
        display_name=body.display_name,
        language=body.language,
    )
    db.add(profile)
    await db.flush()

    access_token = create_access_token({"sub": user.id})
    refresh_token = create_refresh_token({"sub": user.id})

    return AuthResponse(
        user=UserResponse(
            id=user.id,
            role=user.role,
            email=user.email,
            created_at=user.created_at.isoformat(),
        ),
        parent_profile=ParentProfileResponse.from_model(profile),
        access_token=access_token,
        refresh_token=refresh_token,
    )


@router.post("/login", response_model=AuthResponse)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()

    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "INVALID_CREDENTIALS", "message": "Invalid email or password"}},
        )

    profile_result = await db.execute(
        select(ParentProfile).where(ParentProfile.user_id == user.id)
    )
    profile = profile_result.scalar_one_or_none()

    access_token = create_access_token({"sub": user.id})
    refresh_token = create_refresh_token({"sub": user.id})

    return AuthResponse(
        user=UserResponse(
            id=user.id,
            role=user.role,
            email=user.email,
            created_at=user.created_at.isoformat(),
        ),
        parent_profile=ParentProfileResponse.from_model(profile),
        access_token=access_token,
        refresh_token=refresh_token,
    )


@router.post("/logout", response_model=dict)
async def logout():
    # Stateless JWT — client discards the token
    return {"message": "Logged out successfully"}


@router.post("/refresh", response_model=TokenResponse)
async def refresh(body: RefreshRequest, db: AsyncSession = Depends(get_db)):
    payload = decode_token(body.refresh_token)

    if payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "INVALID_TOKEN_TYPE", "message": "Not a refresh token"}},
        )

    user_id = payload.get("sub")
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "USER_NOT_FOUND", "message": "User no longer exists"}},
        )

    access_token = create_access_token({"sub": user.id})
    new_refresh = create_refresh_token({"sub": user.id})

    return TokenResponse(access_token=access_token, refresh_token=new_refresh)
