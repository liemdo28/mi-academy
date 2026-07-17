"""Rewards routes — list, unlock for a child."""

from fastapi import APIRouter, HTTPException, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
import uuid

from apps.api.database import get_db
from apps.api.dependencies import get_parent_profile
from apps.api.models import ParentProfile, Reward, ChildReward
from apps.api.time import utc_now
from apps.api.schemas import RewardResponse, UnlockRewardRequest

router = APIRouter()


def _child_belongs_to_parent(profile: ParentProfile, child_id: str):
    if child_id not in [c.id for c in profile.children]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"error": {"code": "FORBIDDEN", "message": "Child not owned by parent"}},
        )


@router.get("/children/{child_id}/rewards")
async def get_child_rewards(
    child_id: str,
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    """List all rewards — unlocked and locked — for a child."""
    _child_belongs_to_parent(profile, child_id)

    # Get all rewards
    all_result = await db.execute(select(Reward))
    all_rewards = all_result.scalars().all()

    # Get unlocked rewards for this child
    unlocked_result = await db.execute(
        select(ChildReward).where(ChildReward.child_id == child_id)
    )
    unlocked_rewards = {
        ur.reward_id: ur.unlocked_at for ur in unlocked_result.scalars().all()
    }

    return [
        RewardResponse(
            id=r.id,
            reward_type=r.reward_type,
            name=r.name,
            description=r.description,
            asset_url=r.asset_url,
            is_unlocked=r.id in unlocked_rewards,
            unlocked_at=unlocked_rewards[r.id].isoformat() if r.id in unlocked_rewards else None,
        )
        for r in all_rewards
    ]


@router.post("/children/{child_id}/rewards/unlock")
async def unlock_reward(
    child_id: str,
    body: UnlockRewardRequest,
    profile: ParentProfile = Depends(get_parent_profile),
    db: AsyncSession = Depends(get_db),
):
    """Parent manually unlocks a reward for a child."""
    _child_belongs_to_parent(profile, child_id)

    # Verify reward exists
    reward_result = await db.execute(
        select(Reward).where(Reward.id == body.reward_id)
    )
    reward = reward_result.scalar_one_or_none()
    if not reward:
        raise HTTPException(status_code=404, detail="Reward not found")

    # Check not already unlocked
    existing = await db.execute(
        select(ChildReward).where(
            ChildReward.child_id == child_id,
            ChildReward.reward_id == body.reward_id,
        )
    )
    if existing.scalar_one_or_none():
        return {"message": "Already unlocked", "unlocked": True}

    cr = ChildReward(
        id=str(uuid.uuid4()),
        child_id=child_id,
        reward_id=body.reward_id,
        unlocked_at=utc_now(),
    )
    db.add(cr)
    await db.commit()
    return {"message": "Reward unlocked", "unlocked": True}
