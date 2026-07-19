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


# --- Placement Engine games (Shape Builder, Word Sorter) ---


def solve_placement_level(level: dict) -> list[str]:
    """A Placement-based level is solvable per locale if:
    - every item id and target id is unique;
    - every item has at least one target it may legally occupy;
    - every target is reachable by at least one item;
    - total item count does not exceed total target capacity.

    Mirrors (a lightweight Python re-check of) the same rules
    packages/mi_game_engines' PlacementContent.fromJson enforces in Dart --
    this does not replace that engine-side validation, it gives the
    repository's Python content-validation pipeline (this script,
    schema validator, safety audit) its own independent coverage of the
    same two games, matching the pattern already used for the choice
    games' `solve_choice_level`.
    """
    errors = []
    content = level.get("localizedContent", {})
    for locale, loc in content.items():
        if not isinstance(loc, dict):
            continue
        items = loc.get("items", [])
        targets = loc.get("targets", [])
        if not items or not targets:
            errors.append(f"[{locale}] Missing items or targets")
            continue

        item_ids = [i.get("id") for i in items]
        target_ids = [t.get("id") for t in targets]
        if len(item_ids) != len(set(item_ids)):
            errors.append(f"[{locale}] Duplicate item id")
        if len(target_ids) != len(set(target_ids)):
            errors.append(f"[{locale}] Duplicate target id")

        rule = loc.get("rule") or {}
        by_category = rule.get("matchStrategy") == "metadataCategory"
        category_key = rule.get("categoryMetadataKey")

        def _accepts(item: dict, target: dict) -> bool:
            if by_category and category_key:
                return item.get("metadata", {}).get(
                    category_key
                ) is not None and item.get("metadata", {}).get(
                    category_key
                ) == target.get("metadata", {}).get(category_key)
            item_targets = item.get("acceptedTargetIds", [])
            target_items = target.get("acceptedItemIds", [])
            item_allows = not item_targets or target.get("id") in item_targets
            target_allows = not target_items or item.get("id") in target_items
            return item_allows and target_allows

        demand: dict = {}
        for item in items:
            acceptable = [t for t in targets if _accepts(item, t)]
            if not acceptable:
                errors.append(f"[{locale}] Item '{item.get('id')}' has no valid target")
            for t in acceptable:
                demand[t.get("id")] = demand.get(t.get("id"), 0) + 1

        for target in targets:
            if demand.get(target.get("id"), 0) == 0:
                errors.append(
                    f"[{locale}] Target '{target.get('id')}' has no valid item"
                )

        total_capacity = sum(t.get("capacity", 1) for t in targets)
        if len(items) > total_capacity:
            errors.append(
                f"[{locale}] Total items ({len(items)}) exceed total capacity ({total_capacity})"
            )
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
    validate_game_levels(
        all_errors=all_errors,
        game_id="shape_builder",
        file_name="shape_builder.json",
        solver=solve_placement_level,
        label="Shape Builder",
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
