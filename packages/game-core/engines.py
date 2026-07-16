"""Word Builder Engine — Engine 1 (Drag and Drop variant).
Child drags letters into slots to spell a word."""

from dataclasses import dataclass
from typing import Optional

from packages.game_core.game_interface import (
    AnswerResult,
    CompletionResult,
    GameConfig,
    GameInterface,
    LevelState,
    calculate_stars,
)


class WordBuilderEngine(GameInterface):
    """Game where the child builds words by placing letters in the correct slots."""

    LEVEL_DATA = {
        # age_group: list of word lists by difficulty
        "junior": {
            1: ["a", "e", "i", "o", "u"],
            2: ["an", "am", "at", "is", "it", "on", "up"],
            3: ["cat", "dog", "sun", "hat", "map", "pen"],
            4: ["bird", "fish", "tree", "book", "game"],
            5: ["apple", "water", "mouse", "happy", "tiger"],
        },
        "explorer": {
            1: ["school", "friend", "family", "garden"],
            2: ["beautiful", "wonderful", "different", "important"],
            3: ["knowledge", "adventure", "discovery", "creativity"],
            4: ["environment", "communication", "imagination"],
            5: ["extraordinary", "responsibility"],
        },
        "master": {
            1: ["philosophy", "mathematics", "technology"],
            2: ["electromagnetic", "photosynthesis"],
            3: ["antidisestablishmentarianism"],
        },
    }

    def __init__(self):
        super().__init__()
        self._words: list[str] = []
        self._current_word: str = ""

    def load_level(self, level: int) -> LevelState:
        age_group = self._config.language  # Language doubles as age config here
        word_list = self.LEVEL_DATA.get(age_group, self.LEVEL_DATA["junior"]).get(level, ["cat"])
        difficulty = level
        self._words = word_list
        self._current_word = word_list[0] if word_list else ""
        self._state = LevelState(level=level, items=word_list, difficulty=difficulty)
        return self._state

    def submit_answer(self, answer: str) -> AnswerResult:
        self._attempt_count += 1
        correct = answer.strip().lower() == self._current_word.lower()

        result = AnswerResult(
            is_correct=correct,
            correct_answer=self._current_word,
            explanation=self._get_explanation(correct),
            stars_earned=1,
            hints_remaining=self._hints_remaining,
        )

        if correct:
            result.stars_earned = calculate_stars(self._attempt_count, len(self._words))
            self._answers.append({
                "word": self._current_word,
                "correct": True,
                "attempts": self._attempt_count,
            })
            # Advance to next word
            idx = self._words.index(self._current_word)
            next_idx = idx + 1
            if next_idx < len(self._words):
                self._current_word = self._words[next_idx]
                self._state.current_index = next_idx
            else:
                self._state.current_index = len(self._words)
        else:
            self._answers.append({
                "word": self._current_word,
                "correct": False,
                "attempt": answer,
            })

        return result

    def complete(self) -> CompletionResult:
        correct_count = sum(1 for a in self._answers if a.get("correct"))
        mastery = correct_count / max(len(self._answers), 1)
        total_stars = calculate_stars(
            sum(a.get("attempts", 1) for a in self._answers),
            len(self._answers)
        )
        badges = []
        if total_stars == 3:
            badges.append("word_master")
        if correct_count == len(self._words):
            badges.append("perfect_word_builder")
        return CompletionResult(
            total_stars=total_stars,
            badges_unlocked=badges,
            rewards_unlocked=[],
            mastery_score=mastery,
        )

    def _generate_hint(self) -> str:
        word = self._current_word
        # Highlight first missing/incorrect letter
        return f"Gợi ý: từ này bắt đầu bằng chữ '{word[0].upper()}' và có {len(word)} chữ cái."

    def _get_explanation(self, correct: bool) -> str:
        if correct:
            return f"Đúng rồi! Từ '{self._current_word}' được ghép chính xác. Giỏi lắm!"
        return f"Chưa đúng. Hãy thử lại nhé! Gợi ý: từ này có {len(self._current_word)} chữ cái."
