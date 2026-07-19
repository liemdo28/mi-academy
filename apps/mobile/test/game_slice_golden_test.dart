import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/src/games/choice/choice_game_screen.dart';
import 'package:mi_academy/src/games/memory_cards/memory_cards_game.dart';
import 'package:mi_academy/src/games/memory_cards/memory_cards_screen.dart';
import 'package:mi_academy/src/games/robot_commands/robot_commands_screen.dart';
import 'package:mi_academy/src/games/sound_match/sound_match_screen.dart';
import 'package:mi_academy/src/games/word_builder/word_builder_screen.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

import 'game_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Golden tests must render identically regardless of which OS runs
    // them. Loading fonts from OS-specific system paths (previous approach:
    // Windows Arial/Segoe UI vs Linux DejaVu vs macOS Arial) meant the
    // goldens captured on one platform never matched another platform's
    // rendering -- CI (Linux) was seeing 1-4% pixel diffs against goldens
    // captured on a Windows dev machine on every run, since DejaVu's glyph
    // metrics differ from Arial's. Loading one font file bundled in the
    // repo, the same on every platform, removes that source of divergence.
    await _loadFonts('Roboto', [_bundledFontPath]);
    await _loadFonts('MaterialIcons', [
      if (Platform.environment['FLUTTER_ROOT'] case final root?)
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);
  });

  Future<void> pumpGame(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: GameTheme.primary),
          useMaterial3: true,
        ),
        home: child,
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('golden: Word Builder MVP slice', (tester) async {
    await pumpGame(
      tester,
      const WordBuilderScreen(
        level: wordBuilderLevel,
        allLevels: [wordBuilderLevel],
      ),
    );

    // Semantic/widget assertions that hold on every host OS, so this test
    // still gives real regression coverage where pixel comparison isn't
    // authoritative (see _expectMatchesGoldenOnLinux).
    expect(find.text('Ghép chữ thành từ!'), findsOneWidget);
    expect(find.text('m'), findsOneWidget);

    await _expectMatchesGoldenOnLinux(
      tester,
      find.byType(MaterialApp),
      'goldens/word_builder_slice.png',
    );
  });

  testWidgets('golden: Sound Match MVP slice with transcript support', (
    tester,
  ) async {
    await pumpGame(
      tester,
      const SoundMatchScreen(
        level: soundMatchLevel,
        allLevels: [soundMatchLevel],
      ),
    );
    await tester.tap(find.text('Nghe lại'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nghe âm và chọn chữ cái!'), findsOneWidget);
    expect(find.text('A'), findsWidgets);

    await _expectMatchesGoldenOnLinux(
      tester,
      find.byType(MaterialApp),
      'goldens/sound_match_slice.png',
    );
  });

  testWidgets('golden: Math Race MVP slice', (tester) async {
    await pumpGame(
      tester,
      const ChoiceGameScreen(
        title: 'Đường đua cộng trừ',
        worldLabel: 'Xe MI tiến lên khi con chọn đúng.',
        level: mathRaceLevel,
        allLevels: [mathRaceLevel],
        heroIcon: Icons.directions_car_rounded,
        primaryColor: Color(0xFFFFC107),
      ),
    );

    expect(find.text('2 + 3 = ?'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    await _expectMatchesGoldenOnLinux(
      tester,
      find.byType(MaterialApp),
      'goldens/math_race_slice.png',
    );
  });

  testWidgets('golden: Math Supermarket MVP slice', (tester) async {
    await pumpGame(
      tester,
      const ChoiceGameScreen(
        title: 'Siêu thị toán học',
        worldLabel: 'Giỏ hàng MI giúp con luyện tính tiền.',
        level: mathSupermarketLevel,
        allLevels: [mathSupermarketLevel],
        heroIcon: Icons.shopping_cart_rounded,
        primaryColor: Color(0xFF00897B),
      ),
    );

    expect(
      find.text('Quả táo 2 đồng, quả chuối 3 đồng. Tổng cộng bao nhiêu?'),
      findsOneWidget,
    );
    expect(find.text('4 đồng'), findsOneWidget);
    expect(find.text('5 đồng'), findsOneWidget);

    await _expectMatchesGoldenOnLinux(
      tester,
      find.byType(MaterialApp),
      'goldens/math_supermarket_slice.png',
    );
  });

  testWidgets('golden: Memory Cards MVP slice after tutorial', (tester) async {
    await pumpGame(
      tester,
      MemoryCardsScreen(
        game: MemoryCardsGame(),
        level: memoryCardsLevel,
        onComplete: (_) {},
      ),
    );
    await tester.tap(find.text('Tiếp tục'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Tìm cặp giống nhau!'), findsOneWidget);
    expect(find.byType(GestureDetector), findsWidgets);

    await _expectMatchesGoldenOnLinux(
      tester,
      find.byType(MaterialApp),
      'goldens/memory_cards_slice.png',
    );
  });

  testWidgets('golden: Robot Commands MVP slice with one command', (
    tester,
  ) async {
    await pumpGame(
      tester,
      const RobotCommandsScreen(
        level: robotCommandsLevel,
        allLevels: [robotCommandsLevel],
      ),
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(ElevatedButton, 'TIẾN'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'TIẾN'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Đưa MI tới ngôi sao bằng 2 bước tiến.'), findsOneWidget);

    await _expectMatchesGoldenOnLinux(
      tester,
      find.byType(MaterialApp),
      'goldens/robot_commands_slice.png',
    );
  });
}

/// Flutter's own golden-testing docs are explicit that pixel goldens are
/// only guaranteed bit-identical when generated and compared on the same
/// operating system: text hinting/anti-aliasing differ at the Skia/OS
/// rasterizer level even with an identical bundled font loaded (confirmed:
/// loading the bundled Nunito font above already removed the *font-choice*
/// mismatch, but a 0.2-0.6% diff remains on Windows against the
/// Linux-generated goldens in `goldens/`). These goldens are generated on
/// and are authoritative for Linux (matching `.github/workflows/ci.yml`'s
/// `mobile-test-build` job, which runs on `ubuntu-latest`); on any other
/// host OS we skip the pixel comparison explicitly (not silently) and rely
/// on the widget/semantic assertions above for regression coverage instead.
/// See docs/testing.md#golden-tests.
Future<void> _expectMatchesGoldenOnLinux(
  WidgetTester tester,
  Finder finder,
  String golden,
) async {
  if (!Platform.isLinux) {
    markTestSkipped(
      'Pixel golden comparison for $golden only runs on Linux (the CI '
      'platform that generates these goldens); skipped on '
      '${Platform.operatingSystem}. See docs/testing.md#golden-tests.',
    );
    return;
  }
  await expectLater(finder, matchesGoldenFile(golden));
}

/// Bundled in the repo (already shipped as an app asset, OFL-licensed —
/// see apps/mobile/assets/fonts/nunito/OFL.txt) so golden rendering is
/// identical on every platform that runs `flutter test`.
const _bundledFontPath = 'assets/fonts/nunito/Nunito-VariableFont_wght.ttf';

Future<void> _loadFonts(String family, List<String> paths) async {
  final fontLoader = FontLoader(family);
  var loadedAny = false;

  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }
    final bytes = file.readAsBytesSync();
    fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    loadedAny = true;
  }

  if (loadedAny) {
    await fontLoader.load();
  }
}
