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
    await _loadFonts(
      'Roboto',
      [
        r'C:\Windows\Fonts\arial.ttf',
        r'C:\Windows\Fonts\segoeui.ttf',
        r'C:\Windows\Fonts\seguisym.ttf',
        r'C:\Windows\Fonts\seguiemj.ttf',
        '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
        '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf',
        '/System/Library/Fonts/Supplemental/Arial.ttf',
      ],
    );
    await _loadFonts(
      'MaterialIcons',
      [
        if (Platform.environment['FLUTTER_ROOT'] case final root?)
          '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ],
    );
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

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/word_builder_slice.png'),
    );
  });

  testWidgets('golden: Sound Match MVP slice with transcript support',
      (tester) async {
    await pumpGame(
      tester,
      const SoundMatchScreen(
        level: soundMatchLevel,
        allLevels: [soundMatchLevel],
      ),
    );
    await tester.tap(find.text('Nghe lại'));
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sound_match_slice.png'),
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

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/math_race_slice.png'),
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

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/math_supermarket_slice.png'),
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

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/memory_cards_slice.png'),
    );
  });

  testWidgets('golden: Robot Commands MVP slice with one command',
      (tester) async {
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

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/robot_commands_slice.png'),
    );
  });
}

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
