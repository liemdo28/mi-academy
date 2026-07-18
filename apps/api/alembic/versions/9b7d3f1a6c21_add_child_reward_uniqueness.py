"""add child reward uniqueness

Revision ID: 9b7d3f1a6c21
Revises: 3aac9694cdd1
Create Date: 2026-07-17 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = '9b7d3f1a6c21'
down_revision: Union[str, Sequence[str], None] = '3aac9694cdd1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_unique_constraint(
        'uq_child_reward_once',
        'child_rewards',
        ['child_id', 'reward_id'],
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_constraint('uq_child_reward_once', 'child_rewards', type_='unique')
