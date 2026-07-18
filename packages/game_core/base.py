from dataclasses import dataclass
from typing import Any, Optional
from abc import ABC, abstractmethod


@dataclass
class GameConfig:
    game_type: str
    language: str = "vi"
    max_level: int = 10
    hints_per_level: int = 3
    time_limit_seconds: Optional[int] = None


@dataclass
class LevelState:
    level: int
    items: list
    difficulty: int
    current_index: int = 0
    total_questions: int = 0


@dataclass
class AnswerResult:
    is_correct: bool
    correct_answer: Any
    explanation: Optional[str] = None
    next_state: Optional[LevelState] = None
    stars_earned: int = 0
    hints_remaining: int = 3
    retry_allowed: bool = True


@dataclass
class HintResult:
    hint_text: str
    hints_remaining: int
    hint_given: bool


@dataclass
class CompletionResult:
    total_stars: int
    badges_unlocked: list
    rewards_unlocked: list
    mastery_score: float


@dataclass
class ProgressSnapshot:
    game_type: str
    child_id: str
    level: int
    current_index: int
    stars_earned: list
    hints_used: int
    is_complete: bool
    paused_at: Optional[str] = None


class GameEngineBase(ABC):
    def __init__(self, config: GameConfig):
        self.config = config
        self._state = None
        self._hints_remaining = config.hints_per_level
        self._stars_per_question: list[int] = []
        self._retry_count = 0

    @abstractmethod
    def load_level(self, level: int): ...

    def start(self) -> None:
        self._hints_remaining = self.config.hints_per_level
        self._stars_per_question = []
        self._retry_count = 0

    def pause(self) -> None:
        pass

    def resume(self) -> None:
        pass

    def submit_answer(self, answer):
        if self._state is None:
            raise RuntimeError("Level not loaded")
        item = self._state.items[self._state.current_index]
        correct = item.get("correct_answer")
        ok = answer == correct
        if ok:
            stars = self._calculate_stars_for_question()
            self._stars_per_question.append(stars)
            self._state.current_index += 1
            next_state = (
                self._state
                if self._state.current_index < len(self._state.items)
                else None
            )
            return AnswerResult(
                is_correct=True,
                correct_answer=correct,
                explanation=item.get("explanation"),
                next_state=next_state,
                stars_earned=stars,
                hints_remaining=self._hints_remaining,
                retry_allowed=False,
            )
        self._retry_count += 1
        return AnswerResult(
            is_correct=False,
            correct_answer=correct,
            explanation=item.get("explanation"),
            next_state=self._state,
            stars_earned=0,
            hints_remaining=self._hints_remaining,
            retry_allowed=self._retry_count < 3,
        )

    def use_hint(self):
        if self._hints_remaining <= 0:
            return HintResult(hint_text="", hints_remaining=0, hint_given=False)
        item = self._state.items[self._state.current_index]
        self._hints_remaining -= 1
        return HintResult(
            hint_text=item.get("hint", "Thu lai nhe!"),
            hints_remaining=self._hints_remaining,
            hint_given=True,
        )

    def complete(self):
        total = sum(self._stars_per_question)
        item_count = len(self._state.items) if self._state and self._state.items else 0
        mastery = total / (item_count * 3) if item_count > 0 else 0.0
        return CompletionResult(
            total_stars=total,
            badges_unlocked=["Sao dau tien"] if total > 0 else [],
            rewards_unlocked=[],
            mastery_score=min(1.0, mastery),
        )

    def save_progress(self):
        return ProgressSnapshot(
            game_type=self.config.game_type,
            child_id="",
            level=self._state.level if self._state else 1,
            current_index=self._state.current_index if self._state else 0,
            stars_earned=self._stars_per_question,
            hints_used=self.config.hints_per_level - self._hints_remaining,
            is_complete=self._state.current_index >= len(self._state.items)
            if self._state
            else False,
        )

    def dispose(self) -> None:
        self._state = None

    def _calculate_stars_for_question(self) -> int:
        if self._retry_count == 0:
            return 3
        elif self._retry_count == 1:
            return 2
        return 1
