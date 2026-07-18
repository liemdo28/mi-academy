"""Adaptive difficulty adjustment for MI Academy games."""


class DifficultyAdapter:
    def __init__(self):
        self._attempt_history = {}

    def record_attempt(self, child_id, game_type, is_correct, response_ms, hint_used):
        key = f"{child_id}:{game_type}"
        if key not in self._attempt_history:
            self._attempt_history[key] = []
        self._attempt_history[key].append(
            {
                "is_correct": is_correct,
                "response_ms": response_ms,
                "hint_used": hint_used,
            }
        )
        if len(self._attempt_history[key]) > 5:
            self._attempt_history[key] = self._attempt_history[key][-5:]

    def get_recommended_level(self, child_id, game_type, current_level):
        key = f"{child_id}:{game_type}"
        attempts = self._attempt_history.get(key, [])
        if len(attempts) < 3:
            return current_level
        recent = attempts[-3:]
        correct_count = sum(1 for a in recent if a["is_correct"])
        accuracy = correct_count / len(recent)
        avg_hints = sum(1 for a in recent if a["hint_used"]) / len(recent)
        avg_time = sum(a["response_ms"] for a in recent) / len(recent)
        if accuracy >= 0.85 and avg_hints <= 1.0 and avg_time < 8000:
            return min(current_level + 1, 10)
        if accuracy < 0.5 or avg_hints >= 2.0:
            return max(current_level - 1, 1)
        return current_level

    def get_history(self, child_id, game_type):
        return self._attempt_history.get(f"{child_id}:{game_type}", [])

    def clear_history(self, child_id, game_type):
        key = f"{child_id}:{game_type}"
        if key in self._attempt_history:
            del self._attempt_history[key]
