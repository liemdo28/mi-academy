"""Children routes — CRUD for child profiles."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from apps.api.database import get_db
from apps.api.dependencies import get_parent_profile
from apps.api.models import ChildProfile, ParentProfile
from apps.api.schemas import CreateChildRequest, UpdateChildRequest, ChildResponse

router = APIRouter()


def _check_child_ownership(profile: ParentProfile, child_id: str):
    if child_id not in [c.id for c in profile.children]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"error": {"code": "FORBIDDEN", "message": "Child not owned by this parent"}},
        )


@router.get("", response_model=list[ChildResponse])
async def list_children(
    profile: ParentProfile = Depends(get_parent_profile),
):
    return [ChildResponse.from_model(c) for c in profile.children]


@router.post("", response_model=ChildResponse, status_code=status.HTTP_201_CREATED)
async def create_child(
    body: CreateChildRequest,
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    # Max 5 children per parent
    if len(profile.children) >= 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": {"code": "MAX_CHILDREN_REACHED", "message": "Maximum 5 children per account"}},
        )

    child = ChildProfile(
        parent_id=profile.id,
        nickname=body.nickname,
        birth_year=body.birth_year,
        age_group=body.age_group,
        grade_level=body.grade_level,
        avatar_id=body.avatar_id,
        preferred_language=body.preferred_language,
        daily_time_limit=body.daily_time_limit,
    )
    db.add(child)
    await db.flush()
    return ChildResponse.from_model(child)


@router.get("/{child_id}", response_model=ChildResponse)
async def get_child(
    child_id: str,
    profile: ParentProfile = Depends(get_parent_profile),
):
    _check_child_ownership(profile, child_id)
    child = next(c for c in profile.children if c.id == child_id)
    return ChildResponse.from_model(child)


@router.put("/{child_id}", response_model=ChildResponse)
async def update_child(
    child_id: str,
    body: UpdateChildRequest,
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    _check_child_ownership(profile, child_id)
    child = next(c for c in profile.children if c.id == child_id)

    update_data = body.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(child, key, value)

    await db.flush()
    return ChildResponse.from_model(child)


@router.delete("/{child_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_child(
    child_id: str,
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    _check_child_ownership(profile, child_id)
    child = next(c for c in profile.children if c.id == child_id)
    await db.delete(child)
    await db.flush()
