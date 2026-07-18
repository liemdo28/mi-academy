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
    this.contentVersion = 1,
    this.estimatedSeconds = 60,
    this.publicationState = 'published',
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

  /// Content revision within this level's stable [id] -- bumped when a
  /// level's wording/answer/asset references change so a previously-saved
  /// snapshot referencing an older revision can be recognized as stale
  /// (see docs/content-schema.md's migration policy). Independent of the
  /// file-level `schemaVersion` in assets/levels/*.json, which versions the
  /// envelope shape itself, not any one level's content.
  final int contentVersion;

  /// Rough expected time-to-complete, for parent-facing duration estimates
  /// and daily-plan scheduling. Not enforced as a timer.
  final int estimatedSeconds;

  /// One of 'draft' | 'published' | 'archived' (see docs/content-schema.md).
  /// [ContentLoader] only returns levels the caller explicitly asked for by
  /// game/locale, so this is informational metadata today, not itself a
  /// filter -- content authoring/admin tooling is the enforcement point.
  final String publicationState;

  /// This level's age band, per docs/age-bands.md ('junior' | 'explorer' |
  /// 'master'). Sourced from `metadata.ageGroup` -- kept as a computed
  /// accessor rather than a duplicated stored field so there is exactly one
  /// place (`metadata`) that can disagree with itself.
  String? get ageBand => metadata['ageGroup'] as String?;

  /// This level's skill taxonomy tags (content/skills/skill_taxonomy.json),
  /// sourced from `metadata.skillIds`. See [ageBand] for why this is
  /// computed rather than a separate stored field.
  List<String> get skillTags =>
      (metadata['skillIds'] as List?)?.map((e) => e.toString()).toList() ??
      const [];

  /// Get localized content for a given locale, falling back to Vietnamese,
  /// then to whatever locale is actually present -- deterministic fallback
  /// chain per docs/localization.md (never silently show an empty screen).
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
        contentVersion,
        estimatedSeconds,
        publicationState,
      ];
}
