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
    GameCatalogEntry(
        id="game-category-collector",
        name="Category Collector",
        game_type="category_collector",
        age_min=5,
        age_max=12,
        supported_skills=("logic.classification", "letters.vocabulary"),
    ),
    GameCatalogEntry(
        id="game-pattern-parade",
        name="Pattern Parade",
        game_type="pattern_parade",
        age_min=5,
        age_max=12,
        supported_skills=("logic.pattern.basic", "logic.pattern.recognition"),
    ),
    GameCatalogEntry(
        id="game-shape-builder",
        name="Shape Builder",
        game_type="shape_builder",
        age_min=5,
        age_max=12,
        supported_skills=("math.shapes.basic", "logic.spatial_reasoning"),
    ),
    GameCatalogEntry(
        id="game-word-sorter",
        name="Word Sorter",
        game_type="word_sorter",
        age_min=5,
        age_max=12,
        supported_skills=("letters.vocabulary", "letters.initial_sound"),
    ),
    GameCatalogEntry(
        id="game-number-balance",
        name="Number Balance",
        game_type="number_balance",
        age_min=5,
        age_max=12,
        supported_skills=("math.addition.within_20", "math.subtraction.within_20"),
    ),
    GameCatalogEntry(
        id="game-logic-detective",
        name="Logic Detective",
        game_type="logic_detective",
        age_min=7,
        age_max=12,
        supported_skills=("logic.conditions", "logic.algorithms"),
    ),
    GameCatalogEntry(
        id="game-story-steps",
        name="Story Steps",
        game_type="story_steps",
        age_min=5,
        age_max=12,
        supported_skills=("letters.reading_comprehension", "logic.pattern.basic"),
    ),
    GameCatalogEntry(
        id="game-picture-detective",
        name="Picture Detective",
        game_type="picture_detective",
        age_min=5,
        age_max=12,
        supported_skills=("science.observation", "logic.matching"),
    ),
    GameCatalogEntry(
        id="game-color-builder",
        name="Color Builder",
        game_type="color_builder",
        age_min=5,
        age_max=12,
        supported_skills=("creative.color_recognition", "logic.spatial_reasoning"),
    ),
    GameCatalogEntry(
        id="game-animal-homes",
        name="Animal Homes",
        game_type="animal_homes",
        age_min=5,
        age_max=12,
        supported_skills=("science.observation", "logic.matching"),
    ),
    GameCatalogEntry(
        id="game-daily-routine",
        name="Daily Routine",
        game_type="daily_routine",
        age_min=5,
        age_max=12,
        supported_skills=("logic.pattern.basic", "science.cause_effect"),
    ),
    GameCatalogEntry(
        id="game-healthy-foods",
        name="Healthy Foods",
        game_type="healthy_foods",
        age_min=5,
        age_max=12,
        supported_skills=("science.observation", "logic.classification"),
    ),
    GameCatalogEntry(
        id="game-letter-hunt",
        name="Letter Hunt",
        game_type="letter_hunt",
        age_min=5,
        age_max=12,
        supported_skills=("letters.recognition.lowercase", "letters.spelling"),
    ),
    GameCatalogEntry(
        id="game-number-train",
        name="Number Train",
        game_type="number_train",
        age_min=5,
        age_max=12,
        supported_skills=("math.number_recognition.1_20", "math.counting"),
    ),
    GameCatalogEntry(
        id="game-emotion-match",
        name="Emotion Match",
        game_type="emotion_match",
        age_min=5,
        age_max=12,
        supported_skills=("science.observation", "logic.matching"),
    ),
    GameCatalogEntry(
        id="game-puzzle-parts",
        name="Puzzle Parts",
        game_type="puzzle_parts",
        age_min=5,
        age_max=12,
        supported_skills=("creative.shape_construction", "logic.spatial_reasoning"),
    ),
    GameCatalogEntry(
        id="game-odd-one-out",
        name="Odd One Out",
        game_type="odd_one_out",
        age_min=5,
        age_max=12,
        supported_skills=("logic.odd_one_out", "logic.classification"),
    ),
    GameCatalogEntry(
        id="game-opposites",
        name="Opposites",
        game_type="opposites",
        age_min=5,
        age_max=12,
        supported_skills=("letters.synonyms_antonyms", "logic.matching"),
    ),
    GameCatalogEntry(
        id="game-weather-today",
        name="Weather Today",
        game_type="weather_today",
        age_min=5,
        age_max=12,
        supported_skills=("science.cause_effect", "logic.matching"),
    ),
    GameCatalogEntry(
        id="game-memory-journey",
        name="Memory Journey",
        game_type="memory_journey",
        age_min=5,
        age_max=12,
        supported_skills=("logic.memory", "logic.pattern.basic"),
    ),
    GameCatalogEntry(
        id="game-category-expert",
        name="Category Expert",
        game_type="category_expert",
        age_min=5,
        age_max=12,
        supported_skills=("logic.classification", "letters.vocabulary"),
    ),
    GameCatalogEntry(
        id="game-build-the-story",
        name="Build the Story",
        game_type="build_the_story",
        age_min=5,
        age_max=12,
        supported_skills=("letters.storytelling", "creative.storytelling"),
    ),
)


BUILT_GAME_TYPES = tuple(entry.game_type for entry in BUILT_GAME_CATALOG)


def built_game_by_type(game_type: str) -> GameCatalogEntry | None:
    return next(
        (entry for entry in BUILT_GAME_CATALOG if entry.game_type == game_type),
        None,
    )
