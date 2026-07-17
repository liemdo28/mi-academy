class GameRegistry:
    _games = {}
    _legacy_engine_types = {
        "word_builder",
        "sound_match",
        "math_race",
        "math_supermarket",
        "memory_cards",
        "robot_commands",
    }

    @classmethod
    def register(cls, game_type: str, game_class) -> None:
        cls._games[game_type] = game_class

    @classmethod
    def get_game(cls, game_type: str, config) -> "GameEngineBase":
        if game_type not in cls._games:
            raise ValueError(f"Unknown game type: {game_type}")
        return cls._games[game_type](config)

    @classmethod
    def get_engine(cls, game_type: str):
        """Return the pure-Python engine used by legacy unit tests and tools."""
        engines = cls._load_legacy_engines()
        if game_type not in engines:
            raise ValueError(f"Unknown game type: {game_type}")
        return engines[game_type]()

    @classmethod
    def list_games(cls) -> list:
        return sorted(set(cls._games.keys()) | cls._legacy_engine_types)

    @classmethod
    def list_game_types(cls) -> list:
        return cls.list_games()

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

    @staticmethod
    def _load_legacy_engines() -> dict:
        from packages.game_core.engines import WordBuilderEngine
        from packages.game_core.math_race import MathRaceEngine, MemoryCardsEngine, RobotCommandsEngine

        # Sound Match and Math Supermarket have production game classes but no
        # standalone legacy engine class in the Python test surface yet.
        return {
            "word_builder": WordBuilderEngine,
            "math_race": MathRaceEngine,
            "memory_cards": MemoryCardsEngine,
            "robot_commands": RobotCommandsEngine,
        }
