import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_engines/mi_game_engines.dart';

Map<String, dynamic> _ascendingViExample() => {
      'contentId': 'sequence-vi-ascending',
      'gameId': 'number_sequence',
      'locale': 'vi',
      'ageBand': 'explorer',
      'difficulty': 2,
      'instruction': 'Sắp xếp các số theo thứ tự tăng dần!',
      'hint': 'Mỗi số cách nhau 2 đơn vị',
      'mode': 'reorder',
      'rule': {'type': 'ascending', 'step': 2},
      'correctOrder': [
        {'id': 'n1', 'content': '2', 'type': 'number'},
        {'id': 'n2', 'content': '4', 'type': 'number'},
        {'id': 'n3', 'content': '6', 'type': 'number'},
        {'id': 'n4', 'content': '8', 'type': 'number'},
      ],
    };

Map<String, dynamic> _descendingEnExample() => {
      'contentId': 'sequence-en-descending',
      'gameId': 'number_sequence',
      'locale': 'en',
      'ageBand': 'explorer',
      'difficulty': 2,
      'instruction': 'Arrange the numbers in descending order!',
      'mode': 'reorder',
      'rule': {'type': 'descending', 'step': 3},
      'correctOrder': [
        {'id': 'n1', 'content': '12', 'type': 'number'},
        {'id': 'n2', 'content': '9', 'type': 'number'},
        {'id': 'n3', 'content': '6', 'type': 'number'},
      ],
    };

Map<String, dynamic> _imageExample() => {
      'contentId': 'sequence-vi-image-story',
      'gameId': 'picture_story',
      'locale': 'vi',
      'ageBand': 'junior',
      'difficulty': 1,
      'instruction': 'Sắp xếp câu chuyện theo đúng thứ tự!',
      'mode': 'reorder',
      'rule': {'type': 'fixed'},
      'correctOrder': [
        {'id': 'p1', 'content': '🌱', 'type': 'image'},
        {'id': 'p2', 'content': '🌿', 'type': 'image'},
        {'id': 'p3', 'content': '🌳', 'type': 'image'},
      ],
    };

// Alternating rule: even positions repeat the base value, odd positions
// add `step` -- i.e. 2, 5, 2, 5, 2 for base 2 / step 3. Index 3 ("5") is
// blank; the decoy "99" is an obviously-wrong distractor.
Map<String, dynamic> _alternatingExample() => {
      'contentId': 'sequence-vi-alternating',
      'gameId': 'number_sequence',
      'locale': 'vi',
      'ageBand': 'master',
      'difficulty': 4,
      'instruction': 'Tìm quy luật xen kẽ!',
      'mode': 'missingItem',
      'rule': {'type': 'alternating', 'step': 3},
      'missingIndices': [3],
      'choices': [
        {'id': 'c1', 'content': '10', 'type': 'number'},
        {'id': 'c2', 'content': '99', 'type': 'number'},
      ],
      'correctOrder': [
        {'id': 'n1', 'content': '2', 'type': 'number'},
        {'id': 'n2', 'content': '5', 'type': 'number'},
        {'id': 'n3', 'content': '2', 'type': 'number'},
        {'id': 'n4', 'content': '5', 'type': 'number'},
        {'id': 'n5', 'content': '2', 'type': 'number'},
      ],
    };

void main() {
  group('SequenceContent.fromJson', () {
    test('parses a fixed-order Vietnamese example', () {
      final content = SequenceContent.fromJson(_imageExample());
      expect(content.rule.type, SequenceRuleType.fixed);
      expect(content.correctOrder, hasLength(3));
    });

    test('parses an ascending-rule example', () {
      final content = SequenceContent.fromJson(_ascendingViExample());
      expect(content.rule.type, SequenceRuleType.ascending);
      expect(content.rule.step, 2);
    });

    test('parses a descending-rule example', () {
      final content = SequenceContent.fromJson(_descendingEnExample());
      expect(content.rule.type, SequenceRuleType.descending);
    });

    test('parses an alternating-rule missing-item example', () {
      final content = SequenceContent.fromJson(_alternatingExample());
      expect(content.mode, SequenceMode.missingItem);
      expect(content.missingIndices, [3]);
    });

    test('handles a repeating-pattern example', () {
      final data = {
        'contentId': 'sequence-vi-repeating',
        'gameId': 'pattern_game',
        'locale': 'vi',
        'ageBand': 'junior',
        'difficulty': 2,
        'instruction': 'Tìm quy luật lặp lại!',
        'mode': 'reorder',
        'rule': {'type': 'repeating', 'repeatingCycleLength': 2},
        'correctOrder': [
          {'id': 'a', 'content': '1', 'type': 'number'},
          {'id': 'b', 'content': '2', 'type': 'number'},
          {'id': 'c', 'content': '1', 'type': 'number'},
          {'id': 'd', 'content': '2', 'type': 'number'},
        ],
      };
      final content = SequenceContent.fromJson(data);
      expect(content.rule.type, SequenceRuleType.repeating);
    });

    test('throws for duplicate item IDs (malformed content)', () {
      final data = _ascendingViExample();
      (data['correctOrder'] as List)[1] = {
        'id': 'n1', // dup
        'content': '4',
        'type': 'number',
      };
      expect(
        () => SequenceContent.fromJson(data),
        throwsA(isA<SequenceContentException>()),
      );
    });

    test('throws when correctOrder does not match the ascending rule', () {
      final data = _ascendingViExample();
      (data['correctOrder'] as List)[2] = {
        'id': 'n3',
        'content': '99', // breaks the +2 rule
        'type': 'number',
      };
      expect(
        () => SequenceContent.fromJson(data),
        throwsA(isA<SequenceContentException>()),
      );
    });

    test('throws for an invalid/unknown rule type', () {
      final data = _ascendingViExample();
      (data['rule'] as Map)['type'] = 'not_a_real_rule';
      expect(
        () => SequenceContent.fromJson(data),
        throwsA(isA<SequenceContentException>()),
      );
    });

    test('throws when an ascending rule is missing its step', () {
      final data = _ascendingViExample();
      (data['rule'] as Map).remove('step');
      expect(
        () => SequenceContent.fromJson(data),
        throwsA(isA<SequenceContentException>()),
      );
    });

    test('throws for missingItem mode with no missingIndices', () {
      final data = _alternatingExample();
      data['missingIndices'] = <int>[];
      expect(
        () => SequenceContent.fromJson(data),
        throwsA(isA<SequenceContentException>()),
      );
    });
  });

  group('SequenceController (reorder mode)', () {
    test('starting arrangement is shuffled but same items as correctOrder', () {
      final controller = SequenceController(
        content: SequenceContent.fromJson(_ascendingViExample()),
      );
      final ids = controller.arrangement.map((i) => i.id).toSet();
      expect(ids, {'n1', 'n2', 'n3', 'n4'});
    });

    test('submitReorder succeeds once arrangement matches correctOrder', () {
      final content = SequenceContent.fromJson(_ascendingViExample());
      final controller = SequenceController(content: content);
      // Force the arrangement into the correct order directly via repeated
      // moveItem calls until it matches, regardless of the initial shuffle.
      for (var target = 0; target < content.correctOrder.length; target++) {
        final wantedId = content.correctOrder[target].id;
        final currentIndex = controller.arrangement.indexWhere(
          (i) => i.id == wantedId,
        );
        if (currentIndex != target) {
          controller.moveItem(currentIndex, target);
        }
      }
      controller.submitReorder();
      expect(controller.isComplete, isTrue);
      expect(controller.lastSubmissionCorrect, isTrue);
    });

    test('submitReorder fails and increments attempts on a wrong order', () {
      final controller = SequenceController(
        content: SequenceContent.fromJson(_ascendingViExample()),
      );
      // Deliberately reverse -- guaranteed wrong for a 4-item ascending list.
      controller.moveItem(0, 3);
      controller.submitReorder();
      expect(controller.attempts, 1);
      expect(controller.isComplete, isFalse);
    });

    test('retry resets attempts and completion', () {
      final content = SequenceContent.fromJson(_ascendingViExample());
      final controller = SequenceController(content: content);
      controller.submitReorder();
      controller.retry();
      expect(controller.attempts, 0);
      expect(controller.isComplete, isFalse);
    });

    test('exports and restores reorder progress', () {
      final content = SequenceContent.fromJson(_ascendingViExample());
      final controller = SequenceController(content: content);
      controller.moveItem(0, 1);
      controller.submitReorder();

      final restored = SequenceController(content: content)
        ..restoreState(controller.exportState());

      expect(
        restored.arrangement.map((item) => item.id),
        controller.arrangement.map((item) => item.id),
      );
      expect(restored.attempts, 1);
      expect(restored.isComplete, isFalse);
    });

    test('perfect run (first attempt correct) earns 3 stars', () {
      final content = SequenceContent.fromJson(_ascendingViExample());
      final controller = SequenceController(content: content);
      for (var target = 0; target < content.correctOrder.length; target++) {
        final wantedId = content.correctOrder[target].id;
        final currentIndex = controller.arrangement.indexWhere(
          (i) => i.id == wantedId,
        );
        if (currentIndex != target) {
          controller.moveItem(currentIndex, target);
        }
      }
      controller.submitReorder();
      expect(controller.starsEarned, 3);
    });

    test('pause blocks moveItem/submit; resume re-enables it', () {
      final controller = SequenceController(
        content: SequenceContent.fromJson(_ascendingViExample()),
      );
      controller.pause();
      controller.moveItem(0, 1);
      final beforeResume = List.of(controller.arrangement);
      controller.resume();
      controller.moveItem(0, 1);
      expect(controller.arrangement, isNot(equals(beforeResume)));
    });
  });

  group('SequenceController (missingItem mode)', () {
    test('correct selection at the missing index completes the level', () {
      final content = SequenceContent.fromJson(_alternatingExample());
      final controller = SequenceController(content: content);
      controller.selectForMissingIndex(3, 'n4'); // correct value is "6"
      controller.submitMissingItems();
      expect(controller.isComplete, isTrue);
    });

    test('incorrect selection does not complete the level', () {
      final content = SequenceContent.fromJson(_alternatingExample());
      final controller = SequenceController(content: content);
      controller.selectForMissingIndex(3, 'c2'); // decoy "99"
      controller.submitMissingItems();
      expect(controller.isComplete, isFalse);
      expect(controller.attempts, 1);
    });

    test('hint visibility toggles', () {
      final controller = SequenceController(
        content: SequenceContent.fromJson(_alternatingExample()),
      );
      expect(controller.showHint, isFalse);
      controller.requestHint();
      expect(controller.showHint, isTrue);
      controller.dismissHint();
      expect(controller.showHint, isFalse);
    });
  });

  group('SequenceScreen widget', () {
    testWidgets('renders instruction and reorder items for valid content', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SequenceScreen(
            rawContent: _ascendingViExample(),
            onExit: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Sắp xếp các số theo thứ tự tăng dần!'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('shows a recoverable error state for malformed content', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SequenceScreen(
            rawContent: {'contentId': 'broken'},
            onExit: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('không khả dụng'), findsOneWidget);
    });

    testWidgets(
      'tap-based move-right button changes the rendered order (accessibility fallback)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SequenceScreen(
              rawContent: _ascendingViExample(),
              onExit: () {},
              reducedMotion: true,
            ),
          ),
        );
        await tester.pump();

        List<String> currentOrder() => tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(ListTile),
                matching: find.byType(Text),
              ),
            )
            .map((t) => t.data)
            .whereType<String>()
            .where((t) => int.tryParse(t) != null)
            .toList();

        final before = currentOrder();
        await tester.tap(find.byTooltip('Di chuyển sang phải').first);
        await tester.pump();
        final after = currentOrder();

        expect(after, isNot(equals(before)));
      },
    );

    testWidgets('missing-item mode renders blanks and choice buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SequenceScreen(
            rawContent: _alternatingExample(),
            onExit: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Tìm quy luật xen kẽ!'), findsOneWidget);
      // The known (non-blank) values render as chips: "2" at positions
      // 0/2/4, "5" at position 1 (position 3 is the blank).
      expect(find.text('2'), findsNWidgets(3));
      expect(find.text('5'), findsWidgets); // chip + the correct choice button
      // The decoy choice is offered.
      expect(find.text('99'), findsOneWidget);
    });
  });
}
