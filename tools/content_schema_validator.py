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
