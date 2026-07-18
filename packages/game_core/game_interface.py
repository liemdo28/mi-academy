"""MI Academy — Game Engine Core
Pure Python implementation of all 6 game engines.
Each engine is testable without Flutter or network dependencies.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any, Optional


# ── Core Types ──────────────────────────────────────────────────────────────────


@dataclass
class GameConfig:
    game_type: str
    language: str = "vi"
    max_level: int = 10
    hints_per_level: int = 3
    time_limit_seconds: Optional[int] = None  # None = no pressure


@dataclass
class LevelState:
    level: int
    items: list[Any]
    difficulty: int
    current_index: int = 0


@dataclass
class AnswerResult:
    is_correct: bool
    correct_answer: Any
    explanation: Optional[str] = None
    next_state: Optional[LevelState] = None
    stars_earned: int = 1  # 1..3, never 0
    hints_remaining: int = 3


@dataclass
class HintResult:
    hint_text: str
    hint_asset: Optional[str] = None
    hints_remaining: int = 2


@dataclass
class CompletionResult:
    total_stars: int  # ≥ 1 always
    badges_unlocked: list[str]
    rewards_unlocked: list[str]
    mastery_score: float  # 0..1


@dataclass
class ProgressSnapshot:
    game_type: str
    level: int
    current_index: int
    hints_used: int
    attempt_count: int
    answers: list[dict]  # [{index, correct, time_ms}]


# ── Game Interface ──────────────────────────────────────────────────────────────


class GameInterface(ABC):
    """Abstract base for all MI Academy game engines."""

    def __init__(self):
        self._config: Optional[GameConfig] = None
        self._state: Optional[LevelState] = None
        self._hints_remaining: int = 3
        self._attempt_count: int = 0
        self._answers: list[dict] = []
        self._started: bool = False

    def initialize(self, config: GameConfig) -> None:
        self._config = config
        self._hints_remaining = config.hints_per_level
        self._attempt_count = 0
        self._answers = []
        self._started = False

    @abstractmethod
    def load_level(self, level: int) -> LevelState:
        """Load level data and return initial state."""
        ...

    def start(self) -> None:
        self._started = True

    def pause(self) -> None:
        pass  # State is already in memory; nothing to persist here

    def resume(self) -> None:
        pass

    @abstractmethod
    def submit_answer(self, answer: Any) -> AnswerResult: ...

    def use_hint(self) -> HintResult:
        if self._hints_remaining <= 0:
            return HintResult(hint_text="Không còn gợi ý nào!", hints_remaining=0)
        hint = self._generate_hint()
        self._hints_remaining -= 1
        return HintResult(hint_text=hint, hints_remaining=self._hints_remaining)

    @abstractmethod
    def _generate_hint(self) -> str: ...

    @abstractmethod
    def complete(self) -> CompletionResult: ...

    def save_progress(self) -> ProgressSnapshot:
        return ProgressSnapshot(
            game_type=self._config.game_type if self._config else "unknown",
            level=self._state.level if self._state else 1,
            current_index=self._state.current_index if self._state else 0,
            hints_used=self._config.hints_per_level - self._hints_remaining
            if self._config
            else 0,
            attempt_count=self._attempt_count,
            answers=self._answers,
        )

    def dispose(self) -> None:
        self._config = None
        self._state = None


# ── Stars calculation ───────────────────────────────────────────────────────────


def calculate_stars(attempt_count: int, total_items: int) -> int:
    """Stars: 3=first try, 2=retry, 1=completed.
    Never returns 0. Minimum 1 star on completion."""
    if attempt_count <= total_items:
        return 3
    elif attempt_count <= total_items * 2:
        return 2
    return 1
