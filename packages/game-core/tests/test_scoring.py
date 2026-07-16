import pytest
from packages.game_core.scoring import calculate_stars, calculate_mastery_score, calculate_progress_percentage


class TestCalculateStars:
    def test_correct_first_try(self):
        assert calculate_stars(True, 1) == 3

    def test_wrong_then_correct(self):
        assert calculate_stars(True, 2) == 2

    def test_correct_second_try(self):
        assert calculate_stars(True, 2) == 2

    def test_three_attempts(self):
        assert calculate_stars(True, 3) == 1

    def test_multiple_wrong(self):
        assert calculate_stars(False, 3) == 1

    def test_never_zero(self):
        for tries in range(1, 10):
            assert calculate_stars(False, tries) >= 1

    def test_custom_max(self):
        result = calculate_stars(True, 1, max_attempts=5)
        assert result == 3


class TestMasteryScore:
    def test_zero_total(self):
        assert calculate_mastery_score(0, 0, 0) == 0.0

    def test_perfect_accuracy_fast(self):
        score = calculate_mastery_score(10, 10, 1000)
        assert score > 0.9

    def test_perfect_accuracy_slow(self):
        score = calculate_mastery_score(10, 10, 8000)
        assert 0.6 < score <= 1.0

    def test_half_accuracy(self):
        score = calculate_mastery_score(5, 10, 3000)
        assert 0.3 < score < 0.7

    def test_zero_accuracy(self):
        score = calculate_mastery_score(0, 10, 3000)
        assert 0.0 <= score < 0.3

    def test_bounds(self):
        assert 0.0 <= calculate_mastery_score(0, 0, 0) <= 1.0
        assert 0.0 <= calculate_mastery_score(100, 100, 0) <= 1.0


class TestProgressPercentage:
    def test_zero_total(self):
        assert calculate_progress_percentage(0, 0) == 0.0

    def test_half(self):
        assert calculate_progress_percentage(5, 10) == 50.0

    def test_full(self):
        assert calculate_progress_percentage(10, 10) == 100.0

    def test_none(self):
        assert calculate_progress_percentage(3, 7) == round((3/7)*100, 1)
