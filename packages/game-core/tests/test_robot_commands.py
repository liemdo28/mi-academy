from packages.game_core.base import GameConfig
import random
from packages.game_core.games.robot_commands import RobotCommandsGame


class TestRobotCommandsGame:
    def _make_game(self, level=1):
        cfg = GameConfig(game_type="robot_commands")
        g = RobotCommandsGame(cfg)
        g.load_level(level)
        g.start()
        return g

    def test_load_level(self):
        g = self._make_game(1)
        assert g._state is not None
        item = g._state.items[0]
        assert item["size"] >= 5
        assert item["start"] == {"x": 0, "y": 0, "dir": 0}

    def test_empty_commands_no_reach(self):
        g = self._make_game(1)
        r = g.submit_answer([])
        assert r.is_correct is False

    def test_no_obstacles_level1(self):
        import random
        random.seed(0)
        cfg = GameConfig(game_type="robot_commands")
        g = RobotCommandsGame(cfg)
        g.load_level(1)
        item = g._state.items[0]
        assert len(item["obstacles"]) == 0

    def test_manual_path_to_goal(self):
        cfg = GameConfig(game_type="robot_commands")
        g = RobotCommandsGame(cfg)
        found = False
        for seed in range(50):
            random.seed(seed)
            g.load_level(1)
            item = g._state.items[0]
            grid = item["grid"]
            size = item["size"]
            east_ok = all(grid[0][x] == 0 for x in range(1, size))
            south_ok = all(grid[y][size - 1] == 0 for y in range(1, size))
            if east_ok and south_ok:
                cmds = ["turn_right"] + ["forward"] * (size - 1) + ["turn_right"] + ["forward"] * (size - 1)
                g.start()
                r = g.submit_answer(cmds)
                if r.is_correct:
                    assert r.stars_earned >= 1
                    found = True
                    break
        assert found
