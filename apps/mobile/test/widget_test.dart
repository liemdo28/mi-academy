import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:localization/localization.dart';
import 'package:mi_academy/main.dart';
import 'package:mi_academy/providers/child_provider.dart';
import 'package:mi_academy/providers/providers.dart';
import 'package:mi_academy/screens/child_home_screen.dart';
import 'package:mi_academy/screens/garden_screen.dart';
import 'package:mi_academy/screens/parent_dashboard_screen.dart';
import 'package:mi_academy/screens/parent_pin_screen.dart';
import 'package:mi_academy/screens/parent_settings_screen.dart';
import 'package:mi_academy/screens/world_map_screen.dart';
import 'package:mi_academy/services/parent_settings_store.dart';
import 'package:mi_academy/src/games/choice/choice_game_screen.dart';
import 'package:mi_academy/src/games/memory_cards/memory_cards_game.dart';
import 'package:mi_academy/src/games/memory_cards/memory_cards_screen.dart';
import 'package:mi_academy/src/games/robot_commands/robot_commands_screen.dart';
import 'package:mi_academy/src/games/sound_match/sound_match_screen.dart';
import 'package:mi_academy/src/games/word_builder/word_builder_screen.dart';

import 'game_test_fixtures.dart';

class _FixedActiveChildNotifier extends ActiveChildNotifier {
  _FixedActiveChildNotifier(this._state);
  final ActiveChildState _state;

  @override
  ActiveChildState build() => _state;
}

void main() {
  testWidgets('Debug game picker shell renders the first playable game entries',
      (tester) async {
    await tester.pumpWidget(DebugGamePickerApp(key: UniqueKey()));
    await pumpUntilFound(tester, find.text('Thế giới khám phá'));

    expect(find.text('MI Academy'), findsOneWidget);
    expect(find.text('Thế giới khám phá'), findsOneWidget);
    expect(find.text('Hồ sơ của bé'), findsOneWidget);
    expect(find.text('Sao MI: 0'), findsOneWidget);
    expect(find.text('Huy hiệu: sẵn sàng'), findsOneWidget);
    expect(find.text('8 game offline'), findsOneWidget);
    await dragUntilFound(tester, find.text('Khu vực phụ huynh'));
    expect(find.text('Khu vực phụ huynh'), findsOneWidget);
    expect(find.text('Khám phá chữ cái'), findsOneWidget);
    await dragUntilFound(tester, find.text('Tìm chữ còn thiếu'));
    expect(find.text('Tìm chữ còn thiếu'), findsOneWidget);
    await dragUntilFound(tester, find.text('Ghép chữ tạo từ'));
    expect(find.text('Ghép chữ tạo từ'), findsOneWidget);
    await dragUntilFound(tester, find.text('Nghe âm tìm chữ'));
    expect(find.text('Nghe âm tìm chữ'), findsOneWidget);
    await dragUntilFound(tester, find.text('Đường đua cộng trừ'));
    expect(find.text('Đường đua cộng trừ'), findsOneWidget);
    await dragUntilFound(tester, find.text('Siêu thị toán học'));
    expect(find.text('Siêu thị toán học'), findsOneWidget);
    await dragUntilFound(tester, find.text('Ghi nhớ vị trí'));
    expect(find.text('Ghi nhớ vị trí'), findsOneWidget);
    await dragUntilFound(tester, find.text('Robot làm theo lệnh'));
    expect(find.text('Robot làm theo lệnh'), findsOneWidget);
  });

  testWidgets('Local parent area shows gentle report and opens settings',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LocalParentAreaScreen(
          parentSettingsStore: MemoryParentSettingsStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Báo cáo nhẹ nhàng'), findsOneWidget);
    await dragUntilFound(tester, find.text('Kỹ năng đang làm tốt'));
    expect(find.text('Kỹ năng đang làm tốt'), findsOneWidget);
    await dragUntilFound(tester, find.text('Gợi ý luyện thêm'));
    expect(find.text('Gợi ý luyện thêm'), findsOneWidget);
    await dragUntilFound(tester, find.text('Offline'));
    expect(find.text('Offline'), findsOneWidget);

    await dragUntilFound(tester, find.text('Mở cài đặt phụ huynh'));
    await tester.tap(find.text('Mở cài đặt phụ huynh'));
    await tester.pumpAndSettle();

    expect(find.text('Giới hạn thời gian'), findsOneWidget);
    await dragUntilFound(tester, find.text('Tải nội dung offline'));
    expect(find.text('Tải nội dung offline'), findsOneWidget);
  });

  testWidgets('Word Builder renders playable controls', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WordBuilderScreen(
          level: wordBuilderLevel,
          allLevels: [wordBuilderLevel],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Ghép chữ tạo từ'), findsWidgets);
    expect(find.text('Kiểm tra'), findsOneWidget);
    expect(find.text('m'), findsOneWidget);
  });

  testWidgets('Word Builder completes a correct word', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WordBuilderScreen(
          level: wordBuilderLevel,
          allLevels: [wordBuilderLevel],
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('m'));
    await tester.pump();
    await tester.tap(find.text('è'));
    await tester.pump();
    await tester.tap(find.text('o'));
    await tester.pump();
    await tester.tap(find.text('Kiểm tra'));
    await tester.pump();

    expect(find.text('Con đã ghép đúng từ!'), findsOneWidget);
  });

  testWidgets('Word Builder gives a gentle prompt for incomplete answers',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WordBuilderScreen(
          level: wordBuilderLevel,
          allLevels: [wordBuilderLevel],
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Kiểm tra'));
    await tester.pump();

    expect(find.text('Mình còn ô trống, thử ghép thêm nhé!'), findsOneWidget);
    expect(find.textContaining('sai'), findsNothing);
    expect(find.textContaining('trừ'), findsNothing);
  });

  testWidgets('Sound Match renders playable controls', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SoundMatchScreen(
          level: soundMatchLevel,
          allLevels: [soundMatchLevel],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Nghe âm tìm chữ'), findsWidgets);
    expect(find.text('Nghe lại'), findsOneWidget);
    expect(find.text('A'), findsWidgets);
  });

  testWidgets('Sound Match completes a correct answer', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SoundMatchScreen(
          level: soundMatchLevel,
          allLevels: [soundMatchLevel],
        ),
      ),
    );
    await tester.pump();

    final answerA = find.widgetWithText(ElevatedButton, 'A');
    await tester.ensureVisible(answerA);
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getTopLeft(answerA) + const Offset(24, 24));
    await tester.pumpAndSettle();

    expect(find.text('Con đã nghe và chọn đúng!'), findsOneWidget);
  });

  testWidgets('Sound Match reveals transcript and gentle retry after mismatch',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SoundMatchScreen(
          level: soundMatchLevel,
          allLevels: [soundMatchLevel],
        ),
      ),
    );
    await tester.pump();

    final answerB = find.widgetWithText(ElevatedButton, 'B');
    await tester.ensureVisible(answerB);
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getTopLeft(answerB) + const Offset(24, 24));
    await tester.pump();

    expect(
      find.text(
        'Chưa khớp rồi, con nghe lại và thử đáp án khác nhé!',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(find.text('A'), findsWidgets);
    expect(find.textContaining('sai'), findsNothing);
  });

  testWidgets('Math Race renders playable controls', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChoiceGameScreen(
          title: 'Đường đua cộng trừ',
          worldLabel: 'Xe MI tiến lên khi con chọn đúng.',
          level: mathRaceLevel,
          allLevels: [mathRaceLevel],
          heroIcon: Icons.directions_car_rounded,
          primaryColor: Color(0xFFFFC107),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Đường đua cộng trừ'), findsWidgets);
    expect(find.text('2 + 3 = ?'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('Math Race completes a correct answer', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChoiceGameScreen(
          title: 'Đường đua cộng trừ',
          worldLabel: 'Xe MI tiến lên khi con chọn đúng.',
          level: mathRaceLevel,
          allLevels: [mathRaceLevel],
          heroIcon: Icons.directions_car_rounded,
          primaryColor: Color(0xFFFFC107),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('5'));
    await tester.pump();

    expect(find.text('MI thấy con đã hiểu bài!'), findsOneWidget);
  });

  testWidgets('Math Race keeps progress gentle after an incorrect choice',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChoiceGameScreen(
          title: 'Đường đua cộng trừ',
          worldLabel: 'Xe MI tiến lên khi con chọn đúng.',
          level: mathRaceLevel,
          allLevels: [mathRaceLevel],
          heroIcon: Icons.directions_car_rounded,
          primaryColor: Color(0xFFFFC107),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('4'));
    await tester.pump();

    expect(find.text('Gần đúng rồi, mình thử cách khác nhé!'), findsOneWidget);
    expect(find.textContaining('bị trừ'), findsNothing);
    expect(find.textContaining('thua'), findsNothing);
  });

  testWidgets('Math Supermarket renders playable controls', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChoiceGameScreen(
          title: 'Siêu thị toán học',
          worldLabel: 'Giỏ hàng MI giúp con luyện tính tiền.',
          level: mathSupermarketLevel,
          allLevels: [mathSupermarketLevel],
          heroIcon: Icons.shopping_cart_rounded,
          primaryColor: Color(0xFF00897B),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Siêu thị toán học'), findsWidgets);
    expect(find.text('Quả táo 2 đồng, quả chuối 3 đồng. Tổng cộng bao nhiêu?'),
        findsOneWidget);
    expect(find.text('5 đồng'), findsOneWidget);
  });

  testWidgets('Math Supermarket completes a correct answer', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChoiceGameScreen(
          title: 'Siêu thị toán học',
          worldLabel: 'Giỏ hàng MI giúp con luyện tính tiền.',
          level: mathSupermarketLevel,
          allLevels: [mathSupermarketLevel],
          heroIcon: Icons.shopping_cart_rounded,
          primaryColor: Color(0xFF00897B),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('5 đồng'));
    await tester.pump();

    expect(find.text('MI thấy con đã hiểu bài!'), findsOneWidget);
  });

  testWidgets('Math Supermarket hint teaches without solving by pressure',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChoiceGameScreen(
          title: 'Siêu thị toán học',
          worldLabel: 'Giỏ hàng MI giúp con luyện tính tiền.',
          level: mathSupermarketLevel,
          allLevels: [mathSupermarketLevel],
          heroIcon: Icons.shopping_cart_rounded,
          primaryColor: Color(0xFF00897B),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.lightbulb_outline_rounded));
    await tester.pump();

    expect(
      find.text('Cộng giá hai mặt hàng', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.textContaining('nhanh'), findsNothing);
    expect(find.textContaining('hết giờ'), findsNothing);
  });

  testWidgets('Memory Cards initializes from level content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MemoryCardsScreen(
          game: MemoryCardsGame(),
          level: memoryCardsLevel,
          onComplete: (_) {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Memory Cards'), findsWidgets);
    expect(find.text('Tiếp tục'), findsOneWidget);

    await tester.tap(find.text('Tiếp tục'));
    await tester.pump();

    expect(find.text('Tìm cặp giống nhau!'), findsOneWidget);
  });

  testWidgets('Memory Cards completes by matching every pair', (tester) async {
    var completed = false;
    final game = MemoryCardsGame();

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MemoryCardsScreen(
          game: game,
          level: memoryCardsLevel,
          onComplete: (_) => completed = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Tiếp tục'));
    await tester.pump();

    final pairToIndexes = <String, List<int>>{};
    for (var i = 0; i < game.cards.length; i++) {
      pairToIndexes.putIfAbsent(game.cards[i].pairId, () => []).add(i);
    }

    for (final indexes in pairToIndexes.values) {
      await _tapMemoryCardAt(tester, indexes[0]);
      await tester.pump();
      await _tapMemoryCardAt(tester, indexes[1]);
      await tester.pump();
    }

    expect(completed, isTrue);
  });

  testWidgets(
      'Memory Cards respects reduceMotion by collapsing the flip animation',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MemoryCardsScreen(
          game: MemoryCardsGame(),
          level: memoryCardsLevel,
          onComplete: (_) {},
          reduceMotion: true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Tiếp tục'));
    await tester.pump();

    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer).first,
    );
    expect(container.duration, Duration.zero);
  });

  testWidgets('Robot Commands renders playable controls', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RobotCommandsScreen(
          level: robotCommandsLevel,
          allLevels: [robotCommandsLevel],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Robot làm theo lệnh'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('TIẾN'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Chạy lệnh'), findsOneWidget);
    expect(find.text('TIẾN'), findsOneWidget);
  });

  testWidgets('Robot Commands completes a valid command sequence',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RobotCommandsScreen(
          level: robotCommandsLevel,
          allLevels: [robotCommandsLevel],
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.widgetWithText(ElevatedButton, 'TIẾN'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'TIẾN'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'TIẾN'));
    await tester.pump();
    await tester.tap(find.text('Chạy lệnh'));
    await tester.pump();

    expect(find.text('Con đã lập trình cho MI!'), findsOneWidget);
  });

  testWidgets('Robot Commands moves and removes specific commands',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RobotCommandsScreen(
          level: robotCommandsTurnLevel,
          allLevels: [robotCommandsTurnLevel],
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.widgetWithText(ElevatedButton, 'TIẾN'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'TIẾN'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'RẼ PHẢI'));
    await tester.pump();

    expect(find.text('1. TIẾN'), findsOneWidget);
    expect(find.text('2. RẼ PHẢI'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('robot-command-move-left-1')));
    await tester.pump();

    expect(find.text('1. RẼ PHẢI'), findsOneWidget);
    expect(find.text('2. TIẾN'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('robot-command-remove-0')));
    await tester.pump();

    expect(find.text('1. TIẾN'), findsOneWidget);
    expect(find.text('RẼ PHẢI'), findsOneWidget);
    expect(find.text('1. RẼ PHẢI'), findsNothing);

    await tester.tap(find.byTooltip('Làm lại'));
    await tester.pump();

    expect(find.text('1. TIẾN'), findsNothing);
  });

  testWidgets('Robot Commands allows gentle retry after an incomplete run',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RobotCommandsScreen(
          level: robotCommandsLevel,
          allLevels: [robotCommandsLevel],
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.widgetWithText(ElevatedButton, 'TIẾN'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'TIẾN'));
    await tester.pump();
    await tester.tap(find.text('Chạy lệnh'));
    await tester.pump();

    expect(
      find.text(
        'Robot MI chưa tới đủ mục tiêu, mình thử đổi lệnh nhé!',
        skipOffstage: false,
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'TIẾN'));
    await tester.pump();
    await tester.tap(find.text('Chạy lệnh'));
    await tester.pump();

    expect(find.text('Con đã lập trình cho MI!'), findsOneWidget);
  });

  testWidgets('Parent PIN locks after three failed attempts', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          parentPinVerifierProvider.overrideWithValue((_) async => false),
        ],
        child: const MaterialApp(
          home: ParentPinScreen(
            enableBiometricPrompt: false,
            lockoutDuration: Duration(seconds: 30),
          ),
        ),
      ),
    );
    await tester.pump();

    for (var attempt = 0; attempt < 3; attempt++) {
      await _enterPin(tester, '1234');
      await tester.pumpAndSettle();
    }

    expect(
      find.text('Tạm khóa khu vực phụ huynh trong 30 giây.'),
      findsOneWidget,
    );

    final oneButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '1').first,
    );
    expect(oneButton.onPressed, isNull);
  });

  testWidgets('Parent PIN adult math fallback unlocks parent area',
      (tester) async {
    var unlocked = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          parentPinVerifierProvider.overrideWithValue((_) async => false),
        ],
        child: MaterialApp(
          home: ParentPinScreen(
            enableBiometricPrompt: false,
            onUnlocked: () => unlocked = true,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Quên PIN?'));
    await tester.tap(find.text('Quên PIN?'));
    await tester.pumpAndSettle();

    expect(find.text('8 + 5 = ?'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('adult-challenge-answer')),
      '13',
    );
    await tester.tap(find.text('Mở khu vực phụ huynh'));
    await tester.pump();

    expect(unlocked, isTrue);
  });

  group('Parent Dashboard', () {
    Widget buildDashboard({
      required List<Override> overrides,
    }) {
      return ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/dashboard',
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const ParentDashboardScreen(),
              ),
              GoRoute(
                path: '/parent/settings',
                builder: (context, state) =>
                    const Scaffold(body: Text('SETTINGS')),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('shows a loading state while reports are in flight',
        (tester) async {
      await tester.pumpWidget(buildDashboard(overrides: [
        reportsProvider.overrideWith(
          (ref) => Completer<List<Map<String, dynamic>>>().future,
        ),
      ]));
      await tester.pump();

      expect(find.text('Đang tải...'), findsOneWidget);
    });

    testWidgets('shows a retryable error state when reports fail to load',
        (tester) async {
      await tester.pumpWidget(buildDashboard(overrides: [
        reportsProvider
            .overrideWith((ref) async => throw Exception('network down')),
      ]));
      await tester.pump();

      expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('shows an empty-activity placeholder when no report exists yet',
        (tester) async {
      await tester.pumpWidget(buildDashboard(overrides: [
        reportsProvider.overrideWith((ref) async => []),
        activeChildProvider.overrideWith(
          () => _FixedActiveChildNotifier(const ActiveChildState(children: [])),
        ),
      ]));
      await tester.pump();

      expect(find.text('Chưa có hoạt động'), findsOneWidget);
      expect(find.text('Chưa có hồ sơ'), findsOneWidget);
    });

    testWidgets('shows today\'s summary and child cards once data loads',
        (tester) async {
      await tester.pumpWidget(buildDashboard(overrides: [
        reportsProvider.overrideWith((ref) async => [
              {
                'total_lessons_today': 2,
                'total_games_today': 3,
                'total_time_minutes_today': 25,
                'total_stars_today': 4,
              },
            ]),
        activeChildProvider.overrideWith(() => _FixedActiveChildNotifier(
              const ActiveChildState(
                childId: 'child-1',
                children: [
                  {'id': 'child-1', 'nickname': 'Mi', 'age_group': 'junior'},
                ],
              ),
            )),
      ]));
      await tester.pump();

      expect(find.text('Tổng quan hôm nay'), findsOneWidget);
      expect(find.text('4'), findsOneWidget); // stars
      expect(find.text('Mi'), findsOneWidget);
    });

    testWidgets('retry after an error re-fetches and shows real data',
        (tester) async {
      var attempt = 0;
      await tester.pumpWidget(buildDashboard(overrides: [
        reportsProvider.overrideWith((ref) async {
          attempt += 1;
          if (attempt == 1) throw Exception('network down');
          return [
            {
              'total_lessons_today': 1,
              'total_games_today': 1,
              'total_time_minutes_today': 5,
              'total_stars_today': 1,
            },
          ];
        }),
        activeChildProvider.overrideWith(
          () => _FixedActiveChildNotifier(const ActiveChildState(children: [])),
        ),
      ]));
      await tester.pump();

      expect(find.text('Không thể tải dữ liệu'), findsOneWidget);

      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Tổng quan hôm nay'), findsOneWidget);
    });
  });

  group('Child Home v2', () {
    ActiveChildState fakeActiveChild() => const ActiveChildState(
          childId: 'child-1',
          child: {'id': 'child-1', 'nickname': 'Mi'},
        );
    GoRouter buildTestRouter() => GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const ChildHomeScreen(),
            ),
            GoRoute(
              path: '/world',
              builder: (context, state) => const WorldMapScreen(),
            ),
            GoRoute(
              path: '/garden',
              builder: (context, state) => const GardenScreen(),
            ),
            GoRoute(
              path: '/parent-pin',
              builder: (context, state) =>
                  const Scaffold(body: Text('PARENT_GATE')),
            ),
          ],
        );
    Widget buildHomeTestApp(GoRouter router) {
      return MaterialApp.router(
        theme: MiTheme.light,
        locale: const Locale('vi'),
        supportedLocales: supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      );
    }

    testWidgets('shows one dominant CTA and no dead tabs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: buildHomeTestApp(buildTestRouter()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bắt đầu học'), findsOneWidget);
      expect(find.text('Sao'), findsOneWidget);
      expect(find.text('Huy hiệu'), findsOneWidget);
      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Bản đồ'), findsOneWidget);
      expect(find.text('Vườn'), findsOneWidget);
    });

    testWidgets('world map and garden tabs navigate to real screens',
        (tester) async {
      final router = buildTestRouter();
      await tester.pumpWidget(
        ProviderScope(
          child: buildHomeTestApp(router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bản đồ').last);
      await tester.pumpAndSettle();
      expect(find.text('Bản đồ thế giới'), findsOneWidget);

      router.go('/home');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Vườn').last);
      await tester.pumpAndSettle();
      expect(find.text('Vườn thành tích'), findsOneWidget);
    });

    testWidgets(
        "the hero CTA launches the daily plan's game_type, not always memory_cards",
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyPlanProvider.overrideWith((ref) async => [
                  {
                    'lesson_id': 'lesson-1',
                    'title': 'Robot Lesson',
                    'subject': 'logic',
                    'estimated_minutes': 5,
                    'type': 'lesson',
                    'is_required': true,
                    'game_type': 'robot_commands',
                  },
                ]),
            activeChildProvider.overrideWith(
                () => _FixedActiveChildNotifier(fakeActiveChild())),
          ],
          child: buildHomeTestApp(
            GoRouter(
              initialLocation: '/home',
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const ChildHomeScreen(),
                ),
                GoRoute(
                  path: '/game/:gameId',
                  builder: (context, state) =>
                      Text('LAUNCHED_${state.pathParameters['gameId']}'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tiếp tục học'));
      await tester.pumpAndSettle();

      expect(find.text('LAUNCHED_robot_commands'), findsOneWidget);
    });

    testWidgets('parent gate requires a sustained hold, not a tap',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: buildHomeTestApp(buildTestRouter()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel(
        'Khu vực phụ huynh, giữ 3 giây để mở',
      ));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('PARENT_GATE'), findsNothing);

      final gesture = await tester.startGesture(
        tester.getCenter(
            find.bySemanticsLabel('Khu vực phụ huynh, giữ 3 giây để mở')),
      );
      await tester.pump(const Duration(seconds: 3, milliseconds: 100));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('PARENT_GATE'), findsOneWidget);
    });
  });

  testWidgets('Parent settings confirms offline download and data export',
      (tester) async {
    final store = MemoryParentSettingsStore();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ParentSettingsScreen(store: store),
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Tải nội dung offline'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
    await tester.pump();
    await tester.tap(find.text('Tải nội dung offline'));
    await tester.pump();

    expect(find.text('Sẵn sàng học không cần mạng'), findsOneWidget);
    expect(
      find.text('Nội dung MVP đã sẵn sàng để học offline.'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Xuất dữ liệu của bé'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
    await tester.pump();
    await tester.tap(find.text('Xuất dữ liệu của bé'));
    await tester.pump();

    expect(find.text('Bản xuất dữ liệu đã sẵn sàng'), findsOneWidget);
    expect(
        store.lastExportJson, contains('mi-academy-parent-settings-export-v1'));
  });

  testWidgets('Parent settings reduce-motion toggle persists to the store',
      (tester) async {
    final store = MemoryParentSettingsStore();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ParentSettingsScreen(store: store),
        ),
      ),
    );
    await tester.pump();

    expect((await store.load()).reduceMotion, isFalse);

    await tester.tap(find.text('Giảm hiệu ứng chuyển động'));
    await tester.pump();

    expect((await store.load()).reduceMotion, isTrue);
  });

  testWidgets('Parent settings persist after reopening the screen',
      (tester) async {
    final store = MemoryParentSettingsStore();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ParentSettingsScreen(store: store),
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('English'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
    await tester.pump();
    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Tải nội dung offline'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
    await tester.pump();
    await tester.tap(find.text('Tải nội dung offline'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Xuất dữ liệu của bé'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
    await tester.pump();
    await tester.tap(find.text('Xuất dữ liệu của bé'));
    await tester.pump();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ParentSettingsScreen(store: store),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('English'), findsOneWidget);
    final englishChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'English'),
    );
    expect(englishChip.selected, isTrue);

    await tester.scrollUntilVisible(
      find.text('Tải nội dung offline'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
    await tester.pump();
    expect(find.text('Sẵn sàng học không cần mạng'), findsOneWidget);
    expect(find.text('Bản xuất dữ liệu đã sẵn sàng'), findsOneWidget);
  });

  testWidgets('Parent settings requires confirmation before deleting data',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ParentSettingsScreen(store: MemoryParentSettingsStore()),
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Xóa dữ liệu của bé'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
    await tester.pump();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pump();
    await tester.tap(find.text('Xóa dữ liệu của bé'));
    await tester.pumpAndSettle();

    expect(find.text('Xóa dữ liệu của bé?'), findsOneWidget);
    expect(find.text('Cần xác nhận của phụ huynh'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('confirm-delete-child-data')));
    await tester.pumpAndSettle();

    expect(find.text('Yêu cầu xóa đã được ghi nhận'), findsOneWidget);
    expect(
      find.text('Đã ghi nhận yêu cầu xóa dữ liệu trên thiết bị.'),
      findsOneWidget,
    );
  });
}

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final digit in pin.characters) {
    final button = find.widgetWithText(OutlinedButton, digit).first;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 120,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

Future<void> dragUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxDrags = 12,
}) async {
  for (var i = 0; i < maxDrags; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await pumpUntilFound(tester, find.byType(Scrollable), maxPumps: 10);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pumpAndSettle();
  }
}

Future<void> _tapMemoryCardAt(WidgetTester tester, int index) async {
  final card = find.bySemanticsLabel('Thẻ úp, vị trí ${index + 1}');
  expect(card, findsOneWidget);
  await tester.ensureVisible(card);
  await tester.tap(card);
}
