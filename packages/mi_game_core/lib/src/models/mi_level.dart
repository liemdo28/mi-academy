import 'package:equatable/equatable.dart';

/// Represents a single level within a game.
///
/// All level data comes from JSON — never hardcoded.
/// See schemas/level.schema.json for the full schema definition.
class MiLevel extends Equatable {
  const MiLevel({
    required this.id,
    required this.gameId,
    required this.levelNumber,
    required this.difficulty,
    required this.localizedContent,
    required this.hints,
    this.learningObjective,
    this.metadata = const {},
    this.assetRefs = const [],
    this.accessibilityOverrides,
  });

  /// Unique level identifier (UUID v4 from JSON).
  final String id;

  /// Parent game identifier.
  final String gameId;

  /// Ordinal level number (1-based).
  final int levelNumber;

  /// Difficulty tier (1 = easiest).
  final int difficulty;

  /// Learning objective for this level.
  final String? learningObjective;

  /// Map of locale code → localized content (prompts, options, etc.).
  ///
  /// Example:
  /// ```json
  /// { "vi": { "prompt": "Tìm cặp giống nhau" }, "en": { "prompt": "Find matching pairs" } }
  /// ```
  final Map<String, Map<String, dynamic>> localizedContent;

  /// Ordered hint definitions for this level.
  final List<Map<String, dynamic>> hints;

  /// Extra metadata (game-specific).
  final Map<String, dynamic> metadata;

  /// References to required assets (images, audio, etc.).
  final List<String> assetRefs;

  /// Per-level accessibility overrides (optional).
  final Map<String, dynamic>? accessibilityOverrides;

  /// Get localized content for a given locale, falling back to Vietnamese.
  Map<String, dynamic> contentForLocale(String locale) {
    return localizedContent[locale] ??
        localizedContent['vi'] ??
        localizedContent.values.first;
  }

  @override
  List<Object?> get props => [
        id,
        gameId,
        levelNumber,
        difficulty,
        learningObjective,
        localizedContent,
        hints,
        metadata,
        assetRefs,
        accessibilityOverrides,
      ];
}
