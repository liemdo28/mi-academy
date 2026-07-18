"""add performance indexes (daily_sessions.child_id, child_rewards child+unlocked_at)

Revision ID: a3e6f0b8c1d2
Revises: 7c1d3e9a2f45
Create Date: 2026-07-18 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = 'a3e6f0b8c1d2'
down_revision: Union[str, Sequence[str], None] = '7c1d3e9a2f45'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_index('idx_daily_sessions_child', 'daily_sessions', ['child_id'])
    op.create_index(
        'idx_child_rewards_child_unlocked', 'child_rewards', ['child_id', 'unlocked_at']
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index('idx_child_rewards_child_unlocked', table_name='child_rewards')
    op.drop_index('idx_daily_sessions_child', table_name='daily_sessions')
