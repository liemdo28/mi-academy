import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

void main() {
  testWidgets('GameHeader exposes callbacks and child-safe labels',
      (tester) async {
    var exited = false;
    var muted = false;
    var paused = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameHeader(
            title: 'Ghép chữ tạo từ',
            score: 7,
            onExit: () => exited = true,
            onAudioToggle: () => muted = true,
            onPause: () => paused = true,
          ),
        ),
      ),
    );

    expect(find.text('Ghép chữ tạo từ'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.byTooltip('Quay lại'), findsOneWidget);
    expect(find.byTooltip('Tắt âm thanh'), findsOneWidget);
    expect(find.byTooltip('Tạm dừng'), findsOneWidget);

    await tester.tap(find.byTooltip('Quay lại'));
    await tester.tap(find.byTooltip('Tắt âm thanh'));
    await tester.tap(find.byTooltip('Tạm dừng'));

    expect(exited, isTrue);
    expect(muted, isTrue);
    expect(paused, isTrue);
  });

  testWidgets('HintButton disables itself when hints are exhausted',
      (tester) async {
    var hintsUsed = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              HintButton(
                onPressed: () => hintsUsed++,
                hintsAvailable: 2,
                hintsRemaining: 1,
              ),
              HintButton(
                onPressed: () => hintsUsed++,
                hintsAvailable: 2,
                hintsRemaining: 0,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.lightbulb_outline_rounded).first);
    await tester.tap(find.byIcon(Icons.lightbulb_outline_rounded).last);

    expect(hintsUsed, 1);
  });

  testWidgets('RetryPrompt uses gentle retry and optional hint actions',
      (tester) async {
    var retried = false;
    var hinted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RetryPrompt(
            message: 'Mình thử lại nhẹ nhàng nhé!',
            onRetry: () => retried = true,
            onUseHint: () => hinted = true,
          ),
        ),
      ),
    );

    expect(find.text('Mình thử lại nhẹ nhàng nhé!'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Gợi ý'), findsOneWidget);
    expect(find.textContaining('sai'), findsNothing);

    await tester.tap(find.text('Thử lại'));
    await tester.tap(find.text('Gợi ý'));

    expect(retried, isTrue);
    expect(hinted, isTrue);
  });

  testWidgets('CompletionOverlay provides replay, next, and exit actions',
      (tester) async {
    var next = false;
    var replay = false;
    var exit = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompletionOverlay(
            starsEarned: 2,
            maxStars: 3,
            message: 'Con đã hoàn thành nhiệm vụ!',
            score: 80,
            onNext: () => next = true,
            onReplay: () => replay = true,
            onExit: () => exit = true,
          ),
        ),
      ),
    );

    expect(find.text('Con đã hoàn thành nhiệm vụ!'), findsOneWidget);
    expect(find.text('Điểm: 80'), findsOneWidget);
    expect(find.byType(MiBrandIconView), findsWidgets);

    await tester.tap(find.text('Tiếp tục'));
    await tester.tap(find.text('Chơi lại'));
    await tester.tap(find.text('Trang chính'));

    expect(next, isTrue);
    expect(replay, isTrue);
    expect(exit, isTrue);
  });

  testWidgets('OfflineIndicator uses gentle offline wording', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: OfflineIndicator()),
      ),
    );

    expect(find.text('Đang chơi ngoại tuyến'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    expect(find.textContaining('lỗi'), findsNothing);
  });

  testWidgets('FeedbackBubble pairs text with non-color-only icons',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FeedbackBubble(isCorrect: true, message: 'Làm tốt lắm!'),
              FeedbackBubble(isCorrect: false, message: 'Mình thử lại nhé!'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Làm tốt lắm!'), findsOneWidget);
    expect(find.text('Mình thử lại nhé!'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  });

  testWidgets('ProgressDots renders a stable dot for every level',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProgressDots(total: 5, completed: 3),
        ),
      ),
    );

    final dotFinder = find.byWidgetPredicate(
      (widget) => widget is Container && widget.decoration is BoxDecoration,
    );
    expect(dotFinder, findsNWidgets(5));
  });

  testWidgets('AudioButton exposes muted and unmuted states', (tester) async {
    var toggles = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AudioButton(isMuted: false, onToggle: () => toggles++),
              AudioButton(isMuted: true, onToggle: () => toggles++),
            ],
          ),
        ),
      ),
    );

    expect(find.byTooltip('Tắt âm thanh'), findsOneWidget);
    expect(find.byTooltip('Bật âm thanh'), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('Tắt âm thanh'));
    await tester.tap(find.byTooltip('Bật âm thanh'));

    expect(toggles, 2);
  });

  testWidgets('PauseOverlay provides resume, restart, and exit actions',
      (tester) async {
    var resumed = false;
    var restarted = false;
    var exited = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PauseOverlay(
            onResume: () => resumed = true,
            onRestart: () => restarted = true,
            onExit: () => exited = true,
          ),
        ),
      ),
    );

    expect(find.text('Tạm dừng'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
    expect(find.text('Chơi lại'), findsOneWidget);
    expect(find.text('Thoát'), findsOneWidget);

    await tester.tap(find.text('Tiếp tục'));
    await tester.tap(find.text('Chơi lại'));
    await tester.tap(find.text('Thoát'));

    expect(resumed, isTrue);
    expect(restarted, isTrue);
    expect(exited, isTrue);
  });

  testWidgets('ExitConfirmation uses saved-progress wording and callbacks',
      (tester) async {
    var confirmed = false;
    var cancelled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExitConfirmation(
            onConfirm: () => confirmed = true,
            onCancel: () => cancelled = true,
          ),
        ),
      ),
    );

    expect(find.text('Bạn có muốn thoát không?'), findsOneWidget);
    expect(find.text('Tiến trình của bạn đã được lưu'), findsOneWidget);
    expect(find.textContaining('mất'), findsNothing);

    await tester.tap(find.text('Tiếp tục chơi'));
    await tester.tap(find.text('Thoát'));

    expect(cancelled, isTrue);
    expect(confirmed, isTrue);
  });

  testWidgets('TutorialOverlay shows image hint, paging, and continue action',
      (tester) async {
    var continued = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TutorialOverlay(
            title: 'Điều khiển MI',
            message: 'Đặt lệnh theo thứ tự để MI đi tới đích.',
            imageHint: Icons.smart_toy_rounded,
            pageNumber: 1,
            totalPages: 2,
            onContinue: () => continued = true,
          ),
        ),
      ),
    );

    expect(find.text('Điều khiển MI'), findsOneWidget);
    expect(
        find.text('Đặt lệnh theo thứ tự để MI đi tới đích.'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.byIcon(Icons.smart_toy_rounded), findsOneWidget);

    await tester.tap(find.text('Tiếp tục'));
    expect(continued, isTrue);
  });

  testWidgets('LoadingState and ErrorState use gentle retry surfaces',
      (tester) async {
    var retried = false;
    var exited = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const LoadingState(message: 'MI đang chuẩn bị...'),
              ErrorState(
                title: 'Mình thử lại nhé',
                message: 'Trò chơi cần tải lại một chút.',
                onRetry: () => retried = true,
                onExit: () => exited = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('MI đang chuẩn bị...'), findsOneWidget);
    expect(find.text('Mình thử lại nhé'), findsOneWidget);
    expect(find.text('Trò chơi cần tải lại một chút.'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Về trang chính'), findsOneWidget);
    expect(find.textContaining('stack'), findsNothing);

    await tester.tap(find.text('Thử lại'));
    await tester.tap(find.text('Về trang chính'));

    expect(retried, isTrue);
    expect(exited, isTrue);
  });
}
