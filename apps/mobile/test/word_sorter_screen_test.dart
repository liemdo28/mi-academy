import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_academy/src/games/word_sorter/word_sorter_screen.dart';

MiLevel _loadLevel(int index) {
  final file = File('assets/levels/word_sorter.json');
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final raw = Map<String, dynamic>.from(
    (data['levels'] as List)[index] as Map,
  );
  return MiLevel(
    id: raw['id'] as String,
    gameId: raw['gameId'] as String,
    levelNumber: raw['levelNumber'] as int,
    difficulty: raw['difficulty'] as int,
    localizedContent: (raw['localizedContent'] as Map).map(
      (k, v) => MapEntry(k as String, (v as Map).cast<String, dynamic>()),
    ),
    hints: (raw['hints'] as List).cast<Map<String, dynamic>>(),
    metadata: (raw['metadata'] as Map).cast<String, dynamic>(),
  );
}

void main() {
  // Level 0 (ws-lv001, tier 1) is deterministic: 4 toy/vehicle words
  // sorted into "Đồ chơi" (capacity 2) and "Phương tiện đi lại" (capacity 2).
  late MiLevel level;

  setUp(() {
    level = _loadLevel(0);
  });

  testWidgets('renders and completes via tap-to-group, reports a real result', (tester) async {
    MiCompletionResult? result;
    await tester.pumpWidget(MaterialApp(
      home: WordSorterScreen(
        level: level,
        allLevels: const [],
        locale: 'vi',
        onExit: () {},
        onComplete: (r) => result = r,
      ),
    ));
    await tester.pump();

    expect(
      find.text('Sắp xếp các từ vào đúng nhóm: Đồ chơi và Phương tiện đi lại!'),
      findsOneWidget,
    );
    expect(find.text('xếp hình'), findsOneWidget);
    expect(find.text('Đồ chơi'), findsOneWidget);

    await tester.tap(find.text('xếp hình'));
    await tester.pump();
    await tester.tap(find.text('Đồ chơi'));
    await tester.pump();
    await tester.tap(find.text('gấu bông'));
    await tester.pump();
    await tester.tap(find.text('Đồ chơi'));
    await tester.pump();
    await tester.tap(find.text('tàu hỏa'));
    await tester.pump();
    await tester.tap(find.text('Phương tiện đi lại'));
    await tester.pump();
    await tester.tap(find.text('ô tô'));
    await tester.pump();
    await tester.tap(find.text('Phương tiện đi lại'));
    await tester.pump();

    expect(result, isNotNull);
    expect(result!.gameId, 'word_sorter');
    expect(result!.levelId, 'ws-lv001');
    expect(result!.perfectRun, isTrue);
  });

  testWidgets('drag-to-group also places an item', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WordSorterScreen(
        level: level,
        allLevels: const [],
        locale: 'vi',
        onExit: () {},
      ),
    ));
    await tester.pump();

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('xếp hình')));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(tester.getCenter(find.text('Đồ chơi')));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('1/2'), findsOneWidget);
  });

  testWidgets('an incorrect group placement is retryable', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WordSorterScreen(
        level: level,
        allLevels: const [],
        locale: 'vi',
        onExit: () {},
      ),
    ));
    await tester.pump();

    await tester.tap(find.text('xếp hình'));
    await tester.pump();
    await tester.tap(find.text('Phương tiện đi lại'));
    await tester.pump();

    expect(find.text('Chưa đúng vị trí, thử lại nhé!'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('xếp hình'));
    await tester.pump();
    await tester.tap(find.text('Đồ chơi'));
    await tester.pump();
    expect(find.text('1/2'), findsOneWidget);
  });

  testWidgets('hint reveals the authored hint text', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WordSorterScreen(
        level: level,
        allLevels: const [],
        locale: 'vi',
        onExit: () {},
      ),
    ));
    await tester.pump();

    await tester.tap(find.byTooltip('Gợi ý'));
    await tester.pump();
    expect(find.text('Đọc kỹ từng từ trước khi xếp vào nhóm.'), findsOneWidget);
  });

  testWidgets('English locale renders independently-authored English content', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WordSorterScreen(
        level: level,
        allLevels: const [],
        locale: 'en',
        onExit: () {},
      ),
    ));
    await tester.pump();

    // The English words for this exact level are independently authored,
    // not a translation of the Vietnamese ones -- assert the VI-only
    // words are truly absent under the EN locale.
    expect(find.text('xếp hình'), findsNothing);
  });

  testWidgets('malformed content shows a recoverable fallback, not a crash', (tester) async {
    const broken = MiLevel(
      id: 'broken',
      gameId: 'word_sorter',
      levelNumber: 1,
      difficulty: 1,
      localizedContent: {
        'vi': {'prompt': 'x', 'items': [], 'targets': []},
      },
      hints: [],
    );
    await tester.pumpWidget(MaterialApp(
      home: WordSorterScreen(
        level: broken,
        allLevels: const [],
        locale: 'vi',
        onExit: () {},
      ),
    ));
    await tester.pump();

    expect(find.text('Không thể tải cấp độ này lúc này.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('items and targets expose semantics labels', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WordSorterScreen(
        level: level,
        allLevels: const [],
        locale: 'vi',
        onExit: () {},
      ),
    ));
    await tester.pump();

    expect(find.bySemanticsLabel('xếp hình'), findsOneWidget);
  });

  test('titleFor exposes locale-appropriate game titles', () {
    expect(WordSorterScreen.titleFor('vi'), 'Phân loại từ');
    expect(WordSorterScreen.titleFor('en'), 'Word Sorter');
  });
}
