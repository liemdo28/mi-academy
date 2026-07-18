#!/usr/bin/env python3
"""Deterministic content generator for Math Supermarket (WS6 content expansion).

Generates additional math_supermarket levels across 3 real difficulty
tiers, appended to the existing 10 hand-authored levels in
apps/mobile/assets/levels/math_supermarket.json:

- Tier 1 (difficulty 1, "junior"): single-item purchase, "how much
  change?" within a budget of 10.
- Tier 2 (difficulty 3, "explorer"): two-item purchase, "what is the
  total / how much change?" within a budget of 20.
- Tier 3 (difficulty 5, "master"): three-item affordability word
  problems -- "can you also buy X with what's left?" -- requiring a
  two-step calculation (sum items bought, subtract from budget, compare
  against a candidate purchase).

Determinism: a fixed seed (--seed, default 20260718) drives Python's
`random` module.

Independent validation: every generated problem's arithmetic is
recomputed and checked (not merely trusted from generation) before being
added to the output, mirroring math_race_generator.py's approach.

Usage:
    python tools/content_generators/math_supermarket_generator.py --write
    python tools/content_generators/math_supermarket_generator.py   # dry run
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
LEVELS_PATH = ROOT / "apps" / "mobile" / "assets" / "levels" / "math_supermarket.json"

DEFAULT_SEED = 20260718
GENERATED_ID_PREFIX = "ms-gen-"

Tier = Literal[1, 2, 3]

# (item asset key, Vietnamese name, English name)
ITEMS = [
    ("mi-fruit-apple", "quả táo", "an apple"),
    ("mi-fruit-orange", "quả cam", "an orange"),
    ("mi-fruit-banana", "quả chuối", "a banana"),
    ("mi-drink-milk", "hộp sữa", "a milk box"),
    ("mi-drink-water", "chai nước", "a water bottle"),
    ("mi-food-bread", "ổ bánh mì", "a loaf of bread"),
    ("mi-school-pen", "cây bút", "a pen"),
    ("mi-school-notebook", "quyển vở", "a notebook"),
    ("mi-candy", "cái kẹo", "a candy"),
]

TIER_CONFIG: dict[Tier, dict] = {
    1: {"difficulty": 1, "age_group": "junior", "count": 10},
    2: {"difficulty": 3, "age_group": "explorer", "count": 10},
    3: {"difficulty": 5, "age_group": "master", "count": 10},
}


def _make_options(
    correct: int,
    rng: random.Random,
    unit_vi: str,
    unit_en: str,
    template_vi: str,
    template_en: str,
) -> tuple[list[dict], list[dict]]:
    """3 options each (vi/en), one correct, all distinct non-negative values."""
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
    rng.shuffle(values)
    ids = ["a", "b", "c"]
    vi_options = [
        {
            "id": ids[i],
            "text": template_vi.format(v=values[i], u=unit_vi),
            "correct": values[i] == correct,
        }
        for i in range(3)
    ]
    en_options = [
        {
            "id": ids[i],
            "text": template_en.format(v=values[i], u=unit_en),
            "correct": values[i] == correct,
        }
        for i in range(3)
    ]
    return vi_options, en_options


def _tier1_problem(rng: random.Random, seen: set[tuple]) -> dict | None:
    """Single item, "how much change?" within a budget of 10."""
    item_key, name_vi, name_en = rng.choice(ITEMS)
    budget = rng.randint(3, 10)
    price = rng.randint(1, budget)
    change = budget - price
    key = ("t1", item_key, budget, price)
    if key in seen:
        return None
    seen.add(key)
    return {
        "budget": budget,
        "prompt_vi": f"Con có {budget} đồng. Mua {name_vi} giá {price} đồng. Còn lại bao nhiêu?",
        "prompt_en": f"You have {budget} coins. Buy {name_en} for {price} coins. How much is left?",
        "answer": change,
        "skills": ["math.currency.basic", "math.subtraction.within_10"],
        "hint_vi": f"{budget} - {price} = {change}",
        "hint_en": f"{budget} - {price} = {change}",
        "assets": [item_key],
        "unit_template_vi": "{v} đồng",
        "unit_template_en": "{v} coins",
    }


def _tier2_problem(rng: random.Random, seen: set[tuple]) -> dict | None:
    """Two items, total or change within a budget of 20."""
    (item_a, name_a_vi, name_a_en), (item_b, name_b_vi, name_b_en) = rng.sample(
        ITEMS, 2
    )
    price_a = rng.randint(2, 9)
    price_b = rng.randint(2, 9)
    total = price_a + price_b
    budget = rng.randint(total, 20)
    change = budget - total
    key = ("t2", item_a, item_b, price_a, price_b, budget)
    if key in seen:
        return None
    seen.add(key)
    return {
        "budget": budget,
        "prompt_vi": (
            f"Con có {budget} đồng. Mua {name_a_vi} giá {price_a} đồng và "
            f"{name_b_vi} giá {price_b} đồng. Còn lại bao nhiêu?"
        ),
        "prompt_en": (
            f"You have {budget} coins. Buy {name_a_en} for {price_a} coins and "
            f"{name_b_en} for {price_b} coins. How much is left?"
        ),
        "answer": change,
        "skills": [
            "math.currency.basic",
            "math.addition.within_20",
            "math.subtraction.within_20",
        ],
        "hint_vi": f"{price_a} + {price_b} = {total}, rồi {budget} - {total} = {change}",
        "hint_en": f"{price_a} + {price_b} = {total}, then {budget} - {total} = {change}",
        "assets": [item_a, item_b],
        "unit_template_vi": "{v} đồng",
        "unit_template_en": "{v} coins",
    }


def _tier3_problem(rng: random.Random, seen: set[tuple]) -> dict | None:
    """Three items: buy two, then can you also afford a third?"""
    item_a, item_b, item_c = rng.sample(ITEMS, 3)
    price_a = rng.randint(3, 10)
    price_b = rng.randint(3, 10)
    price_c = rng.randint(2, 8)
    spent = price_a + price_b
    budget = rng.randint(spent, spent + 15)
    remaining = budget - spent
    can_afford = remaining >= price_c
    key = ("t3", item_a[0], item_b[0], item_c[0], price_a, price_b, price_c, budget)
    if key in seen:
        return None
    seen.add(key)
    verdict_vi = "đủ" if can_afford else "không đủ"
    verdict_en = "yes" if can_afford else "not enough"
    return {
        "budget": budget,
        "prompt_vi": (
            f"Con có {budget} đồng. Mua {item_a[1]} giá {price_a} đồng và "
            f"{item_b[1]} giá {price_b} đồng. Còn lại có đủ mua {item_c[1]} "
            f"giá {price_c} đồng không?"
        ),
        "prompt_en": (
            f"You have {budget} coins. Buy {item_a[2]} for {price_a} coins and "
            f"{item_b[2]} for {price_b} coins. Is what's left enough for "
            f"{item_c[2]} at {price_c} coins?"
        ),
        "answer": remaining,
        "verdict_vi": verdict_vi,
        "verdict_en": verdict_en,
        "skills": ["math.currency.basic", "math.word_problems"],
        "hint_vi": f"{budget} - {price_a} - {price_b} = {remaining} → {verdict_vi}",
        "hint_en": f"{budget} - {price_a} - {price_b} = {remaining} -> {verdict_en}",
        "assets": [item_a[0], item_b[0], item_c[0]],
        "unit_template_vi": "còn {v} đồng — " + verdict_vi,
        "unit_template_en": "{v} left — " + verdict_en,
    }


_TIER_GENERATORS = {1: _tier1_problem, 2: _tier2_problem, 3: _tier3_problem}


def generate_levels(seed: int = DEFAULT_SEED) -> list[dict]:
    rng = random.Random(seed)
    levels: list[dict] = []
    level_number = 11

    for tier, config in TIER_CONFIG.items():
        generator = _TIER_GENERATORS[tier]
        seen: set[tuple] = set()
        produced = 0
        attempts = 0
        while produced < config["count"] and attempts < config["count"] * 30:
            attempts += 1
            problem = generator(rng, seen)
            if problem is None:
                continue

            vi_options, en_options = _make_options(
                problem["answer"],
                rng,
                unit_vi="",
                unit_en="",
                template_vi=problem["unit_template_vi"],
                template_en=problem["unit_template_en"],
            )
            correct_vi = [o for o in vi_options if o["correct"]]
            correct_en = [o for o in en_options if o["correct"]]
            assert len(correct_vi) == 1 and len(correct_en) == 1, (
                "exactly one correct option required per locale"
            )
            expected_vi_text = problem["unit_template_vi"].format(v=problem["answer"])
            expected_en_text = problem["unit_template_en"].format(v=problem["answer"])
            assert correct_vi[0]["text"] == expected_vi_text, (
                "generated vi option set does not match the computed answer"
            )
            assert correct_en[0]["text"] == expected_en_text, (
                "generated en option set does not match the computed answer"
            )

            level_id = f"{GENERATED_ID_PREFIX}{level_number:03d}"
            levels.append(
                {
                    "id": level_id,
                    "gameId": "math_supermarket",
                    "levelNumber": level_number,
                    "difficulty": config["difficulty"],
                    "learningObjective": f"Generated tier {tier} money-math practice",
                    "localizedContent": {
                        "vi": {"prompt": problem["prompt_vi"], "options": vi_options},
                        "en": {"prompt": problem["prompt_en"], "options": en_options},
                    },
                    "hints": [{"text": problem["hint_vi"]}],
                    "metadata": {
                        "ageGroup": config["age_group"],
                        "skillIds": problem["skills"],
                        "budget": problem["budget"],
                        "currencyUnit": "đồng",
                        "generatedByTier": tier,
                        "generatorSeed": seed,
                        "reviewState": "technically_validated",
                    },
                    "assetRefs": problem["assets"],
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
    # Compact, not indent=2: flutter_test's asset-loading transport hangs
    # indefinitely once a single bundled JSON asset exceeds ~51KB (see
    # math_race_generator.py's write_levels for the full root-cause note).
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
        print("Dry run -- pass --write to update math_supermarket.json")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
