import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_engines/mi_game_engines.dart';

// ---------------------------------------------------------------------------
// Sample content (five real, deterministic, schema-valid samples).
// ---------------------------------------------------------------------------

/// Sample A -- Vietnamese vowels (exact match, explicit submit).
/// 3 correct (a, e, i) out of 6 letters.
Map<String, dynamic> _viVowelsExample() => {
      'contentId': 'multiselect-vi-vowels',
      'gameId': 'letter_sorting',
      'locale': 'vi',
      'ageBand': 'junior',
      'difficulty': 1,
      'instruction': 'Chọn tất cả các nguyên âm!',
      'hint': 'Nguyên âm là A, E, I, O, U.',
      'configuration': {
        'evaluationMode': 'exactMatch',
        'submitMode': 'explicitSubmit',
        'minSelections': 1,
        'maxSelections': 6,
      },
      'options': [
        {'id': 'a', 'label': 'Chữ A', 'text': 'A', 'isCorrect': true},
        {'id': 'b', 'label': 'Chữ B', 'text': 'B', 'isCorrect': false},
        {'id': 'e', 'label': 'Chữ E', 'text': 'E', 'isCorrect': true},
        {'id': 'm', 'label': 'Chữ M', 'text': 'M', 'isCorrect': false},
        {'id': 'i', 'label': 'Chữ I', 'text': 'I', 'isCorrect': true},
        {'id': 'k', 'label': 'Chữ K', 'text': 'K', 'isCorrect': false},
      ],
    };

/// Sample B -- English animals (exact match, explicit submit): select
/// every option that is an animal, out of a mixed set.
Map<String, dynamic> _enAnimalsExample() => {
      'contentId': 'multiselect-en-animals',
      'gameId': 'category_sorting',
      'locale': 'en',
      'ageBand': 'junior',
      'difficulty': 1,
      'instruction': 'Select every animal!',
      'configuration': {
        'evaluationMode': 'exactMatch',
        'submitMode': 'explicitSubmit',
        'minSelections': 1,
        'maxSelections': 5,
      },
      'options': [
        {'id': 'dog', 'label': 'Dog', 'text': '🐶 Dog', 'isCorrect': true},
        {
          'id': 'apple',
          'label': 'Apple',
          'text': '🍎 Apple',
          'isCorrect': false
        },
        {'id': 'cat', 'label': 'Cat', 'text': '🐱 Cat', 'isCorrect': true},
        {
          'id': 'bread',
          'label': 'Bread',
          'text': '🍞 Bread',
          'isCorrect': false
        },
        {'id': 'bird', 'label': 'Bird', 'text': '🐦 Bird', 'isCorrect': true},
      ],
    };

/// Sample C -- even numbers (partial credit, explicit submit): score is
/// prorated by correct/incorrect selections rather than requiring an
/// exact match to complete.
Map<String, dynamic> _enEvenNumbersExample() => {
      'contentId': 'multiselect-en-even-numbers',
      'gameId': 'number_sorting',
      'locale': 'en',
      'ageBand': 'explorer',
      'difficulty': 2,
      'instruction': 'Select all the even numbers.',
      'configuration': {
        'evaluationMode': 'partialCredit',
        'submitMode': 'explicitSubmit',
        'minSelections': 1,
        'maxSelections': 6,
      },
      'options': [
        {'id': 'n2', 'label': 'Number 2', 'text': '2', 'isCorrect': true},
        {'id': 'n3', 'label': 'Number 3', 'text': '3', 'isCorrect': false},
        {'id': 'n4', 'label': 'Number 4', 'text': '4', 'isCorrect': true},
        {'id': 'n5', 'label': 'Number 5', 'text': '5', 'isCorrect': false},
        {'id': 'n6', 'label': 'Number 6', 'text': '6', 'isCorrect': true},
        {'id': 'n7', 'label': 'Number 7', 'text': '7', 'isCorrect': false},
      ],
    };

/// Sample D -- quadrilaterals (exact match, image-flavored options via
/// `assetId`, no real asset file dependency -- same lesson as
/// Placement's rotation sample: text-only rendering, decorative
/// avatar icon only).
Map<String, dynamic> _quadrilateralsExample() => {
      'contentId': 'multiselect-en-quadrilaterals',
      'gameId': 'shape_sorting',
      'locale': 'en',
      'ageBand': 'explorer',
      'difficulty': 2,
      'instruction': 'Select every shape that is a quadrilateral (4 sides).',
      'configuration': {
        'evaluationMode': 'exactMatch',
        'submitMode': 'explicitSubmit',
        'minSelections': 1,
        'maxSelections': 5,
      },
      'options': [
        {
          'id': 'square',
          'label': 'Square',
          'text': 'Square',
          'assetId': 'shape-square',
          'isCorrect': true,
        },
        {
          'id': 'triangle',
          'label': 'Triangle',
          'text': 'Triangle',
          'assetId': 'shape-triangle',
          'isCorrect': false,
        },
        {
          'id': 'rectangle',
          'label': 'Rectangle',
          'text': 'Rectangle',
          'assetId': 'shape-rectangle',
          'isCorrect': true,
        },
        {
          'id': 'circle',
          'label': 'Circle',
          'text': 'Circle',
          'assetId': 'shape-circle',
          'isCorrect': false,
        },
        {
          'id': 'trapezoid',
          'label': 'Trapezoid',
          'text': 'Trapezoid',
          'assetId': 'shape-trapezoid',
          'isCorrect': true,
        },
      ],
    };

/// Sample E -- auto-submit: submission fires automatically once exactly
/// 2 options are selected, no explicit submit button needed.
Map<String, dynamic> _autoSubmitExample() => {
      'contentId': 'multiselect-vi-auto-submit',
      'gameId': 'letter_sorting',
      'locale': 'vi',
      'ageBand': 'junior',
      'difficulty': 1,
      'instruction': 'Chọn 2 hình tròn!',
      'configuration': {
        'evaluationMode': 'exactMatch',
        'submitMode': 'autoSubmit',
        'minSelections': 2,
        'maxSelections': 2,
        'expectedAnswerCount': 2,
      },
      'options': [
        {'id': 'c1', 'label': 'Hình tròn 1', 'text': '⚪', 'isCorrect': true},
        {'id': 's1', 'label': 'Hình vuông', 'text': '⬜', 'isCorrect': false},
        {'id': 'c2', 'label': 'Hình tròn 2', 'text': '⚪', 'isCorrect': true},
      ],
    };

MultiSelectLocalization _testLocalization() => MultiSelectLocalization(
      exitLabel: 'Exit',
      pauseLabel: 'Pause',
      resumeLabel: 'Resume',
      submitLabel: 'Submit',
      clearLabel: 'Clear',
      retryLabel: 'Retry',
      completionLabel: 'Great job!',
      authorHintLabel: 'Hint',
      revealCorrectLabel: 'Reveal one',
      eliminateIncorrectLabel: 'Remove one',
      malformedContentMessage: 'Content unavailable.',
      incorrectMessage: 'Not quite, try again!',
      selectionCountMessage: (min, max) => min == max
          ? 'Select $min answers'
          : 'Select between $min and $max answers',
      optionAnnouncement: (label, selected) =>
          selected ? '$label, selected' : label,
    );

void main() {
  group('MultiSelectContent.fromJson -- valid content', () {
    test('parses valid Vietnamese vowels content', () {
      final content = MultiSelectContent.fromJson(_viVowelsExample());
      expect(content.options, hasLength(6));
      expect(content.correctIds, {'a', 'e', 'i'});
    });

    test('parses valid English animals content', () {
      final content = MultiSelectContent.fromJson(_enAnimalsExample());
      expect(content.correctIds, {'dog', 'cat', 'bird'});
    });

    test('parses valid partial-credit even-numbers content', () {
      final content = MultiSelectContent.fromJson(_enEvenNumbersExample());
      expect(content.configuration.evaluationMode,
          MultiSelectEvaluationMode.partialCredit);
    });

    test('parses valid quadrilaterals content with asset-flavored options', () {
      final content = MultiSelectContent.fromJson(_quadrilateralsExample());
      expect(content.correctIds, {'square', 'rectangle', 'trapezoid'});
      expect(content.options.every((o) => o.assetId != null), isTrue);
    });

    test('parses valid auto-submit content', () {
      final content = MultiSelectContent.fromJson(_autoSubmitExample());
      expect(
          content.configuration.submitMode, MultiSelectSubmitMode.autoSubmit);
      expect(content.configuration.expectedAnswerCount, 2);
    });
  });

  group('MultiSelectContent.fromJson -- rejected content', () {
    test('rejects duplicate option IDs', () {
      final json = _viVowelsExample();
      final options = (json['options'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      options[1] = Map<String, dynamic>.from(options[0]);
      json['options'] = options;
      expect(() => MultiSelectContent.fromJson(json),
          throwsA(isA<MultiSelectContentException>()));
    });

    test('rejects content with no correct answers', () {
      final json = _viVowelsExample();
      final options = (json['options'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      for (final o in options) {
        o['isCorrect'] = false;
      }
      json['options'] = options;
      expect(
        () => MultiSelectContent.fromJson(json),
        throwsA(predicate((e) =>
            e is MultiSelectContentException &&
            e.message.contains('At least one option must be marked correct'))),
      );
    });

    test('rejects invalid min/max (max < min)', () {
      final json = _viVowelsExample();
      json['configuration'] = {'minSelections': 3, 'maxSelections': 2};
      expect(() => MultiSelectContent.fromJson(json),
          throwsA(isA<MultiSelectContentException>()));
    });

    test('rejects an impossible config (minSelections exceeds option count)',
        () {
      // max >= min always, so requesting more selections than options exist
      // is rejected -- whether the message names "maxSelections" or
      // "minSelections" as the immediate cause, both describe the same
      // impossible configuration.
      final json = _viVowelsExample();
      json['configuration'] = {'minSelections': 10, 'maxSelections': 10};
      expect(() => MultiSelectContent.fromJson(json),
          throwsA(isA<MultiSelectContentException>()));
    });

    test(
        'rejects an impossible exactMatch config (correct count outside min/max)',
        () {
      final json = _viVowelsExample();
      // 3 correct options, but the window only allows 4-5 selections.
      json['configuration'] = {'minSelections': 4, 'maxSelections': 5};
      expect(
        () => MultiSelectContent.fromJson(json),
        throwsA(predicate((e) =>
            e is MultiSelectContentException &&
            e.message.contains('Impossible completion'))),
      );
    });

    test('rejects invalid auto-submit (missing expectedAnswerCount)', () {
      final json = _autoSubmitExample();
      final config = Map<String, dynamic>.from(json['configuration'] as Map);
      config.remove('expectedAnswerCount');
      json['configuration'] = config;
      expect(
        () => MultiSelectContent.fromJson(json),
        throwsA(predicate((e) =>
            e is MultiSelectContentException &&
            e.message.contains('autoSubmit requires'))),
      );
    });

    test('rejects invalid auto-submit (expectedAnswerCount outside range)', () {
      final json = _autoSubmitExample();
      final config = Map<String, dynamic>.from(json['configuration'] as Map);
      config['expectedAnswerCount'] = 99;
      json['configuration'] = config;
      expect(() => MultiSelectContent.fromJson(json),
          throwsA(isA<MultiSelectContentException>()));
    });

    test('rejects an option with no text and no assetId (invalid asset)', () {
      final json = _viVowelsExample();
      final options = (json['options'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      options[0] = {'id': 'a', 'label': 'Chữ A', 'isCorrect': true};
      json['options'] = options;
      expect(() => MultiSelectContent.fromJson(json),
          throwsA(isA<MultiSelectContentException>()));
    });

    test('rejects an option with an empty assetId', () {
      final json = _viVowelsExample();
      final options = (json['options'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      options[0] = {
        'id': 'a',
        'label': 'Chữ A',
        'text': 'A',
        'assetId': '',
        'isCorrect': true,
      };
      json['options'] = options;
      expect(() => MultiSelectContent.fromJson(json),
          throwsA(isA<MultiSelectContentException>()));
    });

    test('rejects an option missing a semantic label', () {
      final json = _viVowelsExample();
      final options = (json['options'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      options[0] = {'id': 'a', 'text': 'A', 'isCorrect': true};
      json['options'] = options;
      expect(() => MultiSelectContent.fromJson(json),
          throwsA(isA<MultiSelectContentException>()));
    });

    test('rejects unsupported schema version', () {
      final json = _viVowelsExample();
      json['schemaVersion'] = '99.0';
      expect(() => MultiSelectContent.fromJson(json),
          throwsA(isA<MultiSelectContentException>()));
    });
  });

  group('MultiSelectController -- exact match', () {
    late MultiSelectController controller;
    setUp(() {
      controller = MultiSelectController(
          content: MultiSelectContent.fromJson(_viVowelsExample()));
    });

    test('select/deselect/toggle update selection state', () {
      controller.select('a');
      expect(controller.isSelected('a'), isTrue);
      controller.deselect('a');
      expect(controller.isSelected('a'), isFalse);
      controller.toggle('e');
      expect(controller.isSelected('e'), isTrue);
      controller.toggle('e');
      expect(controller.isSelected('e'), isFalse);
    });

    test('clear empties the current selection', () {
      controller.select('a');
      controller.select('e');
      controller.clear();
      expect(controller.selectedIds, isEmpty);
    });

    test('submitting the exact correct set completes the level', () {
      controller.select('a');
      controller.select('e');
      controller.select('i');
      controller.submit();
      expect(controller.isComplete, isTrue);
      expect(controller.lastSubmissionCorrect, isTrue);
    });

    test('submitting an incorrect set is retryable, not corrupting state', () {
      controller.select('a');
      controller.select('b');
      controller.submit();
      expect(controller.isComplete, isFalse);
      expect(controller.lastSubmissionCorrect, isFalse);
      expect(controller.attempts, 1);

      controller.deselect('b');
      controller.select('e');
      controller.select('i');
      controller.submit();
      expect(controller.isComplete, isTrue);
    });

    test('retry with clearSelection (default) empties the selection', () {
      controller.select('a');
      controller.select('b');
      controller.submit();
      controller.retry();
      expect(controller.selectedIds, isEmpty);
      expect(controller.attempts, 0);
    });

    test('retry with preserveSelection keeps the selection', () {
      final preserving = MultiSelectController(
        content: MultiSelectContent.fromJson({
          ..._viVowelsExample(),
          'configuration': {
            'evaluationMode': 'exactMatch',
            'retryMode': 'preserveSelection',
            'minSelections': 1,
            'maxSelections': 6,
          },
        }),
      );
      preserving.select('a');
      preserving.select('b');
      preserving.submit();
      preserving.retry();
      expect(preserving.selectedIds, {'a', 'b'});
      expect(preserving.attempts, 0);
    });

    test('restart always clears the selection regardless of retryMode', () {
      final preserving = MultiSelectController(
        content: MultiSelectContent.fromJson({
          ..._viVowelsExample(),
          'configuration': {
            'evaluationMode': 'exactMatch',
            'retryMode': 'preserveSelection',
            'minSelections': 1,
            'maxSelections': 6,
          },
        }),
      );
      preserving.select('a');
      preserving.restart();
      expect(preserving.selectedIds, isEmpty);
    });

    test('a selection above maxSelections is rejected by toggle', () {
      // partialCredit, not exactMatch: exactMatch would itself reject a
      // cap below the correct-answer count as an impossible config (the
      // 3-correct-answer vowels content can't use exactMatch with a cap
      // of 2). partialCredit has no such constraint, isolating the
      // capacity behavior being tested here.
      final capped = MultiSelectController(
        content: MultiSelectContent.fromJson({
          ..._viVowelsExample(),
          'configuration': {
            'evaluationMode': 'partialCredit',
            'minSelections': 1,
            'maxSelections': 2,
          },
        }),
      );
      capped.select('a');
      capped.select('e');
      capped.select('i'); // over cap, ignored
      expect(capped.selectedIds, {'a', 'e'});
    });

    test('requestAuthorHint increments hint count and shows the hint', () {
      controller.requestAuthorHint();
      expect(controller.hintCount, 1);
      expect(controller.showAuthorHint, isTrue);
      controller.dismissAuthorHint();
      expect(controller.showAuthorHint, isFalse);
    });

    test('revealCorrectOption reveals one correct option not yet revealed', () {
      controller.revealCorrectOption();
      expect(controller.revealedCorrectIds, hasLength(1));
      expect(controller.hintCount, 1);
      controller.revealCorrectOption();
      controller.revealCorrectOption();
      expect(controller.revealedCorrectIds, hasLength(3));
      // No more to reveal -- a 4th call is a no-op.
      controller.revealCorrectOption();
      expect(controller.hintCount, 3);
    });

    test('eliminateIncorrectOption removes one incorrect option from play', () {
      controller.eliminateIncorrectOption();
      expect(controller.eliminatedIds, hasLength(1));
      final eliminatedId = controller.eliminatedIds.first;
      expect(controller.content.correctIds.contains(eliminatedId), isFalse);
      // An eliminated option cannot be selected.
      controller.select(eliminatedId);
      expect(controller.isSelected(eliminatedId), isFalse);
    });

    test('a perfect single-attempt run earns 3 stars', () {
      controller.select('a');
      controller.select('e');
      controller.select('i');
      controller.submit();
      expect(controller.starsEarned, 3);
    });

    test('score never goes negative regardless of hints/attempts', () {
      for (var i = 0; i < 30; i++) {
        controller.requestAuthorHint();
      }
      controller.select('a');
      controller.select('e');
      controller.select('i');
      controller.submit();
      expect(controller.score, 0);
      expect(controller.starsEarned, 0);
    });

    test('onComplete callback fires exactly once with a normalized result', () {
      var callCount = 0;
      MultiSelectResult? received;
      final withCallback = MultiSelectController(
        content: MultiSelectContent.fromJson(_viVowelsExample()),
        onComplete: (result) {
          callCount++;
          received = result;
        },
      );
      withCallback.select('a');
      withCallback.select('e');
      withCallback.select('i');
      withCallback.submit();
      withCallback.complete(); // idempotent explicit call must not re-fire
      expect(callCount, 1);
      expect(received!.engineId, 'multi_select');
      expect(received!.contentId, 'multiselect-vi-vowels');
      expect(received!.completed, isTrue);
      expect(received!.selectedIds, {'a', 'e', 'i'});
      expect(received!.correctIds, {'a', 'e', 'i'});
    });

    test('duration reflects an injected clock rather than wall-clock time', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final clockController = MultiSelectController(
        content: MultiSelectContent.fromJson(_viVowelsExample()),
        clock: () => now,
      );
      now = now.add(const Duration(seconds: 10));
      clockController.select('a');
      clockController.select('e');
      clockController.select('i');
      clockController.submit();
      expect(clockController.result.duration, const Duration(seconds: 10));
    });

    test('two equivalent results are equal (result equality contract)', () {
      final fixedNow = DateTime(2026, 1, 1, 12, 0, 0);
      final fixedController = MultiSelectController(
        content: MultiSelectContent.fromJson(_viVowelsExample()),
        clock: () => fixedNow,
      );
      fixedController.select('a');
      final resultA = fixedController.result;
      final resultB = fixedController.result;
      expect(resultA, resultB);
    });
  });

  group('MultiSelectController -- partial credit', () {
    test('any valid-size submission completes the level, score prorated', () {
      final controller = MultiSelectController(
        content: MultiSelectContent.fromJson(_enEvenNumbersExample()),
      );
      controller.select('n2');
      controller.select('n4');
      controller.select('n3'); // one wrong pick
      controller.submit();
      expect(controller.isComplete, isTrue);
      // 2 correct - 1 incorrect = net 1, out of 3 total correct -> ~33.
      expect(controller.score, closeTo(33, 1));
    });

    test('a perfect partial-credit submission scores 100', () {
      final controller = MultiSelectController(
        content: MultiSelectContent.fromJson(_enEvenNumbersExample()),
      );
      controller.select('n2');
      controller.select('n4');
      controller.select('n6');
      controller.submit();
      expect(controller.score, 100);
      expect(controller.starsEarned, 3);
    });
  });

  group('MultiSelectController -- auto-submit', () {
    test('submits automatically once selection reaches expectedAnswerCount',
        () {
      final controller = MultiSelectController(
        content: MultiSelectContent.fromJson(_autoSubmitExample()),
      );
      controller.select('c1');
      expect(controller.attempts, 0); // not yet at expected count
      controller.select('c2');
      expect(controller.attempts, 1); // auto-submitted
      expect(controller.isComplete, isTrue);
    });

    test('auto-submit with a wrong pair does not complete but does attempt',
        () {
      final controller = MultiSelectController(
        content: MultiSelectContent.fromJson(_autoSubmitExample()),
      );
      controller.select('c1');
      controller.select('s1');
      expect(controller.attempts, 1);
      expect(controller.isComplete, isFalse);
    });
  });

  group('MultiSelectScreen widget', () {
    testWidgets('renders instruction and all options', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MultiSelectScreen(
          rawContent: _viVowelsExample(),
          localization: _testLocalization(),
          onExit: () {},
        ),
      ));
      await tester.pump();

      expect(find.text('Chọn tất cả các nguyên âm!'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('shows a recoverable error state for malformed content',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MultiSelectScreen(
          rawContent: const {'contentId': 'broken'},
          localization: _testLocalization(),
          onExit: () {},
        ),
      ));
      await tester.pump();

      expect(find.text('Content unavailable.'), findsOneWidget);
    });

    testWidgets('selecting the correct set and submitting shows completion',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MultiSelectScreen(
          rawContent: _viVowelsExample(),
          localization: _testLocalization(),
          onExit: () {},
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.tap(find.text('E'));
      await tester.pump();
      await tester.tap(find.text('I'));
      await tester.pump();
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Great job!'), findsOneWidget);
    });

    testWidgets('renders the English animals sample', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MultiSelectScreen(
          rawContent: _enAnimalsExample(),
          localization: _testLocalization(),
          onExit: () {},
        ),
      ));
      await tester.pump();

      expect(find.text('Select every animal!'), findsOneWidget);
      expect(find.textContaining('Dog'), findsOneWidget);
    });

    testWidgets('renders the quadrilaterals sample with asset avatars',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MultiSelectScreen(
          rawContent: _quadrilateralsExample(),
          localization: _testLocalization(),
          onExit: () {},
        ),
      ));
      await tester.pump();

      expect(find.text('Square'), findsOneWidget);
      expect(find.byIcon(Icons.image_outlined), findsWidgets);
    });

    testWidgets('auto-submit sample completes without a submit button',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MultiSelectScreen(
          rawContent: _autoSubmitExample(),
          localization: _testLocalization(),
          onExit: () {},
        ),
      ));
      await tester.pump();

      expect(find.text('Submit'), findsNothing);
      await tester.tap(find.text('⚪').first);
      await tester.pump();
      await tester.tap(find.text('⚪').last);
      await tester.pump();

      expect(find.text('Great job!'), findsOneWidget);
    });

    testWidgets('hint actions reveal/eliminate/show author hint',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MultiSelectScreen(
          rawContent: _viVowelsExample(),
          localization: _testLocalization(),
          onExit: () {},
        ),
      ));
      await tester.pump();

      await tester.tap(find.byTooltip('Hint'));
      await tester.pump();
      expect(find.text('Nguyên âm là A, E, I, O, U.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('multi-select-hint-dismiss')));
      await tester.pump();
      expect(find.text('Nguyên âm là A, E, I, O, U.'), findsNothing);
    });

    testWidgets('reduced motion still renders without exceptions',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MultiSelectScreen(
          rawContent: _viVowelsExample(),
          localization: _testLocalization(),
          onExit: () {},
          reducedMotion: true,
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('sound-disabled mode still functions normally', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MultiSelectScreen(
          rawContent: _viVowelsExample(),
          localization: _testLocalization(),
          onExit: () {},
          soundEnabled: false,
        ),
      ));
      await tester.pump();
      await tester.tap(find.text('A'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('options expose semantics labels', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MultiSelectScreen(
          rawContent: _viVowelsExample(),
          localization: _testLocalization(),
          onExit: () {},
        ),
      ));
      await tester.pump();

      expect(find.bySemanticsLabel('Chữ A'), findsOneWidget);
      await tester.tap(find.text('A'));
      await tester.pump();
      expect(find.bySemanticsLabel('Chữ A, selected'), findsOneWidget);
    });

    testWidgets('narrow phone layout does not overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: MultiSelectScreen(
          rawContent: _enEvenNumbersExample(),
          localization: _testLocalization(),
          onExit: () {},
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet-size layout renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: MultiSelectScreen(
          rawContent: _enEvenNumbersExample(),
          localization: _testLocalization(),
          onExit: () {},
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
