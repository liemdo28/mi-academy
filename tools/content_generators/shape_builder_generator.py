#!/usr/bin/env python3
"""Deterministic content generator for Shape Builder (Game 11).

Generates apps/mobile/assets/levels/shape_builder.json from scratch (this
game has no hand-authored levels) across 3 real difficulty tiers, built
on the shared Placement Engine's one-to-one placement mode
(packages/mi_game_engines/lib/src/placement/):

- Tier 1 (difficulty 1, "junior"): 2-3 basic shapes, one-to-one, no
  rotation, generous (exact-match-only) placement.
- Tier 2 (difficulty 3, "explorer"): 3-5 parts assembling a themed
  picture (house, boat, tree, ...), simple orientation on one part.
- Tier 3 (difficulty 5, "master"): 4-7 parts, composite figures, full
  rotation range, plus size-awareness levels (same shape, distinct
  small/large targets).

Determinism: a fixed seed (--seed, default 20260720) drives Python's
`random` module; the same seed always reproduces the same level set.

Independent validation: every generated level's item/target mapping is
recomputed and checked (one-to-one, every item has exactly one valid
target, no duplicate ids) before being accepted -- mirroring
math_race_generator.py's approach -- and again by
tools/content_schema_validator.py and tools/level_validator/solve_levels.py
once written to the real content file.

Usage:
    python tools/content_generators/shape_builder_generator.py --write
    python tools/content_generators/shape_builder_generator.py   # dry run
"""

from __future__ import annotations

import argparse
import json
import random
import sys
from pathlib import Path
from typing import Any

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parent.parent.parent
LEVELS_PATH = ROOT / "apps" / "mobile" / "assets" / "levels" / "shape_builder.json"

DEFAULT_SEED = 20260720
GAME_ID = "shape_builder"

# (id, vi label, en label)
BASIC_SHAPES = [
    ("circle", "Hình tròn", "Circle"),
    ("square", "Hình vuông", "Square"),
    ("triangle", "Hình tam giác", "Triangle"),
    ("rectangle", "Hình chữ nhật", "Rectangle"),
    ("star", "Hình ngôi sao", "Star"),
    ("diamond", "Hình thoi", "Diamond"),
    ("oval", "Hình bầu dục", "Oval"),
    ("pentagon", "Hình ngũ giác", "Pentagon"),
]

# Picture-assembly themes for tiers 2-3: (theme_id, vi_name, en_name, parts)
# parts: (part_id, vi_label, en_label)
THEMES = [
    (
        "house",
        "ngôi nhà",
        "house",
        [
            ("roof", "Mái nhà (tam giác)", "Roof (triangle)"),
            ("body", "Thân nhà (vuông)", "Body (square)"),
            ("door", "Cửa ra vào (chữ nhật)", "Door (rectangle)"),
            ("window", "Cửa sổ (vuông nhỏ)", "Window (small square)"),
            ("chimney", "Ống khói (chữ nhật đứng)", "Chimney (tall rectangle)"),
        ],
    ),
    (
        "boat",
        "con thuyền",
        "boat",
        [
            ("hull", "Thân thuyền (bầu dục)", "Hull (oval)"),
            ("sail", "Cánh buồm (tam giác)", "Sail (triangle)"),
            ("mast", "Cột buồm (chữ nhật)", "Mast (rectangle)"),
            ("flag", "Lá cờ (tam giác nhỏ)", "Flag (small triangle)"),
        ],
    ),
    (
        "tree",
        "cây xanh",
        "tree",
        [
            ("trunk", "Thân cây (chữ nhật)", "Trunk (rectangle)"),
            ("leaves", "Tán lá (tròn)", "Leaves (circle)"),
            ("branch", "Cành cây (chữ nhật nhỏ)", "Branch (small rectangle)"),
        ],
    ),
    (
        "robot",
        "chú robot",
        "robot",
        [
            ("head", "Đầu robot (vuông)", "Head (square)"),
            ("body", "Thân robot (chữ nhật)", "Body (rectangle)"),
            ("arm_left", "Tay trái (chữ nhật nhỏ)", "Left arm (small rectangle)"),
            ("arm_right", "Tay phải (chữ nhật nhỏ)", "Right arm (small rectangle)"),
            ("antenna", "Ăng-ten (tam giác)", "Antenna (triangle)"),
            ("eye", "Mắt robot (tròn nhỏ)", "Eye (small circle)"),
            ("leg", "Chân robot (chữ nhật đứng)", "Leg (tall rectangle)"),
        ],
    ),
    (
        "rocket",
        "tên lửa",
        "rocket",
        [
            ("body", "Thân tên lửa (chữ nhật đứng)", "Body (tall rectangle)"),
            ("nose", "Mũi tên lửa (tam giác)", "Nose cone (triangle)"),
            ("fin", "Cánh tên lửa (tam giác nhỏ)", "Fin (small triangle)"),
            ("window", "Cửa sổ (tròn)", "Window (circle)"),
        ],
    ),
    (
        "castle",
        "lâu đài",
        "castle",
        [
            ("wall", "Tường thành (chữ nhật)", "Wall (rectangle)"),
            ("tower", "Tháp canh (chữ nhật đứng)", "Tower (tall rectangle)"),
            ("flag", "Lá cờ (tam giác nhỏ)", "Flag (small triangle)"),
            ("gate", "Cổng thành (chữ nhật)", "Gate (rectangle)"),
            ("window", "Cửa sổ tháp (vuông nhỏ)", "Tower window (small square)"),
            ("roof", "Mái tháp (tam giác)", "Tower roof (triangle)"),
        ],
    ),
    (
        "car",
        "chiếc xe",
        "car",
        [
            ("body", "Thân xe (chữ nhật)", "Body (rectangle)"),
            ("wheel_front", "Bánh trước (tròn)", "Front wheel (circle)"),
            ("wheel_back", "Bánh sau (tròn)", "Back wheel (circle)"),
            ("window", "Cửa sổ xe (vuông)", "Window (square)"),
        ],
    ),
]

ALLOWED_ROTATIONS = [0, 90, 180, 270]
# Tier 2 only introduces "simple orientation" per the spec -- a single
# quarter-turn, not the full rotation range (that's Tier 3's job).
TIER2_ROTATIONS = [0, 90]


def _one_to_one_items_targets(
    shapes: list[tuple[str, str, str]],
    rng: random.Random,
    rotation_choices: list[int] | None,
) -> tuple[list[tuple[dict, dict]], list[tuple[dict, dict]]]:
    """Build one-to-one item/target pairs for a flat list of (id, vi, en).

    [rotation_choices] is the set of rotations this tier's
    `configuration.allowedRotations` will declare -- None means no
    rotation is used at all (Tier 1)."""
    items_vi, items_en = [], []
    targets_vi, targets_en = [], []
    for i, (shape_id, vi_label, en_label) in enumerate(shapes):
        item_id = f"item-{shape_id}-{i}"
        target_id = f"slot-{shape_id}-{i}"
        rotation = (
            rng.choice(rotation_choices)
            if rotation_choices and rng.random() < 0.4
            else None
        )
        item_vi: dict[str, Any] = {
            "id": item_id,
            "label": vi_label,
            "text": vi_label,
            "acceptedTargetIds": [target_id],
        }
        item_en: dict[str, Any] = {
            "id": item_id,
            "label": en_label,
            "text": en_label,
            "acceptedTargetIds": [target_id],
        }
        if rotation is not None:
            item_vi["rotationDegrees"] = rotation
            item_en["rotationDegrees"] = rotation
        items_vi.append(item_vi)
        items_en.append(item_en)
        targets_vi.append(
            {
                "id": target_id,
                "label": f"Ô của {vi_label.lower()}",
                "capacity": 1,
                "acceptedItemIds": [item_id],
            }
        )
        targets_en.append(
            {
                "id": target_id,
                "label": f"Slot for {en_label.lower()}",
                "capacity": 1,
                "acceptedItemIds": [item_id],
            }
        )
    return list(zip(items_vi, targets_vi)), list(zip(items_en, targets_en))


def _validate_one_to_one(items: list[dict], targets: list[dict]) -> None:
    """Independent re-check: every item maps to exactly one existing target
    and vice versa, no duplicate ids -- recomputed here rather than trusted
    from generation, mirroring math_race_generator.py's own philosophy."""
    item_ids = [i["id"] for i in items]
    target_ids = [t["id"] for t in targets]
    assert len(item_ids) == len(set(item_ids)), "duplicate item id"
    assert len(target_ids) == len(set(target_ids)), "duplicate target id"
    target_by_id = {t["id"]: t for t in targets}
    for item in items:
        accepted = item["acceptedTargetIds"]
        assert len(accepted) == 1, "expected exactly one accepted target"
        target = target_by_id.get(accepted[0])
        assert target is not None, "item references a missing target"
        assert item["id"] in target["acceptedItemIds"], "target does not reciprocate"
        if "rotationDegrees" in item:
            assert item["rotationDegrees"] in ALLOWED_ROTATIONS


def _tier1_level(rng: random.Random, seen: set, level_number: int) -> dict | None:
    count = rng.choice([2, 3])
    shapes = tuple(sorted(s[0] for s in rng.sample(BASIC_SHAPES, count)))
    key = ("t1", shapes)
    if key in seen:
        return None
    seen.add(key)
    chosen = [s for s in BASIC_SHAPES if s[0] in shapes]
    rng.shuffle(chosen)
    pairs_vi, pairs_en = _one_to_one_items_targets(chosen, rng, rotation_choices=None)
    items_vi, targets_vi = [p[0] for p in pairs_vi], [p[1] for p in pairs_vi]
    items_en, targets_en = [p[0] for p in pairs_en], [p[1] for p in pairs_en]
    _validate_one_to_one(items_vi, targets_vi)
    _validate_one_to_one(items_en, targets_en)
    return _build_level(
        level_number=level_number,
        tier=1,
        difficulty=1,
        age_group="junior",
        prompt_vi="Đặt mỗi hình vào đúng ô của nó!",
        prompt_en="Place each shape into its own slot!",
        hint_vi="Nhìn kỹ hình dạng của từng ô trống.",
        hint_en="Look closely at the shape of each empty slot.",
        items_vi=items_vi,
        targets_vi=targets_vi,
        items_en=items_en,
        targets_en=targets_en,
        skill_ids=["math.shapes.basic", "logic.spatial_reasoning"],
    )


def _tier2_level(rng: random.Random, seen: set, level_number: int) -> dict | None:
    theme_id, vi_name, en_name, parts = rng.choice(THEMES)
    count = rng.choice([3, 4, 5])
    count = min(count, len(parts))
    chosen_parts = tuple(sorted(p[0] for p in rng.sample(parts, count)))
    key = ("t2", theme_id, chosen_parts)
    if key in seen:
        return None
    seen.add(key)
    chosen = [p for p in parts if p[0] in chosen_parts]
    rng.shuffle(chosen)
    pairs_vi, pairs_en = _one_to_one_items_targets(
        chosen, rng, rotation_choices=TIER2_ROTATIONS
    )
    items_vi, targets_vi = [p[0] for p in pairs_vi], [p[1] for p in pairs_vi]
    items_en, targets_en = [p[0] for p in pairs_en], [p[1] for p in pairs_en]
    _validate_one_to_one(items_vi, targets_vi)
    _validate_one_to_one(items_en, targets_en)
    return _build_level(
        level_number=level_number,
        tier=2,
        difficulty=3,
        age_group="explorer",
        prompt_vi=f"Ghép các mảnh để tạo thành {vi_name}!",
        prompt_en=f"Assemble the pieces to build a {en_name}!",
        hint_vi="Mỗi mảnh chỉ có một vị trí đúng.",
        hint_en="Each piece has exactly one correct spot.",
        items_vi=items_vi,
        targets_vi=targets_vi,
        items_en=items_en,
        targets_en=targets_en,
        skill_ids=["creative.shape_construction", "logic.spatial_reasoning"],
        configuration={"allowedRotations": TIER2_ROTATIONS},
    )


def _tier3_level(rng: random.Random, seen: set, level_number: int) -> dict | None:
    theme_id, vi_name, en_name, parts = rng.choice(THEMES)
    count = rng.choice([4, 5, 6, 7])
    count = min(count, len(parts))
    chosen_parts = tuple(sorted(p[0] for p in rng.sample(parts, count)))
    key = ("t3", theme_id, chosen_parts)
    if key in seen:
        return None
    seen.add(key)
    chosen = [p for p in parts if p[0] in chosen_parts]
    rng.shuffle(chosen)
    pairs_vi, pairs_en = _one_to_one_items_targets(
        chosen, rng, rotation_choices=ALLOWED_ROTATIONS
    )
    items_vi, targets_vi = [p[0] for p in pairs_vi], [p[1] for p in pairs_vi]
    items_en, targets_en = [p[0] for p in pairs_en], [p[1] for p in pairs_en]
    _validate_one_to_one(items_vi, targets_vi)
    _validate_one_to_one(items_en, targets_en)
    return _build_level(
        level_number=level_number,
        tier=3,
        difficulty=5,
        age_group="master",
        prompt_vi=f"Lắp ráp {vi_name} hoàn chỉnh, chú ý hướng của từng mảnh!",
        prompt_en=f"Build the complete {en_name}, watch each piece's orientation!",
        hint_vi="Một vài mảnh cần xoay đúng hướng trước khi đặt.",
        hint_en="Some pieces need the right rotation before they fit.",
        items_vi=items_vi,
        targets_vi=targets_vi,
        items_en=items_en,
        targets_en=targets_en,
        skill_ids=[
            "creative.tangram",
            "logic.spatial_reasoning",
            "math.geometry",
        ],
        configuration={"allowedRotations": ALLOWED_ROTATIONS},
    )


def _build_level(
    *,
    level_number: int,
    tier: int,
    difficulty: int,
    age_group: str,
    prompt_vi: str,
    prompt_en: str,
    hint_vi: str,
    hint_en: str,
    items_vi: list[dict],
    targets_vi: list[dict],
    items_en: list[dict],
    targets_en: list[dict],
    skill_ids: list[str],
    configuration: dict | None = None,
) -> dict:
    level_id = f"sb-lv{level_number:03d}"
    vi_content: dict = {
        "prompt": prompt_vi,
        "hint": hint_vi,
        "items": items_vi,
        "targets": targets_vi,
    }
    en_content: dict = {
        "prompt": prompt_en,
        "hint": hint_en,
        "items": items_en,
        "targets": targets_en,
    }
    if configuration:
        vi_content["configuration"] = configuration
        en_content["configuration"] = configuration
    return {
        "id": level_id,
        "gameId": GAME_ID,
        "levelNumber": level_number,
        "difficulty": difficulty,
        "learningObjective": "spatial_reasoning_and_shape_recognition",
        "localizedContent": {"vi": vi_content, "en": en_content},
        "hints": [{"text": hint_vi}, {"text": hint_en}],
        "metadata": {
            "ageGroup": age_group,
            "skillIds": skill_ids,
            "tier": tier,
            "engineId": "placement",
            "reviewState": "technically_validated",
            "generatorSeed": None,  # filled in by generate_levels()
        },
        "assetRefs": [],
        "contentVersion": 1,
        "estimatedSeconds": 45 + tier * 15,
        "publicationState": "draft",
    }


_TIER_GENERATORS = {1: _tier1_level, 2: _tier2_level, 3: _tier3_level}
_TIER_COUNTS = {1: 15, 2: 15, 3: 15}


def generate_levels(seed: int = DEFAULT_SEED) -> list[dict]:
    rng = random.Random(seed)
    levels: list[dict] = []
    level_number = 1
    for tier, count in _TIER_COUNTS.items():
        generator = _TIER_GENERATORS[tier]
        seen: set = set()
        produced = 0
        attempts = 0
        while produced < count and attempts < count * 40:
            attempts += 1
            level = generator(rng, seen, level_number)
            if level is None:
                continue
            level["metadata"]["generatorSeed"] = seed
            levels.append(level)
            level_number += 1
            produced += 1
        if produced < count:
            raise RuntimeError(
                f"Tier {tier}: only generated {produced}/{count} unique levels"
            )
    return levels


def write_levels(levels: list[dict]) -> None:
    data = {
        "gameId": GAME_ID,
        "schemaVersion": "1.0.0",
        "description": "Shape Builder -- spatial reasoning and geometric part-whole placement (Game 11, Placement Engine).",
        "levels": levels,
    }
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
        tier = lv["metadata"]["tier"]
        by_tier[tier] = by_tier.get(tier, 0) + 1
    print(f"Generated {len(levels)} levels (seed={args.seed}): {by_tier}")

    if args.write:
        write_levels(levels)
        print(f"Wrote {len(levels)} levels into {LEVELS_PATH}")
    else:
        print("Dry run -- pass --write to create shape_builder.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
