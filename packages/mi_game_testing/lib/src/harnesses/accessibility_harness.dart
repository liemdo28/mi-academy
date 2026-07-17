import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test harness for verifying accessibility compliance of game widgets.
class AccessibilityHarness {
  AccessibilityHarness._();

  /// Verify minimum touch target size (default 48x48 logical pixels).
  static void expectMinTouchTarget(
    Widget widget,
    WidgetTester tester, {
    double minSize = 48.0,
  }) {
    final size = tester.getSize(find.byWidget(widget));
    expect(
      size.width,
      greaterThanOrEqualTo(minSize),
      reason: 'Touch target width must be at least $minSize px',
    );
    expect(
      size.height,
      greaterThanOrEqualTo(minSize),
      reason: 'Touch target height must be at least $minSize px',
    );
  }

  /// Verify a widget with the given semantic label exists.
  static void expectSemanticLabelExists(WidgetTester tester, String label) {
    expect(
      find.bySemanticsLabel(label),
      findsOneWidget,
      reason: 'Expected semantic label: $label',
    );
  }

  /// Verify all Semantics nodes in the widget tree have labels.
  static void expectAllSemanticsLabeled(WidgetTester tester) {
    final semantics = tester.widgetList<Semantics>(find.byType(Semantics));
    for (final s in semantics) {
      expect(
        s.properties.label,
        isNotEmpty,
        reason: 'Semantics node must have a non-empty label',
      );
    }
  }
}
