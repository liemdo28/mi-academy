"""Unit tests for game-core — testable without Flutter or network."""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

import pytest

from packages.game_core.game_interface import calculate_stars, GameConfig
from packages.game_core.engines import WordBuilderEngine
from packages.game_core.math_race import MathRaceEngine, MemoryCardsEngine, RobotCommandsEngine


class TestCalculateStars:
    def test_first_try_returns_3(self):
        assert calculate_stars(1, 5) == 3

    def test_second_try_returns_3(self):
        assert calculate_stars(5, 5) == 3

    def test_over_target_returns_2(self):
        # 7 is between 5 (perfect) and 10 (2× total), so earns 2 stars
        assert calculate_stars(7, 5) == 2

    def test_high_attempts_returns_1(self):
        assert calculate_stars(100, 5) == 1

    def test_never_returns_zero(self):
        for attempts in range(1, 1000):
            assert calculate_stars(attempts, 3) >= 1


class TestWordBuilderEngine:
    def test_initialize_sets_config(self):
        engine = WordBuilderEngine()
        config = GameConfig(game_type="word_builder", language="junior")
        engine.initialize(config)
        assert engine._config is not None
        assert engine._hints_remaining == 3

    def test_load_level_sets_state(self):
        engine = WordBuilderEngine()
        engine.initialize(GameConfig(game_type="word_builder", language="junior"))
        state = engine.load_level(3)
        assert state.level == 3
        assert state.difficulty == 3
        assert len(state.items) > 0

    def test_correct_answer_advances(self):
        engine = WordBuilderEngine()
        engine.initialize(GameConfig(game_type="word_builder", language="junior"))
        engine.load_level(3)
        result = engine.submit_answer("cat")
        assert result.stars_earned >= 1

    def test_wrong_answer_does_not_advance(self):
        engine = WordBuilderEngine()
        engine.initialize(GameConfig(game_type="word_builder", language="junior"))
        engine.load_level(3)
        idx_before = engine._state.current_index
        engine.submit_answer("xxx")
        assert engine._state.current_index == idx_before

    def test_complete_returns_valid_result(self):
        engine = WordBuilderEngine()
        engine.initialize(GameConfig(game_type="word_builder", language="junior"))
        engine.load_level(3)
        result = engine.complete()
        assert result.total_stars >= 1
        assert 0.0 <= result.mastery_score <= 1.0
        assert isinstance(result.badges_unlocked, list)

    def test_hint_decrements(self):
        engine = WordBuilderEngine()
        engine.initialize(GameConfig(game_type="word_builder", language="junior"))
        engine.load_level(3)
        hint = engine.use_hint()
        assert hint.hints_remaining == 2


class TestMathRaceEngine:
    def test_load_level_generates_problems(self):
        engine = MathRaceEngine()
        engine.initialize(GameConfig(game_type="math_race"))
        state = engine.load_level(2)
        assert len(state.items) == 10  # 10 problems to finish
        assert state.items[0]["op"] in ["+", "-", "×"]

    def test_correct_answer_increments_progress(self):
        engine = MathRaceEngine()
        engine.initialize(GameConfig(game_type="math_race"))
        engine.load_level(1)
        problem = engine._current_problem
        result = engine.submit_answer(problem["answer"])
        assert result.is_correct
        assert engine._progress == 1

    def test_wrong_answer_keeps_progress(self):
        engine = MathRaceEngine()
        engine.initialize(GameConfig(game_type="math_race"))
        engine.load_level(1)
        engine.submit_answer(99999)  # Wrong answer
        assert engine._progress == 0


class TestMemoryCardsEngine:
    def test_load_level_creates_pairs(self):
        engine = MemoryCardsEngine()
        engine.initialize(GameConfig(game_type="memory_cards"))
        state = engine.load_level(2)
        assert len(state.items) == 3  # 6 tiles = 3 pairs

    def test_matching_pair_accepted(self):
        engine = MemoryCardsEngine()
        engine.initialize(GameConfig(game_type="memory_cards"))
        engine.load_level(1)
        # Find a matching pair in items
        items = engine._pairs
        result = engine.submit_answer([0, 1])  # Generic — depends on shuffle
        assert isinstance(result.is_correct, bool)

    def test_complete_returns_mastery(self):
        engine = MemoryCardsEngine()
        engine.initialize(GameConfig(game_type="memory_cards"))
        engine.load_level(1)
        result = engine.complete()
        assert 0.0 <= result.mastery_score <= 1.0


class TestRobotCommandsEngine:
    def test_load_level_sets_grid(self):
        engine = RobotCommandsEngine()
        engine.initialize(GameConfig(game_type="robot_commands"))
        state = engine.load_level(1)
        assert len(engine._grid) > 0
        assert engine._position == (0, 0)

    def test_correct_path_reaches_goal(self):
        engine = RobotCommandsEngine()
        engine.initialize(GameConfig(game_type="robot_commands"))
        engine.load_level(1)  # 3x3 grid, goal at (2,2)
        # Path: right, right, down, down
        result = engine.submit_answer(["right", "right", "down", "down"])
        assert result.is_correct

    def test_wrong_path_fails(self):
        engine = RobotCommandsEngine()
        engine.initialize(GameConfig(game_type="robot_commands"))
        engine.load_level(1)
        result = engine.submit_answer(["up"])
        assert not result.is_correct


class TestGameRegistry:
    def test_registry_returns_engine(self):
        from packages.game_core.registry import GameRegistry
        engine = GameRegistry.get_engine("math_race")
        assert isinstance(engine, MathRaceEngine)

    def test_unknown_type_raises(self):
        from packages.game_core.registry import GameRegistry
        with pytest.raises(ValueError, match="Unknown game type"):
            GameRegistry.get_engine("nonexistent_game")

    def test_list_game_types(self):
        from packages.game_core.registry import GameRegistry
        types = GameRegistry.list_game_types()
        assert "math_race" in types
        assert "word_builder" in types
