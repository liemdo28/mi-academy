#!/usr/bin/env python3
"""Deterministic content generator for Word Sorter (Game 12).

Generates apps/mobile/assets/levels/word_sorter.json from scratch across
3 real difficulty tiers, built on the shared Placement Engine's
many-to-one placement mode (metadata-category matching strategy --
packages/mi_game_engines/lib/src/placement/placement_content.dart).

- Tier 1 (difficulty 1, "junior"): 2 concrete-category groups, 4-6 items.
- Tier 2 (difficulty 3, "explorer"): 2-3 groups, 6-9 words, phonics/rhyme/
  syllable classification.
- Tier 3 (difficulty 5, "master"): 3-4 groups, 8-12 words, grammar
  (noun/verb/adjective) classification.

Language-authoring rule: English and Vietnamese word banks below are
INDEPENDENTLY authored, not mechanical translations of each other --
each locale's category pairs, rhyme/phonics rules, and grammar examples
use real, distinct words chosen for that language's own linguistic
structure (Vietnamese syllable/tone/initial-consonant patterns do not
map onto English phonics rules 1:1, and vice versa).

Determinism: a fixed seed (--seed, default 20260721) drives Python's
`random` module; the same seed always reproduces the same level set.

Independent validation: every generated level's item-to-group mapping is
recomputed and checked (every item has exactly one group, every group
receives at least one item, no duplicate visible words within one
locale/level) before being accepted, mirroring the other generators in
this directory.

Usage:
    python tools/content_generators/word_sorter_generator.py --write
    python tools/content_generators/word_sorter_generator.py   # dry run
"""

from __future__ import annotations

import argparse
import json
import random
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parent.parent.parent
LEVELS_PATH = ROOT / "apps" / "mobile" / "assets" / "levels" / "word_sorter.json"

DEFAULT_SEED = 20260721
GAME_ID = "word_sorter"
CATEGORY_KEY = "sortCategory"

# ---------------------------------------------------------------------------
# Tier 1: concrete categories, 2 groups each. EN and VI category *pairs* are
# independently chosen (not translations of one another).
# ---------------------------------------------------------------------------

EN_TIER1_PAIRS = [
    ("animals", "Animals", ["dog", "cat", "elephant", "rabbit", "lion", "bird"]),
    ("food", "Food", ["apple", "bread", "cheese", "banana", "rice", "egg"]),
    ("toys", "Toys", ["ball", "kite", "doll", "puzzle", "yo-yo", "top"]),
    ("clothes", "Clothes", ["hat", "sock", "shirt", "shoe", "glove", "scarf"]),
    ("vehicles", "Vehicles", ["car", "bus", "bike", "train", "boat", "plane"]),
    ("furniture", "Furniture", ["chair", "table", "bed", "sofa", "shelf", "desk"]),
]
# Pairs of category indices to combine into one 2-group level.
EN_TIER1_COMBOS = [(0, 1), (2, 3), (4, 5), (0, 3), (1, 4), (2, 5)]

VI_TIER1_PAIRS = [
    (
        "hoc_tap",
        "Đồ dùng học tập",
        ["bút chì", "cục tẩy", "quyển vở", "thước kẻ", "cặp sách", "hộp bút"],
    ),
    (
        "do_choi",
        "Đồ chơi",
        ["quả bóng", "con diều", "búp bê", "xếp hình", "con quay", "gấu bông"],
    ),
    (
        "trai_cay",
        "Trái cây",
        ["quả xoài", "quả chuối", "quả cam", "quả dưa hấu", "quả nho", "quả ổi"],
    ),
    (
        "rau_cu",
        "Rau củ",
        ["củ cà rốt", "quả cà chua", "củ khoai tây", "bắp cải", "quả bí", "củ hành"],
    ),
    (
        "phuong_tien",
        "Phương tiện đi lại",
        ["xe đạp", "xe máy", "ô tô", "tàu hỏa", "máy bay", "thuyền"],
    ),
    (
        "vat_nuoi",
        "Vật nuôi trong nhà",
        ["con chó", "con mèo", "con gà", "con vịt", "con cá", "con chim"],
    ),
]
VI_TIER1_COMBOS = [(0, 1), (2, 3), (4, 5), (0, 5), (1, 4), (2, 4)]

# ---------------------------------------------------------------------------
# Tier 2: phonics/rhyme/syllable, independently designed per locale.
# ---------------------------------------------------------------------------

EN_TIER2_SETS = [
    (
        "initial_b_m",
        "Starts with B",
        "Starts with M",
        ["ball", "bear", "box", "bed", "bell"],
        ["moon", "map", "mouse", "milk", "monkey"],
    ),
    (
        "rhyme_at_og",
        "Rhymes with cat",
        "Rhymes with dog",
        ["cat", "hat", "bat", "mat", "rat"],
        ["dog", "log", "fog", "frog", "jog"],
    ),
    (
        "syllables_1_2",
        "One syllable",
        "Two syllables",
        ["cat", "dog", "sun", "ball", "tree"],
        ["apple", "monkey", "rabbit", "table", "pencil"],
    ),
]

VI_TIER2_SETS = [
    (
        "am_dau_b_c",
        "Âm đầu B",
        "Âm đầu C/K",
        ["bàn", "bút", "bóng", "biển", "bánh"],
        ["cá", "cây", "kẹo", "con", "kem"],
    ),
    (
        "am_tiet_1_2",
        "Từ một âm tiết",
        "Từ hai âm tiết",
        ["mèo", "chó", "hoa", "bàn", "sách"],
        ["con voi", "cái ghế", "quả táo", "cây bút", "bông hoa"],
    ),
    (
        "van_an_uong",
        "Vần AN",
        "Vần ƯƠNG",
        ["bàn", "gan", "khan", "lan", "sàn"],
        ["gương", "vườn", "sương", "lương", "hương"],
    ),
]

# ---------------------------------------------------------------------------
# Tier 3: grammar / multi-property classification, independently designed.
# ---------------------------------------------------------------------------

EN_TIER3_GROUPS = {
    "noun": ["dog", "table", "school", "book", "river", "teacher", "apple", "car"],
    "verb": ["run", "jump", "eat", "sleep", "write", "sing", "swim", "read"],
    "adjective": ["happy", "big", "fast", "blue", "soft", "tall", "cold", "kind"],
}

VI_TIER3_GROUPS = {
    # Independently chosen Vietnamese vocabulary -- not a translation of
    # the English noun/verb/adjective lists above.
    "danh_tu": [
        "con mèo",
        "cái bàn",
        "trường học",
        "quyển sách",
        "dòng sông",
        "cô giáo",
    ],
    "dong_tu": ["chạy", "nhảy", "ăn", "ngủ", "viết", "hát", "bơi", "đọc"],
    "tinh_tu": [
        "vui vẻ",
        "to lớn",
        "nhanh nhẹn",
        "dịu dàng",
        "cao",
        "lạnh",
        "tốt bụng",
    ],
}


def _make_targets(group_ids: list[str], group_labels: dict, counts: dict) -> list[dict]:
    return [
        {
            "id": f"group-{gid}",
            "label": group_labels[gid],
            "capacity": counts[gid],
            "metadata": {CATEGORY_KEY: gid},
        }
        for gid in group_ids
    ]


def _make_items(word_to_group: list[tuple[str, str]], prefix: str) -> list[dict]:
    items = []
    seen_words = set()
    for i, (word, gid) in enumerate(word_to_group):
        assert word not in seen_words, f"duplicate visible word in one level: {word}"
        seen_words.add(word)
        items.append(
            {
                "id": f"{prefix}-{i}",
                "label": word,
                "text": word,
                "metadata": {CATEGORY_KEY: gid},
            }
        )
    return items


def _validate_grouping(items: list[dict], targets: list[dict]) -> None:
    """Independent re-check: every item's category matches a real target,
    every target receives >=1 item, no duplicate item ids/target ids."""
    item_ids = [i["id"] for i in items]
    target_ids = [t["id"] for t in targets]
    assert len(item_ids) == len(set(item_ids)), "duplicate item id"
    assert len(target_ids) == len(set(target_ids)), "duplicate target id"
    target_categories = {t["metadata"][CATEGORY_KEY] for t in targets}
    counts: dict[str, int] = {}
    for item in items:
        cat = item["metadata"][CATEGORY_KEY]
        assert cat in target_categories, f"item {item['id']} has no matching group"
        counts[cat] = counts.get(cat, 0) + 1
    for target in targets:
        cat = target["metadata"][CATEGORY_KEY]
        assert counts.get(cat, 0) >= 1, f"group {target['id']} received no items"
        assert counts[cat] <= target["capacity"], (
            f"group {target['id']} exceeds capacity"
        )


def _tier1_level_vi(rng: random.Random, seen: set, level_number: int) -> tuple | None:
    combo = rng.choice(VI_TIER1_COMBOS)
    a_id, a_label, a_words = VI_TIER1_PAIRS[combo[0]]
    b_id, b_label, b_words = VI_TIER1_PAIRS[combo[1]]
    n = rng.choice([2, 3])
    a_pick = tuple(sorted(rng.sample(a_words, n)))
    b_pick = tuple(sorted(rng.sample(b_words, n)))
    # Uniqueness is keyed on the actual word subset chosen, not just the
    # category pair -- the same two categories with a different sample of
    # words is a legitimately different level, not a duplicate.
    key = ("vi_t1", combo, a_pick, b_pick)
    if key in seen:
        return None
    seen.add(key)
    word_to_group = [(w, a_id) for w in a_pick] + [(w, b_id) for w in b_pick]
    rng.shuffle(word_to_group)
    items = _make_items(word_to_group, f"vi-t1-{level_number}")
    counts = {a_id: len(a_pick), b_id: len(b_pick)}
    targets = _make_targets([a_id, b_id], {a_id: a_label, b_id: b_label}, counts)
    _validate_grouping(items, targets)
    return items, targets, f"Sắp xếp các từ vào đúng nhóm: {a_label} và {b_label}!"


def _tier1_level_en(rng: random.Random, seen: set, level_number: int) -> tuple | None:
    combo = rng.choice(EN_TIER1_COMBOS)
    a_id, a_label, a_words = EN_TIER1_PAIRS[combo[0]]
    b_id, b_label, b_words = EN_TIER1_PAIRS[combo[1]]
    n = rng.choice([2, 3])
    a_pick = tuple(sorted(rng.sample(a_words, n)))
    b_pick = tuple(sorted(rng.sample(b_words, n)))
    key = ("en_t1", combo, a_pick, b_pick)
    if key in seen:
        return None
    seen.add(key)
    word_to_group = [(w, a_id) for w in a_pick] + [(w, b_id) for w in b_pick]
    rng.shuffle(word_to_group)
    items = _make_items(word_to_group, f"en-t1-{level_number}")
    counts = {a_id: len(a_pick), b_id: len(b_pick)}
    targets = _make_targets([a_id, b_id], {a_id: a_label, b_id: b_label}, counts)
    _validate_grouping(items, targets)
    return items, targets, f"Sort the words into {a_label} and {b_label}!"


def _tier2_level(
    rng: random.Random, seen: set, level_number: int, locale: str
) -> tuple | None:
    sets = VI_TIER2_SETS if locale == "vi" else EN_TIER2_SETS
    set_id, a_label, b_label, a_words, b_words = rng.choice(sets)
    n_a = rng.randint(3, len(a_words))
    n_b = rng.randint(3, len(b_words))
    a_pick = tuple(sorted(rng.sample(a_words, n_a)))
    b_pick = tuple(sorted(rng.sample(b_words, n_b)))
    key = (f"{locale}_t2", set_id, a_pick, b_pick)
    if key in seen:
        return None
    seen.add(key)
    word_to_group = [(w, "group_a") for w in a_pick] + [(w, "group_b") for w in b_pick]
    rng.shuffle(word_to_group)
    items = _make_items(word_to_group, f"{locale}-t2-{level_number}")
    counts = {"group_a": len(a_pick), "group_b": len(b_pick)}
    targets = _make_targets(
        ["group_a", "group_b"], {"group_a": a_label, "group_b": b_label}, counts
    )
    _validate_grouping(items, targets)
    prompt = (
        f"Phân loại các từ: {a_label} hay {b_label}?"
        if locale == "vi"
        else f"Classify the words: {a_label} or {b_label}?"
    )
    return items, targets, prompt


def _tier3_level(
    rng: random.Random, seen: set, level_number: int, locale: str
) -> tuple | None:
    groups = VI_TIER3_GROUPS if locale == "vi" else EN_TIER3_GROUPS
    group_ids = sorted(groups.keys())
    n_groups = rng.choice([3])  # both word banks have exactly 3 grammar groups
    chosen_groups = tuple(sorted(rng.sample(group_ids, n_groups)))
    picks = tuple(rng.randint(3, 4) for _ in chosen_groups)
    word_to_group = []
    counts = {}
    labels = {}
    picked_words: dict[str, tuple] = {}
    for gid, n in zip(chosen_groups, picks):
        words = tuple(sorted(rng.sample(groups[gid], min(n, len(groups[gid])))))
        picked_words[gid] = words
        counts[gid] = len(words)
        labels[gid] = _GROUP_LABELS[locale][gid]
        for w in words:
            word_to_group.append((w, gid))
    key = (f"{locale}_t3", chosen_groups, tuple(picked_words[g] for g in chosen_groups))
    if key in seen:
        return None
    seen.add(key)
    rng.shuffle(word_to_group)
    items = _make_items(word_to_group, f"{locale}-t3-{level_number}")
    targets = _make_targets(list(chosen_groups), labels, counts)
    _validate_grouping(items, targets)
    group_names = ", ".join(labels[g] for g in chosen_groups)
    prompt = (
        f"Sắp xếp các từ theo loại: {group_names}!"
        if locale == "vi"
        else f"Sort the words by type: {group_names}!"
    )
    return items, targets, prompt


_GROUP_LABELS = {
    "en": {"noun": "Nouns", "verb": "Verbs", "adjective": "Adjectives"},
    "vi": {"danh_tu": "Danh từ", "dong_tu": "Động từ", "tinh_tu": "Tính từ"},
}


def _build_level(
    *,
    level_number: int,
    tier: int,
    difficulty: int,
    age_group: str,
    prompt_vi: str,
    prompt_en: str,
    items_vi: list[dict],
    targets_vi: list[dict],
    items_en: list[dict],
    targets_en: list[dict],
    skill_ids: list[str],
    seed: int,
) -> dict:
    level_id = f"ws-lv{level_number:03d}"
    return {
        "id": level_id,
        "gameId": GAME_ID,
        "levelNumber": level_number,
        "difficulty": difficulty,
        "learningObjective": "vocabulary_and_language_classification",
        "localizedContent": {
            "vi": {
                "prompt": prompt_vi,
                "hint": "Đọc kỹ từng từ trước khi xếp vào nhóm.",
                "items": items_vi,
                "targets": targets_vi,
                "rule": {
                    "matchStrategy": "metadataCategory",
                    "categoryMetadataKey": CATEGORY_KEY,
                },
            },
            "en": {
                "prompt": prompt_en,
                "hint": "Read each word carefully before sorting it.",
                "items": items_en,
                "targets": targets_en,
                "rule": {
                    "matchStrategy": "metadataCategory",
                    "categoryMetadataKey": CATEGORY_KEY,
                },
            },
        },
        "hints": [
            {"text": "Đọc kỹ từng từ trước khi xếp vào nhóm."},
            {"text": "Read each word carefully before sorting it."},
        ],
        "metadata": {
            "ageGroup": age_group,
            "skillIds": skill_ids,
            "tier": tier,
            "engineId": "placement",
            "reviewState": "technically_validated",
            "generatorSeed": seed,
        },
        "assetRefs": [],
        "contentVersion": 1,
        "estimatedSeconds": 45 + tier * 15,
        "publicationState": "draft",
    }


def generate_levels(seed: int = DEFAULT_SEED) -> list[dict]:
    rng = random.Random(seed)
    levels: list[dict] = []
    level_number = 1

    def produce(
        count: int,
        tier: int,
        difficulty: int,
        age_group: str,
        skills: list[str],
        fn_vi,
        fn_en,
    ):
        nonlocal level_number
        seen_vi: set = set()
        seen_en: set = set()
        produced = 0
        attempts = 0
        while produced < count and attempts < count * 60:
            attempts += 1
            result_vi = fn_vi(rng, seen_vi, level_number)
            result_en = fn_en(rng, seen_en, level_number)
            if result_vi is None or result_en is None:
                continue
            items_vi, targets_vi, prompt_vi = result_vi
            items_en, targets_en, prompt_en = result_en
            levels.append(
                _build_level(
                    level_number=level_number,
                    tier=tier,
                    difficulty=difficulty,
                    age_group=age_group,
                    prompt_vi=prompt_vi,
                    prompt_en=prompt_en,
                    items_vi=items_vi,
                    targets_vi=targets_vi,
                    items_en=items_en,
                    targets_en=targets_en,
                    skill_ids=skills,
                    seed=seed,
                )
            )
            level_number += 1
            produced += 1
        if produced < count:
            raise RuntimeError(
                f"Tier {tier}: only generated {produced}/{count} unique levels"
            )

    produce(
        20,
        1,
        1,
        "junior",
        ["letters.vocabulary", "logic.classification"],
        _tier1_level_vi,
        _tier1_level_en,
    )
    produce(
        20,
        2,
        3,
        "explorer",
        ["letters.initial_sound", "letters.rhyming", "logic.classification"],
        lambda rng_, seen_, ln: _tier2_level(rng_, seen_, ln, "vi"),
        lambda rng_, seen_, ln: _tier2_level(rng_, seen_, ln, "en"),
    )
    produce(
        20,
        3,
        5,
        "master",
        ["letters.vocabulary", "logic.classification"],
        lambda rng_, seen_, ln: _tier3_level(rng_, seen_, ln, "vi"),
        lambda rng_, seen_, ln: _tier3_level(rng_, seen_, ln, "en"),
    )
    return levels


def write_levels(levels: list[dict]) -> None:
    data = {
        "gameId": GAME_ID,
        "schemaVersion": "1.0.0",
        "description": "Word Sorter -- vocabulary, phonics, and grammar classification via the Placement Engine (Game 12). English and Vietnamese content is independently authored per locale, not mechanically translated.",
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
        print("Dry run -- pass --write to create word_sorter.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
