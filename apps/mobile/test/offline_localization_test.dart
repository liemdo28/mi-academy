import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/providers/providers.dart';
import 'package:mi_academy/screens/login_screen.dart';
import 'package:mi_academy/services/parent_settings_store.dart';

void main() {
  testWidgets('login screen follows the selected English locale',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          parentSettingsStoreProvider.overrideWithValue(
            MemoryParentSettingsStore(
              const ParentSettingsSnapshot(
                language: 'en',
                localeConfirmed: true,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Learn through play'), findsOneWidget);
    expect(find.text('Log in'), findsWidgets);
    expect(find.text('Offline mode'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsNothing);
    expect(find.text('Chế độ offline'), findsNothing);
  });

  test('offline daily plan follows the selected English locale', () async {
    final container = ProviderContainer(
      overrides: [
        parentSettingsStoreProvider.overrideWithValue(
          MemoryParentSettingsStore(
            const ParentSettingsSnapshot(
              language: 'en',
              localeConfirmed: true,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(activeChildProvider.notifier).selectOfflineChild();
    final plan = await container.read(dailyPlanProvider.future);

    expect(plan.first['title'], 'Find the missing letter');
    expect(plan.first['subject'], 'Letters');
    expect(plan[1]['title'], 'Memory Cards');
    expect(plan[2]['title'], 'Robot Commands');
  });
}
