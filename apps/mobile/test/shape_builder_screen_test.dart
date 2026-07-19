import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_academy/src/games/shape_builder/shape_builder_screen.dart';

MiLevel _loadLevel(int index) {
  final file = File('assets/levels/shape_builder.json');
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
  // Level 0 (sb-lv001, tier 1) is deterministic: two items, "Hình tam
  // giác" -> "Ô của hình tam giác" and "Hình thoi" -> "Ô của hình thoi".
  late MiLevel level;

  setUp(() {
    level = _loadLevel(0);
  });

  testWidgets('renders and completes via tap-to-place, reports a real result', (tester) async {
    MiCompletionResult? result;
    await tester.pumpWidget(MaterialApp(
      home: ShapeBuilderScreen(
        level: level,
        allLevels: const [],
        locale: 'vi',
        onExit: () {},
        onComplete: (r) => result = r,
      ),
    ));
    await tester.pump();

    expect(find.text('Đặt mỗi hình vào đúng ô của nó!'), findsOneWidget);
    expect(find.text('Hình tam giác'), findsOneWidget);
    expect(find.text('Hình thoi'), findsOneWidget);

    await tester.tap(find.text('Hình tam giác'));
    await tester.pump();
    await tester.tap(find.text('Ô của hình tam giác'));
    await tester.pump();
    await tester.tap(find.text('Hình thoi'));
    await tester.pump();
    await tester.tap(find.text('Ô của hình thoi'));
    await tester.pump();

    expect(result, isNotNull);
    expect(result!.gameId, 'shape_builder');
    expect(result!.levelId, 'sb-lv001');
    expect(result!.perfectRun, isTrue);
    expect(result!.maxScore, 100);
  });

  testWidgets('drag placement also completes the level', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ShapeBuilderScreen(
        level: level,
        allLevels: const [],
        locale: 'vi',
        onExit: () {},
      ),
    ));
    await tester.pump();

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Hình tam giác')));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture
        .moveTo(tester.getCenter(find.text('Ô của hình tam giác')));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('1/1'), findsOneWidget);
  });

  testWidgets('an incorrect placement is retryable, not a crash', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ShapeBuilderScreen(
        level: level,
        allLevels: const [],
        locale: 'vi',
        onExit: () {},
      ),
    ));
    await tester.pump();

    await tester.tap(find.text('Hình tam giác'));
    await tester.pump();
    await tester.tap(find.text('Ô của hình thoi'));
    await tester.pump();

    expect(find.text('Chưa đúng vị trí, thử lại nhé!'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Retryable: the correct placement still works afterwards.
    await tester.tap(find.text('Hình tam giác'));
    await tester.pump();
    await tester.tap(find.text('Ô của hình tam giác'));
    await tester.pump();
    expect(find.text('1/1'), findsOneWidget);
  });

  testWidgets('hint reveals the authored hint text', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ShapeBuilderScreen(
        level: level,
        allLevels: const [],
        locale: 'vi',
        onExit: () {},
      ),
    ));
    await tester.pump();

    await tester.tap(find.byTooltip('Gợi ý'));
    await tester.pump();
    expect(find.text('Nhìn kỹ hình dạng của từng ô trống.'), findsOneWidget);
  });

  testWidgets('English locale renders English labels', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ShapeBuilderScreen(
        level: level,
        allLevels: const [],
        locale: 'en',
        onExit: () {},
      ),
    ));
    await tester.pump();

    expect(find.text('Place each shape into its own slot!'), findsOneWidget);
    expect(find.text('Triangle'), findsOneWidget);
  });

  testWidgets('malformed content shows a recoverable fallback, not a crash', (tester) async {
    const broken = MiLevel(
      id: 'broken',
      gameId: 'shape_builder',
      levelNumber: 1,
      difficulty: 1,
      localizedContent: {
        'vi': {'prompt': 'x', 'items': [], 'targets': []},
      },
      hints: [],
    );
    await tester.pumpWidget(MaterialApp(
      home: ShapeBuilderScreen(
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
      home: ShapeBuilderScreen(
        level: level,
        allLevels: const [],
        locale: 'vi',
        onExit: () {},
      ),
    ));
    await tester.pump();

    expect(find.bySemanticsLabel('Hình tam giác'), findsOneWidget);
  });

  test('titleFor exposes locale-appropriate game titles', () {
    expect(ShapeBuilderScreen.titleFor('vi'), 'Xây hình khối');
    expect(ShapeBuilderScreen.titleFor('en'), 'Shape Builder');
  });
}
