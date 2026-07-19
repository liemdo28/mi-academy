import json
from pathlib import Path

from tools.content_generators.games_9_15_generator import placement_sort_level


ROOT = Path(__file__).resolve().parents[1]


def _production_levels(game_id: str) -> list[dict]:
    path = ROOT / "apps" / "mobile" / "assets" / "levels" / f"{game_id}.json"
    return json.loads(path.read_text(encoding="utf-8"))["levels"]


def test_shape_builder_generation_is_deterministic_and_matches_content():
    generated = [
        placement_sort_level("shape_builder", "sb", index, 45) for index in range(1, 46)
    ]
    regenerated = [
        placement_sort_level("shape_builder", "sb", index, 45) for index in range(1, 46)
    ]

    assert generated == regenerated
    assert generated == _production_levels("shape_builder")


def test_word_sorter_generation_is_deterministic_and_matches_content():
    generated = [
        placement_sort_level("word_sorter", "ws", index, 60) for index in range(1, 61)
    ]
    regenerated = [
        placement_sort_level("word_sorter", "ws", index, 60) for index in range(1, 61)
    ]

    assert generated == regenerated
    assert generated == _production_levels("word_sorter")
