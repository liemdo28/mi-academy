#!/usr/bin/env python3
"""Generate deterministic bilingual level packs and review checklist for Games 16-30."""

from __future__ import annotations

import csv
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
LEVEL_DIR = ROOT / "apps" / "mobile" / "assets" / "levels"
REVIEW_PATH = (
    ROOT / "docs" / "content-review" / "milestone-3-games-16-30-review-checklist.csv"
)


GAME_SPECS: dict[str, tuple[str, int, str, list[str], str, str]] = {
    "picture_detective": (
        "pd",
        60,
        "matching",
        ["science.observation", "logic.matching"],
        "Picture Detective",
        "Tham tu hinh anh",
    ),
    "color_builder": (
        "cb",
        60,
        "placement",
        ["creative.color_recognition", "logic.spatial_reasoning"],
        "Color Builder",
        "Xay mau sac",
    ),
    "animal_homes": (
        "ah",
        60,
        "matching",
        ["science.observation", "logic.matching"],
        "Animal Homes",
        "Nha cua dong vat",
    ),
    "daily_routine": (
        "dr",
        60,
        "sequence",
        ["logic.pattern.basic", "science.cause_effect"],
        "Daily Routine",
        "Sinh hoat hang ngay",
    ),
    "healthy_foods": (
        "hf",
        60,
        "multi_select",
        ["science.observation", "logic.classification"],
        "Healthy Foods",
        "Thuc pham lanh manh",
    ),
    "letter_hunt": (
        "lh",
        75,
        "placement",
        ["letters.recognition.lowercase", "letters.spelling"],
        "Letter Hunt",
        "San tim chu cai",
    ),
    "number_train": (
        "nt",
        75,
        "sequence",
        ["math.number_recognition.1_20", "math.counting"],
        "Number Train",
        "Doan tau so",
    ),
    "emotion_match": (
        "em",
        60,
        "matching",
        ["science.observation", "logic.matching"],
        "Emotion Match",
        "Ghep cam xuc",
    ),
    "puzzle_parts": (
        "pp2",
        60,
        "placement",
        ["creative.shape_construction", "logic.spatial_reasoning"],
        "Puzzle Parts",
        "Manh ghep do vat",
    ),
    "odd_one_out": (
        "ooo",
        75,
        "multi_select",
        ["logic.odd_one_out", "logic.classification"],
        "Odd One Out",
        "Tim vat khac nhom",
    ),
    "opposites": (
        "op",
        60,
        "matching",
        ["letters.synonyms_antonyms", "logic.matching"],
        "Opposites",
        "Cap tu trai nghia",
    ),
    "weather_today": (
        "wt",
        60,
        "matching",
        ["science.cause_effect", "logic.matching"],
        "Weather Today",
        "Thoi tiet hom nay",
    ),
    "memory_journey": (
        "mj",
        75,
        "sequence",
        ["logic.memory", "logic.pattern.basic"],
        "Memory Journey",
        "Hanh trinh ghi nho",
    ),
    "category_expert": (
        "ce",
        75,
        "multi_select",
        ["logic.classification", "letters.vocabulary"],
        "Category Expert",
        "Chuyen gia phan loai",
    ),
    "build_the_story": (
        "bts",
        75,
        "sequence",
        ["letters.storytelling", "creative.storytelling"],
        "Build the Story",
        "Xay cau chuyen",
    ),
}


def tier_for(index: int, total: int) -> tuple[int, str]:
    third = total // 3
    if index <= third:
        return 1, "junior"
    if index <= third * 2:
        return 3, "explorer"
    return 5, "master"


def level_base(
    game_id: str,
    index: int,
    objective: str,
    localized_content: dict[str, Any],
    asset_refs: list[str],
) -> dict[str, Any]:
    prefix, total, engine, skill_ids, _, _ = GAME_SPECS[game_id]
    difficulty, age = tier_for(index, total)
    return {
        "id": f"{prefix}-lv{index:03d}",
        "gameId": game_id,
        "levelNumber": index,
        "difficulty": difficulty,
        "learningObjective": objective,
        "localizedContent": localized_content,
        "hints": [{"text": localized_content["vi"].get("hint", "Thu tung buoc.")}],
        "metadata": {
            "ageGroup": age,
            "skillIds": skill_ids,
            "engine": engine,
            "generatedBy": "games_16_30_generator",
            "generatorSeed": 20260720,
            "reviewStatus": "pending_human_review",
        },
        "assetRefs": asset_refs,
        "contentVersion": 1,
        "estimatedSeconds": 60,
        "publicationState": "published",
    }


def item(option_id: str, label: str, correct: bool = False) -> dict[str, Any]:
    return {
        "id": option_id,
        "label": label,
        "text": label,
        "semanticLabel": label,
        "isCorrect": correct,
    }


def match_pair(
    index: int, left: str, right: str, left_type: str = "text"
) -> dict[str, Any]:
    return {
        "left": {
            "id": f"l{index}",
            "content": left,
            "type": left_type,
            "semanticLabel": left,
        },
        "right": {
            "id": f"r{index}",
            "content": right,
            "type": "text",
            "semanticLabel": right,
        },
    }


def matching_level(game_id: str, index: int) -> dict[str, Any]:
    banks = {
        "picture_detective": [
            ("spoon", "spoon outline", "thia", "net thia"),
            ("shoe", "shoe shadow", "giay", "bong giay"),
            ("leaf", "leaf photo", "la cay", "anh la cay"),
            ("cup", "cup outline", "coc", "net coc"),
        ],
        "animal_homes": [
            ("bird", "nest", "chim", "to chim"),
            ("fish", "pond", "ca", "ao"),
            ("bee", "hive", "ong", "to ong"),
            ("rabbit", "burrow", "tho", "hang tho"),
        ],
        "emotion_match": [
            ("happy face", "smile", "mat vui", "nu cuoi"),
            ("sad face", "tear", "mat buon", "nuoc mat"),
            ("angry face", "frown", "mat gian", "nhan mat"),
            ("surprised face", "wide eyes", "ngac nhien", "mat tron"),
        ],
        "opposites": [
            ("hot", "cold", "nong", "lanh"),
            ("big", "small", "to", "nho"),
            ("fast", "slow", "nhanh", "cham"),
            ("day", "night", "ngay", "dem"),
        ],
        "weather_today": [
            ("rain", "umbrella", "mua", "o"),
            ("snow", "coat", "tuyet", "ao am"),
            ("sunny", "hat", "nang", "mu"),
            ("windy", "kite", "gio", "dieu"),
        ],
    }
    rows = banks[game_id]
    rotated = rows[index % len(rows) :] + rows[: index % len(rows)]
    pairs_en = [
        match_pair(i, left, right) for i, (left, right, _, _) in enumerate(rotated[:4])
    ]
    pairs_vi = [
        match_pair(i, left, right) for i, (_, _, left, right) in enumerate(rotated[:4])
    ]
    prompts = {
        "picture_detective": (
            "Match each object to its clue.",
            "Ghep moi vat voi dau hieu cua no.",
        ),
        "animal_homes": (
            "Match each animal to its home.",
            "Ghep moi con vat voi nha cua no.",
        ),
        "emotion_match": (
            "Match each feeling to the clue.",
            "Ghep moi cam xuc voi dau hieu.",
        ),
        "opposites": (
            "Match each word to its opposite.",
            "Ghep moi tu voi tu trai nghia.",
        ),
        "weather_today": (
            "Match the weather to what helps.",
            "Ghep thoi tiet voi vat phu hop.",
        ),
    }
    objective = {
        "picture_detective": "visual observation and matching",
        "animal_homes": "life-science association",
        "emotion_match": "emotion recognition",
        "opposites": "opposite word matching",
        "weather_today": "weather cause and effect",
    }[game_id]
    en_prompt, vi_prompt = prompts[game_id]
    return level_base(
        game_id,
        index,
        objective,
        {
            "en": {
                "prompt": en_prompt,
                "pairs": pairs_en,
                "hint": "Start with the pair you know best.",
            },
            "vi": {
                "prompt": vi_prompt,
                "pairs": pairs_vi,
                "hint": "Bat dau voi cap con biet ro nhat.",
            },
        },
        [f"asset-{game_id}-{index % 8}"],
    )


def placement_level(game_id: str, index: int) -> dict[str, Any]:
    banks = {
        "color_builder": (
            ("warm colors", "cool colors", "mau nong", "mau mat"),
            [
                ("red", "left", "do"),
                ("yellow", "left", "vang"),
                ("orange", "left", "cam"),
                ("blue", "right", "xanh duong"),
                ("green", "right", "xanh la"),
                ("purple", "right", "tim"),
            ],
            "color classification",
        ),
        "letter_hunt": (
            ("c-a-t", "d-o-g", "m-e-o", "c-h-o"),
            [
                ("c", "left", "m"),
                ("a", "left", "e"),
                ("t", "left", "o"),
                ("d", "right", "c"),
                ("o", "right", "h"),
                ("g", "right", "o"),
            ],
            "letter placement into words",
        ),
        "puzzle_parts": (
            ("bicycle", "house", "xe dap", "ngoi nha"),
            [
                ("wheel", "left", "banh xe"),
                ("seat", "left", "yen xe"),
                ("handlebar", "left", "tay lai"),
                ("roof", "right", "mai nha"),
                ("door", "right", "cua"),
                ("window", "right", "cua so"),
            ],
            "part-whole reasoning",
        ),
    }
    (left_en, right_en, left_vi, right_vi), rows, objective = banks[game_id]
    items_en = [
        {
            "id": f"item{i}",
            "label": en,
            "text": en,
            "acceptedTargetIds": [target],
            "initialOrder": i,
        }
        for i, (en, target, _) in enumerate(rows)
    ]
    items_vi = [
        {
            "id": f"item{i}",
            "label": vi,
            "text": vi,
            "acceptedTargetIds": [target],
            "initialOrder": i,
        }
        for i, (_, target, vi) in enumerate(rows)
    ]

    def targets(
        items: list[dict[str, Any]], left: str, right: str
    ) -> list[dict[str, Any]]:
        return [
            {
                "id": "left",
                "label": left,
                "text": left,
                "capacity": 3,
                "acceptedItemIds": [
                    it["id"] for it in items if it["acceptedTargetIds"] == ["left"]
                ],
            },
            {
                "id": "right",
                "label": right,
                "text": right,
                "capacity": 3,
                "acceptedItemIds": [
                    it["id"] for it in items if it["acceptedTargetIds"] == ["right"]
                ],
            },
        ]

    shared = {
        "configuration": {"tapAccessibilityMode": True, "shuffleItems": True},
        "rule": {"matchStrategy": "explicitIds"},
    }
    return level_base(
        game_id,
        index,
        objective,
        {
            "en": {
                "prompt": f"Place each card into {left_en} or {right_en}.",
                "items": items_en,
                "targets": targets(items_en, left_en, right_en),
                **shared,
                "hint": "Tap a card, then tap its target.",
            },
            "vi": {
                "prompt": f"Dat moi the vao {left_vi} hoac {right_vi}.",
                "items": items_vi,
                "targets": targets(items_vi, left_vi, right_vi),
                **shared,
                "hint": "Cham vao the, roi cham vao dich den.",
            },
        },
        [f"asset-{game_id}-{index % 8}"],
    )


def sequence_level(game_id: str, index: int) -> dict[str, Any]:
    banks = {
        "daily_routine": (
            ["Wake up", "Brush teeth", "Eat breakfast", "Go to school", "Bedtime"],
            ["Thuc day", "Danh rang", "An sang", "Den truong", "Di ngu"],
            "daily routine sequencing",
            "Put the day in order.",
            "Sap xep mot ngay theo thu tu.",
        ),
        "number_train": (
            [str(index + n) for n in range(5)],
            [str(index + n) for n in range(5)],
            "number sequencing",
            "Arrange the train numbers.",
            "Sap xep cac so tren tau.",
        ),
        "memory_journey": (
            ["Pack bag", "Ride bus", "Visit museum", "Draw picture", "Return home"],
            ["Xep cap", "Len xe buyt", "Tham bao tang", "Ve tranh", "Ve nha"],
            "memory sequence replay",
            "Replay the journey in order.",
            "Lap lai hanh trinh theo thu tu.",
        ),
        "build_the_story": (
            ["Find seed", "Plant seed", "Water seed", "Watch sprout", "Share flower"],
            ["Tim hat", "Gieo hat", "Tuoi nuoc", "Thay mam", "Tang hoa"],
            "story sequencing",
            "Build the story from first to last.",
            "Xay cau chuyen tu dau den cuoi.",
        ),
    }
    en_steps, vi_steps, objective, en_prompt, vi_prompt = banks[game_id]
    difficulty, _ = tier_for(index, GAME_SPECS[game_id][1])
    count = 3 if difficulty == 1 else 4 if difficulty == 3 else 5

    def order(steps: list[str]) -> list[dict[str, Any]]:
        return [
            {"id": f"s{i}", "content": text, "type": "text"}
            for i, text in enumerate(steps[:count])
        ]

    return level_base(
        game_id,
        index,
        objective,
        {
            "en": {
                "prompt": en_prompt,
                "mode": "reorder",
                "correctOrder": order(en_steps),
                "rule": {"type": "fixed"},
                "hint": "Think about what comes first.",
            },
            "vi": {
                "prompt": vi_prompt,
                "mode": "reorder",
                "correctOrder": order(vi_steps),
                "rule": {"type": "fixed"},
                "hint": "Nghi xem viec nao den truoc.",
            },
        },
        [f"asset-{game_id}-{index % 8}"],
    )


def multi_select_level(game_id: str, index: int) -> dict[str, Any]:
    banks = {
        "healthy_foods": (
            "Select every healthy food.",
            "Chon tat ca mon an lanh manh.",
            [
                ("apple", True, "tao"),
                ("carrot", True, "ca rot"),
                ("water", True, "nuoc"),
                ("candy", False, "keo"),
                ("soda", False, "nuoc ngot"),
                ("chips", False, "khoai chien"),
            ],
            "nutrition classification",
        ),
        "odd_one_out": (
            "Select every item that does not belong.",
            "Chon tat ca vat khong cung nhom.",
            [
                ("cat", False, "meo"),
                ("dog", False, "cho"),
                ("bird", False, "chim"),
                ("chair", True, "ghe"),
                ("spoon", True, "thia"),
                ("shoe", True, "giay"),
            ],
            "odd-one-out reasoning",
        ),
        "category_expert": (
            "Select every school supply.",
            "Chon tat ca do dung hoc tap.",
            [
                ("pencil", True, "but chi"),
                ("book", True, "sach"),
                ("ruler", True, "thuoc"),
                ("banana", False, "chuoi"),
                ("shoe", False, "giay"),
                ("cup", False, "coc"),
            ],
            "advanced category classification",
        ),
    }
    prompt_en, prompt_vi, rows, objective = banks[game_id]
    correct_count = len([row for row in rows if row[1]])
    cfg = {
        "submissionMode": "explicitSubmit",
        "evaluationMode": "exactMatch",
        "minimumSelections": correct_count,
        "maximumSelections": correct_count,
        "shuffleSeed": 30000 + index,
        "maxAttempts": 3,
    }
    return level_base(
        game_id,
        index,
        objective,
        {
            "en": {
                "prompt": prompt_en,
                "options": [
                    item(f"o{i}", en, correct)
                    for i, (en, correct, _) in enumerate(rows)
                ],
                "configuration": cfg,
                "hint": f"There are {correct_count} correct choices.",
            },
            "vi": {
                "prompt": prompt_vi,
                "options": [
                    item(f"o{i}", vi, correct)
                    for i, (_, correct, vi) in enumerate(rows)
                ],
                "configuration": cfg,
                "hint": f"Co {correct_count} lua chon dung.",
            },
        },
        [f"asset-{game_id}-{index % 8}"],
    )


def make_level(game_id: str, index: int) -> dict[str, Any]:
    engine = GAME_SPECS[game_id][2]
    if engine == "matching":
        return matching_level(game_id, index)
    if engine == "placement":
        return placement_level(game_id, index)
    if engine == "sequence":
        return sequence_level(game_id, index)
    if engine == "multi_select":
        return multi_select_level(game_id, index)
    raise ValueError(engine)


def write_pack(game_id: str) -> list[dict[str, Any]]:
    total = GAME_SPECS[game_id][1]
    levels = [make_level(game_id, index) for index in range(1, total + 1)]
    path = LEVEL_DIR / f"{game_id}.json"
    path.write_text(
        json.dumps(
            {"schemaVersion": "1.0", "gameId": game_id, "levels": levels},
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    return levels


def write_review_checklist(levels_by_game: dict[str, list[dict[str, Any]]]) -> None:
    REVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    columns = [
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
    with REVIEW_PATH.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        writer.writeheader()
        for game_id in GAME_SPECS:
            for level in levels_by_game[game_id]:
                for locale in ("en", "vi"):
                    writer.writerow(
                        {
                            "level_id": level["id"],
                            "locale": locale,
                            "tier": level["metadata"]["ageGroup"],
                            "learning_objective": level["learningObjective"],
                            "correctness_review": "",
                            "language_review": "",
                            "age_review": "",
                            "cultural_review": "",
                            "accessibility_review": "",
                            "reviewer": "",
                            "review_date": "",
                            "status": "pending",
                            "notes": "",
                        }
                    )


def main() -> int:
    levels_by_game = {game_id: write_pack(game_id) for game_id in GAME_SPECS}
    write_review_checklist(levels_by_game)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
