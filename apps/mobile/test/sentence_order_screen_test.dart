import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/src/games/sentence_order/sentence_order_screen.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_engines/mi_game_engines.dart';

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
    expect(snapshot!.state['engine'], 'sequence');
    expect((snapshot!.state['sequence'] as Map)['missingSelections'], {
      '1': 'w2',
    });
    expect(find.text('Completed in 1 attempt!'), findsOneWidget);
  });

  testWidgets('Sentence Order restores a saved missing-word snapshot',
      (tester) async {
    MiCompletionResult? completion;

    await tester.pumpWidget(
      MaterialApp(
        home: SentenceOrderScreen(
          level: _missingWordLevel,
          allLevels: const [_missingWordLevel],
          childProfileId: 'child-1',
          locale: 'en',
          initialSnapshot: _savedMissingWordSnapshot,
          onExit: () {},
          onComplete: (result) => completion = result,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Check'));
    await tester.pump();

    expect(completion, isNotNull);
    expect(completion!.attemptsUsed, 2);
    expect(completion!.perfectRun, isFalse);
    expect(find.text('Completed in 2 attempts!'), findsOneWidget);
  });

  testWidgets('Sentence Order advances to the next level from completion',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SentenceOrderScreen(
          level: _missingWordLevel,
          allLevels: const [_missingWordLevel, _secondMissingWordLevel],
          childProfileId: 'child-1',
          locale: 'en',
          onExit: () {},
          onComplete: (_) {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'reads'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Check'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Next level'));
    await tester.pump();

    expect(find.text('Choose the action word.'), findsOneWidget);
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

final _savedMissingWordSnapshot = MiGameSnapshot(
  gameId: 'sentence_order',
  levelId: 'sentence-order-test-missing',
  childProfileId: 'child-1',
  state: {
    'engine': 'sequence',
    'sequence': const SequenceSnapshot(
      contentId: 'sentence-order-test-missing-en',
      mode: SequenceMode.missingItem,
      arrangementIds: [],
      missingSelections: {1: 'w2'},
      selectedMissingIndex: 1,
      attempts: 1,
      hintsUsed: 0,
      showHint: false,
      isComplete: false,
      lastSubmissionCorrect: false,
      completedItemCount: 1,
      totalItemCount: 3,
    ).toJson(),
    'contentVersion': 1,
  },
  createdAt: DateTime(2026, 1, 1),
  attemptsUsed: 1,
  itemsCompleted: 1,
  totalItems: 3,
);

const _secondMissingWordLevel = MiLevel(
  id: 'sentence-order-test-next',
  gameId: 'sentence_order',
  levelNumber: 2,
  difficulty: 1,
  localizedContent: {
    'en': {
      'prompt': 'Choose the action word.',
      'sequence': {
        'contentId': 'sentence-order-test-next-en',
        'gameId': 'sentence_order',
        'locale': 'en',
        'ageBand': 'explorer',
        'difficulty': 1,
        'instruction': 'Choose the action word.',
        'mode': 'missingItem',
        'correctOrder': [
          {'id': 'w1', 'content': 'Dad', 'type': 'text'},
          {'id': 'w2', 'content': 'waters', 'type': 'text'},
          {'id': 'w3', 'content': 'plants', 'type': 'text'},
        ],
        'rule': {'type': 'fixed'},
        'missingIndices': [1],
        'choices': [
          {'id': 'd1', 'content': 'yellow', 'type': 'text'},
          {'id': 'd2', 'content': 'slowly', 'type': 'text'},
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
