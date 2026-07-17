import 'package:mi_game_core/mi_game_core.dart';

import 'content_loader.dart';
import 'content_validator.dart';

/// Provides levels for a game from bundled JSON or a content source.
///
/// All content must go through this provider — games never load their own data.
class GameContentProvider {
  GameContentProvider({
    ContentValidator? validator,
  }) : validator = validator ?? const ContentValidator();

  final ContentValidator validator;
  final Map<String, List<MiLevel>> _levelCache = {};

  /// Load levels from pre-parsed JSON data.
  ///
  /// Validates all levels; throws [ContentLoadException] if any are invalid.
  Future<List<MiLevel>> loadLevels(
    List<Map<String, dynamic>> levelData, {
    required String gameId,
  }) async {
    final result = validator.validateGameLevels(levelData);
    if (!result.isValid) {
      throw ContentLoadException(
        'Invalid content for $gameId:\n${result.errors.join("\n")}',
      );
    }

    final levels = ContentLoader.parseLevels(levelData, gameId: gameId);
    _levelCache[gameId] = levels;
    return levels;
  }

  /// Get a specific level by gameId and levelNumber.
  MiLevel? getLevel(String gameId, int levelNumber) {
    final levels = _levelCache[gameId];
    if (levels == null) return null;
    return levels.cast<MiLevel?>().firstWhere(
          (l) => l!.levelNumber == levelNumber,
          orElse: () => null,
        );
  }

  /// Get all levels for a game (already loaded).
  List<MiLevel> getLevels(String gameId) {
    return _levelCache[gameId] ?? [];
  }

  /// Clear cache (for memory management or testing).
  void clearCache([String? gameId]) {
    if (gameId != null) {
      _levelCache.remove(gameId);
    } else {
      _levelCache.clear();
    }
  }
}
