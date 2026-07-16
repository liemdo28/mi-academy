from typing import Type, Optional


class GameRegistry:
    _games = {}

    @classmethod
    def register(cls, game_type: str, game_class) -> None:
        cls._games[game_type] = game_class

    @classmethod
    def get_game(cls, game_type: str, config) -> "GameEngineBase":
        if game_type not in cls._games:
            raise ValueError(f"Unknown game type: {game_type}")
        return cls._games[game_type](config)

    @classmethod
    def list_games(cls) -> list:
        return list(cls._games.keys())

    @classmethod
    def get_available_games_for_age(cls, age: int) -> list:
        age_map = {5: ["word_builder", "sound_match", "math_race", "memory_cards"],
            6: ["word_builder", "sound_match", "math_race", "memory_cards"],
            7: ["word_builder", "sound_match", "math_race", "memory_cards"],
            8: ["word_builder", "sound_match", "math_race", "math_supermarket", "memory_cards", "robot_commands"],
            9: ["word_builder", "sound_match", "math_race", "math_supermarket", "memory_cards", "robot_commands"],
            10: ["word_builder", "sound_match", "math_race", "math_supermarket", "memory_cards", "robot_commands"],
            11: ["math_race", "math_supermarket", "memory_cards", "robot_commands"],
            12: ["math_race", "math_supermarket", "memory_cards", "robot_commands"],}
        return age_map.get(age, age_map.get(10, []))
