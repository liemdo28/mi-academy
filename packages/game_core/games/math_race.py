import random
from packages.game_core.base import (
    GameEngineBase,
    LevelState,
    AnswerResult,
)


class MathRaceGame(GameEngineBase):
    def __init__(self, config):
        super().__init__(config)
        self._seed = 0

    def _difficulty_band(self, level):
        if level <= 3:
            return 5, 10, ["+", "-"]
        elif level <= 5:
            return 5, 20, ["+", "-"]
        elif level <= 7:
            return 10, 100, ["+", "-"]
        elif level <= 9:
            return 50, 1000, ["+", "-", "x"]
        return -50, 1000, ["+", "-", "x", "/"]

    def _gen_problem(self, rnd, level):
        lo, hi, ops = self._difficulty_band(level)
        op = rnd.choice(ops)
        if op == "+":
            a, b = rnd.randint(lo, hi), rnd.randint(lo, hi)
            return str(a) + " + " + str(b) + " = ?", a + b
        if op == "-":
            a, b = rnd.randint(lo, hi), rnd.randint(lo, hi)
            return str(max(a, b)) + " - " + str(min(a, b)) + " = ?", max(a, b) - min(
                a, b
            )
        if op == "x":
            a, b = rnd.randint(1, 12), rnd.randint(1, 12)
            return str(a) + " x " + str(b) + " = ?", a * b
        b = rnd.randint(1, 12)
        res = rnd.randint(1, 12)
        return str(b * res) + " / " + str(b) + " = ?", res

    def load_level(self, level):
        level = max(1, min(10, level))
        rnd = random.Random(self._seed + level * 1000)
        items = []
        for _ in range(10):
            q, ans = self._gen_problem(rnd, level)
            opts = [ans]
            for _ in range(3):
                d = ans + rnd.randint(1, max(2, abs(ans) // 5 + 2)) * rnd.choice(
                    [-1, 1]
                )
                if d not in opts:
                    opts.append(d)
                else:
                    opts.append(ans + rnd.randint(1, 5))
            rnd.shuffle(opts)
            items.append(
                {
                    "question": q,
                    "options": opts,
                    "correct_answer": ans,
                    "hint": "Tinh toan ky nhe",
                    "explanation": q + " = " + str(ans),
                }
            )
        self._state = LevelState(
            level=level,
            items=items,
            difficulty=level,
            current_index=0,
            total_questions=len(items),
        )
        return self._state

    def set_seed(self, seed):
        self._seed = seed

    def start(self):
        super().start()
        self._seed = 0

    def submit_answer(self, answer):
        if self._state is None:
            raise RuntimeError("Level not loaded")
        if self._state.current_index >= len(self._state.items):
            return AnswerResult(
                is_correct=False,
                correct_answer="",
                explanation="No more",
                next_state=None,
                stars_earned=0,
                hints_remaining=self._hints_remaining,
                retry_allowed=False,
            )
        item = self._state.items[self._state.current_index]
        correct = item["correct_answer"]
        try:
            user = int(answer) if not isinstance(answer, str) else int(answer.strip())
        except Exception:
            user = None
        is_correct = user == correct
        if is_correct:
            stars = self._calculate_stars_for_question()
            self._stars_per_question.append(stars)
            self._state.current_index += 1
            ns = (
                self._state
                if self._state.current_index < len(self._state.items)
                else None
            )
            return AnswerResult(
                is_correct=True,
                correct_answer=correct,
                explanation=item.get("explanation"),
                next_state=ns,
                stars_earned=stars,
                hints_remaining=self._hints_remaining,
                retry_allowed=False,
            )
        self._retry_count += 1
        return AnswerResult(
            is_correct=False,
            correct_answer=correct,
            explanation=None,
            next_state=self._state,
            stars_earned=0,
            hints_remaining=self._hints_remaining,
            retry_allowed=self._retry_count < 3,
        )
