import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('high contrast mode actually swaps semantic colors, not just tokens on paper', () {
    final normal = MiTheme.light();
    final highContrast = MiTheme.light(highContrast: true);

    expect(normal.colorScheme.primary, MiColors.primary);
    expect(highContrast.colorScheme.primary, MiColors.primaryHc);
    expect(normal.colorScheme.primary, isNot(equals(highContrast.colorScheme.primary)));

    expect(normal.textTheme.bodyLarge!.color, MiColors.textPrimary);
    expect(highContrast.textTheme.bodyLarge!.color, MiColors.textPrimaryHc);

    expect(normal.dividerTheme.color, MiColors.border);
    expect(highContrast.dividerTheme.color, MiColors.borderHc);

    expect(normal.colorScheme.error, MiColors.error);
    expect(highContrast.colorScheme.error, MiColors.errorHc);
  });

  testWidgets('MiMotion.resolve returns zero duration under reduced motion',
      (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(MiMotion.resolve(capturedContext, MiMotion.normal), MiMotion.normal);

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: SizedBox()),
      ),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(MiMotion.resolve(capturedContext, MiMotion.normal), Duration.zero);
  });
}
