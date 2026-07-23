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

/// One GardenScreen scenario per file/isolate -- see
/// garden_screen_empty_test.dart's doc comment: running more than one
/// GardenScreen widget test in the same isolate left
/// rewardCatalogProvider's asset-backed Future unresolved for every test
/// after the first, a test-binding asset-cache timing quirk unrelated to
/// GardenScreen's actual (correct, individually-verified) behavior.
void main() {
  testWidgets(
      'shows locally-unlocked rewards fully offline (no backend call)',
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
                  language: 'vi', localeConfirmed: true),
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

    expect(find.text('Sao đầu tiên'), findsOneWidget);
  });
}
