import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_accessibility/mi_game_accessibility.dart';

void main() {
  group('MiAccessibleButton', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiAccessibleButton(
              onPressed: () {},
              semanticLabel: 'Test button',
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      expect(find.text('Tap me'), findsOneWidget);
    });

    testWidgets('renders label and icon fallback content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiAccessibleButton(
              onPressed: () {},
              semanticLabel: 'Play game',
              label: 'Play',
              icon: Icons.play_arrow,
            ),
          ),
        ),
      );

      expect(find.text('Play'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiAccessibleButton(
              onPressed: () => tapped = true,
              semanticLabel: 'Tap me',
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MiAccessibleButton));

      expect(tapped, isTrue);
    });

    testWidgets('uses 48dp touch target by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MiAccessibleButton(
                onPressed: () {},
                semanticLabel: 'Test',
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(MiAccessibleButton),
          matching: find.byType(SizedBox),
        ),
      );

      expect(sizedBox.width, 48.0);
      expect(sizedBox.height, 48.0);
    });

    testWidgets('uses 64dp touch target when largeTarget is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MiAccessibleButton(
                onPressed: () {},
                semanticLabel: 'Test',
                largeTarget: true,
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(MiAccessibleButton),
          matching: find.byType(SizedBox),
        ),
      );

      expect(sizedBox.width, 64.0);
      expect(sizedBox.height, 64.0);
    });
  });

  group('MiAccessibleIconButton', () {
    testWidgets('renders icon with default touch target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiAccessibleIconButton(
              icon: Icons.volume_up,
              semanticLabel: 'Volume',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MiAccessibleIconButton),
          matching: find.byWidgetPredicate(
            (widget) => widget is SizedBox && widget.width == 48.0 && widget.height == 48.0,
          ),
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('renders large icon target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiAccessibleIconButton(
              icon: Icons.check,
              semanticLabel: 'Check',
              largeTarget: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(MiAccessibleIconButton),
          matching: find.byWidgetPredicate(
            (widget) => widget is SizedBox && widget.width == 64.0 && widget.height == 64.0,
          ),
        ),
        findsAtLeastNWidgets(1),
      );
    });
  });
}
