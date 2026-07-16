import random
from packages.game_core.base import GameEngineBase, GameConfig, LevelState, AnswerResult, HintResult, CompletionResult


class MemoryCardsGame(GameEngineBase):
    SYMBOLS = ["cat", "dog", "fish", "bird", "tree", "star", "moon", "sun", "apple", "ball", "car", "boat", "kite", "drum", "bell", "leaf"]
    GRIDS = {1: (2, 2), 2: (2, 3), 3: (2, 4), 4: (3, 4), 5: (4, 4), 6: (4, 4), 7: (4, 4), 8: (4, 4), 9: (4, 4), 10: (4, 4)}

    def __init__(self, config):
        super().__init__(config)
        self._revealed = set()
        self._matched = set()
        self._moves = 0

    def load_level(self, level):
        level = max(1, min(10, level))
        rows, cols = self.GRIDS.get(level, (4, 4))
        total_cards = rows * cols
        n_pairs = total_cards // 2
        syms = random.sample(self.SYMBOLS, n_pairs)
        deck = syms * 2
        random.shuffle(deck)
        cards = [{"index": i, "symbol": s, "matched": False} for i, s in enumerate(deck)]
        items = [{"cards": cards, "rows": rows, "cols": cols, "n_pairs": n_pairs, "correct_answer": "all_matched", "hint": "Nho vi tri cac the", "explanation": "Ghep tat ca cac cap"}]
        self._state = LevelState(level=level, items=items, difficulty=level, current_index=0, total_questions=n_pairs)
        self._revealed = set()
        self._matched = set()
        self._moves = 0
        return self._state

    def start(self):
        super().start()
        self._revealed = set()
        self._matched = set()
        self._moves = 0

    def submit_answer(self, answer):
        # answer is a tuple/list of two card indices
        if self._state is None: raise RuntimeError("Level not loaded")
        cards = self._state.items[0]["cards"]
        try:
            i1, i2 = int(answer[0]), int(answer[1])
        except Exception:
            return AnswerResult(is_correct=False, correct_answer=None, explanation="Chon 2 the", next_state=self._state, stars_earned=0, hints_remaining=self._hints_remaining, retry_allowed=True)
        self._moves += 1
        if i1 == i2 or i1 in self._matched or i2 in self._matched or i1 < 0 or i2 < 0 or i1 >= len(cards) or i2 >= len(cards):
            self._retry_count += 1
            return AnswerResult(is_correct=False, correct_answer=None, explanation="The khong hop le", next_state=self._state, stars_earned=0, hints_remaining=self._hints_remaining, retry_allowed=True)
        if cards[i1]["symbol"] == cards[i2]["symbol"]:
            self._matched.add(i1)
            self._matched.add(i2)
            cards[i1]["matched"] = True
            cards[i2]["matched"] = True
            stars = self._calculate_stars_for_question()
            self._stars_per_question.append(stars)
            all_done = len(self._matched) >= len(cards)
            ns = None if all_done else self._state
            self._retry_count = 0
            return AnswerResult(is_correct=True, correct_answer=cards[i1]["symbol"], explanation="Ghep dung!", next_state=ns, stars_earned=stars, hints_remaining=self._hints_remaining, retry_allowed=False)
        self._retry_count += 1
        return AnswerResult(is_correct=False, correct_answer=None, explanation="Khong khop, thu lai", next_state=self._state, stars_earned=0, hints_remaining=self._hints_remaining, retry_allowed=True)

    def is_complete(self):
        if self._state is None: return False
        return len(self._matched) >= len(self._state.items[0]["cards"])

    def get_moves(self):
        return self._moves

    def complete(self):
        total = sum(self._stars_per_question)
        n_pairs = self._state.total_questions if self._state else 1
        mastery = total / (n_pairs * 3) if n_pairs > 0 else 0.0
        return CompletionResult(total_stars=total, badges_unlocked=["Sieu tri nho"] if total > 0 else [], rewards_unlocked=[], mastery_score=min(1.0, mastery))
