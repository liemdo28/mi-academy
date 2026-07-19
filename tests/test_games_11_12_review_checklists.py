import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHECKLISTS = {
    "shape_builder": ("shape-builder-review-checklist.csv", 45),
    "word_sorter": ("word-sorter-review-checklist.csv", 60),
}
REVIEW_FIELDS = {
    "correctness_review",
    "language_review",
    "age_review",
    "cultural_review",
    "accessibility_review",
    "reviewer",
    "review_date",
    "notes",
}


def _levels(game_id: str) -> list[dict]:
    path = ROOT / "apps" / "mobile" / "assets" / "levels" / f"{game_id}.json"
    return json.loads(path.read_text(encoding="utf-8"))["levels"]


def _rows(filename: str) -> list[dict[str, str]]:
    path = ROOT / "docs" / "content-review" / filename
    return list(csv.DictReader(path.read_text(encoding="utf-8").splitlines()))


def test_games_11_12_review_checklists_cover_every_level_and_locale():
    for game_id, (filename, expected_levels) in CHECKLISTS.items():
        levels = _levels(game_id)
        rows = _rows(filename)
        expected_pairs = {
            (level["id"], locale) for level in levels for locale in ("en", "vi")
        }
        actual_pairs = {(row["level_id"], row["locale"]) for row in rows}

        assert len(levels) == expected_levels
        assert len(rows) == expected_levels * 2
        assert actual_pairs == expected_pairs


def test_games_11_12_review_checklists_remain_pending_human_review():
    for filename, _expected_levels in CHECKLISTS.values():
        rows = _rows(filename)
        assert rows
        for row in rows:
            assert row["locale"] in {"en", "vi"}
            assert row["tier"] in {"1", "2", "3"}
            assert row["status"] == "pending_human_review"
            assert all(row[field] == "" for field in REVIEW_FIELDS)
