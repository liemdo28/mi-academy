import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_content/mi_game_content.dart';

late List<Map<String, dynamic>> levels;

void main() {
  setUpAll(() {
    final file = File('assets/levels/missing_letter.json');
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    levels = (data['levels'] as List)
        .map((level) => Map<String, dynamic>.from(level as Map))
        .toList();
  });

  test('has bilingual production content and three material tiers', () {
    expect(levels.length, 75);
    expect(_countDifficulty(1), 25);
    expect(_countDifficulty(2), 25);
    expect(_countDifficulty(3), 25);

    final tier1Choices = _averageChoiceCount(1);
    final tier3Missing = _averageMissingCount(3);
    expect(tier1Choices, 3);
    expect(tier3Missing, greaterThan(1));

    for (final level in levels) {
      final localized = level['localizedContent'] as Map<String, dynamic>;
      expect(localized.keys, containsAll(['vi', 'en']));
      for (final locale in const ['vi', 'en']) {
        final content = localized[locale] as Map<String, dynamic>;
        expect(content['prompt'], isNotEmpty);
        expect(content['categoryHint'], isNotEmpty);
        expect(content['phonicsHint'], isNotEmpty);
      }
    }
  });

  test('has enough unique target words per locale', () {
    expect(_uniqueWords('vi').length, 75);
    expect(_uniqueWords('en').length, 75);
  });

  test('has exact cue and missing-letter distribution', () {
    expect(_missingCount(1), 50);
    expect(_missingCount(2), 25);
    expect(levels.where((level) => (level['assetRefs'] as List).isNotEmpty),
        isEmpty);
    expect(_levelsWithTextCues(), 75);
    expect(_duplicateLogicalQuestions('vi'), isEmpty);
    expect(_duplicateLogicalQuestions('en'), isEmpty);
  });

  test('tier 3 is materially harder than tier 1', () {
    for (final locale in const ['vi', 'en']) {
      expect(_averageWordLength(locale, 3),
          greaterThan(_averageWordLength(locale, 1)));
    }
    expect(_averageChoiceCount(3), greaterThan(_averageChoiceCount(1)));
    expect(_averageMissingCount(3), greaterThan(_averageMissingCount(1)));
    expect(_averageDistractorLengthDelta('en', 3),
        lessThanOrEqualTo(_averageDistractorLengthDelta('en', 1)));
  });

  test('every item has valid missing positions and exactly one answer', () {
    for (final level in levels) {
      for (final locale in const ['vi', 'en']) {
        final content = (level['localizedContent']
            as Map<String, dynamic>)[locale] as Map<String, dynamic>;
        final target = (content['targetWord'] as String).toUpperCase();
        final displayWord = content['displayWord'] as String;
        final positions = (content['missingPositions'] as List).cast<int>();
        final answer = positions.map((pos) => target[pos]).join();
        final options = (content['options'] as List).cast<Map>();
        final optionTexts = options.map((option) => option['text']).toList();

        expect(answer, content['correctAnswer'],
            reason: '${level['id']} $locale');
        expect(content['correctLetters'], positions.map((pos) => target[pos]));
        expect(optionTexts, contains(answer));
        expect(
            options.where((option) => option['correct'] == true), hasLength(1));
        expect(optionTexts.toSet(), hasLength(optionTexts.length));
        for (final pos in positions) {
          expect(pos, inInclusiveRange(0, displayWord.length - 1));
          expect(displayWord[pos], '_');
        }
      }
    }
  });

  test('Vietnamese text remains NFC-normalized with diacritics intact', () {
    final viWords = _uniqueWords('vi');
    expect(viWords.any((word) => word.contains('đ')), isTrue);
    expect(viWords.any((word) => word.contains('ư')), isTrue);
    expect(viWords.any((word) => word.contains('ơ')), isTrue);
    for (final word in viWords) {
      expect(
        RegExp(r'[\u0300-\u036f]').hasMatch(word),
        isFalse,
        reason: 'Use precomposed Vietnamese characters in $word',
      );
    }
  });

  test('loads through the shared content loader', () async {
    final parsed = await GameContentProvider().loadLevels(
      levels,
      gameId: 'missing_letter',
    );

    expect(parsed, hasLength(levels.length));
    expect(parsed.first.gameId, 'missing_letter');
    expect(parsed.first.contentForLocale('en')['prompt'], isNotEmpty);
    expect(parsed.first.skillTags, contains('letters.spelling'));
  });
}

int _countDifficulty(int difficulty) =>
    levels.where((level) => level['difficulty'] == difficulty).length;

double _averageChoiceCount(int difficulty) {
  final relevant = levels.where((level) => level['difficulty'] == difficulty);
  final total = relevant.fold<int>(0, (sum, level) {
    final content = (level['localizedContent'] as Map<String, dynamic>)['en']
        as Map<String, dynamic>;
    return sum + (content['options'] as List).length;
  });
  return total / math.max(1, relevant.length);
}

double _averageMissingCount(int difficulty) {
  final relevant = levels.where((level) => level['difficulty'] == difficulty);
  final total = relevant.fold<int>(0, (sum, level) {
    final content = (level['localizedContent'] as Map<String, dynamic>)['en']
        as Map<String, dynamic>;
    return sum + (content['missingPositions'] as List).length;
  });
  return total / math.max(1, relevant.length);
}

double _averageWordLength(String locale, int difficulty) {
  final relevant = levels.where((level) => level['difficulty'] == difficulty);
  final total = relevant.fold<int>(0, (sum, level) {
    final content = (level['localizedContent'] as Map<String, dynamic>)[locale]
        as Map<String, dynamic>;
    return sum + (content['targetWord'] as String).length;
  });
  return total / math.max(1, relevant.length);
}

double _averageDistractorLengthDelta(String locale, int difficulty) {
  final deltas = <int>[];
  for (final level
      in levels.where((level) => level['difficulty'] == difficulty)) {
    final content = (level['localizedContent'] as Map<String, dynamic>)[locale]
        as Map<String, dynamic>;
    final correct = content['correctAnswer'] as String;
    final options = (content['options'] as List).cast<Map>();
    for (final option in options.where((option) => option['correct'] != true)) {
      deltas.add(((option['text'] as String).length - correct.length).abs());
    }
  }
  return deltas.fold<int>(0, (sum, delta) => sum + delta) /
      math.max(1, deltas.length);
}

int _missingCount(int missingLetters) => levels.where((level) {
      final content = (level['localizedContent'] as Map<String, dynamic>)['en']
          as Map<String, dynamic>;
      return (content['missingPositions'] as List).length == missingLetters;
    }).length;

int _levelsWithTextCues() => levels.where((level) {
      final localized = level['localizedContent'] as Map<String, dynamic>;
      return const ['vi', 'en'].every((locale) {
        final content = localized[locale] as Map<String, dynamic>;
        return (content['categoryHint'] as String).isNotEmpty &&
            (content['phonicsHint'] as String).isNotEmpty;
      });
    }).length;

Set<String> _duplicateLogicalQuestions(String locale) {
  final seen = <String>{};
  final duplicates = <String>{};
  for (final level in levels) {
    final content = (level['localizedContent'] as Map<String, dynamic>)[locale]
        as Map<String, dynamic>;
    final options =
        (content['options'] as List).map((option) => option['text']).join('|');
    final key = [
      content['displayWord'],
      content['correctAnswer'],
      options,
    ].join('::');
    if (!seen.add(key)) duplicates.add(key);
  }
  return duplicates;
}

Set<String> _uniqueWords(String locale) {
  return {
    for (final level in levels)
      (((level['localizedContent'] as Map<String, dynamic>)[locale]
          as Map<String, dynamic>)['targetWord'] as String)
  };
}
