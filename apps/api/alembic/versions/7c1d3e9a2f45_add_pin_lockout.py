"""add pin brute-force lockout fields

Revision ID: 7c1d3e9a2f45
Revises: 5f2a8c14e9b7
Create Date: 2026-07-18 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '7c1d3e9a2f45'
down_revision: Union[str, Sequence[str], None] = '5f2a8c14e9b7'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column(
        'parent_profiles',
        sa.Column('pin_failed_attempts', sa.Integer(), nullable=False, server_default='0'),
    )
    op.add_column(
        'parent_profiles',
        sa.Column('pin_locked_until', sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('parent_profiles', 'pin_locked_until')
    op.drop_column('parent_profiles', 'pin_failed_attempts')
