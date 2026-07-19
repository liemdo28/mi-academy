import json
from pathlib import Path

from tools.level_validator.solve_levels import solve_placement


ROOT = Path(__file__).resolve().parents[1]


def _level(items, targets, rule=None):
    payload = {
        "prompt": "Sort the items.",
        "items": items,
        "targets": targets,
        "rule": rule or {"matchStrategy": "explicitIds"},
    }
    return {"localizedContent": {"en": payload, "vi": payload}}


def test_rejects_unknown_item_target_reference():
    errors = solve_placement(
        _level(
            [{"id": "item1", "acceptedTargetIds": ["missing"]}],
            [{"id": "left", "capacity": 1}],
        )
    )

    assert any("references unknown target missing" in error for error in errors)


def test_rejects_unknown_target_item_reference():
    errors = solve_placement(
        _level(
            [{"id": "item1", "acceptedTargetIds": ["left"]}],
            [{"id": "left", "capacity": 1, "acceptedItemIds": ["missing"]}],
        )
    )

    assert any("references unknown item missing" in error for error in errors)


def test_rejects_duplicate_item_and_target_ids():
    errors = solve_placement(
        _level(
            [
                {"id": "item1", "acceptedTargetIds": ["left"]},
                {"id": "item1", "acceptedTargetIds": ["left"]},
            ],
            [{"id": "left", "capacity": 2}, {"id": "left", "capacity": 2}],
        )
    )

    assert any("Duplicate item id item1" in error for error in errors)
    assert any("Duplicate target id left" in error for error in errors)


def test_rejects_unreachable_target():
    errors = solve_placement(
        _level(
            [{"id": "item1", "acceptedTargetIds": ["left"]}],
            [{"id": "left", "capacity": 1}, {"id": "right", "capacity": 1}],
        )
    )

    assert any("Target right has no valid item" in error for error in errors)


def test_rejects_total_capacity_shortage():
    errors = solve_placement(
        _level(
            [
                {"id": "item1", "acceptedTargetIds": ["left"]},
                {"id": "item2", "acceptedTargetIds": ["right"]},
                {"id": "item3", "acceptedTargetIds": ["right"]},
            ],
            [{"id": "left", "capacity": 1}, {"id": "right", "capacity": 1}],
        )
    )

    assert any("exceed target capacity" in error for error in errors)


def test_rejects_exclusive_target_over_capacity():
    errors = solve_placement(
        _level(
            [
                {"id": "item1", "acceptedTargetIds": ["left"]},
                {"id": "item2", "acceptedTargetIds": ["left"]},
            ],
            [{"id": "left", "capacity": 1}, {"id": "right", "capacity": 2}],
        )
    )

    assert any("Impossible completion" in error for error in errors)


def test_accepts_metadata_category_levels():
    errors = solve_placement(
        _level(
            [
                {"id": "circle", "metadata": {"category": "round"}},
                {"id": "square", "metadata": {"category": "corners"}},
            ],
            [
                {"id": "round", "capacity": 1, "metadata": {"category": "round"}},
                {
                    "id": "corners",
                    "capacity": 1,
                    "metadata": {"category": "corners"},
                },
            ],
            {"matchStrategy": "metadataCategory", "categoryMetadataKey": "category"},
        )
    )

    assert errors == []


def test_games_11_12_production_levels_are_solvable():
    for game_id in ("shape_builder", "word_sorter"):
        path = ROOT / "apps" / "mobile" / "assets" / "levels" / f"{game_id}.json"
        data = json.loads(path.read_text(encoding="utf-8"))
        assert data["levels"]
        for level in data["levels"]:
            assert solve_placement(level) == []
