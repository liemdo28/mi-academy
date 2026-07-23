import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/providers/child_provider.dart';
import 'package:mi_academy/providers/providers.dart';
import 'package:mi_academy/screens/garden_screen.dart';
import 'package:mi_academy/services/parent_settings_store.dart';
import 'package:mi_academy/services/reward_store.dart';

/// Fixes the active child without a network call, so
/// [localRewardsProvider] (which watches [activeChildProvider]) resolves
/// deterministically in a widget test.
class _FixedActiveChild extends ActiveChildNotifier {
  _FixedActiveChild(this.childId);

  final String childId;

  @override
  ActiveChildState build() {
    super.build();
    return ActiveChildState(childId: childId);
  }
}

/// See garden_screen_empty_test.dart's doc comment for why each
/// GardenScreen scenario lives in its own file/isolate.
void main() {
  testWidgets('shows the English name when the parent language is English',
      (tester) async {
    final rewardStore = InMemoryRewardStore();
    await rewardStore.unlock('c1', 'first_completion');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeChildProvider.overrideWith(() => _FixedActiveChild('c1')),
          rewardStoreProvider.overrideWithValue(rewardStore),
          parentSettingsStoreProvider.overrideWithValue(
            MemoryParentSettingsStore(
              const ParentSettingsSnapshot(
                  language: 'en', localeConfirmed: true),
            ),
          ),
        ],
        child: const MaterialApp(home: GardenScreen()),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('First Star'), findsOneWidget);
  });
}
