"""Backend/mobile content-schema parity tests (WS3).

Confirms apps/api/schemas/content_item.py (Pydantic) accepts every real
production level (the same content tools/content_schema_validator.py and
the Dart ContentLoader/ContentValidator already validate) and rejects the
same malformed fixtures they reject -- proving mobile and backend agree on
what "valid content" means, not just that each has its own independent
notion of it.
"""

import json
from pathlib import Path

from apps.api.schemas.content_item import validate_content_item

ROOT = Path(__file__).resolve().parent.parent
LEVELS_DIR = ROOT / "apps" / "mobile" / "assets" / "levels"
MALFORMED_DIR = ROOT / "content" / "fixtures" / "malformed"


def _all_real_levels():
    for level_file in sorted(LEVELS_DIR.glob("*.json")):
        data = json.loads(level_file.read_text(encoding="utf-8"))
        for level in data["levels"]:
            yield level_file.name, level


def test_every_real_production_level_validates():
    checked = 0
    for filename, level in _all_real_levels():
        item, errors = validate_content_item(level)
        assert item is not None, f"{filename}:{level.get('id')}: {errors}"
        checked += 1
    assert checked == 60  # 6 games x 10 levels each, at time of writing


def test_age_band_and_skill_tags_readable_from_metadata():
    _, first_level = next(_all_real_levels())
    item, errors = validate_content_item(first_level)
    assert item is not None, errors
    assert item.age_band in ("junior", "explorer", "master")
    assert isinstance(item.skill_tags, list)


def test_missing_locale_fixture_is_rejected():
    data = json.loads(
        (MALFORMED_DIR / "missing_locale.json").read_text(encoding="utf-8")
    )
    item, errors = validate_content_item(data)
    assert item is None
    assert errors


def test_invalid_difficulty_fixture_is_rejected():
    data = json.loads(
        (MALFORMED_DIR / "invalid_difficulty.json").read_text(encoding="utf-8")
    )
    item, errors = validate_content_item(data)
    assert item is None
    assert errors


def test_valid_fixture_shape_is_accepted():
    item, errors = validate_content_item(
        {
            "id": "test-lv1",
            "gameId": "word_builder",
            "levelNumber": 1,
            "difficulty": 1,
            "localizedContent": {
                "vi": {"prompt": "Ghép chữ thành từ!"},
                "en": {"prompt": "Build the word!"},
            },
            "hints": [{"text": "Try the first letter"}],
        }
    )
    assert errors == []
    assert item is not None
    assert item.contentVersion == 1
    assert item.publicationState == "published"
