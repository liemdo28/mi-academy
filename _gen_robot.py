#!/usr/bin/env python3
"""Generate robot_commands.json with correct validator schema."""
import json
from pathlib import Path

out = Path(__file__).parent / 'apps' / 'mobile' / 'assets' / 'levels' / 'robot_commands.json'

levels = [
    {
        "id": "rc-lv01", "levelNumber": 1, "difficulty": 1,
        "objective_vi": "Lệnh cơ bản — tiến 1 bước",
        "prompt_vi": "Hãy ra lệnh cho robot đi tới ngôi sao!",
        "prompt_en": "Command the robot to walk to the star!",
        "grid": {"width": 2, "height": 1}, "start": {"x": 0, "y": 0, "facing": "east"}, "goal": {"x": 1, "y": 0},
        "available": ["MOVE_FORWARD"],
        "required_vi": ["START", "MOVE_FORWARD"],
        "required_en": ["START", "MOVE_FORWARD"],
        "hints_vi": ["Dùng lệnh Tiến để robot đi tới"],
        "hints_en": ["Use the Forward command"],
        "skillIds": ["logic.programming_sequences"],
    },
    {
        "id": "rc-lv02", "levelNumber": 2, "difficulty": 1,
        "objective_vi": "Hai bước liên tiếp",
        "prompt_vi": "Robot cần đi 2 bước tới quả táo!",
        "prompt_en": "Robot needs to walk 2 steps to the apple!",
        "grid": {"width": 3, "height": 1}, "start": {"x": 0, "y": 0, "facing": "east"}, "goal": {"x": 2, "y": 0},
        "available": ["MOVE_FORWARD"],
        "required_vi": ["START", "MOVE_FORWARD", "MOVE_FORWARD"],
        "required_en": ["START", "MOVE_FORWARD", "MOVE_FORWARD"],
        "hints_vi": ["Lặp lại lệnh Tiến hai lần"],
        "hints_en": ["Repeat the Forward command twice"],
        "skillIds": ["logic.programming_sequences"],
    },
    {
        "id": "rc-lv03", "levelNumber": 3, "difficulty": 2,
        "objective_vi": "Rẽ phải — quay hướng",
        "prompt_vi": "Đi tới, rẽ phải, đi tới!",
        "prompt_en": "Forward, turn right, forward!",
        "grid": {"width": 3, "height": 3}, "start": {"x": 0, "y": 0, "facing": "east"}, "goal": {"x": 1, "y": 1},
        "available": ["MOVE_FORWARD", "TURN_RIGHT"],
        "required_vi": ["START", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD"],
        "required_en": ["START", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD"],
        "hints_vi": ["Dùng lệnh Quay phải trước, rồi Tiến"],
        "hints_en": ["Use Turn Right first, then Forward"],
        "skillIds": ["logic.programming_sequences"],
    },
    {
        "id": "rc-lv04", "levelNumber": 4, "difficulty": 2,
        "objective_vi": "Rẽ phải — quay hướng",
        "prompt_vi": "Rẽ phải rồi đi tới chìa khóa!",
        "prompt_en": "Turn right then walk to the key!",
        "grid": {"width": 2, "height": 2}, "start": {"x": 0, "y": 0, "facing": "east"}, "goal": {"x": 1, "y": 1},
        "available": ["MOVE_FORWARD", "TURN_RIGHT"],
        "required_vi": ["START", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD"],
        "required_en": ["START", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD"],
        "hints_vi": ["Đi tới, rẽ phải, rồi đi tiếp"],
        "hints_en": ["Go forward, turn right, then forward again"],
        "skillIds": ["logic.programming_sequences"],
    },
    {
        "id": "rc-lv05", "levelNumber": 5, "difficulty": 3,
        "objective_vi": "Vòng lặp lặp lại 3 lần",
        "prompt_vi": "Dùng vòng lặp 'Lặp lại 3 lần' để đi tới trái tim!",
        "prompt_en": "Use a 'Repeat 3 times' loop to reach the heart!",
        "grid": {"width": 4, "height": 1}, "start": {"x": 0, "y": 0, "facing": "east"}, "goal": {"x": 3, "y": 0},
        "available": ["MOVE_FORWARD", "REPEAT"],
        "required_vi": ["START", "MOVE_FORWARD", "MOVE_FORWARD", "MOVE_FORWARD"],
        "required_en": ["START", "MOVE_FORWARD", "MOVE_FORWARD", "MOVE_FORWARD"],
        "hints_vi": ["Lặp lại lệnh Tiến 3 lần bằng khối Lặp"],
        "hints_en": ["Repeat Forward 3 times using the Repeat block"],
        "skillIds": ["logic.loops"],
    },
    {
        "id": "rc-lv06", "levelNumber": 6, "difficulty": 3,
        "objective_vi": "Kết hợp quay và tiến",
        "prompt_vi": "Tiến, quay trái, tiến, quay phải, tiến — tới viên kim cương!",
        "prompt_en": "Forward, left, forward, right, forward — to the diamond!",
        "grid": {"width": 4, "height": 3}, "start": {"x": 0, "y": 0, "facing": "east"}, "goal": {"x": 3, "y": 2},
        "available": ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"],
        "required_vi": ["START", "MOVE_FORWARD", "MOVE_FORWARD", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD", "MOVE_FORWARD"],
        "required_en": ["START", "MOVE_FORWARD", "MOVE_FORWARD", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD", "MOVE_FORWARD"],
        "hints_vi": ["Sắp xếp các lệnh theo thứ tự đúng"],
        "hints_en": ["Arrange commands in the correct order"],
        "skillIds": ["logic.programming_sequences"],
    },
    {
        "id": "rc-lv07", "levelNumber": 7, "difficulty": 4,
        "objective_vi": "Vòng lặp lồng nhau",
        "prompt_vi": "Dùng vòng lặp 4 lần với lệnh quay để đi hình vuông!",
        "prompt_en": "Use a repeat-4 loop with turns to walk a square!",
        "grid": {"width": 4, "height": 4}, "start": {"x": 0, "y": 0, "facing": "east"}, "goal": {"x": 3, "y": 2},
        "available": ["MOVE_FORWARD", "TURN_RIGHT", "REPEAT"],
        "required_vi": ["START", "MOVE_FORWARD", "MOVE_FORWARD", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD", "MOVE_FORWARD"],
        "required_en": ["START", "MOVE_FORWARD", "MOVE_FORWARD", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD", "MOVE_FORWARD"],
        "hints_vi": ["Đi 3 bước về phía đông, quay phải, đi 2 bước về phía nam"],
        "hints_en": ["Go 3 steps east, turn right, go 2 steps south"],
        "skillIds": ["logic.loops", "logic.programming_sequences"],
    },
    {
        "id": "rc-lv08", "levelNumber": 8, "difficulty": 4,
        "objective_vi": "Điều kiện — tránh chướng ngại vật",
        "prompt_vi": "Dùng lệnh Nếu-không-vướng để tránh tảng đá!",
        "prompt_en": "Use 'If Path Ahead' to avoid the rock!",
        "grid": {"width": 4, "height": 2}, "start": {"x": 0, "y": 0, "facing": "east"}, "goal": {"x": 3, "y": 1},
        "obstacles": [{"x": 2, "y": 0}],
        "available": ["MOVE_FORWARD", "TURN_RIGHT", "TURN_LEFT", "IF_PATH_AHEAD"],
        "required_vi": ["START", "MOVE_FORWARD", "IF_PATH_AHEAD", "TURN_RIGHT", "MOVE_FORWARD", "TURN_LEFT", "MOVE_FORWARD", "MOVE_FORWARD"],
        "required_en": ["START", "MOVE_FORWARD", "IF_PATH_AHEAD", "TURN_RIGHT", "MOVE_FORWARD", "TURN_LEFT", "MOVE_FORWARD", "MOVE_FORWARD"],
        "hints_vi": ["Nếu phía trước không có đá, thì Tiến"],
        "hints_en": ["If path ahead, go forward; else turn"],
        "skillIds": ["logic.conditions"],
    },
    {
        "id": "rc-lv09", "levelNumber": 9, "difficulty": 5,
        "objective_vi": "Thuật toán đường đi — tìm đường ngắn nhất",
        "prompt_vi": "Tìm đường ngắn nhất tới cờ!",
        "prompt_en": "Find the shortest path to the flag!",
        "grid": {"width": 4, "height": 3}, "start": {"x": 0, "y": 0, "facing": "east"}, "goal": {"x": 3, "y": 2},
        "available": ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"],
        "required_vi": ["START", "MOVE_FORWARD", "MOVE_FORWARD", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD", "MOVE_FORWARD"],
        "required_en": ["START", "MOVE_FORWARD", "MOVE_FORWARD", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD", "MOVE_FORWARD"],
        "hints_vi": ["Lập kế hoạch trước khi viết lệnh"],
        "hints_en": ["Plan your path before writing commands"],
        "skillIds": ["logic.algorithms"],
    },
    {
        "id": "rc-lv10", "levelNumber": 10, "difficulty": 5,
        "objective_vi": "Thu thập items — về đích!",
        "prompt_vi": "Thu thập tất cả items, về đích!",
        "prompt_en": "Collect all items, reach the goal!",
        "grid": {"width": 4, "height": 1}, "start": {"x": 0, "y": 0, "facing": "east"}, "goal": {"x": 3, "y": 0},
        "obstacles": [],
        "collectibles": [{"x": 1, "y": 0}, {"x": 2, "y": 0}],
        "available": ["MOVE_FORWARD", "COLLECT"],
        "required_vi": ["START", "MOVE_FORWARD", "COLLECT", "MOVE_FORWARD", "COLLECT", "MOVE_FORWARD"],
        "required_en": ["START", "MOVE_FORWARD", "COLLECT", "MOVE_FORWARD", "COLLECT", "MOVE_FORWARD"],
        "hints_vi": ["Thu thập từng item trước khi tiến tới đích"],
        "hints_en": ["Collect each item before heading to the goal"],
        "skillIds": ["logic.algorithms", "logic.programming_sequences"],
    },
]

result = {
    "gameId": "robot_commands",
    "schemaVersion": "1.0.0",
    "description": "Kids program a robot by placing sequential commands to navigate a grid and collect items. Teaches sequencing, loops, and basic programming.",
    "levels": []
}

for ld in levels:
    age = "junior" if ld["difficulty"] <= 2 else ("explorer" if ld["difficulty"] <= 4 else "master")
    metadata = {"grid": ld["grid"], "start": ld["start"], "goal": ld["goal"], "ageGroup": age, "skillIds": ld["skillIds"]}
    if "obstacles" in ld: metadata["obstacles"] = ld["obstacles"]
    if "collectibles" in ld: metadata["collectibles"] = ld["collectibles"]
    level = {
        "id": ld["id"], "gameId": "robot_commands", "levelNumber": ld["levelNumber"],
        "difficulty": ld["difficulty"], "learningObjective": ld["objective_vi"],
        "localizedContent": {
            "vi": {"prompt": ld["prompt_vi"], "availableCommands": ld["available"], "requiredCommands": ld["required_vi"]},
            "en": {"prompt": ld["prompt_en"], "availableCommands": ld["available"], "requiredCommands": ld["required_en"]},
        },
        "hints": [{"text": h} for h in ld["hints_vi"]],
        "metadata": metadata, "assetRefs": [],
    }
    result["levels"].append(level)

out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8")
print(f"Wrote {len(result['levels'])} levels to {out}")
