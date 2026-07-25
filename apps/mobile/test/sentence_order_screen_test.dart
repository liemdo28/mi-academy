import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/src/games/sentence_order/sentence_order_screen.dart';
import 'package:mi_game_core/mi_game_core.dart';

void main() {
  testWidgets(
      'Sentence Order launches Sequence Engine and completes in English',
      (tester) async {
    MiCompletionResult? completion;
    MiGameSnapshot? snapshot;

    await tester.pumpWidget(
      MaterialApp(
        home: SentenceOrderScreen(
          level: _missingWordLevel,
          allLevels: const [_missingWordLevel],
          childProfileId: 'child-1',
          locale: 'en',
          onExit: () {},
          onComplete: (result) => completion = result,
          onSaveSnapshot: (value) => snapshot = value,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Choose the missing word to complete the sentence.'),
        findsOneWidget);
    expect(find.text('Check'), findsOneWidget);
    expect(find.text('Kiểm tra'), findsNothing);

    await tester.tap(find.widgetWithText(ElevatedButton, 'reads'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Check'));
    await tester.pump();

    expect(completion, isNotNull);
    expect(completion!.gameId, 'sentence_order');
    expect(completion!.metadata['engine'], 'sequence');
    expect(completion!.perfectRun, isTrue);
    expect(snapshot, isNotNull);
    expect(snapshot!.metadata, isEmpty);
    expect(find.text('Completed in 1 attempt!'), findsOneWidget);
  });

  testWidgets('Sentence Order uses Vietnamese sequence copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SentenceOrderScreen(
          level: _reorderLevel,
          allLevels: const [_reorderLevel],
          childProfileId: 'child-1',
          locale: 'vi',
          onExit: () {},
          onComplete: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sắp xếp các từ thành câu đúng.'), findsOneWidget);
    expect(find.text('Kiểm tra'), findsOneWidget);
  });
}

const _missingWordLevel = MiLevel(
  id: 'sentence-order-test-missing',
  gameId: 'sentence_order',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'en': {
      'prompt': 'Choose the missing word.',
      'sequence': {
        'contentId': 'sentence-order-test-missing-en',
        'gameId': 'sentence_order',
        'locale': 'en',
        'ageBand': 'explorer',
        'difficulty': 1,
        'instruction': 'Choose the missing word to complete the sentence.',
        'mode': 'missingItem',
        'correctOrder': [
          {'id': 'w1', 'content': 'Mia', 'type': 'text'},
          {'id': 'w2', 'content': 'reads', 'type': 'text'},
          {'id': 'w3', 'content': 'books', 'type': 'text'},
        ],
        'rule': {'type': 'fixed'},
        'missingIndices': [1],
        'choices': [
          {'id': 'd1', 'content': 'blue', 'type': 'text'},
          {'id': 'd2', 'content': 'quickly', 'type': 'text'},
        ],
        'estimatedSeconds': 60,
      },
    },
  },
  hints: [],
  metadata: {
    'ageGroup': 'explorer',
    'skillIds': ['letters.simple_sentences'],
  },
);

const _reorderLevel = MiLevel(
  id: 'sentence-order-test-reorder',
  gameId: 'sentence_order',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {
      'prompt': 'Sắp xếp câu đúng thứ tự.',
      'sequence': {
        'contentId': 'sentence-order-test-reorder-vi',
        'gameId': 'sentence_order',
        'locale': 'vi',
        'ageBand': 'explorer',
        'difficulty': 1,
        'instruction': 'Sắp xếp các từ thành câu đúng.',
        'mode': 'reorder',
        'correctOrder': [
          {'id': 'w1', 'content': 'Bé', 'type': 'text'},
          {'id': 'w2', 'content': 'đọc', 'type': 'text'},
          {'id': 'w3', 'content': 'sách', 'type': 'text'},
        ],
        'rule': {'type': 'fixed'},
        'estimatedSeconds': 60,
      },
    },
  },
  hints: [],
  metadata: {
    'ageGroup': 'explorer',
    'skillIds': ['letters.simple_sentences'],
  },
);
