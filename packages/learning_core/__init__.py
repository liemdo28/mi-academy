"""Learning Core — difficulty adaptation + rewards engine."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional


@dataclass
class AdaptationResult:
    recommended_level: int
    reason: str
    silently: bool = False  # Never tell child they're being demoted


class DifficultyAdapter:
    """Adapt difficulty based on child's recent performance.
    
    Rules:
    - ≥85% correct AND avg hints ≤ 1 AND stable response time → level+1
    - <50% correct OR repeated hints → level-1 (silent, no UI message)
    """

    def __init__(self, current_level: int = 1, max_level: int = 10):
        self.current_level = current_level
        self.max_level = max_level
        self._history: list[dict] = []  # [{correct, hints_used, response_time_ms}]

    def record_attempt(self, is_correct: bool, hints_used: int, response_time_ms: int) -> None:
        self._history.append({
            "correct": is_correct,
            "hints_used": hints_used,
            "response_time_ms": response_time_ms,
        })
        # Keep last 5 attempts for sliding window
        if len(self._history) > 5:
            self._history = self._history[-5:]

    def evaluate(self) -> AdaptationResult:
        if len(self._history) < 3:
            return AdaptationResult(
                recommended_level=self.current_level,
                reason="Not enough data yet",
            )

        recent = self._history[-3:]
        correct_count = sum(1 for a in recent if a["correct"])
        correct_rate = correct_count / len(recent)
        avg_hints = sum(a["hints_used"] for a in recent) / len(recent)
        avg_time = sum(a["response_time_ms"] for a in recent) / len(recent)

        # Promote: excellent performance
        if correct_rate >= 0.85 and avg_hints <= 1 and avg_time < 5000:
            new_level = min(self.current_level + 1, self.max_level)
            return AdaptationResult(
                recommended_level=new_level,
                reason=f"Excellent! {correct_rate*100:.0f}% correct, {avg_hints:.1f} hints avg",
            )

        # Demote: struggling
        if correct_rate < 0.50 or avg_hints >= 2:
            new_level = max(self.current_level - 1, 1)
            return AdaptationResult(
                recommended_level=new_level,
                reason="Adjusting difficulty",
                silently=True,  # Never show demotion UI to child
            )

        return AdaptationResult(
            recommended_level=self.current_level,
            reason=f"Holding at level {self.current_level}",
        )


class RewardEngine:
    """Evaluate badge/reward unlocks after game completion."""

    BADGE_DEFINITIONS = {
        "first_lesson": {"type": "first_completion", "trigger": 1},
        "word_master": {"type": "word_builder_3stars", "trigger": 1},
        "math_whiz": {"type": "math_race_3stars", "trigger": 1},
        "math_racer": {"type": "math_race_complete", "trigger": 1},
        "memory_champion": {"type": "memory_cards_100pct", "trigger": 1},
        "robot_coder": {"type": "robot_commands_success", "trigger": 1},
        "perfect_word_builder": {"type": "word_builder_all_correct", "trigger": 1},
    }

    def evaluate(self, game_type: str, completion_data: dict) -> list[str]:
        """Returns list of newly unlocked badge names."""
        unlocked = []
        stars = completion_data.get("total_stars", 1)
        mastery = completion_data.get("mastery_score", 0)
        correct_count = completion_data.get("correct_count", 0)

        # Star-based badges
        if stars == 3:
            if game_type == "word_builder":
                unlocked.append("word_master")
            elif game_type == "math_race":
                unlocked.append("math_whiz")

        # Completion badges
        if completion_data.get("completed", False):
            if game_type == "math_race":
                unlocked.append("math_racer")
            if game_type == "robot_commands":
                unlocked.append("robot_coder")
            if game_type == "memory_cards" and mastery >= 1.0:
                unlocked.append("memory_champion")

        # Perfect score
        if correct_count > 0 and mastery >= 1.0:
            if game_type == "word_builder":
                unlocked.append("perfect_word_builder")

        return unlocked


# ── Universal star rules (never broken) ──────────────────────────────────────────

def compute_stars_for_completion(
    correct_first_try: int,
    total_items: int,
    hints_used: int,
) -> int:
    """
    Stars for a completed game session.
    Rules from PRD:
    - 3 stars: correct on first try
    - 2 stars: needed a retry
    - 1 star: completed (minimum)
    - NEVER subtract stars for wrong answers
    """
    if correct_first_try >= total_items:
        return 3
    elif correct_first_try >= total_items * 0.7:
        return 2
    return 1
