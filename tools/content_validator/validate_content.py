#!/usr/bin/env python3
"""MI Academy — Content Validator Tool.

Validates all game level content against schemas, skill taxonomy,
and content rules. Runs in dev, CI, and admin publishing pipeline.

Usage:
    python tools/content_validator/validate_content.py [--all] [--game GAME]

Exit code 0 = all valid, 1 = errors found.
"""

import json
import sys
from pathlib import Path
from typing import Any

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
MOBILE_ASSETS = PROJECT_ROOT / "apps" / "mobile" / "assets"


def load_json(path: Path) -> Any:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def validate_level(data: dict, level_num: int) -> list[str]:
    """Validate a single level against required rules."""
    errors = []

    # Required fields
    for field in ["id", "levelNumber", "difficulty", "localizedContent"]:
        if field not in data:
            errors.append(f"Level {level_num}: Missing required field '{field}'")

    # ID uniqueness
    if not isinstance(data.get("id", ""), str) or not data.get("id", ""):
        errors.append(f"Level {level_num}: ID must not be empty")

    # Difficulty range
    difficulty = data.get("difficulty", 0)
    if not isinstance(difficulty, int) or not (1 <= difficulty <= 5):
        errors.append(f"Level {level_num}: difficulty must be 1-5, got {difficulty}")

    # Vietnamese localization required
    content = data.get("localizedContent", {})
    if isinstance(content, dict):
        if "vi" not in content:
            errors.append(f"Level {level_num}: Vietnamese (vi) localization required")
        # English should also be present
        if "en" not in content:
            errors.append(f"Level {level_num}: English (en) localization missing")
    else:
        errors.append(f"Level {level_num}: localizedContent must be a map")

    # Hints validation
    hints = data.get("hints", [])
    if isinstance(hints, list):
        for i, hint in enumerate(hints):
            if not isinstance(hint, dict):
                errors.append(f"Level {level_num}, hint {i}: must be a map")
            elif not hint.get("text", ""):
                errors.append(f"Level {level_num}, hint {i}: 'text' must not be empty")
    else:
        errors.append(f"Level {level_num}: hints must be a list")

    return errors


def validate_card_pairs(cards: list[dict], level_num: int) -> list[str]:
    """Validate Memory Cards level has correct pair structure."""
    errors = []
    pairs: dict[object, list[object]] = {}
    ids_seen: set[object] = set()

    for card in cards:
        card_id = card.get("id", "")
        pair_id = card.get("pairId", "")

        if not card_id:
            errors.append(f"Level {level_num}: Card has empty ID")
        elif card_id in ids_seen:
            errors.append(f"Level {level_num}: Duplicate card ID '{card_id}'")
        ids_seen.add(card_id)

        if not pair_id:
            errors.append(f"Level {level_num}: Card '{card_id}' has empty pairId")
        else:
            pairs.setdefault(pair_id, []).append(card_id)

    # Every pair must have exactly 2 cards
    for pair_id, card_ids in pairs.items():
        if len(card_ids) != 2:
            errors.append(
                f"Level {level_num}: Pair '{pair_id}' has {len(card_ids)} cards (expected 2)"
            )

    # Total cards must be even
    if len(cards) % 2 != 0:
        errors.append(f"Level {level_num}: Total cards ({len(cards)}) must be even")

    return errors


def validate_word_builder_content(content: dict, level_num: int) -> list[str]:
    """Validate Word Builder localized content."""
    errors = []
    for locale, loc_data in content.items():
        if not isinstance(loc_data, dict):
            continue
        target = loc_data.get("targetWord")
        letters = loc_data.get("letters")
        if not isinstance(target, str) or not target:
            errors.append(f"Level {level_num} ({locale}): targetWord must not be empty")
        if not isinstance(letters, list) or not letters:
            errors.append(
                f"Level {level_num} ({locale}): letters must be a non-empty list"
            )
        elif isinstance(target, str):
            built = "".join(str(letter) for letter in letters)
            if built != target:
                errors.append(
                    f"Level {level_num} ({locale}): letters build '{built}', expected '{target}'"
                )
    return errors


def validate_sound_match_content(content: dict, level_num: int) -> list[str]:
    """Validate Sound Match localized content."""
    errors = []
    for locale, loc_data in content.items():
        if not isinstance(loc_data, dict):
            continue
        answer = loc_data.get("correctAnswer")
        options = loc_data.get("options")
        audio_key = loc_data.get("audioKey")
        transcript = loc_data.get("audioTranscript")
        if not isinstance(answer, str) or not answer:
            errors.append(
                f"Level {level_num} ({locale}): correctAnswer must not be empty"
            )
        if not isinstance(options, list) or len(options) < 2:
            errors.append(
                f"Level {level_num} ({locale}): options must contain at least 2 items"
            )
        else:
            normalized = [str(option) for option in options]
            if len(set(normalized)) != len(normalized):
                errors.append(f"Level {level_num} ({locale}): options must be unique")
            if answer not in normalized:
                errors.append(
                    f"Level {level_num} ({locale}): correctAnswer '{answer}' is not in options"
                )
        if not isinstance(audio_key, str) or not audio_key:
            errors.append(f"Level {level_num} ({locale}): audioKey must not be empty")
        if not isinstance(transcript, str) or not transcript:
            errors.append(
                f"Level {level_num} ({locale}): audioTranscript must not be empty"
            )
    return errors


def validate_choice_options(content: dict, level_num: int) -> list[str]:
    """Validate multiple-choice math level content."""
    errors = []
    for locale, loc_data in content.items():
        if not isinstance(loc_data, dict):
            continue
        prompt = loc_data.get("prompt")
        options = loc_data.get("options")
        if not isinstance(prompt, str) or not prompt:
            errors.append(f"Level {level_num} ({locale}): prompt must not be empty")
        if not isinstance(options, list) or len(options) < 2:
            errors.append(
                f"Level {level_num} ({locale}): options must contain at least 2 items"
            )
            continue
        correct_count = 0
        option_texts = []
        for option_index, option in enumerate(options):
            if not isinstance(option, dict):
                errors.append(
                    f"Level {level_num} ({locale}) option {option_index}: must be a map"
                )
                continue
            text = option.get("text")
            if not isinstance(text, str) or not text:
                errors.append(
                    f"Level {level_num} ({locale}) option {option_index}: text must not be empty"
                )
            else:
                option_texts.append(text)
            if option.get("correct") is True:
                correct_count += 1
        if len(option_texts) != len(set(option_texts)):
            errors.append(
                f"Level {level_num} ({locale}): option text values must be unique"
            )
        if correct_count != 1:
            errors.append(
                f"Level {level_num} ({locale}): expected exactly 1 correct option, got {correct_count}"
            )
    return errors


def validate_multi_select_content(content: dict, level_num: int) -> list[str]:
    """Validate Multi-select Engine localized content."""
    errors = []
    for locale, loc_data in content.items():
        if not isinstance(loc_data, dict):
            continue
        options = loc_data.get("options")
        config = loc_data.get("configuration", {})
        if not isinstance(loc_data.get("prompt"), str) or not loc_data.get("prompt"):
            errors.append(f"Level {level_num} ({locale}): prompt must not be empty")
        if not isinstance(options, list) or len(options) < 2:
            errors.append(
                f"Level {level_num} ({locale}): multi-select options must contain at least 2 items"
            )
            continue
        ids = []
        correct = 0
        for option_index, opt in enumerate(options):
            if not isinstance(opt, dict):
                errors.append(
                    f"Level {level_num} ({locale}) option {option_index}: must be a map"
                )
                continue
            option_id = opt.get("id")
            label = opt.get("label")
            if not isinstance(option_id, str) or not option_id:
                errors.append(
                    f"Level {level_num} ({locale}) option {option_index}: id required"
                )
            else:
                ids.append(option_id)
            if not isinstance(label, str) or not label:
                errors.append(
                    f"Level {level_num} ({locale}) option {option_index}: label required"
                )
            if opt.get("isCorrect") is True:
                correct += 1
        if len(ids) != len(set(ids)):
            errors.append(f"Level {level_num} ({locale}): duplicate option IDs")
        if correct < 1:
            errors.append(
                f"Level {level_num} ({locale}): at least one option must be correct"
            )
        if isinstance(config, dict):
            minimum = config.get("minimumSelections", 1)
            maximum = config.get("maximumSelections", len(options))
            if minimum > correct or maximum < correct:
                errors.append(
                    f"Level {level_num} ({locale}): selection bounds exclude the correct answer set"
                )
    return errors


def validate_sequence_content(content: dict, level_num: int) -> list[str]:
    """Validate Sequence Engine localized content."""
    errors = []
    for locale, loc_data in content.items():
        if not isinstance(loc_data, dict):
            continue
        order = loc_data.get("correctOrder")
        rule = loc_data.get("rule")
        mode = loc_data.get("mode")
        if mode not in {"reorder", "missingItem"}:
            errors.append(f"Level {level_num} ({locale}): invalid sequence mode")
        if not isinstance(order, list) or len(order) < 2:
            errors.append(
                f"Level {level_num} ({locale}): correctOrder must contain at least 2 items"
            )
            continue
        ids = [item.get("id") for item in order if isinstance(item, dict)]
        if len(ids) != len(set(ids)):
            errors.append(f"Level {level_num} ({locale}): duplicate sequence item IDs")
        if not isinstance(rule, dict) or not rule.get("type"):
            errors.append(f"Level {level_num} ({locale}): sequence rule required")
        if mode == "missingItem" and not loc_data.get("missingIndices"):
            errors.append(
                f"Level {level_num} ({locale}): missingItem mode requires missingIndices"
            )
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


def validate_placement_content(content: dict, level_num: int) -> list[str]:
    """Validate Placement Engine localized content."""
    errors = []
    for locale, loc_data in content.items():
        if not isinstance(loc_data, dict):
            continue
        items = loc_data.get("items")
        targets = loc_data.get("targets")
        if not isinstance(items, list) or not items:
            errors.append(f"Level {level_num} ({locale}): placement items required")
            continue
        if not isinstance(targets, list) or not targets:
            errors.append(f"Level {level_num} ({locale}): placement targets required")
            continue
        normalized_items = [item for item in items if isinstance(item, dict)]
        normalized_targets = [target for target in targets if isinstance(target, dict)]
        rule = loc_data.get("rule", {})
        if not isinstance(rule, dict):
            rule = {}

        item_ids = [item.get("id") for item in normalized_items]
        target_ids = [target.get("id") for target in normalized_targets]
        for item_id in _duplicate_values(item_ids):
            errors.append(f"Level {level_num} ({locale}): duplicate item ID {item_id}")
        for target_id in _duplicate_values(target_ids):
            errors.append(
                f"Level {level_num} ({locale}): duplicate target ID {target_id}"
            )

        known_items = set(item_ids)
        known_targets = set(target_ids)
        for item in items:
            if not isinstance(item, dict):
                errors.append(f"Level {level_num} ({locale}): item must be a map")
                continue
            item_id = item.get("id")
            accepted = item.get("acceptedTargetIds", [])
            if not isinstance(accepted, list):
                errors.append(
                    f"Level {level_num} ({locale}): item {item_id} acceptedTargetIds must be a list"
                )
                continue
            for target_id in accepted:
                if target_id not in known_targets:
                    errors.append(
                        f"Level {level_num} ({locale}): item {item_id} references unknown target {target_id}"
                    )

        for target in normalized_targets:
            capacity = _placement_capacity(target)
            if capacity < 1:
                errors.append(
                    f"Level {level_num} ({locale}): target {target.get('id')} has invalid capacity"
                )
            accepted_items = target.get("acceptedItemIds", [])
            if not isinstance(accepted_items, list):
                errors.append(
                    f"Level {level_num} ({locale}): target {target.get('id')} acceptedItemIds must be a list"
                )
                continue
            for item_id in accepted_items:
                if item_id not in known_items:
                    errors.append(
                        f"Level {level_num} ({locale}): target {target.get('id')} references unknown item {item_id}"
                    )

        if rule.get("matchStrategy") == "metadataCategory" and not rule.get(
            "categoryMetadataKey"
        ):
            errors.append(
                f"Level {level_num} ({locale}): metadataCategory rule requires categoryMetadataKey"
            )

        legal_targets_by_item: dict[object, list[dict]] = {}
        for item in normalized_items:
            legal = [
                target
                for target in normalized_targets
                if _placement_accepts(item, target, rule)
            ]
            legal_targets_by_item[item.get("id")] = legal
            if not legal:
                errors.append(
                    f"Level {level_num} ({locale}): item {item.get('id')} has no valid target"
                )

        for target in normalized_targets:
            if not any(
                _placement_accepts(item, target, rule) for item in normalized_items
            ):
                errors.append(
                    f"Level {level_num} ({locale}): target {target.get('id')} has no valid item"
                )

        total_capacity = sum(
            _placement_capacity(target) for target in normalized_targets
        )
        if len(normalized_items) > total_capacity:
            errors.append(
                f"Level {level_num} ({locale}): total item count exceeds target capacity"
            )

        exclusive_demand: dict[object, int] = {}
        for item_id, legal_targets in legal_targets_by_item.items():
            if len(legal_targets) == 1:
                target_id = legal_targets[0].get("id")
                exclusive_demand[target_id] = exclusive_demand.get(target_id, 0) + 1
        for target in normalized_targets:
            demand = exclusive_demand.get(target.get("id"), 0)
            capacity = _placement_capacity(target)
            if demand > capacity:
                errors.append(
                    f"Level {level_num} ({locale}): {demand} item(s) require target "
                    f"{target.get('id')} but capacity is {capacity}"
                )
    return errors


def validate_matching_content(content: dict, level_num: int) -> list[str]:
    """Validate Matching Engine localized content."""
    errors = []
    for locale, loc_data in content.items():
        if not isinstance(loc_data, dict):
            continue
        pairs = loc_data.get("pairs")
        if not isinstance(pairs, list) or len(pairs) < 2:
            errors.append(
                f"Level {level_num} ({locale}): matching pairs must contain at least 2 pairs"
            )
            continue
        left_ids = []
        right_ids = []
        for pair in pairs:
            if not isinstance(pair, dict):
                errors.append(f"Level {level_num} ({locale}): pair must be a map")
                continue
            left = pair.get("left", {})
            right = pair.get("right", {})
            left_ids.append(left.get("id"))
            right_ids.append(right.get("id"))
        if len(left_ids) != len(set(left_ids)):
            errors.append(f"Level {level_num} ({locale}): duplicate left IDs")
        if len(right_ids) != len(set(right_ids)):
            errors.append(f"Level {level_num} ({locale}): duplicate right IDs")
    return errors


def validate_robot_commands_level(level: dict, level_num: int) -> list[str]:
    """Validate Robot Commands grid and command content."""
    errors = []
    metadata = level.get("metadata", {})
    if not isinstance(metadata, dict):
        return [f"Level {level_num}: metadata must be a map"]

    grid = metadata.get("grid", {})
    start = metadata.get("start", {})
    goal = metadata.get("goal", {})
    if (
        not isinstance(grid, dict)
        or not isinstance(start, dict)
        or not isinstance(goal, dict)
    ):
        errors.append(f"Level {level_num}: grid, start, and goal metadata are required")
        return errors

    width = grid.get("width", 0)
    height = grid.get("height", 0)
    if (
        not isinstance(width, int)
        or not isinstance(height, int)
        or width < 1
        or height < 1
    ):
        errors.append(f"Level {level_num}: grid width/height must be positive integers")
        return errors

    def check_point(name: str, point: dict) -> None:
        x = point.get("x", -1)
        y = point.get("y", -1)
        if (
            not isinstance(x, int)
            or not isinstance(y, int)
            or not (0 <= x < width and 0 <= y < height)
        ):
            errors.append(f"Level {level_num}: {name} ({x},{y}) is out of bounds")

    check_point("start", start)
    check_point("goal", goal)

    obstacles: set[tuple[int, int]] = set()
    collectibles: set[tuple[int, int]] = set()
    for field in ["obstacles", "collectibles"]:
        values = metadata.get(field, [])
        if not isinstance(values, list):
            errors.append(f"Level {level_num}: {field} must be a list")
            continue
        for index, point in enumerate(values):
            if not isinstance(point, dict):
                errors.append(f"Level {level_num}: {field}[{index}] must be a map")
            else:
                check_point(f"{field}[{index}]", point)
                px, py = point.get("x"), point.get("y")
                if isinstance(px, int) and isinstance(py, int):
                    target = obstacles if field == "obstacles" else collectibles
                    target.add((px, py))

    valid_available_commands = {
        "MOVE_FORWARD",
        "TURN_LEFT",
        "TURN_RIGHT",
        "COLLECT",
        "REPEAT",
        "IF_PATH_AHEAD",
    }
    valid_required_commands = valid_available_commands | {"START"}
    content = level.get("localizedContent", {})
    if isinstance(content, dict):
        for locale, loc_data in content.items():
            if not isinstance(loc_data, dict):
                continue
            commands = loc_data.get("availableCommands")
            if not isinstance(commands, list) or not commands:
                errors.append(
                    f"Level {level_num} ({locale}): availableCommands required"
                )
            else:
                for command in commands:
                    if command not in valid_available_commands:
                        errors.append(
                            f"Level {level_num} ({locale}): unsupported command '{command}'"
                        )
            required = loc_data.get("requiredCommands")
            if not isinstance(required, list) or len(required) < 2:
                errors.append(
                    f"Level {level_num} ({locale}): requiredCommands must contain START plus commands"
                )
            else:
                if required[0] != "START":
                    errors.append(
                        f"Level {level_num} ({locale}): requiredCommands must start with START"
                    )
                for command in required:
                    if command not in valid_required_commands:
                        errors.append(
                            f"Level {level_num} ({locale}): unsupported required command '{command}'"
                        )
                if not errors:
                    errors.extend(
                        validate_robot_required_path(
                            required,
                            width=width,
                            height=height,
                            start=start,
                            goal=goal,
                            obstacles=obstacles,
                            collectibles=collectibles,
                            level_num=level_num,
                            locale=locale,
                        )
                    )
    return errors


def validate_robot_required_path(
    commands: list,
    *,
    width: int,
    height: int,
    start: dict,
    goal: dict,
    obstacles: set[tuple[int, int]],
    collectibles: set[tuple[int, int]],
    level_num: int,
    locale: str,
) -> list[str]:
    """Simulate the authored solution path for Robot Commands."""
    errors = []
    directions = ["north", "east", "south", "west"]
    deltas = {
        "north": (0, -1),
        "east": (1, 0),
        "south": (0, 1),
        "west": (-1, 0),
    }
    x = start.get("x", 0)
    y = start.get("y", 0)
    facing = start.get("facing", "east")
    collected = set()

    for command in commands[1:]:
        if command == "TURN_LEFT":
            facing = directions[(directions.index(facing) - 1) % len(directions)]
        elif command == "TURN_RIGHT":
            facing = directions[(directions.index(facing) + 1) % len(directions)]
        elif command == "MOVE_FORWARD":
            dx, dy = deltas[facing]
            nx, ny = x + dx, y + dy
            if not (0 <= nx < width and 0 <= ny < height):
                errors.append(
                    f"Level {level_num} ({locale}): requiredCommands moves out of bounds to ({nx},{ny})"
                )
                return errors
            if (nx, ny) in obstacles:
                errors.append(
                    f"Level {level_num} ({locale}): requiredCommands moves into obstacle at ({nx},{ny})"
                )
                return errors
            x, y = nx, ny
        elif command == "COLLECT":
            if (x, y) in collectibles:
                collected.add((x, y))

    if (x, y) != (goal.get("x"), goal.get("y")):
        errors.append(
            f"Level {level_num} ({locale}): requiredCommands ends at ({x},{y}), expected goal ({goal.get('x')},{goal.get('y')})"
        )
    missing = collectibles - collected
    if missing:
        errors.append(
            f"Level {level_num} ({locale}): requiredCommands misses collectibles {sorted(missing)}"
        )
    return errors


def validate_robot_map(map_data: dict, map_num: int) -> list[str]:
    """Validate a Robot Commands map."""
    errors = []

    for field in ["width", "height", "goal"]:
        if field not in map_data:
            errors.append(f"Map {map_num}: Missing '{field}'")

    # Goal must be within bounds
    width = map_data.get("width", 0)
    height = map_data.get("height", 0)
    goal = map_data.get("goal", {})
    if isinstance(goal, dict):
        gx, gy = goal.get("x", -1), goal.get("y", -1)
        if not (0 <= gx < width and 0 <= gy < height):
            errors.append(f"Map {map_num}: Goal ({gx},{gy}) is out of bounds")

    return errors


def validate_game_file(path: Path, game_id: str) -> list[str]:
    """Validate a game content JSON file."""
    errors = []
    try:
        data = load_json(path)
    except json.JSONDecodeError as e:
        return [f"{path.name}: Invalid JSON — {e}"]

    levels = data.get("levels", [])
    if not levels:
        errors.append(f"{path.name}: No levels found")
        return errors
    if game_id == "robot_commands" and len(levels) < 10:
        errors.append(f"{path.name}: Robot Commands must contain at least 10 levels")
    minimums = {
        "category_collector": 60,
        "pattern_parade": 60,
        "shape_builder": 45,
        "word_sorter": 60,
        "number_balance": 60,
        "logic_detective": 45,
        "story_steps": 45,
    }
    if game_id in minimums and len(levels) < minimums[game_id]:
        errors.append(
            f"{path.name}: {game_id} must contain at least {minimums[game_id]} levels"
        )
    if game_id in minimums:
        tiers = {level.get("difficulty") for level in levels}
        if not ({1, 3, 5} <= tiers):
            errors.append(f"{path.name}: {game_id} must contain three difficulty tiers")

    level_ids = set()
    for i, level in enumerate(levels):
        errors.extend(validate_level(level, i + 1))

        # Level ID uniqueness within file
        lid = level.get("id", "")
        if lid in level_ids:
            errors.append(f"Duplicate level ID: '{lid}'")
        level_ids.add(lid)

        # Game-specific validation
        if game_id == "memory_cards":
            content = level.get("localizedContent", {})
            for locale, loc_data in content.items():
                if isinstance(loc_data, dict):
                    cards = loc_data.get("cards", [])
                    if cards:
                        errors.extend(
                            validate_card_pairs(cards, level.get("levelNumber", i + 1))
                        )
                        break  # Only need to validate cards once per level
        elif game_id == "word_builder":
            errors.extend(
                validate_word_builder_content(
                    level.get("localizedContent", {}),
                    level.get("levelNumber", i + 1),
                )
            )
        elif game_id == "sound_match":
            errors.extend(
                validate_sound_match_content(
                    level.get("localizedContent", {}),
                    level.get("levelNumber", i + 1),
                )
            )
        elif game_id in {"math_race", "math_supermarket"}:
            errors.extend(
                validate_choice_options(
                    level.get("localizedContent", {}),
                    level.get("levelNumber", i + 1),
                )
            )
        elif game_id == "robot_commands":
            errors.extend(
                validate_robot_commands_level(
                    level,
                    level.get("levelNumber", i + 1),
                )
            )
        elif game_id in {"category_collector", "logic_detective"}:
            errors.extend(
                validate_multi_select_content(
                    level.get("localizedContent", {}),
                    level.get("levelNumber", i + 1),
                )
            )
        elif game_id in {"pattern_parade", "story_steps"}:
            errors.extend(
                validate_sequence_content(
                    level.get("localizedContent", {}),
                    level.get("levelNumber", i + 1),
                )
            )
        elif game_id in {"shape_builder", "word_sorter"}:
            errors.extend(
                validate_placement_content(
                    level.get("localizedContent", {}),
                    level.get("levelNumber", i + 1),
                )
            )
        elif game_id == "number_balance":
            errors.extend(
                validate_matching_content(
                    level.get("localizedContent", {}),
                    level.get("levelNumber", i + 1),
                )
            )

    return errors


def collect_audio_keys(path: Path) -> set[str]:
    """Collect audioKey values from a level content file."""
    data = load_json(path)
    keys = set()
    for level in data.get("levels", []):
        content = level.get("localizedContent", {})
        if not isinstance(content, dict):
            continue
        for loc_data in content.values():
            if isinstance(loc_data, dict) and loc_data.get("audioKey"):
                keys.add(loc_data["audioKey"])
    return keys


def validate_audio_placeholders(required_keys: set[str]) -> list[str]:
    """Ensure every required audio key has a bundled placeholder asset."""
    errors = []
    audio_dir = MOBILE_ASSETS / "audio"
    manifest_path = audio_dir / "audio_manifest.json"
    if not manifest_path.exists():
        return [f"Missing audio manifest: {manifest_path}"]

    try:
        manifest = load_json(manifest_path)
    except json.JSONDecodeError as e:
        return [f"audio_manifest.json: Invalid JSON - {e}"]

    manifest_keys = {
        item.get("assetKey")
        for item in manifest.get("assets", [])
        if isinstance(item, dict)
    }

    for key in sorted(required_keys):
        wav_path = audio_dir / f"{key}.wav"
        if key not in manifest_keys:
            errors.append(f"Audio key '{key}' missing from audio_manifest.json")
        if not wav_path.exists():
            errors.append(f"Audio key '{key}' missing file {wav_path.name}")
            continue
        with open(wav_path, "rb") as f:
            header = f.read(12)
        if not (header.startswith(b"RIFF") and header[8:12] == b"WAVE"):
            errors.append(f"Audio file {wav_path.name} is not a valid WAV placeholder")

    return errors


def main():
    games = {
        "word_builder": PROJECT_ROOT
        / "apps"
        / "mobile"
        / "assets"
        / "levels"
        / "word_builder.json",
        "sound_match": PROJECT_ROOT
        / "apps"
        / "mobile"
        / "assets"
        / "levels"
        / "sound_match.json",
        "math_race": PROJECT_ROOT
        / "apps"
        / "mobile"
        / "assets"
        / "levels"
        / "math_race.json",
        "math_supermarket": PROJECT_ROOT
        / "apps"
        / "mobile"
        / "assets"
        / "levels"
        / "math_supermarket.json",
        "memory_cards": PROJECT_ROOT
        / "apps"
        / "mobile"
        / "assets"
        / "levels"
        / "memory_cards.json",
        "robot_commands": PROJECT_ROOT
        / "apps"
        / "mobile"
        / "assets"
        / "levels"
        / "robot_commands.json",
        "category_collector": PROJECT_ROOT
        / "apps"
        / "mobile"
        / "assets"
        / "levels"
        / "category_collector.json",
        "pattern_parade": PROJECT_ROOT
        / "apps"
        / "mobile"
        / "assets"
        / "levels"
        / "pattern_parade.json",
        "shape_builder": PROJECT_ROOT
        / "apps"
        / "mobile"
        / "assets"
        / "levels"
        / "shape_builder.json",
        "word_sorter": PROJECT_ROOT
        / "apps"
        / "mobile"
        / "assets"
        / "levels"
        / "word_sorter.json",
        "number_balance": PROJECT_ROOT
        / "apps"
        / "mobile"
        / "assets"
        / "levels"
        / "number_balance.json",
        "logic_detective": PROJECT_ROOT
        / "apps"
        / "mobile"
        / "assets"
        / "levels"
        / "logic_detective.json",
        "story_steps": PROJECT_ROOT
        / "apps"
        / "mobile"
        / "assets"
        / "levels"
        / "story_steps.json",
    }

    all_errors = []

    for game_id, path in games.items():
        if not path.exists():
            all_errors.append(f"Missing content file: {path}")
            continue
        errors = validate_game_file(path, game_id)
        for err in errors:
            all_errors.append(f"[{game_id}] {err}")

    sound_match_path = games["sound_match"]
    if sound_match_path.exists():
        required_audio = collect_audio_keys(sound_match_path)
        required_audio.update({"correct", "try_again", "card_flip", "match_correct"})
        for err in validate_audio_placeholders(required_audio):
            all_errors.append(f"[audio] {err}")

    # Check skill taxonomy exists
    taxonomy_path = PROJECT_ROOT / "content" / "skills" / "skill_taxonomy.json"
    if taxonomy_path.exists():
        taxonomy = load_json(taxonomy_path)
        skill_ids = set()
        for subject in taxonomy.get("subjects", []):
            for skill in subject.get("skills", []):
                skill_ids.add(skill.get("skillId", ""))
        print(f"[OK] Skill taxonomy: {len(skill_ids)} skills registered")
    else:
        all_errors.append("Missing skill_taxonomy.json")

    # Check curriculum files exist
    for age_file in ["age_5_7.json", "age_8_10.json", "age_11_12.json"]:
        path = PROJECT_ROOT / "content" / "curriculum" / age_file
        if path.exists():
            print(f"[OK] Curriculum: {age_file} present")
        else:
            all_errors.append(f"Missing curriculum: {age_file}")

    # Print results
    print()
    if all_errors:
        print(f"VALIDATION FAILED — {len(all_errors)} error(s):")
        for err in all_errors:
            print(f"  [ERROR] {err}")
        sys.exit(1)
    else:
        print("ALL CONTENT VALID")
        sys.exit(0)


if __name__ == "__main__":
    main()
