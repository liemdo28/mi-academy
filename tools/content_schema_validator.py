#!/usr/bin/env python3
"""Versioned content-schema validator (WS3).

Validates every level in apps/mobile/assets/levels/*.json against
schemas/level.schema.json (JSON Schema draft 2020-12) plus repository-level
cross-checks that a generic JSON Schema can't express on its own:

- every `metadata.skillIds` entry exists in content/skills/skill_taxonomy.json;
- level IDs are unique across ALL games, not just within one game's file
  (the existing per-game Dart `ContentValidator.validateGameLevels` only
  checks within one game's own level list);
- `assetRefs` entries, if present, point at files that actually exist.

Two modes:

    python tools/content_schema_validator.py
        Validates real production content (apps/mobile/assets/levels/*.json).
        Exit 0 only if everything is valid.

    python tools/content_schema_validator.py --check-malformed
        Validates content/fixtures/malformed/*.json and asserts EVERY one of
        them fails validation with an actionable error message -- this is
        the negative-test proof that the validator actually catches bad
        content, not just a happy-path smoke test. Exit 0 only if every
        malformed fixture was correctly rejected (i.e. the validator is
        working); exit 1 if any malformed fixture was wrongly accepted.
"""

from __future__ import annotations

import argparse
import json
import sys
import unicodedata
from pathlib import Path

import jsonschema

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parent.parent
SCHEMA_PATH = ROOT / "schemas" / "level.schema.json"
LEVELS_DIR = ROOT / "apps" / "mobile" / "assets" / "levels"
MALFORMED_DIR = ROOT / "content" / "fixtures" / "malformed"
SKILL_TAXONOMY_PATH = ROOT / "content" / "skills" / "skill_taxonomy.json"
MOBILE_ASSETS_DIR = ROOT / "apps" / "mobile" / "assets"


def load_schema() -> dict:
    return json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))


def load_skill_taxonomy_ids() -> set[str]:
    data = json.loads(SKILL_TAXONOMY_PATH.read_text(encoding="utf-8"))
    return {
        skill["skillId"] for subject in data["subjects"] for skill in subject["skills"]
    }


def validate_against_schema(level: dict, schema: jsonschema.Validator) -> list[str]:
    return [
        f"{'.'.join(str(p) for p in error.path) or '(root)'}: {error.message}"
        for error in sorted(schema.iter_errors(level), key=lambda e: e.path)
    ]


def cross_check_skill_tags(level: dict, known_skills: set[str]) -> list[str]:
    errors = []
    skill_ids = level.get("metadata", {}).get("skillIds") or []
    for skill_id in skill_ids:
        if skill_id not in known_skills:
            errors.append(
                f'skillIds: "{skill_id}" is not defined in '
                "content/skills/skill_taxonomy.json"
            )
    return errors


def check_asset_refs(level: dict) -> list[str]:
    """Only checks refs shaped like real file paths (contain "/" or a file
    extension). Real content today mostly uses bare symbolic keys (e.g.
    "mi-fruit-apple") resolved by an in-app icon/emoji lookup table, not a
    file on disk -- flagging those as "missing" would be a false positive
    against a legitimate, existing pattern, not a real content bug."""
    errors = []
    for ref in level.get("assetRefs") or []:
        looks_like_path = "/" in ref or "." in Path(ref).name
        if not looks_like_path:
            continue
        if not (MOBILE_ASSETS_DIR.parent / ref).exists() and not (ROOT / ref).exists():
            errors.append(f'assetRefs: referenced asset file not found: "{ref}"')
    return errors


def validate_missing_letter_content(level: dict) -> list[str]:
    """Game-specific checks for Missing Letter content.

    The shared JSON Schema intentionally allows game-specific localized
    payload fields, so this function validates the authored word-gap
    contract that the generic schema cannot express.
    """
    if level.get("gameId") != "missing_letter":
        return []

    errors: list[str] = []
    localized = level.get("localizedContent")
    if not isinstance(localized, dict):
        return ["localizedContent: must be an object"]

    if set(localized) - {"vi", "en"}:
        errors.append("localizedContent: unsupported locale for missing_letter")

    for locale in ("vi", "en"):
        content = localized.get(locale)
        field_prefix = f"localizedContent.{locale}"
        if not isinstance(content, dict):
            errors.append(f"{field_prefix}: locale content is required")
            continue

        target_word = content.get("targetWord")
        display_word = content.get("displayWord")
        positions = content.get("missingPositions")
        correct_letters = content.get("correctLetters")
        correct_answer = content.get("correctAnswer")
        options = content.get("options")
        category_hint = content.get("categoryHint")

        if not isinstance(target_word, str) or not target_word:
            errors.append(f"{field_prefix}.targetWord: required non-empty string")
            continue
        if unicodedata.normalize("NFC", target_word) != target_word:
            errors.append(f"{field_prefix}.targetWord: must be NFC-normalized")
        if not isinstance(display_word, str) or "_" not in display_word:
            errors.append(f"{field_prefix}.displayWord: must contain one or more gaps")
        if not isinstance(positions, list) or not positions:
            errors.append(f"{field_prefix}.missingPositions: required non-empty list")
            continue
        if not all(isinstance(pos, int) for pos in positions):
            errors.append(
                f"{field_prefix}.missingPositions: every position must be an integer"
            )
            continue

        target_upper = target_word.upper()
        for pos in positions:
            if pos < 0 or pos >= len(target_upper):
                errors.append(
                    f"{field_prefix}.missingPositions: position {pos} is outside targetWord"
                )
            elif isinstance(display_word, str) and (
                pos >= len(display_word) or display_word[pos] != "_"
            ):
                errors.append(
                    f"{field_prefix}.displayWord: missing position {pos} must be shown as '_'"
                )

        expected_letters = [
            target_upper[pos] for pos in positions if 0 <= pos < len(target_upper)
        ]
        expected_answer = "".join(expected_letters)
        if correct_letters != expected_letters:
            errors.append(
                f"{field_prefix}.correctLetters: must match targetWord at missingPositions"
            )
        if correct_answer != expected_answer:
            errors.append(
                f"{field_prefix}.correctAnswer: must equal ordered missing letters"
            )
        if isinstance(correct_answer, str) and len(correct_answer) != len(positions):
            errors.append(
                f"{field_prefix}.correctAnswer: length must match missingPositions"
            )

        if not isinstance(options, list) or not options:
            errors.append(f"{field_prefix}.options: required non-empty list")
            continue

        option_ids: list[str] = []
        option_texts: list[str] = []
        correct_count = 0
        for index, option in enumerate(options):
            if not isinstance(option, dict):
                errors.append(f"{field_prefix}.options[{index}]: must be an object")
                continue
            option_id = option.get("id")
            option_text = option.get("text")
            if not isinstance(option_id, str) or not option_id:
                errors.append(f"{field_prefix}.options[{index}].id: required")
            else:
                option_ids.append(option_id)
            if not isinstance(option_text, str) or not option_text:
                errors.append(f"{field_prefix}.options[{index}].text: required")
            else:
                option_texts.append(option_text)
            if option.get("correct") is True:
                correct_count += 1

        if len(option_ids) != len(set(option_ids)):
            errors.append(f"{field_prefix}.options: duplicate option IDs")
        if len(option_texts) != len(set(option_texts)):
            errors.append(f"{field_prefix}.options: duplicate visible choices")
        if correct_count != 1:
            errors.append(f"{field_prefix}.options: exactly one option must be correct")
        if isinstance(correct_answer, str) and correct_answer not in option_texts:
            errors.append(
                f"{field_prefix}.options: correct answer is absent from choices"
            )

        # If there are several one-letter gaps but no category/phonics hint,
        # the item is too easy to make ambiguous for this game mode.
        if len(positions) > 1 and not category_hint and not content.get("phonicsHint"):
            errors.append(
                f"{field_prefix}: multi-gap items require categoryHint or phonicsHint"
            )

    return errors


def validate_free_creativity_content(level: dict) -> list[str]:
    if level.get("gameId") != "free_creativity":
        return []

    errors: list[str] = []
    metadata = level.get("metadata")
    if not isinstance(metadata, dict):
        return ["metadata: free_creativity requires metadata"]

    metadata_deep = metadata.get("deepData")
    if not isinstance(metadata_deep, dict):
        errors.append("metadata.deepData: free_creativity requires deepData")
        metadata_deep = {}

    required_metadata = {
        "engine": "creative_story_lab",
        "completionModel": "participation",
        "assessmentModel": "ungraded",
    }
    for key, expected in required_metadata.items():
        if metadata.get(key, metadata_deep.get(key)) != expected:
            errors.append(f"metadata.{key}: expected {expected!r}")

    localized = level.get("localizedContent")
    if not isinstance(localized, dict):
        return errors + ["localizedContent: must be an object"]

    for locale in ("vi", "en"):
        content = localized.get(locale)
        field_prefix = f"localizedContent.{locale}"
        if not isinstance(content, dict):
            errors.append(f"{field_prefix}: locale content is required")
            continue
        deep_data = content.get("deepData")
        if not isinstance(deep_data, dict):
            errors.append(f"{field_prefix}.deepData: required for creative_story_lab")
            continue

        for key in ("scenes", "characters", "feelings"):
            choices = deep_data.get(key)
            if not isinstance(choices, list) or not choices:
                errors.append(f"{field_prefix}.deepData.{key}: required non-empty list")
                continue
            seen_ids: set[str] = set()
            for index, choice in enumerate(choices):
                if not isinstance(choice, dict):
                    errors.append(
                        f"{field_prefix}.deepData.{key}[{index}]: must be an object"
                    )
                    continue
                choice_id = choice.get("id")
                label = choice.get("label")
                if not isinstance(choice_id, str) or not choice_id:
                    errors.append(
                        f"{field_prefix}.deepData.{key}[{index}].id: required"
                    )
                elif choice_id in seen_ids:
                    errors.append(
                        f"{field_prefix}.deepData.{key}: duplicate id {choice_id!r}"
                    )
                else:
                    seen_ids.add(choice_id)
                if not isinstance(label, str) or not label.strip():
                    errors.append(
                        f"{field_prefix}.deepData.{key}[{index}].label: required"
                    )

        minimum = deep_data.get("minimumStoryLength", 1)
        maximum = deep_data.get("maximumStoryLength", 500)
        if not isinstance(minimum, int) or minimum < 1:
            errors.append(f"{field_prefix}.deepData.minimumStoryLength: positive int")
        if not isinstance(maximum, int) or maximum < 1:
            errors.append(f"{field_prefix}.deepData.maximumStoryLength: positive int")
        if isinstance(minimum, int) and isinstance(maximum, int) and minimum > maximum:
            errors.append(
                f"{field_prefix}.deepData: minimumStoryLength exceeds maximumStoryLength"
            )

        options = content.get("options")
        if isinstance(options, list) and options:
            if metadata_deep.get("legacyChoiceOptionsIgnored") is not True:
                errors.append(
                    f"{field_prefix}.options: legacy options require "
                    "metadata.deepData.legacyChoiceOptionsIgnored=true"
                )

    return errors


def validate_production_content() -> tuple[bool, list[str]]:
    schema_dict = load_schema()
    validator_cls = jsonschema.validators.validator_for(schema_dict)
    validator_cls.check_schema(schema_dict)
    validator = validator_cls(schema_dict)

    known_skills = load_skill_taxonomy_ids()
    all_errors: list[str] = []
    seen_ids: dict[str, str] = {}  # id -> first file that used it

    if not LEVELS_DIR.exists():
        return False, [f"Level directory not found: {LEVELS_DIR}"]

    for level_file in sorted(LEVELS_DIR.glob("*.json")):
        data = json.loads(level_file.read_text(encoding="utf-8"))
        levels = data.get("levels", [])
        for level in levels:
            level_id = level.get("id", "<missing id>")
            location = f"{level_file.name}:{level_id}"

            schema_errors = validate_against_schema(level, validator)
            for err in schema_errors:
                all_errors.append(f"{location}: {err}")

            for err in cross_check_skill_tags(level, known_skills):
                all_errors.append(f"{location}: {err}")

            for err in check_asset_refs(level):
                all_errors.append(f"{location}: {err}")

            for err in validate_missing_letter_content(level):
                all_errors.append(f"{location}: {err}")

            for err in validate_free_creativity_content(level):
                all_errors.append(f"{location}: {err}")

            if level_id in seen_ids and level_id != "<missing id>":
                all_errors.append(
                    f"{location}: duplicate level id (also used in "
                    f"{seen_ids[level_id]})"
                )
            else:
                seen_ids[level_id] = level_file.name

    return not all_errors, all_errors


def check_malformed_fixtures() -> tuple[bool, list[str]]:
    """Returns (all_correctly_rejected, report_lines)."""
    schema_dict = load_schema()
    validator_cls = jsonschema.validators.validator_for(schema_dict)
    validator = validator_cls(schema_dict)
    known_skills = load_skill_taxonomy_ids()

    if not MALFORMED_DIR.exists():
        return False, [f"Malformed fixtures directory not found: {MALFORMED_DIR}"]

    fixture_files = sorted(MALFORMED_DIR.glob("*.json"))
    if not fixture_files:
        return False, ["No malformed fixtures found -- nothing to prove"]

    report: list[str] = []
    all_ok = True

    # duplicate_id_a.json / duplicate_id_b.json only fail when checked
    # together (against each other), not individually against the schema --
    # handle that pair as a dedicated case.
    seen_ids: dict[str, str] = {}
    duplicate_detected = False

    for fixture_file in fixture_files:
        data = json.loads(fixture_file.read_text(encoding="utf-8"))
        errors = validate_against_schema(data, validator)
        errors += cross_check_skill_tags(data, known_skills)
        errors += validate_missing_letter_content(data)
        errors += validate_free_creativity_content(data)

        level_id = data.get("id")
        if level_id in seen_ids:
            duplicate_detected = True
            errors.append(f"duplicate id also used in {seen_ids[level_id]}")
        elif level_id:
            seen_ids[level_id] = fixture_file.name

        if fixture_file.name in ("duplicate_id_a.json", "duplicate_id_b.json"):
            # Each is individually schema-valid; only fails as a pair.
            if fixture_file.name == "duplicate_id_b.json" and not duplicate_detected:
                all_ok = False
                report.append(
                    f"[UNEXPECTEDLY VALID] {fixture_file.name}: expected a "
                    "duplicate-id error against duplicate_id_a.json but none "
                    "was raised"
                )
            else:
                report.append(f"[OK] {fixture_file.name}: correctly rejected")
            continue

        if errors:
            report.append(
                f"[OK] {fixture_file.name}: correctly rejected -- {errors[0]}"
            )
        else:
            all_ok = False
            report.append(
                f"[UNEXPECTEDLY VALID] {fixture_file.name}: expected this "
                "malformed fixture to fail validation, but it passed"
            )

    return all_ok, report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true")
    parser.add_argument(
        "--check-malformed",
        action="store_true",
        help="Validate content/fixtures/malformed/ instead of production "
        "content, asserting every fixture is correctly rejected.",
    )
    args = parser.parse_args()

    if args.check_malformed:
        ok, report = check_malformed_fixtures()
        if args.json:
            print(
                json.dumps({"all_correctly_rejected": ok, "report": report}, indent=2)
            )
        else:
            for line in report:
                print(line)
            print(
                f"\n[{'PASS' if ok else 'FAIL'}] "
                f"{len(report)} malformed fixtures checked"
            )
        return 0 if ok else 1

    valid, errors = validate_production_content()
    if args.json:
        print(
            json.dumps({"valid": valid, "errors": errors}, indent=2, ensure_ascii=False)
        )
    else:
        if valid:
            print(
                "[PASS] All production content validates against schemas/level.schema.json"
            )
        else:
            print(f"[FAIL] {len(errors)} content-schema error(s):")
            for err in errors:
                print(f"  {err}")
    return 0 if valid else 1


if __name__ == "__main__":
    raise SystemExit(main())
