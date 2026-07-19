import csv
from pathlib import Path

from tools.release_counts import compute_release_counts


ROOT = Path(__file__).resolve().parent.parent
CHECKLIST_PATH = (
    ROOT / "docs" / "content-review" / "milestone-3-games-16-30-review-checklist.csv"
)

EXPECTED_COLUMNS = [
    "level_id",
    "locale",
    "tier",
    "learning_objective",
    "correctness_review",
    "language_review",
    "age_review",
    "cultural_review",
    "accessibility_review",
    "reviewer",
    "review_date",
    "status",
    "notes",
]


def test_milestone_3_human_review_checklist_covers_every_new_level_locale():
    assert CHECKLIST_PATH.exists()
    with CHECKLIST_PATH.open(encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        rows = list(reader)

    assert reader.fieldnames == EXPECTED_COLUMNS
    new_level_count = sum(
        summary.level_count
        for summary in compute_release_counts().level_files
        if summary.game_id
        in {
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
        }
    )
    assert len(rows) == new_level_count * 2
    assert {row["locale"] for row in rows} == {"en", "vi"}
    assert {row["status"] for row in rows} == {"pending"}
