"""Game engines — MathRace, MemoryCards, RobotCommands, MathSupermarket.
Engine 4 (Runner), Engine 3 (Grid), Engine 6 (Block), Engine 5 (Simulation)."""

import random
from typing import cast

from packages.game_core.game_interface import (
    AnswerResult,
    CompletionResult,
    GameInterface,
    LevelState,
    calculate_stars,
)


class MathRaceEngine(GameInterface):
    """Math race — each correct answer moves the character forward along a track."""

    OPERATIONS = {
        1: ["+", "-"],
        2: ["+", "-", "×"],
        3: ["+", "-", "×", "÷"],
    }

    def __init__(self):
        super().__init__()
        self._problems: list[dict] = []
        self._current_problem: dict = {}
        self._progress: int = 0
        self._goal: int = 10

    def load_level(self, level: int) -> LevelState:
        difficulty = min(level, 3)
        ops = self.OPERATIONS[difficulty]
        problems = self._generate_problems(ops)
        self._problems = problems
        self._current_problem = problems[0] if problems else {}
        self._progress = 0
        self._state = LevelState(level=level, items=problems, difficulty=difficulty)
        return self._state

    def _generate_problems(self, ops: list[str]) -> list[dict]:
        problems = []
        for _ in range(self._goal):
            op = random.choice(ops)
            a, b, answer = self._make_problem(op)
            options = self._make_options(answer)
            problems.append(
                {"a": a, "b": b, "op": op, "answer": answer, "options": options}
            )
        return problems

    def _make_problem(self, op: str):
        if op == "+":
            a = random.randint(1, 20)
            b = random.randint(1, 20)
            return a, b, a + b
        elif op == "-":
            a = random.randint(5, 30)
            b = random.randint(1, a)
            return a, b, a - b
        elif op == "×":
            a = random.randint(1, 10)
            b = random.randint(1, 10)
            return a, b, a * b
        else:  # ÷
            b = random.randint(1, 10)
            answer = random.randint(1, 10)
            return b * answer, b, answer

    def _make_options(self, correct: int) -> list[int]:
        options = [correct]
        while len(options) < 4:
            d = correct + random.randint(-5, 5)
            if d > 0 and d not in options:
                options.append(d)
        random.shuffle(options)
        return options

    def submit_answer(self, answer: int) -> AnswerResult:
        assert self._state is not None, (
            "load_level() must be called before submit_answer()"
        )
        self._attempt_count += 1
        correct_val = self._current_problem.get("answer")
        assert correct_val is not None, "current problem is missing its answer"
        is_correct = answer == correct_val

        result = AnswerResult(
            is_correct=is_correct,
            correct_answer=correct_val,
            explanation=self._get_explanation(is_correct, correct_val),
            stars_earned=1,
            hints_remaining=self._hints_remaining,
        )

        if is_correct:
            self._progress += 1
            self._answers.append(
                {
                    "problem": f"{self._current_problem['a']} {self._current_problem['op']} {self._current_problem['b']}",
                    "correct": True,
                    "attempts": self._attempt_count,
                }
            )
            result.stars_earned = calculate_stars(self._attempt_count, self._goal)
            idx = self._problems.index(self._current_problem)
            if idx + 1 < len(self._problems):
                self._current_problem = self._problems[idx + 1]
                self._state.current_index = idx + 1
        else:
            self._answers.append(
                {
                    "problem": f"{self._current_problem['a']} {self._current_problem['op']} {self._current_problem['b']}",
                    "correct": False,
                    "attempt": answer,
                }
            )
        return result

    def complete(self) -> CompletionResult:
        mastery = self._progress / self._goal
        total_stars = calculate_stars(
            sum(a.get("attempts", 1) for a in self._answers), self._goal
        )
        badges = []
        if self._progress >= self._goal:
            badges.append("math_racer")
        if total_stars == 3:
            badges.append("math_whiz")
        return CompletionResult(
            total_stars=total_stars,
            badges_unlocked=badges,
            rewards_unlocked=[],
            mastery_score=mastery,
        )

    def _generate_hint(self) -> str:
        p = self._current_problem
        return (
            f"Hãy đếm thử! {p['a']} {p['op']} {p['b']} = ? "
            f"Đáp án nằm trong: {p['options']}"
        )

    def _get_explanation(self, correct: bool, answer: int) -> str:
        if correct:
            return f"Đúng rồi! Đáp án là {answer}. Xe đua tiến lên!"
        return f"Chưa đúng. Đáp án là {answer}. Đừng lo, cứ thử lại nhé!"


class MemoryCardsEngine(GameInterface):
    """Memory Cards — find matching pairs on a grid. Engine 3 (Grid and Tile)."""

    def __init__(self):
        super().__init__()
        self._pairs: list[tuple[str, str]] = []
        self._matched: set[int] = set()

    def load_level(self, level: int) -> LevelState:
        grid_sizes = {1: 4, 2: 6, 3: 8, 4: 10, 5: 12}
        grid_size = grid_sizes.get(level, 6)
        pairs = self._generate_pairs(grid_size // 2)
        self._pairs = pairs
        self._matched = set()
        self._state = LevelState(level=level, items=pairs, difficulty=level)
        return self._state

    def _generate_pairs(self, count: int) -> list[tuple[str, str]]:
        icons = [
            "🌟",
            "🐱",
            "🐶",
            "🍎",
            "🚗",
            "🌸",
            "⭐",
            "🎈",
            "🔵",
            "🟢",
            "🟡",
            "🔴",
            "🌙",
            "☀️",
            "🌈",
            "🎯",
        ]
        icons = icons[:count]
        pairs = [(i, i) for i in icons]
        random.shuffle(pairs)
        return pairs

    def submit_answer(self, indices: list[int]) -> AnswerResult:
        if len(indices) != 2:
            return AnswerResult(
                is_correct=False,
                correct_answer=[],
                explanation="Chọn đúng 2 thẻ!",
                hints_remaining=self._hints_remaining,
            )
        i1, i2 = indices
        is_match = self._pairs[i1][0] == self._pairs[i2][0]
        self._attempt_count += 1

        if is_match:
            self._matched.add(i1)
            self._matched.add(i2)
            self._answers.append({"pair": [i1, i2], "correct": True})

        return AnswerResult(
            is_correct=is_match,
            correct_answer=[] if is_match else [i1, i2],
            explanation="Ghép đúng!" if is_match else "Không khớp, thử lại nhé!",
            stars_earned=1,
            hints_remaining=self._hints_remaining,
        )

    def complete(self) -> CompletionResult:
        matched_pairs = len(self._matched) // 2
        total_pairs = len(self._pairs)
        mastery = matched_pairs / total_pairs if total_pairs else 0
        total_stars = calculate_stars(self._attempt_count, total_pairs)
        return CompletionResult(
            total_stars=total_stars,
            badges_unlocked=["memory_champion"] if mastery >= 1.0 else [],
            rewards_unlocked=[],
            mastery_score=mastery,
        )

    def _generate_hint(self) -> str:
        unmatched = [i for i in range(len(self._pairs)) if i not in self._matched]
        if len(unmatched) >= 2:
            return "Thử mở 2 thẻ cùng một lúc để tìm cặp giống nhau!"
        return "Chỉ còn một vài thẻ, bạn làm tốt lắm!"


class RobotCommandsEngine(GameInterface):
    """Robot Commands — sequence blocks to navigate a grid. Engine 6 (Block Programming)."""

    MAPS = {
        1: {
            "grid": [[0, 0, 0], [0, 1, 0], [0, 0, 0]],
            "start": (0, 0),
            "goal": (2, 2),
            "max_cmds": 5,
        },
        2: {
            "grid": [[0, 0, 0, 0], [0, 1, 1, 0], [0, 0, 0, 0]],
            "start": (0, 0),
            "goal": (3, 2),
            "max_cmds": 7,
        },
        3: {
            "grid": [[0, 0, 0, 0, 0], [0, 1, 0, 1, 0], [0, 0, 0, 0, 0]],
            "start": (0, 0),
            "goal": (4, 2),
            "max_cmds": 10,
        },
    }

    def __init__(self):
        super().__init__()
        self._grid: list[list[int]] = []
        self._start: tuple[int, int] = (0, 0)
        self._goal: tuple[int, int] = (2, 2)
        self._position: tuple[int, int] = (0, 0)
        self._commands: list[str] = []

    def load_level(self, level: int) -> LevelState:
        map_data = self.MAPS.get(level, self.MAPS[1])
        grid_data = cast("list[list[int]]", map_data["grid"])
        self._grid = [row[:] for row in grid_data]
        self._start = cast("tuple[int, int]", map_data["start"])
        self._goal = cast("tuple[int, int]", map_data["goal"])
        self._position = self._start
        self._commands = []
        self._state = LevelState(level=level, items=self._commands, difficulty=level)
        return self._state

    def submit_answer(self, commands: list[str]) -> AnswerResult:
        self._commands = commands
        self._attempt_count += 1
        self._position = self._start

        for cmd in commands:
            self._execute_cmd(cmd)
            if self._position == self._goal:
                break

        reached_goal = self._position == self._goal
        return AnswerResult(
            is_correct=reached_goal,
            correct_answer=self._commands,
            explanation="Robot đã đến đích!"
            if reached_goal
            else "Robot chưa đến đích, thử lại!",
            stars_earned=1,
            hints_remaining=self._hints_remaining,
        )

    def _execute_cmd(self, cmd: str) -> None:
        x, y = self._position
        if cmd == "up":
            x -= 1
        elif cmd == "down":
            x += 1
        elif cmd == "left":
            y -= 1
        elif cmd == "right":
            y += 1
        if 0 <= x < len(self._grid) and 0 <= y < len(self._grid[0]):
            if self._grid[x][y] != 1:
                self._position = (x, y)

    def complete(self) -> CompletionResult:
        assert self._state is not None, "load_level() must be called before complete()"
        mastery = 1.0 if self._position == self._goal else 0.5
        total_stars = calculate_stars(self._attempt_count, self._state.difficulty)
        return CompletionResult(
            total_stars=total_stars,
            badges_unlocked=["robot_coder"] if self._position == self._goal else [],
            rewards_unlocked=[],
            mastery_score=mastery,
        )

    def _generate_hint(self) -> str:
        sx, sy = self._start
        gx, gy = self._goal
        hints = []
        if gx > sx:
            hints.append("↓")
        elif gx < sx:
            hints.append("↑")
        if gy > sy:
            hints.append("→")
        elif gy < sy:
            hints.append("←")
        return f"Hãy thử các lệnh: {' '.join(hints)}"


class MathSupermarketEngine:
    """Math Supermarket — add prices, give change. Engine 5 (Simulation)."""

    def __init__(self):
        self._products: list[dict] = []
        self._total: int = 0

    def load_level(self, level: int) -> dict:
        products = self._generate_products(level)
        self._products = products
        self._total = sum(p["price"] for p in products)
        return {"products": products, "total": self._total}

    def _generate_products(self, level: int) -> list[dict]:
        all_products = [
            {"name": "Bánh mì", "emoji": "🥖", "price": 15},
            {"name": "Sữa", "emoji": "🥛", "price": 25},
            {"name": "Trứng", "emoji": "🥚", "price": 30},
            {"name": "Táo", "emoji": "🍎", "price": 10},
            {"name": "Nước ngọt", "emoji": "🥤", "price": 20},
            {"name": "Bánh quy", "emoji": "🍪", "price": 18},
        ]
        count = min(2 + level, len(all_products))
        return random.sample(all_products, count)

    def check_payment(self, amount_paid: int) -> dict:
        if amount_paid < self._total:
            return {
                "correct": False,
                "type": "underpayment",
                "message": f"Còn thiếu {self._total - amount_paid} đồng!",
                "correct_answer": self._total,
            }
        change = amount_paid - self._total
        return {
            "correct": True,
            "type": "change",
            "change": change,
            "message": f"Hoàn {change} đồng tiền thừa!",
        }
