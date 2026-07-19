import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_content/mi_game_content.dart';

late List<Map<String, dynamic>> levels;

void main() {
  setUpAll(() {
    final file = File('assets/levels/alphabet_explorer.json');
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    levels = (data['levels'] as List)
        .map((level) => Map<String, dynamic>.from(level as Map))
        .toList();
  });

  test('has production-scale bilingual content and three tiers', () {
    expect(levels.length, greaterThanOrEqualTo(80));
    expect(levels.map((level) => level['difficulty']).toSet(), {1, 2, 3});

    for (final level in levels) {
      final localized = level['localizedContent'] as Map<String, dynamic>;
      expect(localized.keys, containsAll(['vi', 'en']));
      for (final locale in const ['vi', 'en']) {
        final content = localized[locale] as Map<String, dynamic>;
        final options = content['options'] as List;
        expect(content['prompt'], isNotEmpty);
        expect(options.length, greaterThanOrEqualTo(3));
        expect(
          options.where((option) => (option as Map)['correct'] == true),
          hasLength(1),
          reason: '${level['id']} $locale must have one correct answer',
        );
      }
    }
  });

  test('covers required Alphabet Explorer content modes', () {
    final kinds = levels
        .map((level) => (level['metadata'] as Map)['contentKind'])
        .toSet();

    expect(
      kinds,
      containsAll([
        'uppercase_recognition',
        'lowercase_recognition',
        'case_matching',
        'first_letter',
        'visual_discrimination',
      ]),
    );
    expect(_countKind('case_matching'), greaterThanOrEqualTo(20));
    expect(_countKind('first_letter'), greaterThanOrEqualTo(20));
    expect(_countKind('visual_discrimination'), greaterThanOrEqualTo(15));
  });

  test('covers English alphabet and Vietnamese extended letters', () {
    final enCorrect = _correctAnswers('en');
    final viCorrect = _correctAnswers('vi');

    for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
      expect(enCorrect, contains(letter), reason: 'Missing English $letter');
    }
    for (final letter in const ['Ă', 'Â', 'Đ', 'Ê', 'Ô', 'Ơ', 'Ư']) {
      expect(viCorrect, contains(letter), reason: 'Missing Vietnamese $letter');
    }
  });

  test('loads through the shared content loader', () async {
    final parsed = await GameContentProvider().loadLevels(
      levels,
      gameId: 'alphabet_explorer',
    );

    expect(parsed, hasLength(levels.length));
    expect(parsed.first.gameId, 'alphabet_explorer');
    expect(parsed.first.contentForLocale('en')['prompt'], isNotEmpty);
    expect(parsed.first.skillTags, contains('letters.recognition.uppercase'));
  });
}

int _countKind(String kind) => levels
    .where((level) => (level['metadata'] as Map)['contentKind'] == kind)
    .length;

Set<String> _correctAnswers(String locale) {
  final answers = <String>{};
  for (final level in levels) {
    final localized = level['localizedContent'] as Map<String, dynamic>;
    final content = localized[locale] as Map<String, dynamic>;
    for (final option in content['options'] as List) {
      final map = option as Map;
      if (map['correct'] == true) {
        answers.add(map['text'] as String);
      }
    }
  }
  return answers;
}
