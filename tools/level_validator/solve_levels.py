#!/usr/bin/env python3
"""MI Academy — Level Solver / Validator.

Verifies that every level is solvable and well-formed per game rules.
Runs in CI to guarantee no unsolvable level reaches production.

Usage:
    python tools/level_validator/solve_levels.py

Exit code 0 = all levels solvable, 1 = at least one unsolvable/invalid.
"""

import json
import sys
from collections import deque
from pathlib import Path
from typing import Any

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent


def load_json(path: Path) -> Any:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


# --- Memory Cards solver ---


def solve_memory_cards(level: dict) -> list[str]:
    """A Memory Cards level is solvable if every card has exactly one match."""
    errors = []
    content = level.get("localizedContent", {})
    for locale, loc in content.items():
        if not isinstance(loc, dict):
            continue
        cards = loc.get("cards", [])
        if not cards:
            continue
        # Group by pairId
        pairs: dict[object, list[object]] = {}
        for card in cards:
            pairs.setdefault(card.get("pairId"), []).append(card.get("id"))
        for pair_id, ids in pairs.items():
            if len(ids) != 2:
                errors.append(
                    f"[{locale}] Pair '{pair_id}' has {len(ids)} cards (must be 2) "
                    f"— level not solvable"
                )
        if len(cards) % 2 != 0:
            errors.append(f"[{locale}] Odd number of cards — level not solvable")
        break  # validate one locale's cards structure
    return errors


# --- Robot Commands solver (BFS reachability) ---


def solve_robot_map(map_data: dict) -> list[str]:
    """Robot map is solvable if goal is reachable from start via BFS."""
    errors = []
    grid = map_data.get("grid", map_data)
    width = grid.get("width", 0)
    height = grid.get("height", 0)
    obstacles = {(o["x"], o["y"]) for o in map_data.get("obstacles", [])}
    start = map_data.get("start", {"x": 0, "y": 0})
    goal = map_data.get("goal", {})

    sx, sy = start.get("x", 0), start.get("y", 0)
    gx, gy = goal.get("x", -1), goal.get("y", -1)

    if not (0 <= gx < width and 0 <= gy < height):
        return ["Goal out of bounds - not solvable"]

    # BFS from start to goal
    visited = set()
    queue = deque([(sx, sy)])
    visited.add((sx, sy))
    reachable = False

    while queue:
        x, y = queue.popleft()
        if (x, y) == (gx, gy):
            reachable = True
            break
        for dx, dy in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
            nx, ny = x + dx, y + dy
            if (
                0 <= nx < width
                and 0 <= ny < height
                and (nx, ny) not in obstacles
                and (nx, ny) not in visited
            ):
                visited.add((nx, ny))
                queue.append((nx, ny))

    if not reachable:
        errors.append(
            f"Goal ({gx},{gy}) unreachable from start ({sx},{sy}) - not solvable"
        )

    return errors


# --- Word Builder solver ---


def solve_word_builder(level: dict) -> list[str]:
    """A Word Builder level is solvable if provided letters build the target."""
    errors = []
    content = level.get("localizedContent", {})
    for locale, loc in content.items():
        if not isinstance(loc, dict):
            continue
        target = loc.get("targetWord")
        letters = loc.get("letters", [])
        if not isinstance(target, str) or not target:
            errors.append(f"[{locale}] Missing targetWord")
            continue
        if "".join(str(letter) for letter in letters) != target:
            errors.append(f"[{locale}] Letters do not build target '{target}'")
    return errors


# --- Sound Match solver ---


def solve_sound_match(level: dict) -> list[str]:
    """A Sound Match level is solvable if the answer is in unique options."""
    errors = []
    content = level.get("localizedContent", {})
    for locale, loc in content.items():
        if not isinstance(loc, dict):
            continue
        answer = loc.get("correctAnswer")
        options = [str(option) for option in loc.get("options", [])]
        if not answer:
            errors.append(f"[{locale}] Missing correctAnswer")
        if answer not in options:
            errors.append(f"[{locale}] Correct answer '{answer}' not in options")
        if len(options) != len(set(options)):
            errors.append(f"[{locale}] Duplicate options make answer ambiguous")
    return errors


# --- Multiple-choice math validator ---


def solve_choice_level(level: dict) -> list[str]:
    """A choice level is solvable if exactly one option is marked correct."""
    errors = []
    content = level.get("localizedContent", {})
    for locale, loc in content.items():
        if not isinstance(loc, dict):
            continue
        options = loc.get("options", [])
        correct_count = 0
        seen_text = set()
        for option in options:
            if not isinstance(option, dict):
                errors.append(f"[{locale}] Option must be an object")
                continue
            text = option.get("text")
            if text in seen_text:
                errors.append(f"[{locale}] Duplicate option text '{text}'")
            seen_text.add(text)
            if option.get("correct") is True:
                correct_count += 1
        if correct_count != 1:
            errors.append(
                f"[{locale}] Expected exactly 1 correct option, got {correct_count}"
            )
    return errors


def solve_multi_select(level: dict) -> list[str]:
    errors = []
    for locale, loc in level.get("localizedContent", {}).items():
        if not isinstance(loc, dict):
            continue
        correct = [
            opt for opt in loc.get("options", []) if opt.get("isCorrect") is True
        ]
        config = loc.get("configuration", {})
        minimum = config.get("minimumSelections", 1) if isinstance(config, dict) else 1
        maximum = (
            config.get("maximumSelections", len(loc.get("options", [])))
            if isinstance(config, dict)
            else len(loc.get("options", []))
        )
        if not correct:
            errors.append(f"[{locale}] No correct multi-select option")
        if not (minimum <= len(correct) <= maximum):
            errors.append(f"[{locale}] Correct answer count outside configured bounds")
    return errors


def solve_sequence(level: dict) -> list[str]:
    errors = []
    for locale, loc in level.get("localizedContent", {}).items():
        if not isinstance(loc, dict):
            continue
        order = loc.get("correctOrder", [])
        if len(order) < 2:
            errors.append(f"[{locale}] Sequence has fewer than 2 steps")
        ids = [item.get("id") for item in order if isinstance(item, dict)]
        if len(ids) != len(set(ids)):
            errors.append(f"[{locale}] Duplicate sequence item id")
        if loc.get("mode") == "missingItem":
            for index in loc.get("missingIndices", []):
                if not isinstance(index, int) or index < 0 or index >= len(order):
                    errors.append(f"[{locale}] Missing index out of range")
    return errors


def _duplicate_values(values: list[object]) -> set[object]:
    seen: set[object] = set()
    duplicates: set[object] = set()
    for value in values:
        if value in seen:
            duplicates.add(value)
        seen.add(value)
    return duplicates


def _placement_capacity(target: dict) -> int:
    capacity = target.get("capacity", 1)
    return capacity if isinstance(capacity, int) else 0


def _placement_accepts(item: dict, target: dict, rule: dict) -> bool:
    if rule.get("matchStrategy") == "metadataCategory":
        key = rule.get("categoryMetadataKey")
        item_metadata = item.get("metadata", {})
        target_metadata = target.get("metadata", {})
        if not isinstance(key, str) or not key:
            return False
        if not isinstance(item_metadata, dict) or not isinstance(target_metadata, dict):
            return False
        return item_metadata.get(key) is not None and item_metadata.get(
            key
        ) == target_metadata.get(key)

    accepted_targets = item.get("acceptedTargetIds", [])
    accepted_items = target.get("acceptedItemIds", [])
    item_allows = not accepted_targets or target.get("id") in accepted_targets
    target_allows = not accepted_items or item.get("id") in accepted_items
    return item_allows and target_allows


def solve_placement(level: dict) -> list[str]:
    errors = []
    for locale, loc in level.get("localizedContent", {}).items():
        if not isinstance(loc, dict):
            continue
        items = [item for item in loc.get("items", []) if isinstance(item, dict)]
        targets = [
            target for target in loc.get("targets", []) if isinstance(target, dict)
        ]
        rule = loc.get("rule", {})
        if not isinstance(rule, dict):
            rule = {}

        if not items:
            errors.append(f"[{locale}] Placement level has no items")
            continue
        if not targets:
            errors.append(f"[{locale}] Placement level has no targets")
            continue

        item_ids = [item.get("id") for item in items]
        target_ids = [target.get("id") for target in targets]
        for item_id in _duplicate_values(item_ids):
            errors.append(f"[{locale}] Duplicate item id {item_id}")
        for target_id in _duplicate_values(target_ids):
            errors.append(f"[{locale}] Duplicate target id {target_id}")

        known_items = set(item_ids)
        known_targets = set(target_ids)
        for item in items:
            for target_id in item.get("acceptedTargetIds", []):
                if target_id not in known_targets:
                    errors.append(
                        f"[{locale}] Item {item.get('id')} references unknown target {target_id}"
                    )
        for target in targets:
            capacity = _placement_capacity(target)
            if capacity < 1:
                errors.append(
                    f"[{locale}] Target {target.get('id')} has invalid capacity {target.get('capacity')}"
                )
            for item_id in target.get("acceptedItemIds", []):
                if item_id not in known_items:
                    errors.append(
                        f"[{locale}] Target {target.get('id')} references unknown item {item_id}"
                    )

        if rule.get("matchStrategy") == "metadataCategory" and not rule.get(
            "categoryMetadataKey"
        ):
            errors.append(
                f"[{locale}] metadataCategory placement rule requires categoryMetadataKey"
            )

        legal_targets_by_item: dict[object, list[dict]] = {}
        for item in items:
            legal = [
                target for target in targets if _placement_accepts(item, target, rule)
            ]
            legal_targets_by_item[item.get("id")] = legal
            if not legal:
                errors.append(f"[{locale}] Item {item.get('id')} has no valid target")

        for target in targets:
            if not any(_placement_accepts(item, target, rule) for item in items):
                errors.append(f"[{locale}] Target {target.get('id')} has no valid item")

        total_capacity = sum(_placement_capacity(target) for target in targets)
        if len(items) > total_capacity:
            errors.append(
                f"[{locale}] Total items ({len(items)}) exceed target capacity ({total_capacity})"
            )

        exclusive_demand: dict[object, int] = {}
        for item_id, legal_targets in legal_targets_by_item.items():
            if len(legal_targets) == 1:
                target_id = legal_targets[0].get("id")
                exclusive_demand[target_id] = exclusive_demand.get(target_id, 0) + 1
        for target in targets:
            demand = exclusive_demand.get(target.get("id"), 0)
            capacity = _placement_capacity(target)
            if demand > capacity:
                errors.append(
                    f"[{locale}] Impossible completion: {demand} item(s) require target "
                    f"{target.get('id')} but capacity is {capacity}"
                )
    return errors


def solve_matching(level: dict) -> list[str]:
    errors = []
    for locale, loc in level.get("localizedContent", {}).items():
        if not isinstance(loc, dict):
            continue
        pairs = loc.get("pairs", [])
        if len(pairs) < 2:
            errors.append(f"[{locale}] Matching level has fewer than 2 pairs")
    return errors


def validate_game_levels(
    *,
    all_errors: list[str],
    game_id: str,
    file_name: str,
    solver,
    label: str,
) -> None:
    path = PROJECT_ROOT / "apps" / "mobile" / "assets" / "levels" / file_name
    if not path.exists():
        all_errors.append(f"[{game_id}] Missing content file: {path}")
        return

    data = load_json(path)
    levels = data.get("levels", [])
    solvable = 0
    for level in levels:
        errs = solver(level)
        if errs:
            for e in errs:
                all_errors.append(f"[{game_id} {level.get('id')}] {e}")
        else:
            solvable += 1
    print(f"[OK] {label}: {solvable}/{len(levels)} levels solvable")


def main():
    all_errors = []

    validate_game_levels(
        all_errors=all_errors,
        game_id="word_builder",
        file_name="word_builder.json",
        solver=solve_word_builder,
        label="Word Builder",
    )
    validate_game_levels(
        all_errors=all_errors,
        game_id="sound_match",
        file_name="sound_match.json",
        solver=solve_sound_match,
        label="Sound Match",
    )
    validate_game_levels(
        all_errors=all_errors,
        game_id="math_race",
        file_name="math_race.json",
        solver=solve_choice_level,
        label="Math Race",
    )
    validate_game_levels(
        all_errors=all_errors,
        game_id="math_supermarket",
        file_name="math_supermarket.json",
        solver=solve_choice_level,
        label="Math Supermarket",
    )
    validate_game_levels(
        all_errors=all_errors,
        game_id="alphabet_explorer",
        file_name="alphabet_explorer.json",
        solver=solve_choice_level,
        label="Alphabet Explorer",
    )
    validate_game_levels(
        all_errors=all_errors,
        game_id="missing_letter",
        file_name="missing_letter.json",
        solver=solve_choice_level,
        label="Missing Letter",
    )
    validate_game_levels(
        all_errors=all_errors,
        game_id="memory_cards",
        file_name="memory_cards.json",
        solver=solve_memory_cards,
        label="Memory Cards",
    )
    for game_id, file_name, solver, label in [
        (
            "category_collector",
            "category_collector.json",
            solve_multi_select,
            "Category Collector",
        ),
        ("pattern_parade", "pattern_parade.json", solve_sequence, "Pattern Parade"),
        ("shape_builder", "shape_builder.json", solve_placement, "Shape Builder"),
        ("word_sorter", "word_sorter.json", solve_placement, "Word Sorter"),
        ("number_balance", "number_balance.json", solve_matching, "Number Balance"),
        (
            "logic_detective",
            "logic_detective.json",
            solve_multi_select,
            "Logic Detective",
        ),
        ("story_steps", "story_steps.json", solve_sequence, "Story Steps"),
    ]:
        validate_game_levels(
            all_errors=all_errors,
            game_id=game_id,
            file_name=file_name,
            solver=solver,
            label=label,
        )

    rc_path = (
        PROJECT_ROOT / "apps" / "mobile" / "assets" / "levels" / "robot_commands.json"
    )
    if rc_path.exists():
        data = load_json(rc_path)
        maps = data.get("maps", data.get("levels", []))
        solvable = 0
        for m in maps:
            errs = solve_robot_map(m.get("metadata", m))
            if errs:
                for e in errs:
                    all_errors.append(f"[robot_commands {m.get('id')}] {e}")
            else:
                solvable += 1
        print(f"[OK] Robot Commands: {solvable}/{len(maps)} maps solvable")
    else:
        all_errors.append(f"[robot_commands] Missing content file: {rc_path}")

    print()
    if all_errors:
        print(
            f"LEVEL VALIDATION FAILED - {len(all_errors)} unsolvable/invalid level(s):"
        )
        for err in all_errors:
            print(f"  [ERROR] {err}")
        sys.exit(1)
    else:
        print("ALL LEVELS SOLVABLE")
        sys.exit(0)


if __name__ == "__main__":
    main()
