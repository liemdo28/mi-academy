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

LOCALIZED_OBJECTIVES: dict[str, dict[str, str]] = {
    "advanced category classification": {
        "en": "advanced category classification",
        "vi": "phân loại nhóm nâng cao",
    },
    "color classification": {
        "en": "color classification",
        "vi": "phân loại màu sắc",
    },
    "daily routine sequencing": {
        "en": "daily routine sequencing",
        "vi": "sắp xếp trình tự sinh hoạt hằng ngày",
    },
    "emotion recognition": {
        "en": "emotion recognition",
        "vi": "nhận biết cảm xúc",
    },
    "letter placement into words": {
        "en": "letter placement into words",
        "vi": "đặt chữ cái vào từ",
    },
    "life-science association": {
        "en": "life-science association",
        "vi": "ghép cặp khoa học sự sống",
    },
    "memory sequence replay": {
        "en": "memory sequence replay",
        "vi": "ghi nhớ và lặp lại trình tự",
    },
    "number sequencing": {
        "en": "number sequencing",
        "vi": "sắp xếp trình tự số",
    },
    "nutrition classification": {
        "en": "nutrition classification",
        "vi": "phân loại dinh dưỡng",
    },
    "odd-one-out reasoning": {
        "en": "odd-one-out reasoning",
        "vi": "suy luận vật khác nhóm",
    },
    "opposite word matching": {
        "en": "opposite word matching",
        "vi": "ghép từ trái nghĩa",
    },
    "part-whole reasoning": {
        "en": "part-whole reasoning",
        "vi": "suy luận bộ phận và toàn thể",
    },
    "story sequencing": {
        "en": "story sequencing",
        "vi": "sắp xếp trình tự câu chuyện",
    },
    "visual observation and matching": {
        "en": "visual observation and matching",
        "vi": "quan sát hình ảnh và ghép cặp",
    },
    "weather cause and effect": {
        "en": "weather cause and effect",
        "vi": "nguyên nhân và kết quả thời tiết",
    },
}


GAME_SPECS: dict[str, tuple[str, int, str, list[str], str, str]] = {
    "picture_detective": (
        "pd",
        60,
        "matching",
        ["science.observation", "logic.matching"],
        "Picture Detective",
        "Thám tử hình ảnh",
    ),
    "color_builder": (
        "cb",
        60,
        "placement",
        ["creative.color_recognition", "logic.spatial_reasoning"],
        "Color Builder",
        "Xây màu sắc",
    ),
    "animal_homes": (
        "ah",
        60,
        "matching",
        ["science.observation", "logic.matching"],
        "Animal Homes",
        "Nhà của động vật",
    ),
    "daily_routine": (
        "dr",
        60,
        "sequence",
        ["logic.pattern.basic", "science.cause_effect"],
        "Daily Routine",
        "Sinh hoạt hằng ngày",
    ),
    "healthy_foods": (
        "hf",
        60,
        "multi_select",
        ["science.observation", "logic.classification"],
        "Healthy Foods",
        "Thực phẩm lành mạnh",
    ),
    "letter_hunt": (
        "lh",
        75,
        "placement",
        ["letters.recognition.lowercase", "letters.spelling"],
        "Letter Hunt",
        "Săn tìm chữ cái",
    ),
    "number_train": (
        "nt",
        75,
        "sequence",
        ["math.number_recognition.1_20", "math.counting"],
        "Number Train",
        "Đoàn tàu số",
    ),
    "emotion_match": (
        "em",
        60,
        "matching",
        ["science.observation", "logic.matching"],
        "Emotion Match",
        "Ghép cảm xúc",
    ),
    "puzzle_parts": (
        "pp2",
        60,
        "placement",
        ["creative.shape_construction", "logic.spatial_reasoning"],
        "Puzzle Parts",
        "Mảnh ghép đồ vật",
    ),
    "odd_one_out": (
        "ooo",
        75,
        "multi_select",
        ["logic.odd_one_out", "logic.classification"],
        "Odd One Out",
        "Tìm vật khác nhóm",
    ),
    "opposites": (
        "op",
        60,
        "matching",
        ["letters.synonyms_antonyms", "logic.matching"],
        "Opposites",
        "Cặp từ trái nghĩa",
    ),
    "weather_today": (
        "wt",
        60,
        "matching",
        ["science.cause_effect", "logic.matching"],
        "Weather Today",
        "Thời tiết hôm nay",
    ),
    "memory_journey": (
        "mj",
        75,
        "sequence",
        ["logic.memory", "logic.pattern.basic"],
        "Memory Journey",
        "Hành trình ghi nhớ",
    ),
    "category_expert": (
        "ce",
        75,
        "multi_select",
        ["logic.classification", "letters.vocabulary"],
        "Category Expert",
        "Chuyên gia phân loại",
    ),
    "build_the_story": (
        "bts",
        75,
        "sequence",
        ["letters.storytelling", "creative.storytelling"],
        "Build the Story",
        "Xây câu chuyện",
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
            ("spoon", "spoon outline", "thìa", "nét thìa"),
            ("shoe", "shoe shadow", "giày", "bóng giày"),
            ("leaf", "leaf photo", "lá cây", "ảnh lá cây"),
            ("cup", "cup outline", "cốc", "nét cốc"),
        ],
        "animal_homes": [
            ("bird", "nest", "chim", "tổ chim"),
            ("fish", "pond", "cá", "ao"),
            ("bee", "hive", "ong", "tổ ong"),
            ("rabbit", "burrow", "thỏ", "hang thỏ"),
        ],
        "emotion_match": [
            ("happy face", "smile", "mặt vui", "nụ cười"),
            ("sad face", "tear", "mặt buồn", "nước mắt"),
            ("angry face", "frown", "mặt giận", "nhăn mặt"),
            ("surprised face", "wide eyes", "ngạc nhiên", "mắt tròn"),
        ],
        "opposites": [
            ("hot", "cold", "nóng", "lạnh"),
            ("big", "small", "to", "nhỏ"),
            ("fast", "slow", "nhanh", "chậm"),
            ("day", "night", "ngày", "đêm"),
        ],
        "weather_today": [
            ("rain", "umbrella", "mưa", "ô"),
            ("snow", "coat", "tuyết", "áo ấm"),
            ("sunny", "hat", "nắng", "mũ"),
            ("windy", "kite", "gió", "diều"),
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
                "Ghép mỗi vật với dấu hiệu của nó.",
            ),
            "animal_homes": (
                "Match each animal to its home.",
                "Ghép mỗi con vật với nhà của nó.",
            ),
            "emotion_match": (
                "Match each feeling to the clue.",
                "Ghép mỗi cảm xúc với dấu hiệu.",
            ),
            "opposites": (
                "Match each word to its opposite.",
                "Ghép mỗi từ với từ trái nghĩa.",
            ),
            "weather_today": (
                "Match the weather to what helps.",
                "Ghép thời tiết với vật phù hợp.",
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
    objective_text = LOCALIZED_OBJECTIVES[objective]
    return level_base(
        game_id,
        index,
        objective,
        {
            "en": {
                "prompt": en_prompt,
                "learningObjective": objective_text["en"],
                "pairs": pairs_en,
                "hint": "Start with the pair you know best.",
            },
            "vi": {
                "prompt": vi_prompt,
                "learningObjective": objective_text["vi"],
                "pairs": pairs_vi,
                "hint": "Bắt đầu với cặp con biết rõ nhất.",
            },
        },
        [f"asset-{game_id}-{index % 8}"],
    )


def placement_level(game_id: str, index: int) -> dict[str, Any]:
    banks = {
        "color_builder": (
            ("warm colors", "cool colors", "màu nóng", "màu mát"),
            [
                ("red", "left", "đỏ"),
                ("yellow", "left", "vàng"),
                ("orange", "left", "cam"),
                ("blue", "right", "xanh dương"),
                ("green", "right", "xanh lá"),
                ("purple", "right", "tím"),
            ],
            "color classification",
        ),
        "letter_hunt": (
            ("c-a-t", "d-o-g", "m-è-o", "c-h-ó"),
            [
                ("c", "left", "m"),
                ("a", "left", "è"),
                ("t", "left", "o"),
                ("d", "right", "c"),
                ("o", "right", "h"),
                ("g", "right", "ó"),
            ],
            "letter placement into words",
        ),
        "puzzle_parts": (
            ("bicycle", "house", "xe đạp", "ngôi nhà"),
            [
                ("wheel", "left", "bánh xe"),
                ("seat", "left", "yên xe"),
                ("handlebar", "left", "tay lái"),
                ("roof", "right", "mái nhà"),
                ("door", "right", "cửa"),
                ("window", "right", "cửa sổ"),
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
    objective_text = LOCALIZED_OBJECTIVES[objective]
    return level_base(
        game_id,
        index,
        objective,
        {
            "en": {
                "prompt": f"Place each card into {left_en} or {right_en}.",
                "learningObjective": objective_text["en"],
                "items": items_en,
                "targets": targets(items_en, left_en, right_en),
                **shared,
                "hint": "Tap a card, then tap its target.",
            },
            "vi": {
                "prompt": f"Đặt mỗi thẻ vào {left_vi} hoặc {right_vi}.",
                "learningObjective": objective_text["vi"],
                "items": items_vi,
                "targets": targets(items_vi, left_vi, right_vi),
                **shared,
                "hint": "Chạm vào thẻ, rồi chạm vào đích đến.",
            },
        },
        [f"asset-{game_id}-{index % 8}"],
    )


def sequence_level(game_id: str, index: int) -> dict[str, Any]:
    banks = {
        "daily_routine": (
            ["Wake up", "Brush teeth", "Eat breakfast", "Go to school", "Bedtime"],
            ["Thức dậy", "Đánh răng", "Ăn sáng", "Đến trường", "Đi ngủ"],
            "daily routine sequencing",
            "Put the day in order.",
            "Sắp xếp một ngày theo thứ tự.",
        ),
        "number_train": (
            [str(index + n) for n in range(5)],
            [str(index + n) for n in range(5)],
            "number sequencing",
            "Arrange the train numbers.",
            "Sắp xếp các số trên tàu.",
        ),
        "memory_journey": (
            ["Pack bag", "Ride bus", "Visit museum", "Draw picture", "Return home"],
            [
                "Xếp cặp sách",
                "Lên xe buýt",
                "Thăm bảo tàng",
                "Vẽ tranh",
                "Về nhà",
            ],
            "memory sequence replay",
            "Replay the journey in order.",
            "Lặp lại hành trình theo thứ tự.",
        ),
        "build_the_story": (
            ["Find seed", "Plant seed", "Water seed", "Watch sprout", "Share flower"],
            ["Tìm hạt", "Gieo hạt", "Tưới nước", "Thấy mầm", "Tặng hoa"],
            "story sequencing",
            "Build the story from first to last.",
            "Xây câu chuyện từ đầu đến cuối.",
        ),
    }
    en_steps, vi_steps, objective, en_prompt, vi_prompt = banks[game_id]
    objective_text = LOCALIZED_OBJECTIVES[objective]
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
                "learningObjective": objective_text["en"],
                "mode": "reorder",
                "correctOrder": order(en_steps),
                "rule": {"type": "fixed"},
                "hint": "Think about what comes first.",
            },
            "vi": {
                "prompt": vi_prompt,
                "learningObjective": objective_text["vi"],
                "mode": "reorder",
                "correctOrder": order(vi_steps),
                "rule": {"type": "fixed"},
                "hint": "Nghĩ xem việc nào đến trước.",
            },
        },
        [f"asset-{game_id}-{index % 8}"],
    )


def multi_select_level(game_id: str, index: int) -> dict[str, Any]:
    banks = {
        "healthy_foods": (
            "Select every healthy food.",
            "Chọn tất cả món ăn lành mạnh.",
            [
                ("apple", True, "táo"),
                ("carrot", True, "cà rốt"),
                ("water", True, "nước"),
                ("candy", False, "kẹo"),
                ("soda", False, "nước ngọt"),
                ("chips", False, "khoai chiên"),
            ],
            "nutrition classification",
        ),
        "odd_one_out": (
            "Select every item that does not belong.",
            "Chọn tất cả vật không cùng nhóm.",
            [
                ("cat", False, "mèo"),
                ("dog", False, "chó"),
                ("bird", False, "chim"),
                ("chair", True, "ghế"),
                ("spoon", True, "thìa"),
                ("shoe", True, "giày"),
            ],
            "odd-one-out reasoning",
        ),
        "category_expert": (
            "Select every school supply.",
            "Chọn tất cả đồ dùng học tập.",
            [
                ("pencil", True, "bút chì"),
                ("book", True, "sách"),
                ("ruler", True, "thước"),
                ("banana", False, "chuối"),
                ("shoe", False, "giày"),
                ("cup", False, "cốc"),
            ],
            "advanced category classification",
        ),
    }
    prompt_en, prompt_vi, rows, objective = banks[game_id]
    objective_text = LOCALIZED_OBJECTIVES[objective]
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
                "learningObjective": objective_text["en"],
                "options": [
                    item(f"o{i}", en, correct)
                    for i, (en, correct, _) in enumerate(rows)
                ],
                "configuration": cfg,
                "hint": f"There are {correct_count} correct choices.",
            },
            "vi": {
                "prompt": prompt_vi,
                "learningObjective": objective_text["vi"],
                "options": [
                    item(f"o{i}", vi, correct)
                    for i, (_, correct, vi) in enumerate(rows)
                ],
                "configuration": cfg,
                "hint": f"Có {correct_count} lựa chọn đúng.",
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
                            "learning_objective": level["localizedContent"][
                                locale
                            ]["learningObjective"],
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
