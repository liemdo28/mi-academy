#!/usr/bin/env python3
"""Generate deterministic bilingual level packs for Games 9-15."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
LEVEL_DIR = ROOT / "apps" / "mobile" / "assets" / "levels"


GAME_SPECS = {
    "category_collector": ("cc", 60, "multi_select", ["logic.classification"]),
    "pattern_parade": ("pp", 60, "sequence", ["logic.pattern.recognition"]),
    "shape_builder": (
        "sb",
        45,
        "placement",
        ["math.shapes.basic", "logic.spatial_reasoning"],
    ),
    "word_sorter": (
        "ws",
        60,
        "placement",
        ["letters.vocabulary", "letters.initial_sound"],
    ),
    "number_balance": (
        "nb",
        60,
        "matching",
        ["math.addition.within_20", "math.subtraction.within_20"],
    ),
    "logic_detective": (
        "ld",
        45,
        "multi_select",
        ["logic.conditions", "logic.algorithms"],
    ),
    "story_steps": (
        "ss",
        45,
        "sequence",
        ["letters.reading_comprehension", "logic.pattern.basic"],
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
    prefix: str,
    index: int,
    total: int,
    objective: str,
    content: dict[str, Any],
) -> dict[str, Any]:
    difficulty, age = tier_for(index, total)
    return {
        "id": f"{prefix}-lv{index:03d}",
        "gameId": game_id,
        "levelNumber": index,
        "difficulty": difficulty,
        "learningObjective": objective,
        "localizedContent": content,
        "hints": [{"text": content["vi"].get("hint", "Thu tung buoc nhe.")}],
        "metadata": {
            "ageGroup": age,
            "skillIds": GAME_SPECS[game_id][3],
            "generatedBy": "games_9_15_generator",
            "generatorSeed": 20260719,
            "reviewStatus": "pending_human_review",
        },
        "assetRefs": [],
        "contentVersion": 1,
        "estimatedSeconds": 60,
        "publicationState": "published",
    }


def option(option_id: str, text: str, correct: bool) -> dict[str, Any]:
    return {
        "id": option_id,
        "label": text,
        "text": text,
        "semanticLabel": text,
        "isCorrect": correct,
    }


def category_level(index: int, total: int) -> dict[str, Any]:
    sets = [
        ("animals", "con vat", ["cat", "dog", "bird"], ["chair", "pencil", "shoe"]),
        ("fruits", "trai cay", ["apple", "banana", "mango"], ["bus", "book", "hat"]),
        ("even numbers", "so chan", ["2", "4", "8"], ["1", "5", "9"]),
        (
            "four-sided shapes",
            "hinh bon canh",
            ["square", "rectangle", "rhombus"],
            ["circle", "triangle", "oval"],
        ),
        (
            "school tools",
            "do dung hoc tap",
            ["pencil", "book", "ruler"],
            ["apple", "sock", "cup"],
        ),
        (
            "living things",
            "vat song",
            ["tree", "fish", "flower"],
            ["rock", "table", "ball"],
        ),
    ]
    label_en, label_vi, good, bad = sets[(index - 1) % len(sets)]
    opts_en = [option(f"c{i}", text, True) for i, text in enumerate(good, 1)] + [
        option(f"d{i}", text, False) for i, text in enumerate(bad, 1)
    ]
    opts_vi = [option(o["id"], _vi_word(o["text"]), o["isCorrect"]) for o in opts_en]
    cfg = {
        "submissionMode": "explicitSubmit",
        "evaluationMode": "exactMatch",
        "minimumSelections": len(good),
        "maximumSelections": len(good),
        "shuffleSeed": 9000 + index,
        "maxAttempts": 3,
    }
    return level_base(
        "category_collector",
        "cc",
        index,
        total,
        "classification",
        {
            "en": {
                "prompt": f"Select all {label_en}.",
                "options": opts_en,
                "configuration": cfg,
                "hint": f"There are {len(good)} correct choices.",
            },
            "vi": {
                "prompt": f"Chon tat ca {label_vi}.",
                "options": opts_vi,
                "configuration": cfg,
                "hint": f"Co {len(good)} lua chon dung.",
            },
        },
    )


def pattern_level(index: int, total: int) -> dict[str, Any]:
    difficulty, _ = tier_for(index, total)
    rule: dict[str, Any]
    if difficulty == 1:
        values = ["red", "blue", "red", "blue"]
        rule = {"type": "fixed"}
    elif difficulty == 3:
        start = index % 5 + 2
        values = [str(start + 2 * n) for n in range(5)]
        rule = {"type": "ascending", "step": 2}
    else:
        start = 20 + index
        values = [str(start - 3 * n) for n in range(5)]
        rule = {"type": "descending", "step": 3}
    order = [
        {
            "id": f"i{n}",
            "content": value,
            "type": "number" if value.isdigit() else "text",
        }
        for n, value in enumerate(values)
    ]
    content = {
        "mode": "missingItem",
        "correctOrder": order,
        "missingIndices": [len(order) - 1],
        "choices": [
            {"id": "x1", "content": "star", "type": "text"},
            {"id": "x2", "content": "11", "type": "number"},
        ],
        "rule": rule,
    }
    return level_base(
        "pattern_parade",
        "pp",
        index,
        total,
        "pattern recognition",
        {
            "en": {
                "prompt": "Choose the missing pattern item.",
                **content,
                "hint": "Look at how the sequence changes.",
            },
            "vi": {
                "prompt": "Chon muc con thieu trong mau hinh.",
                **content,
                "hint": "Quan sat cach day thay doi.",
            },
        },
    )


def placement_sort_level(
    game_id: str, prefix: str, index: int, total: int
) -> dict[str, Any]:
    if game_id == "word_sorter":
        left, right = (
            ("noun", "verb") if index % 2 else ("one syllable", "two syllables")
        )
        left_vi, right_vi = (
            ("danh tu", "dong tu") if index % 2 else ("mot am tiet", "hai am tiet")
        )
        words = [
            ("book", left),
            ("jump", right),
            ("tree", left),
            ("run", right),
            ("cup", left),
            ("read", right),
        ]
        objective = "language sorting"
    else:
        left, right = ("circle shapes", "corner shapes")
        left_vi, right_vi = ("hinh tron", "hinh co goc")
        words = [
            ("circle", left),
            ("oval", left),
            ("square", right),
            ("triangle", right),
            ("wheel", left),
            ("block", right),
        ]
        objective = "spatial reasoning"
    items = [
        {
            "id": f"item{i}",
            "label": word,
            "text": word,
            "acceptedTargetIds": ["left" if cat == left else "right"],
            "initialOrder": i,
        }
        for i, (word, cat) in enumerate(words)
    ]
    targets = [
        {
            "id": "left",
            "label": left,
            "text": left,
            "capacity": 3,
            "acceptedItemIds": [
                item["id"] for item in items if item["acceptedTargetIds"] == ["left"]
            ],
        },
        {
            "id": "right",
            "label": right,
            "text": right,
            "capacity": 3,
            "acceptedItemIds": [
                item["id"] for item in items if item["acceptedTargetIds"] == ["right"]
            ],
        },
    ]
    engine = {
        "items": items,
        "targets": targets,
        "configuration": {"tapAccessibilityMode": True, "shuffleItems": True},
        "rule": {"matchStrategy": "explicitIds"},
    }
    return level_base(
        game_id,
        prefix,
        index,
        total,
        objective,
        {
            "en": {
                "prompt": f"Sort each item into {left} or {right}.",
                **engine,
                "hint": "Choose one item, then choose its group.",
            },
            "vi": {
                "prompt": f"Sap xep vao {left_vi} hoac {right_vi}.",
                **engine,
                "hint": "Chon mot the roi chon nhom.",
            },
        },
    )


def number_balance_level(index: int, total: int) -> dict[str, Any]:
    base = 3 + (index % 12)
    pairs = []
    for n in range(4):
        value = base + n
        pairs.append(
            {
                "left": {
                    "id": f"l{n}",
                    "content": f"{value - 1} + 1",
                    "type": "text",
                    "semanticLabel": f"{value - 1} plus 1",
                },
                "right": {
                    "id": f"r{n}",
                    "content": str(value),
                    "type": "number",
                    "semanticLabel": str(value),
                },
            }
        )
    engine = {"pairs": pairs}
    return level_base(
        "number_balance",
        "nb",
        index,
        total,
        "number equivalence",
        {
            "en": {
                "prompt": "Match each expression to the equal value.",
                **engine,
                "hint": "Solve each expression first.",
            },
            "vi": {
                "prompt": "Ghep moi phep tinh voi gia tri bang nhau.",
                **engine,
                "hint": "Tinh tung phep tinh truoc.",
            },
        },
    )


def logic_detective_level(index: int, total: int) -> dict[str, Any]:
    modulus = 2 + (index % 3)
    values = list(range(1, 9))
    opts = [option(f"n{n}", str(n), n % modulus == 0) for n in values]
    cfg = {
        "submissionMode": "explicitSubmit",
        "evaluationMode": "exactMatch",
        "minimumSelections": len([n for n in values if n % modulus == 0]),
        "maximumSelections": len([n for n in values if n % modulus == 0]),
        "shuffleSeed": 14000 + index,
        "maxAttempts": 3,
    }
    return level_base(
        "logic_detective",
        "ld",
        index,
        total,
        "deductive reasoning",
        {
            "en": {
                "prompt": f"Select every number divisible by {modulus}.",
                "options": opts,
                "configuration": cfg,
                "hint": "Use the rule on every option.",
            },
            "vi": {
                "prompt": f"Chon moi so chia het cho {modulus}.",
                "options": opts,
                "configuration": cfg,
                "hint": "Dung quy tac cho tung lua chon.",
            },
        },
    )


def story_steps_level(index: int, total: int) -> dict[str, Any]:
    stories = [
        ["Wake up", "Brush teeth", "Eat breakfast", "Go to school", "Read a book"],
        ["Plant seed", "Water soil", "See sprout", "Watch leaves grow", "Pick flower"],
        ["Read problem", "Choose operation", "Solve", "Check answer", "Share result"],
    ]
    steps = stories[(index - 1) % len(stories)]
    difficulty, _ = tier_for(index, total)
    count = 3 if difficulty == 1 else 4 if difficulty == 3 else 5
    order = [
        {"id": f"s{n}", "content": step, "type": "text"}
        for n, step in enumerate(steps[:count])
    ]
    engine = {"mode": "reorder", "correctOrder": order, "rule": {"type": "fixed"}}
    return level_base(
        "story_steps",
        "ss",
        index,
        total,
        "narrative sequencing",
        {
            "en": {
                "prompt": "Put the steps in order.",
                **engine,
                "hint": "Think about what happens first.",
            },
            "vi": {
                "prompt": "Sap xep cac buoc theo thu tu.",
                **engine,
                "hint": "Nghi xem viec nao xay ra truoc.",
            },
        },
    )


def _vi_word(text: str) -> str:
    words = {
        "cat": "meo",
        "dog": "cho",
        "bird": "chim",
        "chair": "ghe",
        "pencil": "but chi",
        "shoe": "giay",
        "apple": "tao",
        "banana": "chuoi",
        "mango": "xoai",
        "bus": "xe buyt",
        "book": "sach",
        "hat": "mu",
        "square": "hinh vuong",
        "rectangle": "hinh chu nhat",
        "rhombus": "hinh thoi",
        "circle": "hinh tron",
        "triangle": "tam giac",
        "oval": "hinh bau duc",
        "ruler": "thuoc",
        "sock": "vo",
        "cup": "coc",
        "tree": "cay",
        "fish": "ca",
        "flower": "hoa",
        "rock": "da",
        "table": "ban",
        "ball": "bong",
    }
    return words.get(text, text)


def write_pack(game_id: str, levels: list[dict[str, Any]]) -> None:
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


def main() -> int:
    write_pack("category_collector", [category_level(i, 60) for i in range(1, 61)])
    write_pack("pattern_parade", [pattern_level(i, 60) for i in range(1, 61)])
    write_pack(
        "shape_builder",
        [placement_sort_level("shape_builder", "sb", i, 45) for i in range(1, 46)],
    )
    write_pack(
        "word_sorter",
        [placement_sort_level("word_sorter", "ws", i, 60) for i in range(1, 61)],
    )
    write_pack("number_balance", [number_balance_level(i, 60) for i in range(1, 61)])
    write_pack("logic_detective", [logic_detective_level(i, 45) for i in range(1, 46)])
    write_pack("story_steps", [story_steps_level(i, 45) for i in range(1, 46)])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
