"""Scoring utilities for MI Academy games."""


def calculate_stars(correct_first_try: bool, total_attempts: int, max_attempts: int = 3) -> int:
    """Returns 1-3 stars. Never returns 0."""
    if total_attempts == 1 and correct_first_try:
        return 3
    elif total_attempts <= 2 and correct_first_try:
        return 2
    else:
        return 1


def calculate_mastery_score(correct_count: int, total_count: int, avg_response_ms: float) -> float:
    """Returns 0.0-1.0 mastery score."""
    if total_count == 0:
        return 0.0
    accuracy = correct_count / total_count
    time_score = max(0.0, 1.0 - (avg_response_ms / 10000))
    return min(1.0, (accuracy * 0.7) + (time_score * 0.3))


def calculate_progress_percentage(completed: int, total: int) -> float:
    if total == 0:
        return 0.0
    return round((completed / total) * 100, 1)
