"""add client_attempt_id to attempts

Revision ID: 3aac9694cdd1
Revises: 27676b1dea5d
Create Date: 2026-07-17 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '3aac9694cdd1'
down_revision: Union[str, Sequence[str], None] = '27676b1dea5d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('attempts', sa.Column('client_attempt_id', sa.String(length=64), nullable=True))
    op.create_unique_constraint('uq_attempts_client_attempt_id', 'attempts', ['client_attempt_id'])


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_constraint('uq_attempts_client_attempt_id', 'attempts', type_='unique')
    op.drop_column('attempts', 'client_attempt_id')
