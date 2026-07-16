"""Rewards routes — list, unlock for a child."""

from datetime import datetime
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
import uuid

from apps.api.database import get_db
from apps.api.dependencies import get_current_user
from apps.api.models import ChildProfile, Reward, ChildReward
from apps.api.schemas import RewardResponse, UnlockRewardRequest
from apps.api.models import User

router = APIRouter()


@router.get("/children/{child_id}/rewards")
async def get_child_rewards(
    child_id: str,
    user: User = get_current_user,
    db: AsyncSession = get_db,
):
    """List all rewards — unlocked and locked — for a child."""
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
            unlocked_at=unlocked_rewards.get(r.id),
        )
        for r in all_rewards
    ]


@router.post("/children/{child_id}/rewards/unlock")
async def unlock_reward(
    child_id: str,
    body: UnlockRewardRequest,
    user: User = get_current_user,
    db: AsyncSession = get_db,
):
    """Parent manually unlocks a reward for a child."""
    # Verify child exists
    child_result = await db.execute(
        select(ChildProfile).where(ChildProfile.id == child_id)
    )
    if not child_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Child not found")

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
        unlocked_at=datetime.utcnow(),
    )
    db.add(cr)
    await db.commit()
    return {"message": "Reward unlocked", "unlocked": True}
