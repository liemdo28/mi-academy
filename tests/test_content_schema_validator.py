"""Tests for tools/content_schema_validator.py (WS3 versioned content schema)."""

from tools import content_schema_validator as v


def test_all_production_content_validates():
    valid, errors = v.validate_production_content()
    assert valid, errors


def test_every_malformed_fixture_is_correctly_rejected():
    all_ok, report = v.check_malformed_fixtures()
    assert all_ok, report
    # Every fixture must appear in the report exactly once, and none may be
    # unexpectedly valid -- guards against a fixture silently being skipped
    # rather than actually checked.
    assert len(report) == len(list(v.MALFORMED_DIR.glob("*.json")))
    assert not any("UNEXPECTEDLY VALID" in line for line in report)


def test_cross_check_skill_tags_flags_unknown_ids():
    known = v.load_skill_taxonomy_ids()
    assert known, "skill taxonomy must not be empty"

    errors = v.cross_check_skill_tags(
        {"metadata": {"skillIds": ["letters.word_building", "made.up.skill"]}},
        known,
    )
    assert len(errors) == 1
    assert "made.up.skill" in errors[0]


def test_cross_check_skill_tags_accepts_real_ids():
    known = v.load_skill_taxonomy_ids()
    errors = v.cross_check_skill_tags(
        {"metadata": {"skillIds": ["letters.word_building", "logic.memory"]}},
        known,
    )
    assert errors == []


def test_check_asset_refs_ignores_bare_symbolic_keys():
    # Real content today references symbolic keys like "mi-fruit-apple"
    # (resolved by an in-app icon lookup, not a filesystem asset) -- these
    # must not be flagged as missing files.
    errors = v.check_asset_refs({"assetRefs": ["mi-fruit-apple", "mi-coin-1"]})
    assert errors == []


def test_check_asset_refs_flags_missing_path_like_refs():
    errors = v.check_asset_refs({"assetRefs": ["assets/images/does_not_exist.png"]})
    assert len(errors) == 1
    assert "does_not_exist.png" in errors[0]
