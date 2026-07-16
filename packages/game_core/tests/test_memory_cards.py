from packages.game_core.base import GameConfig
from packages.game_core.games.memory_cards import MemoryCardsGame


class TestMemoryCardsGame:
    def _make_game(self, level=1):
        cfg = GameConfig(game_type="memory_cards")
        g = MemoryCardsGame(cfg)
        g.load_level(level)
        g.start()
        return g

    def test_load_level_2x2(self):
        g = self._make_game(1)
        assert g._state is not None
        assert len(g._state.items[0]["cards"]) == 4

    def test_load_larger_grid(self):
        g = self._make_game(5)
        assert len(g._state.items[0]["cards"]) == 16

    def test_matching_pair(self):
        g = self._make_game(1)
        cards = g._state.items[0]["cards"]
        symbol_map = {}
        for c in cards:
            symbol_map.setdefault(c["symbol"], []).append(c["index"])
        sym = next(iter(symbol_map))
        i1, i2 = symbol_map[sym][0], symbol_map[sym][1]
        r = g.submit_answer([i1, i2])
        assert r.is_correct is True

    def test_non_matching(self):
        g = self._make_game(1)
        cards = g._state.items[0]["cards"]
        a_sym = cards[0]["symbol"]
        b_idx = next(c["index"] for c in cards if c["symbol"] != a_sym)
        r = g.submit_answer([cards[0]["index"], b_idx])
        assert r.is_correct is False

    def test_no_match_advance(self):
        g = self._make_game(1)
        cards = g._state.items[0]["cards"]
        a_sym = cards[0]["symbol"]
        b_idx = next(c["index"] for c in cards if c["symbol"] != a_sym)
        matched_before = len(g._matched)
        g.submit_answer([cards[0]["index"], b_idx])
        assert len(g._matched) == matched_before

    def test_complete_all_pairs(self):
        g = self._make_game(1)
        cards = g._state.items[0]["cards"]
        symbol_map = {}
        for c in cards:
            symbol_map.setdefault(c["symbol"], []).append(c["index"])
        for sym, idxs in symbol_map.items():
            r = g.submit_answer([idxs[0], idxs[1]])
            assert r.is_correct is True
        assert g.is_complete()

    def test_same_index_rejected(self):
        g = self._make_game(1)
        r = g.submit_answer([0, 0])
        assert r.is_correct is False

    def test_completion_total_stars(self):
        g = self._make_game(1)
        cards = g._state.items[0]["cards"]
        symbol_map = {}
        for c in cards:
            symbol_map.setdefault(c["symbol"], []).append(c["index"])
        for sym, idxs in symbol_map.items():
            g.submit_answer([idxs[0], idxs[1]])
        result = g.complete()
        n_pairs = g._state.total_questions
        expected = n_pairs * 3
        assert result.total_stars == expected
