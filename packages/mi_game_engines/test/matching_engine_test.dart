import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_engines/mi_game_engines.dart';

Map<String, dynamic> _viExample() => {
      'contentId': 'matching-vi-01',
      'gameId': 'letter_picture_match',
      'locale': 'vi',
      'ageBand': 'junior',
      'difficulty': 1,
      'instruction': 'Ghép chữ cái với hình ảnh!',
      'hint': 'Chữ M là con mèo (mèo)',
      'estimatedSeconds': 45,
      'pairs': [
        {
          'left': {'id': 'l1', 'content': 'M', 'type': 'text'},
          'right': {'id': 'r1', 'content': '🐱 mèo', 'type': 'text'},
        },
        {
          'left': {'id': 'l2', 'content': 'C', 'type': 'text'},
          'right': {'id': 'r2', 'content': '🐟 cá', 'type': 'text'},
        },
        {
          'left': {'id': 'l3', 'content': 'B', 'type': 'text'},
          'right': {'id': 'r3', 'content': '🐦 bồ câu', 'type': 'text'},
        },
      ],
    };

Map<String, dynamic> _enExample() => {
      'contentId': 'matching-en-01',
      'gameId': 'letter_picture_match',
      'locale': 'en',
      'ageBand': 'junior',
      'difficulty': 1,
      'instruction': 'Match the letter to the picture!',
      'hint': 'C is for cat',
      'estimatedSeconds': 45,
      'pairs': [
        {
          'left': {'id': 'l1', 'content': 'C', 'type': 'text'},
          'right': {'id': 'r1', 'content': '🐱 cat', 'type': 'text'},
        },
        {
          'left': {'id': 'l2', 'content': 'F', 'type': 'text'},
          'right': {'id': 'r2', 'content': '🐟 fish', 'type': 'text'},
        },
        {
          'left': {'id': 'l3', 'content': 'B', 'type': 'text'},
          'right': {'id': 'r3', 'content': '🐦 bird', 'type': 'text'},
        },
      ],
    };

void main() {
  group('MatchingContent.fromJson', () {
    test('parses a valid Vietnamese example', () {
      final content = MatchingContent.fromJson(_viExample());
      expect(content.locale, 'vi');
      expect(content.pairs, hasLength(3));
    });

    test('parses a valid English example', () {
      final content = MatchingContent.fromJson(_enExample());
      expect(content.locale, 'en');
      expect(content.pairs, hasLength(3));
    });

    test('throws for missing required fields', () {
      final data = _viExample()..remove('instruction');
      expect(
        () => MatchingContent.fromJson(data),
        throwsA(isA<MatchingContentException>()),
      );
    });

    test('throws for out-of-range difficulty', () {
      final data = _viExample()..['difficulty'] = 9;
      expect(
        () => MatchingContent.fromJson(data),
        throwsA(isA<MatchingContentException>()),
      );
    });

    test('throws for duplicate pair IDs (malformed content)', () {
      final data = _viExample();
      (data['pairs'] as List)[1] = {
        'left': {'id': 'l1', 'content': 'X', 'type': 'text'}, // dup of l1
        'right': {'id': 'r9', 'content': 'Y', 'type': 'text'},
      };
      expect(
        () => MatchingContent.fromJson(data),
        throwsA(isA<MatchingContentException>()),
      );
    });

    test('throws for an empty pairs list', () {
      final data = _viExample()..['pairs'] = <dynamic>[];
      expect(
        () => MatchingContent.fromJson(data),
        throwsA(isA<MatchingContentException>()),
      );
    });
  });

  group('MatchingController', () {
    late MatchingController controller;

    setUp(() {
      controller =
          MatchingController(content: MatchingContent.fromJson(_viExample()));
    });

    test('correct pair gets marked matched and increments attempts', () {
      controller.selectLeft('l1');
      controller.selectRight('r1');
      expect(controller.isLeftMatched('l1'), isTrue);
      expect(controller.isRightMatched('r1'), isTrue);
      expect(controller.attempts, 1);
      expect(controller.lastFeedbackWasCorrect, isTrue);
    });

    test('incorrect pair does not mark matched but counts an attempt', () {
      controller.selectLeft('l1');
      controller.selectRight('r2');
      expect(controller.isLeftMatched('l1'), isFalse);
      expect(controller.isRightMatched('r2'), isFalse);
      expect(controller.attempts, 1);
      expect(controller.lastFeedbackWasCorrect, isFalse);
    });

    test('selecting an already-matched item again is a no-op', () {
      controller.selectLeft('l1');
      controller.selectRight('r1');
      final attemptsAfterMatch = controller.attempts;
      controller.selectLeft('l1'); // already matched, ignored
      expect(controller.attempts, attemptsAfterMatch);
    });

    test('duplicate selection on the same side just replaces the pending pick',
        () {
      controller.selectLeft('l1');
      controller.selectLeft('l2'); // re-picks before a right is chosen
      expect(controller.selectedLeftId, 'l2');
      expect(controller.attempts, 0); // no right picked yet, no attempt made
    });

    test('retry resets attempts and matches', () {
      controller.selectLeft('l1');
      controller.selectRight('r1');
      controller.retry();
      expect(controller.attempts, 0);
      expect(controller.isLeftMatched('l1'), isFalse);
      expect(controller.isComplete, isFalse);
    });

    test('completes and awards 3 stars for a perfect run', () {
      controller.selectLeft('l1');
      controller.selectRight('r1');
      controller.selectLeft('l2');
      controller.selectRight('r2');
      controller.selectLeft('l3');
      controller.selectRight('r3');
      expect(controller.isComplete, isTrue);
      expect(controller.starsEarned, 3);
    });

    test('awards fewer stars for more attempts than pairs', () {
      // 3 pairs but deliberately mismatch first before matching each --
      // 6 attempts total for 3 pairs => 1 star.
      controller.selectLeft('l1');
      controller.selectRight('r2'); // wrong
      controller.selectLeft('l1');
      controller.selectRight('r1'); // right
      controller.selectLeft('l2');
      controller.selectRight('r3'); // wrong
      controller.selectLeft('l2');
      controller.selectRight('r2'); // right
      controller.selectLeft('l3');
      controller.selectRight('r1'); // wrong (r1 already matched, but not
      // marked so still selectable in this controller-only test)
      controller.selectLeft('l3');
      controller.selectRight('r3'); // right
      expect(controller.isComplete, isTrue);
      expect(controller.starsEarned, lessThan(3));
    });

    test('pause blocks selection; resume re-enables it', () {
      controller.pause();
      controller.selectLeft('l1');
      expect(controller.selectedLeftId, isNull);
      controller.resume();
      controller.selectLeft('l1');
      expect(controller.selectedLeftId, 'l1');
    });

    test('hint visibility toggles', () {
      expect(controller.showHint, isFalse);
      controller.requestHint();
      expect(controller.showHint, isTrue);
      controller.dismissHint();
      expect(controller.showHint, isFalse);
    });
  });

  group('MatchingScreen widget', () {
    testWidgets('renders instruction and both columns for valid content',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MatchingScreen(
          rawContent: _viExample(),
          onExit: () {},
        ),
      ));
      await tester.pump();

      expect(find.text('Ghép chữ cái với hình ảnh!'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.textContaining('mèo'), findsOneWidget);
    });

    testWidgets('shows a recoverable error state for malformed content',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MatchingScreen(
          rawContent: {'contentId': 'broken'}, // missing everything else
          onExit: () {},
        ),
      ));
      await tester.pump();

      expect(find.textContaining('không khả dụng'), findsOneWidget);
      // Must not throw/crash -- reaching this assertion at all is the proof.
    });

    testWidgets(
        'tapping matching items completes the level and calls onComplete',
        (tester) async {
      MatchingCompletionResult? result;
      await tester.pumpWidget(MaterialApp(
        home: MatchingScreen(
          rawContent: _viExample(),
          onExit: () {},
          onComplete: (r) => result = r,
          reducedMotion: true,
        ),
      ));
      await tester.pump();

      // Tap every left item then its correct right partner, in the order
      // the columns actually render (shuffled) -- read displayed text back
      // via a content->side map instead of assuming column order.
      for (final pair in [
        ('M', '🐱 mèo'),
        ('C', '🐟 cá'),
        ('B', '🐦 bồ câu'),
      ]) {
        await tester.tap(find.text(pair.$1));
        await tester.pump();
        await tester.tap(find.textContaining(pair.$2));
        await tester.pump();
      }

      expect(result, isNotNull);
      expect(result!.starsEarned, 3);
      expect(find.textContaining('Hoàn thành'), findsOneWidget);
    });

    testWidgets('reduced motion is honored (no animation duration)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MatchingScreen(
          rawContent: _viExample(),
          onExit: () {},
          reducedMotion: true,
        ),
      ));
      await tester.pump();

      final containers =
          tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(containers, isNotEmpty);
      for (final c in containers) {
        expect(c.duration, Duration.zero);
      }
    });
  });
}
