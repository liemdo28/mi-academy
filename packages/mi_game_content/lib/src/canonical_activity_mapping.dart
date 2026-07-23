import 'package:equatable/equatable.dart';

/// How serious a [MappingValidationError] is. `fatal` means
/// [ActivityMappingResult.mapping] is null -- the mapping could not be
/// trusted enough to hand to `AdaptiveLearningService`/`GameScreen`.
/// `warning` means a mapping was still produced, but something about it
/// disagrees with another part of the content (e.g. a game's registered
/// category doesn't match its skill's taxonomy subject).
enum MappingErrorSeverity { fatal, warning }

/// A typed validation finding, always carrying enough context (gameId,
/// levelId, a stable `code`) to be actionable in a CI failure report --
/// never a bare string.
class MappingValidationError extends Equatable {
  const MappingValidationError({
    required this.severity,
    required this.code,
    required this.message,
    required this.gameId,
    required this.levelId,
  });

  final MappingErrorSeverity severity;

  /// Stable machine code, e.g. 'NO_SKILL_MAPPING', 'UNKNOWN_SKILL_ID' --
  /// see [ActivityMappingResolver] for the full set.
  final String code;
  final String message;
  final String gameId;
  final String levelId;

  @override
  List<Object?> get props => [severity, code, message, gameId, levelId];

  @override
  String toString() =>
      '[${severity.name.toUpperCase()}] $code ($gameId/$levelId): $message';
}

/// The canonical, stable-ID mapping for one playable activity. Every field
/// is a machine ID or a plain measurement -- never a localized display
/// string (display names live in [SkillDefinition.name] /
/// [SubjectDefinition.name], looked up separately by whatever UI needs
/// them).
class CanonicalActivityMapping extends Equatable {
  const CanonicalActivityMapping({
    required this.gameId,
    required this.levelId,
    required this.activityId,
    required this.primarySkillId,
    required this.secondarySkillIds,
    required this.subjectId,
    required this.curriculumNodeId,
    required this.difficulty,
    required this.prerequisites,
    required this.supportedLocales,
    required this.contentPackId,
  });

  final String gameId;
  final String levelId;

  /// The playable unit within [levelId]. MI Academy's engines record
  /// attempts/mastery per *level*, not per question within a level (see
  /// `mi_game_progress`'s `AttemptRecord`), so today `activityId == levelId`
  /// -- documented here rather than silently assumed, so a future
  /// finer-grained activity concept (e.g. per-question) has one place to
  /// change this equivalence.
  final String activityId;

  final String primarySkillId;
  final List<String> secondarySkillIds;

  /// Resolved from the taxonomy skill definition, not from the game's own
  /// registered category -- see [ActivityMappingResolver]'s
  /// `GAME_CATEGORY_SKILL_SUBJECT_MISMATCH` warning for when those two
  /// disagree.
  final String subjectId;

  /// Null when this (age band, subject) pair has no curriculum node yet
  /// (e.g. 'junior' has no 'science' node in content/curriculum/age_5_7.json
  /// -- science starts at 'explorer'). Not an error by itself.
  final String? curriculumNodeId;

  final int difficulty;

  /// This activity's primary skill's prerequisites, from the taxonomy --
  /// what `recommendation_core`'s prerequisite checker needs before it can
  /// recommend this activity.
  final List<String> prerequisites;

  final List<String> supportedLocales;

  /// Today, one content pack per game (`apps/mobile/assets/levels/<gameId>.json`
  /// is the only content-pack granularity that exists) -- equals [gameId].
  /// Documented rather than silently assumed, same reasoning as [activityId].
  final String contentPackId;

  @override
  List<Object?> get props => [
        gameId,
        levelId,
        activityId,
        primarySkillId,
        secondarySkillIds,
        subjectId,
        curriculumNodeId,
        difficulty,
        prerequisites,
        supportedLocales,
        contentPackId,
      ];
}

/// The result of resolving one (game, level) pair: either a trustworthy
/// [mapping] (possibly with non-fatal [errors]/warnings attached), or a
/// null mapping with at least one fatal error explaining why.
class ActivityMappingResult extends Equatable {
  const ActivityMappingResult({required this.mapping, required this.errors});

  final CanonicalActivityMapping? mapping;
  final List<MappingValidationError> errors;

  bool get isValid => mapping != null;

  bool get hasFatalErrors =>
      errors.any((e) => e.severity == MappingErrorSeverity.fatal);

  List<MappingValidationError> get warnings =>
      errors.where((e) => e.severity == MappingErrorSeverity.warning).toList();

  @override
  List<Object?> get props => [mapping, errors];
}
