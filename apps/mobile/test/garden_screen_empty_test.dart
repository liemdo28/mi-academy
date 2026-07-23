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

/// Kept in its own file (own isolate), separate from
/// garden_screen_test.dart: running this empty-state case before the
/// reward-showing cases in the same isolate left rewardCatalogProvider's
/// asset-backed Future unresolved for the later tests -- a pre-existing
/// test-binding asset-cache timing quirk (see game_completion_rewards_test.dart
/// for the same pattern with level content), not a production bug.
void main() {
  testWidgets('shows the empty-garden state when nothing is unlocked yet',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeChildProvider.overrideWith(() => _FixedActiveChild('c1')),
          rewardStoreProvider.overrideWithValue(InMemoryRewardStore()),
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

    expect(find.text('Vườn của con còn trống'), findsOneWidget);
  });
}
