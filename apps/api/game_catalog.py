"""Canonical backend catalog for built MI Academy games."""

from __future__ import annotations

import json
from dataclasses import dataclass


@dataclass(frozen=True)
class GameCatalogEntry:
    id: str
    name: str
    game_type: str
    age_min: int
    age_max: int
    supported_skills: tuple[str, ...]

    @property
    def config_json(self) -> str:
        return json.dumps(
            {"supportedSkills": list(self.supported_skills)},
            ensure_ascii=False,
            sort_keys=True,
        )


BUILT_GAME_CATALOG: tuple[GameCatalogEntry, ...] = (
    GameCatalogEntry(
        id="game-word-builder",
        name="Ghép chữ tạo từ",
        game_type="word_builder",
        age_min=5,
        age_max=10,
        supported_skills=("letters.spelling", "letters.vocabulary"),
    ),
    GameCatalogEntry(
        id="game-sound-match",
        name="Nghe âm tìm chữ",
        game_type="sound_match",
        age_min=5,
        age_max=10,
        supported_skills=("letters.recognition.uppercase", "letters.initial_sound"),
    ),
    GameCatalogEntry(
        id="game-alphabet-explorer",
        name="Khám phá chữ cái",
        game_type="alphabet_explorer",
        age_min=5,
        age_max=7,
        supported_skills=(
            "letters.recognition.uppercase",
            "letters.recognition.lowercase",
            "letters.case_matching",
            "letters.initial_sound",
            "letters.vocabulary",
        ),
    ),
    GameCatalogEntry(
        id="game-missing-letter",
        name="Tìm chữ còn thiếu",
        game_type="missing_letter",
        age_min=6,
        age_max=9,
        supported_skills=(
            "letters.recognition.lowercase",
            "letters.spelling",
            "letters.vocabulary",
            "letters.initial_sound",
        ),
    ),
    GameCatalogEntry(
        id="game-math-race",
        name="Đường đua cộng trừ",
        game_type="math_race",
        age_min=5,
        age_max=12,
        supported_skills=(
            "math.addition.within_10",
            "math.subtraction.within_10",
            "math.addition.multi_digit",
            "math.subtraction.multi_digit",
        ),
    ),
    GameCatalogEntry(
        id="game-math-supermarket",
        name="Siêu thị toán học",
        game_type="math_supermarket",
        age_min=8,
        age_max=12,
        supported_skills=(
            "math.currency.basic",
            "math.addition.within_20",
            "math.subtraction.within_20",
        ),
    ),
    GameCatalogEntry(
        id="game-memory-cards",
        name="Ghi nhớ vị trí",
        game_type="memory_cards",
        age_min=5,
        age_max=12,
        supported_skills=("logic.memory.visual",),
    ),
    GameCatalogEntry(
        id="game-robot-commands",
        name="Robot làm theo lệnh",
        game_type="robot_commands",
        age_min=8,
        age_max=12,
        supported_skills=("logic.sequencing",),
    ),
)


BUILT_GAME_TYPES = (
    "word_builder",
    "sound_match",
    "math_race",
    "math_supermarket",
    "robot_commands",
    "memory_cards",
    "alphabet_explorer",
    "missing_letter",
)


def built_game_by_type(game_type: str) -> GameCatalogEntry | None:
    return next(
        (entry for entry in BUILT_GAME_CATALOG if entry.game_type == game_type),
        None,
    )
