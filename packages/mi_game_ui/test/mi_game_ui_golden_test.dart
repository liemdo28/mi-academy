import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFont(
      'Roboto',
      _firstExistingPath([
        r'C:\Windows\Fonts\arial.ttf',
        r'C:\Windows\Fonts\segoeui.ttf',
        '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
        '/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf',
        '/System/Library/Fonts/Supplemental/Arial.ttf',
      ]),
    );
    await _loadFont(
      'MaterialIcons',
      _firstExistingPath([
        if (Platform.environment['FLUTTER_ROOT'] case final root?)
          '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ]),
    );
  });

  Future<void> pumpGoldenSurface(
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
        home: Scaffold(
          backgroundColor: GameTheme.background,
          body: Center(child: child),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('golden: completion overlay keeps child-safe reward layout',
      (tester) async {
    await pumpGoldenSurface(
      tester,
      CompletionOverlay(
        starsEarned: 2,
        maxStars: 3,
        message: 'Con đã hoàn thành nhiệm vụ!',
        score: 80,
        onNext: () {},
        onReplay: () {},
        onExit: () {},
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/completion_overlay.png'),
    );
  });

  testWidgets('golden: tutorial overlay shows MI guidance without pressure',
      (tester) async {
    await pumpGoldenSurface(
      tester,
      TutorialOverlay(
        title: 'Điều khiển MI',
        message: 'Đặt lệnh theo thứ tự để MI đi tới đích.',
        imageHint: Icons.smart_toy_rounded,
        pageNumber: 1,
        totalPages: 2,
        onContinue: () {},
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tutorial_overlay.png'),
    );
  });

  testWidgets('golden: pause overlay keeps calm resume-first actions',
      (tester) async {
    await pumpGoldenSurface(
      tester,
      PauseOverlay(
        onResume: () {},
        onRestart: () {},
        onExit: () {},
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/pause_overlay.png'),
    );
  });

  testWidgets('golden: exit confirmation avoids loss-pressure wording',
      (tester) async {
    await pumpGoldenSurface(
      tester,
      ExitConfirmation(
        onConfirm: () {},
        onCancel: () {},
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/exit_confirmation.png'),
    );
  });

  testWidgets('golden: retry prompt and hint use gentle recovery copy',
      (tester) async {
    await pumpGoldenSurface(
      tester,
      RetryPrompt(
        message: 'Mình thử lại nhẹ nhàng nhé!',
        onRetry: () {},
        onUseHint: () {},
      ),
      size: const Size(390, 520),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/retry_prompt.png'),
    );
  });

  testWidgets('golden: error state keeps retry and home actions scannable',
      (tester) async {
    await pumpGoldenSurface(
      tester,
      ErrorState(
        title: 'Mình thử lại nhé',
        message: 'Trò chơi cần tải lại một chút.',
        onRetry: () {},
        onExit: () {},
      ),
      size: const Size(390, 640),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/error_state.png'),
    );
  });

  testWidgets('golden: loading state gives MI preparation feedback',
      (tester) async {
    await pumpGoldenSurface(
      tester,
      const LoadingState(message: 'MI đang chuẩn bị...'),
      size: const Size(390, 520),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/loading_state.png'),
    );
  });

  testWidgets('golden: compact controls remain readable together',
      (tester) async {
    await pumpGoldenSurface(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameHeader(
            title: 'Ghép chữ tạo từ',
            score: 7,
            onExit: () {},
            onAudioToggle: () {},
            onPause: () {},
          ),
          const SizedBox(height: 24),
          HintButton(
            onPressed: () {},
            hintsAvailable: 2,
            hintsRemaining: 1,
          ),
          const SizedBox(height: 24),
          const ProgressDots(total: 5, completed: 3),
          const SizedBox(height: 24),
          const FeedbackBubble(
            isCorrect: false,
            message: 'Mình thử lại nhé!',
          ),
          const SizedBox(height: 24),
          const OfflineIndicator(),
        ],
      ),
      size: const Size(390, 720),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/compact_controls.png'),
    );
  });
}

String? _firstExistingPath(List<String> paths) {
  for (final path in paths) {
    if (File(path).existsSync()) {
      return path;
    }
  }
  return null;
}

Future<void> _loadFont(String family, String? path) async {
  if (path == null) {
    return;
  }
  final bytes = File(path).readAsBytesSync();
  final fontLoader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
  await fontLoader.load();
}
