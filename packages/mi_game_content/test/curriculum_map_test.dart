import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_content/mi_game_content.dart';

Map<String, dynamic> _ageFileJson({
  required String ageGroup,
  required Map<String, List<String>> subjectSkills,
}) {
  return {
    'version': '1.0.0',
    'ageGroup': ageGroup,
    'label': {'vi': 'x', 'en': 'x'},
    'subjects': {
      for (final entry in subjectSkills.entries)
        entry.key: {
          'skills': entry.value,
          'description': {'vi': 'x', 'en': 'x'},
        },
    },
    'dailyTimeMinutes': {'min': 15, 'max': 25},
    'lessonsPerDay': {'min': 1, 'max': 3},
  };
}

void main() {
  test('derives a stable nodeId from ageGroup + subject key', () {
    final map = CurriculumMap.fromAgeFiles([
      _ageFileJson(ageGroup: 'junior', subjectSkills: {
        'letters': ['letters.recognition.uppercase'],
      }),
    ]);

    final node = map.nodeFor(ageGroup: 'junior', subjectId: 'letters');
    expect(node, isNotNull);
    expect(node!.nodeId, 'junior.letters');
    expect(node.skillIds, ['letters.recognition.uppercase']);
  });

  test(
      'returns null for a (age, subject) pair with no node -- e.g. junior '
      'has no science', () {
    final map = CurriculumMap.fromAgeFiles([
      _ageFileJson(ageGroup: 'junior', subjectSkills: {
        'letters': ['letters.recognition.uppercase'],
      }),
    ]);

    expect(map.nodeFor(ageGroup: 'junior', subjectId: 'science'), isNull);
  });

  test('merges multiple age files into one queryable map', () {
    final map = CurriculumMap.fromAgeFiles([
      _ageFileJson(ageGroup: 'junior', subjectSkills: {
        'letters': ['letters.recognition.uppercase'],
      }),
      _ageFileJson(ageGroup: 'explorer', subjectSkills: {
        'science': ['science.observation'],
      }),
    ]);

    expect(map.nodeFor(ageGroup: 'junior', subjectId: 'letters'), isNotNull);
    expect(map.nodeFor(ageGroup: 'explorer', subjectId: 'science'), isNotNull);
    expect(map.nodes, hasLength(2));
  });

  test('nodesContaining finds every node listing a given skill', () {
    final map = CurriculumMap.fromAgeFiles([
      _ageFileJson(ageGroup: 'junior', subjectSkills: {
        'letters': ['letters.recognition.uppercase'],
      }),
    ]);

    expect(
      map.nodesContaining('letters.recognition.uppercase'),
      hasLength(1),
    );
    expect(map.nodesContaining('letters.unknown'), isEmpty);
  });
}
