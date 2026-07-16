from packages.game_core.games.word_builder import WordBuilderGame
from packages.game_core.games.sound_match import SoundMatchGame
from packages.game_core.games.math_race import MathRaceGame
from packages.game_core.games.math_supermarket import MathSupermarketGame
from packages.game_core.games.memory_cards import MemoryCardsGame
from packages.game_core.games.robot_commands import RobotCommandsGame
from packages.game_core.registry import GameRegistry

GameRegistry.register("word_builder", WordBuilderGame)
GameRegistry.register("sound_match", SoundMatchGame)
GameRegistry.register("math_race", MathRaceGame)
GameRegistry.register("math_supermarket", MathSupermarketGame)
GameRegistry.register("memory_cards", MemoryCardsGame)
GameRegistry.register("robot_commands", RobotCommandsGame)

__all__ = ["WordBuilderGame", "SoundMatchGame", "MathRaceGame", "MathSupermarketGame", "MemoryCardsGame", "RobotCommandsGame"]
