from packages.game_core.base import GameConfig
from packages.game_core.games.math_race import MathRaceGame


class TestMathRaceGame:
    def _make_game(self, level=1):
        cfg = GameConfig(game_type="math_race", max_level=10)
        g = MathRaceGame(cfg)
        g.load_level(level)
        g.start()
        return g

    def test_load_level(self):
        g = self._make_game(1)
        assert g._state is not None
        assert len(g._state.items) == 10

    def test_correct_answer(self):
        g = self._make_game(1)
        item = g._state.items[0]
        correct = item["correct_answer"]
        r = g.submit_answer(correct)
        assert r.is_correct is True
        assert r.stars_earned >= 1

    def test_wrong_answer(self):
        g = self._make_game(1)
        item = g._state.items[0]
        wrong = item["correct_answer"] + 999
        r = g.submit_answer(wrong)
        assert r.is_correct is False
        assert r.retry_allowed is True

    def test_retry_min_1_star(self):
        g = self._make_game(1)
        item = g._state.items[0]
        correct = item["correct_answer"]
        g.submit_answer(-999)
        g.submit_answer(-999)
        r = g.submit_answer(correct)
        assert r.is_correct is True
        assert r.stars_earned >= 1

    def test_completion_perfect(self):
        g = self._make_game(1)
        for _ in range(10):
            item = g._state.items[g._state.current_index]
            correct = item["correct_answer"]
            g.submit_answer(correct)
        result = g.complete()
        assert result.total_stars == 30
        assert result.mastery_score == 1.0

    def test_save_progress(self):
        g = self._make_game(1)
        item = g._state.items[0]
        g.submit_answer(item["correct_answer"])
        p = g.save_progress()
        assert p.current_index == 1
        assert p.is_complete is False

    def test_seed_reproducibility(self):
        cfg = GameConfig(game_type="math_race")
        g1 = MathRaceGame(cfg)
        g1.set_seed(42)
        s1 = g1.load_level(5)
        g2 = MathRaceGame(cfg)
        g2.set_seed(42)
        s2 = g2.load_level(5)
        for i in range(10):
            assert s1.items[i]["correct_answer"] == s2.items[i]["correct_answer"]
