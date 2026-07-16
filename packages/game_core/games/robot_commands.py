import random
from packages.game_core.base import GameEngineBase, GameConfig, LevelState, AnswerResult, HintResult, CompletionResult


class RobotCommandsGame(GameEngineBase):
    DIRECTIONS = [(0, -1), (1, 0), (0, 1), (-1, 0)]  # N,E,S,W with y increasing downward
    DIR_NAMES = ["N", "E", "S", "W"]

    def __init__(self, config):
        super().__init__(config)
        self._optimal_steps = 0

    def _level_size(self, level):
        if level <= 2: return 5
        if level <= 4: return 6
        if level <= 6: return 7
        return 8

    def _level_features(self, level):
        return {"turns": level >= 2, "obstacles": level >= 3, "loops": level >= 5, "nested_loops": level >= 7}

    def load_level(self, level):
        level = max(1, min(10, level))
        size = self._level_size(level)
        grid = [[0] * size for _ in range(size)]
        obstacles = []
        feats = self._level_features(level)
        if feats["obstacles"]:
            num_obst = 1 + level // 2
            for _ in range(num_obst):
                rx = random.randint(1, size - 2)
                ry = random.randint(1, size - 2)
                if (rx, ry) not in [(0, 0), (size - 1, size - 1)]:
                    grid[ry][rx] = 1
                    if (rx, ry) not in obstacles:
                        obstacles.append((rx, ry))
        start = {"x": 0, "y": 0, "dir": 0}
        goal = {"x": size - 1, "y": size - 1}
        manhattan = abs(goal["x"] - start["x"]) + abs(goal["y"] - start["y"])
        optimal = manhattan + 1
        self._optimal_steps = optimal
        item = {"grid": grid, "obstacles": obstacles, "start": start, "goal": goal, "size": size, "features": feats, "correct_answer": "reach_goal", "hint": "Den dich voi it buoc nhat", "explanation": "Dat den dich la thanh cong", "optimal_steps": optimal}
        self._state = LevelState(level=level, items=[item], difficulty=level, current_index=0, total_questions=1)
        return self._state

    def _run_commands(self, commands, grid, start, goal, size):
        x, y, d = start["x"], start["y"], start["dir"]
        obs = set()
        for ry, row in enumerate(grid):
            for rx, v in enumerate(row):
                if v == 1: obs.add((rx, ry))
        cx, cy, cd = x, y, d
        for cmd in commands:
            if cmd == "forward":
                dx, dy = self.DIRECTIONS[cd]
                nx, ny = cx + dx, cy + dy
                if 0 <= nx < size and 0 <= ny < size and (nx, ny) not in obs:
                    cx, cy = nx, ny
            elif cmd == "backward":
                dx, dy = self.DIRECTIONS[cd]
                nx, ny = cx - dx, cy - dy
                if 0 <= nx < size and 0 <= ny < size and (nx, ny) not in obs:
                    cx, cy = nx, ny
            elif cmd == "turn_left":
                cd = (cd - 1) % 4
            elif cmd == "turn_right":
                cd = (cd + 1) % 4
            elif cmd == "if_obstacle":
                dx, dy = self.DIRECTIONS[cd]
                nx, ny = cx + dx, cy + dy
                if not (0 <= nx < size and 0 <= ny < size and (nx, ny) in obs):
                    pass  # no obstacle ahead, continue normally
        return cx, cy

    def submit_answer(self, answer):
        if self._state is None: raise RuntimeError("Level not loaded")
        if self._state.current_index >= len(self._state.items):
            return AnswerResult(is_correct=False, correct_answer=None, explanation="No more", next_state=None, stars_earned=0, hints_remaining=self._hints_remaining, retry_allowed=False)
        item = self._state.items[self._state.current_index]
        goal = item["goal"]
        commands = list(answer) if not isinstance(answer, list) else answer
        x, y = self._run_commands(commands, item["grid"], item["start"], item["goal"], item["size"])
        is_correct = (x == goal["x"] and y == goal["y"])
        if is_correct:
            num_cmds = len(commands)
            opt = self._optimal_steps
            if num_cmds <= opt:
                stars = 3
            elif num_cmds <= opt * 2:
                stars = 2
            else:
                stars = 1
            self._stars_per_question.append(stars)
            self._state.current_index += 1
            ns = self._state if self._state.current_index < len(self._state.items) else None
            return AnswerResult(is_correct=True, correct_answer={"x": goal["x"], "y": goal["y"]}, explanation="Robot dat dich", next_state=ns, stars_earned=stars, hints_remaining=self._hints_remaining, retry_allowed=False)
        self._retry_count += 1
        return AnswerResult(is_correct=False, correct_answer={"x": goal["x"], "y": goal["y"]}, explanation="Robot dung tai (" + str(x) + "," + str(y) + ")", next_state=self._state, stars_earned=0, hints_remaining=self._hints_remaining, retry_allowed=self._retry_count < 5)

    def use_hint(self):
        if self._hints_remaining <= 0: return HintResult(hint_text="", hints_remaining=0, hint_given=False)
        if self._state is None: return HintResult(hint_text="", hints_remaining=self._hints_remaining, hint_given=False)
        item = self._state.items[self._state.current_index]
        goal = item["goal"]
        start = item["start"]
        dx = goal["x"] - start["x"]
        dy = goal["y"] - start["y"]
        self._hints_remaining -= 1
        txt = "Di " + str(abs(dx)) + " buoc sang phai, " + str(abs(dy)) + " buoc len tren"
        return HintResult(hint_text=txt, hints_remaining=self._hints_remaining, hint_given=True)

    def complete(self):
        total = sum(self._stars_per_question)
        item_count = len(self._state.items) if self._state and self._state.items else 1
        mastery = total / (item_count * 3) if item_count > 0 else 0.0
        badges = ["Lap trinh vien"] if total > 0 else []
        if mastery >= 0.8: badges.append("Thu robot")
        return CompletionResult(total_stars=total, badges_unlocked=badges, rewards_unlocked=[], mastery_score=min(1.0, mastery))
