import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards against the exact bug this test was written to catch: a widget
/// referencing an SVG asset path that isn't actually bundled anywhere,
/// which `SvgPicture.asset` fails on *silently* (renders nothing, throws
/// no error) rather than loudly. Every MiIcon/MiCharacter asset must be
/// declared in this package's own pubspec.yaml so both `flutter test`
/// here and every consumer's asset bundle can resolve it.
Future<void> _expectAllSvgsLoad(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Center(child: child)));

  final pictures = tester.widgetList<SvgPicture>(find.byType(SvgPicture));
  expect(pictures, isNotEmpty);

  for (final picture in pictures) {
    final element = tester.element(find.byWidget(picture));
    final bytes = await picture.bytesLoader.loadBytes(element);
    expect(
      bytes.lengthInBytes,
      greaterThan(0),
      reason: 'Asset failed to resolve for $picture',
    );
  }
}

void main() {
  testWidgets('every MiIcon variant loads its SVG asset', (tester) async {
    for (final name in MiIconName.values) {
      await _expectAllSvgsLoad(tester, MiIcon(name));
      await _expectAllSvgsLoad(tester, MiIcon(name, filled: true));
    }
  });

  testWidgets('every MiCharacter expression loads its SVG asset',
      (tester) async {
    for (final expression in MiExpression.values) {
      await _expectAllSvgsLoad(tester, MiCharacter(expression: expression));
    }
  });

  testWidgets('every MiCharacter pose loads its SVG asset', (tester) async {
    for (final pose in MiPose.values) {
      await _expectAllSvgsLoad(tester, MiCharacter(pose: pose));
    }
  });

  testWidgets('MiCharacterHead loads its SVG asset', (tester) async {
    await _expectAllSvgsLoad(tester, const MiCharacterHead());
  });
}
