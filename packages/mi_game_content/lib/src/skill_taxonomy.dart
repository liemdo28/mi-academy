import 'package:equatable/equatable.dart';

/// Evidence thresholds a skill needs before mastery evaluation trusts an
/// attempt (content/skills/skill_taxonomy.json's `evidenceRules`).
class SkillEvidenceRules extends Equatable {
  const SkillEvidenceRules({
    required this.minimumAttempts,
    required this.minimumAccuracy,
    required this.maximumHintRatio,
  });

  final int minimumAttempts;
  final double minimumAccuracy;
  final double maximumHintRatio;

  factory SkillEvidenceRules.fromJson(Map<String, dynamic> json) {
    return SkillEvidenceRules(
      minimumAttempts: json['minimumAttempts'] as int,
      minimumAccuracy: (json['minimumAccuracy'] as num).toDouble(),
      maximumHintRatio: (json['maximumHintRatio'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props =>
      [minimumAttempts, minimumAccuracy, maximumHintRatio];
}

/// One node in the knowledge graph -- a single learnable competency, with
/// its prerequisites, target age band, and difficulty range. This is the
/// canonical, machine-stable identity for a skill; `name` is display-only
/// and must never be used as an identifier (see
/// `ActivityMappingResolver`'s `localizedNameUsedAsId` check).
class SkillDefinition extends Equatable {
  const SkillDefinition({
    required this.skillId,
    required this.subjectId,
    required this.name,
    required this.ageGroup,
    required this.difficultyMin,
    required this.difficultyMax,
    required this.prerequisites,
    required this.evidenceRules,
  });

  final String skillId;
  final String subjectId;
  final Map<String, String> name;
  final String ageGroup;
  final int difficultyMin;
  final int difficultyMax;
  final List<String> prerequisites;
  final SkillEvidenceRules evidenceRules;

  factory SkillDefinition.fromJson(
      String subjectId, Map<String, dynamic> json) {
    return SkillDefinition(
      skillId: json['skillId'] as String,
      subjectId: subjectId,
      name: Map<String, String>.from(json['name'] as Map),
      ageGroup: json['ageGroup'] as String,
      difficultyMin: json['difficultyMin'] as int,
      difficultyMax: json['difficultyMax'] as int,
      prerequisites:
          (json['prerequisites'] as List).map((e) => e as String).toList(),
      evidenceRules: SkillEvidenceRules.fromJson(
        json['evidenceRules'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  List<Object?> get props => [
        skillId,
        subjectId,
        name,
        ageGroup,
        difficultyMin,
        difficultyMax,
        prerequisites,
        evidenceRules,
      ];
}

class SubjectDefinition extends Equatable {
  const SubjectDefinition({
    required this.subjectId,
    required this.name,
    required this.skills,
  });

  final String subjectId;
  final Map<String, String> name;
  final List<SkillDefinition> skills;

  factory SubjectDefinition.fromJson(Map<String, dynamic> json) {
    final subjectId = json['subjectId'] as String;
    return SubjectDefinition(
      subjectId: subjectId,
      name: Map<String, String>.from(json['name'] as Map),
      skills: (json['skills'] as List)
          .map((e) =>
              SkillDefinition.fromJson(subjectId, e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [subjectId, name, skills];
}

/// Parsed, queryable form of `content/skills/skill_taxonomy.json` -- the
/// ONE knowledge graph for MI Academy. Deliberately does not duplicate or
/// extend `content_sdk`'s `Skill`/`Curriculum` models: those use an
/// incompatible subject vocabulary (`language`/`creativity` vs this file's
/// `letters`/`creative`) and are not loaded by any real game content --
/// building on them would have created a second, conflicting taxonomy.
class SkillTaxonomy {
  SkillTaxonomy({
    required this.version,
    required this.subjects,
    required this.masteryThreshold,
    required this.reviewIntervalDays,
    required this.spacedRecallDays,
  });

  final String version;
  final List<SubjectDefinition> subjects;
  final double masteryThreshold;
  final int reviewIntervalDays;
  final int spacedRecallDays;

  factory SkillTaxonomy.fromJson(Map<String, dynamic> json) {
    return SkillTaxonomy(
      version: json['version'] as String,
      subjects: (json['subjects'] as List)
          .map((e) => SubjectDefinition.fromJson(e as Map<String, dynamic>))
          .toList(),
      masteryThreshold: (json['masteryThreshold'] as num).toDouble(),
      reviewIntervalDays: json['reviewIntervalDays'] as int,
      spacedRecallDays: json['spacedRecallDays'] as int,
    );
  }

  late final Map<String, SkillDefinition> _bySkillId = {
    for (final subject in subjects)
      for (final skill in subject.skills) skill.skillId: skill,
  };

  /// O(1) lookup by stable skill ID, cached once per [SkillTaxonomy]
  /// instance -- callers (the resolver, [AdaptiveLearningService]) should
  /// construct one [SkillTaxonomy] per app session and reuse it rather
  /// than re-parsing JSON per lookup.
  SkillDefinition? skill(String skillId) => _bySkillId[skillId];

  bool hasSkill(String skillId) => _bySkillId.containsKey(skillId);

  /// Self-consistency check of the taxonomy data itself -- every
  /// prerequisite must reference a skill that actually exists, and every
  /// skillId must be unique. Independent of any game/level content.
  List<String> validate() {
    final errors = <String>[];
    final seen = <String>{};
    for (final subject in subjects) {
      for (final skill in subject.skills) {
        if (!seen.add(skill.skillId)) {
          errors.add('Duplicate skillId in taxonomy: ${skill.skillId}');
        }
        for (final prereq in skill.prerequisites) {
          if (!_bySkillId.containsKey(prereq)) {
            errors.add(
              'Skill ${skill.skillId} references missing prerequisite: $prereq',
            );
          }
        }
      }
    }
    return errors;
  }
}
