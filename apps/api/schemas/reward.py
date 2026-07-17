"""Reward schemas."""

from pydantic import BaseModel


class RewardResponse(BaseModel):
    id: str
    reward_type: str  # star | badge | sticker | avatar_item
    name: str
    description: str | None
    asset_url: str | None
    is_unlocked: bool = False
    unlocked_at: str | None = None


class ChildRewardResponse(BaseModel):
    id: str
    reward_id: str
    reward: RewardResponse
    unlocked_at: str

    @classmethod
    def from_model(cls, child_reward, reward) -> "ChildRewardResponse":
        return cls(
            id=child_reward.id,
            reward_id=child_reward.reward_id,
            reward=RewardResponse(
                id=reward.id,
                reward_type=reward.reward_type,
                name=reward.name,
                description=reward.description,
                asset_url=reward.asset_url,
            ),
            unlocked_at=child_reward.unlocked_at.isoformat(),
        )
