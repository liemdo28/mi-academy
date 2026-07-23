import 'package:mi_game_core/mi_game_core.dart';

import 'canonical_activity_mapping.dart';
import 'curriculum_map.dart';
import 'skill_taxonomy.dart';

/// A stable machine ID looks like `letters.recognition.uppercase`, not
/// like a localized display string -- lowercase, digits, dot/underscore
/// separators only. Every skill ID this resolver touches is checked
/// against this, so a future content author accidentally wiring a display
/// name in as an ID (e.g. "Nhận biết chữ hoa") is caught immediately
/// rather than silently treated as a valid-but-unknown skill.
final _stableIdPattern = RegExp(r'^[a-z][a-z0-9_.]*$');

/// The minimal, package-agnostic description of a game this resolver
/// needs. Deliberately not `GameRegistry` itself: `GameRegistry` lives in
/// `apps/mobile` (the app layer), and this package must not depend
/// upward on it -- callers construct a [GameDescriptor] from their own
/// registry instead.
class GameDescriptor {
  const GameDescriptor({
    required this.gameId,
    required this.subjectId,
    required this.ageBands,
  });

  final String gameId;

  /// The game's own registered category (e.g. `GameRegistryEntry.category`)
  /// -- 'letters' | 'math' | 'logic' today. Used only as a fallback and a
  /// cross-check; the taxonomy's per-skill `subjectId` is authoritative.
  final String subjectId;
  final List<String> ageBands;
}

/// Resolves a (game, level) pair into a [CanonicalActivityMapping] against
/// the real, already-authored content:
/// [SkillTaxonomy] (content/skills/skill_taxonomy.json) for skill identity,
/// prerequisites, and subject ownership, and [CurriculumMap]
/// (content/curriculum/age_*.json) for curriculum position. Never derives
/// skill/subject identity from a game name or a localized display string.
///
/// Fully offline: both inputs are already-parsed in-memory data, no I/O.
/// Construct one instance per app session (or per taxonomy/curriculum
/// version) and reuse it -- [SkillTaxonomy] and [CurriculumMap] already
/// cache their own lookups, so repeated [resolve] calls are cheap.
class ActivityMappingResolver {
  const ActivityMappingResolver({
    required this.taxonomy,
    required this.curriculum,
  });

  final SkillTaxonomy taxonomy;
  final CurriculumMap curriculum;

  ActivityMappingResult resolve({
    required GameDescriptor game,
    required MiLevel level,
  }) {
    final errors = <MappingValidationError>[];
    final skillIds = level.skillTags;

    if (skillIds.isEmpty) {
      errors.add(MappingValidationError(
        severity: MappingErrorSeverity.fatal,
        code: 'NO_SKILL_MAPPING',
        message: 'Level has no metadata.skillIds -- cannot resolve a '
            'canonical mapping.',
        gameId: game.gameId,
        levelId: level.id,
      ));
      return ActivityMappingResult(mapping: null, errors: errors);
    }

    for (final skillId in skillIds) {
      if (!_stableIdPattern.hasMatch(skillId)) {
        errors.add(MappingValidationError(
          severity: MappingErrorSeverity.fatal,
          code: 'SKILL_ID_LOOKS_LIKE_DISPLAY_NAME',
          message: '"$skillId" does not look like a stable machine ID '
              '(expected lowercase.dot.separated).',
          gameId: game.gameId,
          levelId: level.id,
        ));
      } else if (!taxonomy.hasSkill(skillId)) {
        errors.add(MappingValidationError(
          severity: MappingErrorSeverity.fatal,
          code: 'UNKNOWN_SKILL_ID',
          message: '"$skillId" is not defined in skill_taxonomy.json.',
          gameId: game.gameId,
          levelId: level.id,
        ));
      }
    }

    if (errors.any((e) => e.severity == MappingErrorSeverity.fatal)) {
      return ActivityMappingResult(mapping: null, errors: errors);
    }

    final primarySkillId = skillIds.first;
    final secondarySkillIds = skillIds.skip(1).toList();
    final primarySkill = taxonomy.skill(primarySkillId)!;
    final subjectId = primarySkill.subjectId;

    if (subjectId != game.subjectId) {
      errors.add(MappingValidationError(
        severity: MappingErrorSeverity.warning,
        code: 'GAME_CATEGORY_SKILL_SUBJECT_MISMATCH',
        message: "Game is registered under category '${game.subjectId}' but "
            "its primary skill '$primarySkillId' belongs to taxonomy "
            "subject '$subjectId'.",
        gameId: game.gameId,
        levelId: level.id,
      ));
    }

    final ageGroup = level.ageBand ?? game.ageBands.firstOrNull;
    final curriculumNodeId = ageGroup == null
        ? null
        : curriculum.nodeFor(ageGroup: ageGroup, subjectId: subjectId)?.nodeId;
    if (curriculumNodeId == null) {
      errors.add(MappingValidationError(
        severity: MappingErrorSeverity.warning,
        code: 'NO_CURRICULUM_NODE',
        message: 'No curriculum node for ageGroup=$ageGroup, '
            'subjectId=$subjectId.',
        gameId: game.gameId,
        levelId: level.id,
      ));
    }

    if (level.difficulty < primarySkill.difficultyMin ||
        level.difficulty > primarySkill.difficultyMax) {
      errors.add(MappingValidationError(
        severity: MappingErrorSeverity.warning,
        code: 'DIFFICULTY_OUT_OF_TAXONOMY_RANGE',
        message: 'Level difficulty ${level.difficulty} is outside '
            "'$primarySkillId' taxonomy range "
            '${primarySkill.difficultyMin}-${primarySkill.difficultyMax}.',
        gameId: game.gameId,
        levelId: level.id,
      ));
    }

    final mapping = CanonicalActivityMapping(
      gameId: game.gameId,
      levelId: level.id,
      activityId: level.id,
      primarySkillId: primarySkillId,
      secondarySkillIds: secondarySkillIds,
      subjectId: subjectId,
      curriculumNodeId: curriculumNodeId,
      difficulty: level.difficulty,
      prerequisites: primarySkill.prerequisites,
      supportedLocales: level.localizedContent.keys.toList(),
      contentPackId: game.gameId,
    );

    return ActivityMappingResult(mapping: mapping, errors: errors);
  }

  /// Cross-mapping check: two different (gameId, levelId) pairs must never
  /// resolve to the same [CanonicalActivityMapping.activityId] -- that
  /// would mean two incompatible activities are sharing one identity (mastery
  /// evidence, snapshots, and analytics all key off `activityId`/`levelId`).
  static List<MappingValidationError> findDuplicateActivityIds(
    List<CanonicalActivityMapping> mappings,
  ) {
    final seen = <String, CanonicalActivityMapping>{};
    final errors = <MappingValidationError>[];
    for (final mapping in mappings) {
      final existing = seen[mapping.activityId];
      if (existing != null && existing.gameId != mapping.gameId) {
        errors.add(MappingValidationError(
          severity: MappingErrorSeverity.fatal,
          code: 'DUPLICATE_ACTIVITY_ID',
          message: "activityId '${mapping.activityId}' is shared by "
              "${existing.gameId} and ${mapping.gameId}.",
          gameId: mapping.gameId,
          levelId: mapping.levelId,
        ));
      } else {
        seen[mapping.activityId] = mapping;
      }
    }
    return errors;
  }

  /// Taxonomy skills that no resolved mapping covers -- the reverse audit
  /// ("taxonomy skills with no activity coverage").
  static List<String> findOrphanSkills(
    SkillTaxonomy taxonomy,
    List<CanonicalActivityMapping> mappings,
  ) {
    final covered = <String>{
      for (final m in mappings) ...[m.primarySkillId, ...m.secondarySkillIds],
    };
    return [
      for (final subject in taxonomy.subjects)
        for (final skill in subject.skills)
          if (!covered.contains(skill.skillId)) skill.skillId,
    ];
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
