from packages.game_core.difficulty import DifficultyAdapter


class TestDifficultyAdapter:
    def test_init(self):
        a = DifficultyAdapter()
        assert a.get_history("c1", "math") == []

    def test_level_up_high_accuracy(self):
        adapter = DifficultyAdapter()
        for _ in range(3):
            adapter.record_attempt("c1", "math", True, 3000, False)
        assert adapter.get_recommended_level("c1", "math", 3) == 4

    def test_level_down_low_accuracy(self):
        adapter = DifficultyAdapter()
        for _ in range(3):
            adapter.record_attempt("c1", "math", False, 5000, False)
        assert adapter.get_recommended_level("c1", "math", 5) == 4


    def test_stays_same(self):
        adapter = DifficultyAdapter()
        adapter.record_attempt("c1", "math", True, 4000, True)
        adapter.record_attempt("c1", "math", True, 3500, False)
        adapter.record_attempt("c1", "math", False, 4500, False)
        assert adapter.get_recommended_level("c1", "math", 3) == 3

    def test_needs_3_attempts(self):
        adapter = DifficultyAdapter()
        adapter.record_attempt("c1", "math", True, 3000, False)
        adapter.record_attempt("c1", "math", True, 3000, False)
        assert adapter.get_recommended_level("c1", "math", 5) == 5

    def test_max_level_cap(self):
        adapter = DifficultyAdapter()
        for _ in range(3):
            adapter.record_attempt("c1", "math", True, 3000, False)
        assert adapter.get_recommended_level("c1", "math", 10) == 10

    def test_min_level_cap(self):
        adapter = DifficultyAdapter()
        for _ in range(3):
            adapter.record_attempt("c1", "math", False, 5000, False)
        assert adapter.get_recommended_level("c1", "math", 1) == 1

    def test_history_cap_5(self):
        adapter = DifficultyAdapter()
        for _ in range(10):
            adapter.record_attempt("c1", "math", True, 3000, False)
        assert len(adapter.get_history("c1", "math")) == 5

    def test_clear(self):
        adapter = DifficultyAdapter()
        adapter.record_attempt("c1", "math", True, 3000, False)
        adapter.clear_history("c1", "math")
        assert len(adapter.get_history("c1", "math")) == 0
