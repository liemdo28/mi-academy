import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_content/mi_game_content.dart';

Map<String, dynamic> _skillJson(
  String id, {
  List<String> prerequisites = const [],
}) {
  return {
    'skillId': id,
    'name': {'vi': 'x', 'en': 'x'},
    'ageGroup': 'junior',
    'difficultyMin': 1,
    'difficultyMax': 3,
    'prerequisites': prerequisites,
    'evidenceRules': {
      'minimumAttempts': 4,
      'minimumAccuracy': 0.75,
      'maximumHintRatio': 0.5,
    },
  };
}

Map<String, dynamic> _taxonomyJson() {
  return {
    'version': '1.0.0',
    'masteryThreshold': 0.8,
    'reviewIntervalDays': 3,
    'spacedRecallDays': 2,
    'subjects': [
      {
        'subjectId': 'letters',
        'name': {'vi': 'x', 'en': 'x'},
        'skills': [
          _skillJson('letters.recognition.uppercase'),
          _skillJson(
            'letters.recognition.lowercase',
            prerequisites: ['letters.recognition.uppercase'],
          ),
        ],
      },
      {
        'subjectId': 'math',
        'name': {'vi': 'x', 'en': 'x'},
        'skills': [_skillJson('math.counting')],
      },
    ],
  };
}

void main() {
  test('parses subjects, skills, and evidence rules', () {
    final taxonomy = SkillTaxonomy.fromJson(_taxonomyJson());

    expect(taxonomy.subjects, hasLength(2));
    final skill = taxonomy.skill('letters.recognition.lowercase');
    expect(skill, isNotNull);
    expect(skill!.subjectId, 'letters');
    expect(skill.prerequisites, ['letters.recognition.uppercase']);
    expect(skill.evidenceRules.minimumAttempts, 4);
  });

  test('hasSkill / skill lookup is O(1) via cached map', () {
    final taxonomy = SkillTaxonomy.fromJson(_taxonomyJson());

    expect(taxonomy.hasSkill('math.counting'), isTrue);
    expect(taxonomy.hasSkill('math.does_not_exist'), isFalse);
    expect(taxonomy.skill('math.does_not_exist'), isNull);
  });

  test('validate() reports missing prerequisite references', () {
    final json = _taxonomyJson();
    (json['subjects'] as List)[1] = {
      'subjectId': 'math',
      'name': {'vi': 'x', 'en': 'x'},
      'skills': [
        _skillJson('math.addition', prerequisites: ['math.missing_skill']),
      ],
    };
    final taxonomy = SkillTaxonomy.fromJson(json);

    final errors = taxonomy.validate();
    expect(
      errors,
      contains(contains('math.addition')),
    );
    expect(errors.single, contains('math.missing_skill'));
  });

  test('validate() reports duplicate skillIds', () {
    final json = _taxonomyJson();
    (json['subjects'] as List)[1] = {
      'subjectId': 'math',
      'name': {'vi': 'x', 'en': 'x'},
      'skills': [
        _skillJson('letters.recognition.uppercase'), // duplicate on purpose
      ],
    };
    final taxonomy = SkillTaxonomy.fromJson(json);

    expect(
      taxonomy.validate(),
      contains(contains('Duplicate skillId')),
    );
  });

  test('validate() finds nothing wrong with a self-consistent taxonomy', () {
    final taxonomy = SkillTaxonomy.fromJson(_taxonomyJson());
    expect(taxonomy.validate(), isEmpty);
  });
}
