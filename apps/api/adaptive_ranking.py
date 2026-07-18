"""Shared "what should this child do next" ranking.

Used by both GET /lessons/recommended and GET
/progress/children/{id}/daily-plan so the two surfaces agree, using the
signal already recorded for every lesson: Progress.status and
Progress.mastery_score for this child (spaced-repetition-lite -- content
the child is struggling with resurfaces first, content they've mastered is
deprioritized, and new/continuing content is targeted at the difficulty
that matches their demonstrated mastery, not just introduced lowest-first).
"""

from collections.abc import Sequence

from apps.api.models import Lesson, Progress

# Lower sorts first.
STATUS_PRIORITY = {
    "needs_practice": 0,
    "learning": 1,
    "not_started": 2,
    "completed": 3,
    "mastered": 3,
}


def target_difficulty(progress_rows: list[Progress]) -> int:
    scored = [p.mastery_score for p in progress_rows if p.total_attempts > 0]
    if not scored:
        return 1
    avg_mastery = sum(scored) / len(scored)
    return max(1, min(5, round(1 + avg_mastery * 4)))


def rank_lessons(
    lessons: Sequence[Lesson], progress_by_lesson: dict[str, Progress]
) -> list[Lesson]:
    target = target_difficulty(list(progress_by_lesson.values()))

    def _rank(lesson: Lesson) -> tuple[int, int, int]:
        status = (
            progress_by_lesson[lesson.id].status
            if lesson.id in progress_by_lesson
            else "not_started"
        )
        priority = STATUS_PRIORITY.get(status, STATUS_PRIORITY["not_started"])
        return (priority, abs(lesson.difficulty - target), lesson.difficulty)

    return sorted(lessons, key=_rank)
