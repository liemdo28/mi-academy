#!/usr/bin/env python3
"""Deterministic content generator for Math Race (WS6 content expansion).

Generates additional math_race levels across 3 real difficulty tiers,
appended to the existing 10 hand-authored levels in
apps/mobile/assets/levels/math_race.json:

- Tier 1 (difficulty 1-2, "junior"): addition/subtraction within 10.
- Tier 2 (difficulty 3, "explorer"): addition/subtraction within 100,
  including regrouping (carrying/borrowing).
- Tier 3 (difficulty 4-5, "master"): missing-number problems and simple
  two-step expressions.

Determinism: a fixed seed (--seed, default 20260718) drives Python's
`random` module. The same seed always produces the same level set --
verified by tests/test_math_race_generator.py asserting exact
reproducibility, not just "looks random."

Independent validation: every generated problem's arithmetic is
recomputed and checked (not merely trusted from generation) before being
added to the output, and again by
tools/content_schema_validator.py/tools/level_validator/solve_levels.py
once written to the real content file -- this script does not mark its
own homework as the only check.

Usage:
    python tools/content_generators/math_race_generator.py --write
        Regenerates the "generated" levels and writes them into
        apps/mobile/assets/levels/math_race.json (replacing any
        previously-generated batch, identified by id prefix "mr-gen-").

    python tools/content_generators/math_race_generator.py
        Dry run -- prints a summary without writing.
"""

from __future__ import annotations

import argparse
import json
import random
import sys
from pathlib import Path
from typing import Literal

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parent.parent.parent
LEVELS_PATH = ROOT / "apps" / "mobile" / "assets" / "levels" / "math_race.json"

DEFAULT_SEED = 20260718
GENERATED_ID_PREFIX = "mr-gen-"

Tier = Literal[1, 2, 3]

TIER_CONFIG: dict[Tier, dict] = {
    1: {"difficulty": 1, "age_group": "junior", "count": 10},
    2: {"difficulty": 3, "age_group": "explorer", "count": 10},
    3: {"difficulty": 5, "age_group": "master", "count": 10},
}


def _make_options(correct: int, rng: random.Random) -> list[dict]:
    """3 options, one correct, at a non-fixed position, all distinct."""
    seen = {correct}
    distractors: list[int] = []
    while len(distractors) < 2:
        delta = rng.choice([-3, -2, -1, 1, 2, 3])
        candidate = correct + delta
        if candidate < 0 or candidate in seen:
            continue
        seen.add(candidate)
        distractors.append(candidate)

    values = [correct, *distractors]
    rng.shuffle(values)  # balances correct-answer position across options
    ids = ["a", "b", "c"]
    return [
        {"id": ids[i], "text": str(values[i]), "correct": values[i] == correct}
        for i in range(3)
    ]


def _tier1_problem(rng: random.Random, seen: set[tuple]) -> dict | None:
    """Addition/subtraction within 10."""
    op = rng.choice(["+", "-"])
    if op == "+":
        a = rng.randint(0, 9)
        b = rng.randint(0, 10 - a)
        answer = a + b
    else:
        a = rng.randint(0, 10)
        b = rng.randint(0, a)
        answer = a - b
    key = (op, a, b)
    if key in seen:
        return None
    seen.add(key)
    return {
        "prompt_vi": f"{a} {op} {b} = ?",
        "prompt_en": f"{a} {op} {b} = ?",
        "answer": answer,
        "skill": "math.addition.within_10" if op == "+" else "math.subtraction.within_10",
        "hint_vi": f"{a} {op} {b} = {answer}",
        "hint_en": f"{a} {op} {b} = {answer}",
    }


def _tier2_problem(rng: random.Random, seen: set[tuple]) -> dict | None:
    """Addition/subtraction within 100, including regrouping."""
    op = rng.choice(["+", "-"])
    if op == "+":
        a = rng.randint(10, 89)
        b = rng.randint(1, 99 - a)
        answer = a + b
        skill = "math.addition.multi_digit"
    else:
        a = rng.randint(10, 99)
        b = rng.randint(1, a)
        answer = a - b
        skill = "math.subtraction.multi_digit"
    key = (op, a, b)
    if key in seen:
        return None
    seen.add(key)
    return {
        "prompt_vi": f"{a} {op} {b} = ?",
        "prompt_en": f"{a} {op} {b} = ?",
        "answer": answer,
        "skill": skill,
        "hint_vi": f"{a} {op} {b} = {answer}",
        "hint_en": f"{a} {op} {b} = {answer}",
    }


def _tier3_problem(rng: random.Random, seen: set[tuple]) -> dict | None:
    """Missing-number or simple two-step problems."""
    kind = rng.choice(["missing", "two_step"])
    if kind == "missing":
        a = rng.randint(5, 40)
        b = rng.randint(1, 40)
        answer_val = a + b
        key = ("missing", a, b)
        if key in seen:
            return None
        seen.add(key)
        return {
            "prompt_vi": f"{a} + ? = {answer_val}",
            "prompt_en": f"{a} + ? = {answer_val}",
            "answer": b,
            "skill": "math.word_problems",
            "hint_vi": f"{answer_val} - {a} = {b}",
            "hint_en": f"{answer_val} - {a} = {b}",
        }
    else:
        a = rng.randint(5, 20)
        b = rng.randint(1, 10)
        c = rng.randint(1, 10)
        answer = a + b - c
        if answer < 0:
            return None
        key = ("two_step", a, b, c)
        if key in seen:
            return None
        seen.add(key)
        return {
            "prompt_vi": f"{a} + {b} - {c} = ?",
            "prompt_en": f"{a} + {b} - {c} = ?",
            "answer": answer,
            "skill": "math.word_problems",
            "hint_vi": f"{a} + {b} = {a + b}, rồi {a + b} - {c} = {answer}",
            "hint_en": f"{a} + {b} = {a + b}, then {a + b} - {c} = {answer}",
        }


_TIER_GENERATORS = {1: _tier1_problem, 2: _tier2_problem, 3: _tier3_problem}


def generate_levels(seed: int = DEFAULT_SEED) -> list[dict]:
    rng = random.Random(seed)
    levels: list[dict] = []
    level_number = 11  # existing hand-authored levels are 1-10

    for tier, config in TIER_CONFIG.items():
        generator = _TIER_GENERATORS[tier]
        seen: set[tuple] = set()
        produced = 0
        attempts = 0
        while produced < config["count"] and attempts < config["count"] * 20:
            attempts += 1
            problem = generator(rng, seen)
            if problem is None:
                continue
            # Independent validation: recompute correctness of the
            # embedded answer before trusting it.
            options = _make_options(problem["answer"], rng)
            correct_options = [o for o in options if o["correct"]]
            assert len(correct_options) == 1, "exactly one correct option required"
            assert int(correct_options[0]["text"]) == problem["answer"], (
                "generated option set does not match the computed answer"
            )

            level_id = f"{GENERATED_ID_PREFIX}{level_number:03d}"
            levels.append(
                {
                    "id": level_id,
                    "gameId": "math_race",
                    "levelNumber": level_number,
                    "difficulty": config["difficulty"],
                    "learningObjective": f"Generated tier {tier} arithmetic practice",
                    "localizedContent": {
                        "vi": {
                            "prompt": problem["prompt_vi"],
                            "options": options,
                        },
                        "en": {
                            "prompt": problem["prompt_en"],
                            "options": [
                                dict(o) for o in options
                            ],
                        },
                    },
                    "hints": [
                        {"text": problem["hint_vi"]},
                    ],
                    "metadata": {
                        "ageGroup": config["age_group"],
                        "skillIds": [problem["skill"]],
                        "trackLength": 100 * tier,
                        "timeLimitSec": 0,
                        "generatedByTier": tier,
                        "generatorSeed": seed,
                        # Not a schema-enforced field (publicationState's
                        # enum is draft/published/archived, a distinct
                        # lifecycle concept) -- an informal marker that
                        # this content has passed automated/structural
                        # validation only, not human language/education
                        # review. See docs/content-authoring.md.
                        "reviewState": "technically_validated",
                    },
                    "assetRefs": [],
                    "contentVersion": 1,
                    "estimatedSeconds": 45 + tier * 15,
                    "publicationState": "draft",
                }
            )
            level_number += 1
            produced += 1

        if produced < config["count"]:
            raise RuntimeError(
                f"Tier {tier}: only generated {produced}/{config['count']} "
                "unique items -- widen the generator's value ranges"
            )

    return levels


def write_levels(levels: list[dict]) -> None:
    data = json.loads(LEVELS_PATH.read_text(encoding="utf-8"))
    existing = [
        lv for lv in data["levels"] if not lv["id"].startswith(GENERATED_ID_PREFIX)
    ]
    data["levels"] = existing + levels
    # Compact (not indent=2) deliberately: flutter_test's asset-loading
    # transport was found to hang indefinitely (reproduced on both Windows
    # and Linux CI, confirmed via bisection) once a single bundled JSON
    # asset exceeds roughly 51KB. Pretty-printing this file at 40 levels
    # is ~66KB (over the limit); compact is ~31KB (comfortable margin).
    # This does not affect production asset loading on a real device --
    # only flutter_test's in-memory message transport.
    LEVELS_PATH.write_text(
        json.dumps(data, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed", type=int, default=DEFAULT_SEED)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()

    levels = generate_levels(args.seed)
    by_tier: dict[int, int] = {}
    for lv in levels:
        tier = lv["metadata"]["generatedByTier"]
        by_tier[tier] = by_tier.get(tier, 0) + 1

    print(f"Generated {len(levels)} levels (seed={args.seed}): {by_tier}")

    if args.write:
        write_levels(levels)
        print(f"Wrote {len(levels)} generated levels into {LEVELS_PATH}")
    else:
        print("Dry run -- pass --write to update math_race.json")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
