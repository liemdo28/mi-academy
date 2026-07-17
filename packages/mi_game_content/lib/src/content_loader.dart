import 'package:mi_game_core/mi_game_core.dart';

/// Loads [MiLevel] from JSON maps (from files, assets, or network).
///
/// Validates basic structure before returning.
class ContentLoader {
  /// Parse a list of level JSON maps into [MiLevel] objects.
  ///
  /// Throws [ContentLoadException] on invalid data.
  static List<MiLevel> parseLevels(
    List<Map<String, dynamic>> levelData, {
    required String gameId,
  }) {
    final levels = <MiLevel>[];
    for (final data in levelData) {
      levels.add(parseLevel(data, gameId: gameId));
    }
    return levels;
  }

  /// Parse a single level JSON map into a [MiLevel].
  static MiLevel parseLevel(
    Map<String, dynamic> data, {
    required String gameId,
  }) {
    final required = ['id', 'levelNumber', 'difficulty', 'localizedContent'];
    for (final field in required) {
      if (!data.containsKey(field)) {
        throw ContentLoadException('Missing required field: $field');
      }
    }

    final localizedContent = <String, Map<String, dynamic>>{};
    final rawContent = data['localizedContent'] as Map<String, dynamic>;
    for (final entry in rawContent.entries) {
      localizedContent[entry.key] =
          Map<String, dynamic>.from(entry.value as Map);
    }

    return MiLevel(
      id: data['id'] as String,
      gameId: data['gameId'] as String? ?? gameId,
      levelNumber: data['levelNumber'] as int,
      difficulty: data['difficulty'] as int,
      learningObjective: data['learningObjective'] as String?,
      localizedContent: localizedContent,
      hints: (data['hints'] as List?)
              ?.map((h) => Map<String, dynamic>.from(h as Map))
              .toList() ??
          [],
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
      assetRefs: (data['assetRefs'] as List?)?.cast<String>() ?? [],
    );
  }
}

class ContentLoadException implements Exception {
  ContentLoadException(this.message);
  final String message;

  @override
  String toString() => 'ContentLoadException: $message';
}
