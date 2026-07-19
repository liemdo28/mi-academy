"""seed games 16 through 30

Revision ID: d2a4f8e9b730
Revises: c9f1a7b2d615
Create Date: 2026-07-20 00:00:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

from apps.api.game_catalog import built_game_by_type


revision: str = "d2a4f8e9b730"
down_revision: Union[str, Sequence[str], None] = "c9f1a7b2d615"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


GAME_TYPES = (
    "picture_detective",
    "color_builder",
    "animal_homes",
    "daily_routine",
    "healthy_foods",
    "letter_hunt",
    "number_train",
    "emotion_match",
    "puzzle_parts",
    "odd_one_out",
    "opposites",
    "weather_today",
    "memory_journey",
    "category_expert",
    "build_the_story",
)


def upgrade() -> None:
    bind = op.get_bind()
    games = sa.table(
        "games",
        sa.column("id", sa.String(length=36)),
        sa.column("name", sa.String(length=100)),
        sa.column("game_type", sa.String(length=50)),
        sa.column("age_min", sa.Integer()),
        sa.column("age_max", sa.Integer()),
        sa.column("config_json", sa.Text()),
        sa.column("is_active", sa.Boolean()),
    )
    for game_type in GAME_TYPES:
        exists = bind.execute(
            sa.select(games.c.id).where(games.c.game_type == game_type).limit(1)
        ).first()
        if exists is not None:
            continue
        entry = built_game_by_type(game_type)
        if entry is None:
            raise RuntimeError(f"Missing game catalog entry for {game_type}")
        bind.execute(
            games.insert().values(
                id=entry.id,
                name=entry.name,
                game_type=entry.game_type,
                age_min=entry.age_min,
                age_max=entry.age_max,
                config_json=entry.config_json,
                is_active=True,
            )
        )


def downgrade() -> None:
    bind = op.get_bind()
    games = sa.table(
        "games",
        sa.column("id", sa.String(length=36)),
        sa.column("game_type", sa.String(length=50)),
    )
    bind.execute(games.delete().where(games.c.game_type.in_(GAME_TYPES)))
