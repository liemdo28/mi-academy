import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/providers/providers.dart';
import 'package:mi_academy/screens/game_screen.dart';
import 'package:mi_academy/services/parent_settings_store.dart';
import 'package:mi_academy/services/progress_store.dart';
import 'package:mi_academy/services/reward_store.dart';
import 'package:mi_academy/services/snapshot_store.dart';
import 'package:mi_academy/src/games/free_creativity/creative_artifact_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_mockAudioplayersChannels);

  testWidgets('ungraded Free Creativity does not create mastery evidence',
      (tester) async {
    final rewardStore = InMemoryRewardStore();
    final progressStore = InMemoryProgressStore();
    final artifactStore = InMemoryCreativeArtifactStore();

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
          snapshotStoreProvider.overrideWithValue(InMemorySnapshotStore()),
          progressStoreProvider.overrideWithValue(progressStore),
          rewardStoreProvider.overrideWithValue(rewardStore),
          creativeArtifactStoreProvider.overrideWithValue(artifactStore),
        ],
        child: const MaterialApp(
          home: GameScreen(
            childId: 'offline-child',
            gameType: 'free_creativity',
          ),
        ),
      ),
    );
    for (var i = 0;
        i < 20 && find.byType(OutlinedButton).evaluate().isEmpty;
        i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(OutlinedButton), findsWidgets);

    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pump();
    await tester.tap(find.text('MI').last);
    await tester.pump();
    await tester.tap(find.text('curious'));
    await tester.pump();

    final storyField = find.byType(TextField);
    await tester.scrollUntilVisible(
      storyField,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.enterText(storyField.first, 'MI opens the tiny door.');
    await tester.tap(find.text('Share story'));
    await tester.pumpAndSettle();

    final tracker = progressStore.load('offline-child')!;
    expect(tracker.attempts.single.correct, isFalse);
    expect(tracker.skills, isEmpty);
    expect(rewardStore.unlockedIds('offline-child'), isEmpty);
    expect(artifactStore.listForChild('offline-child'), hasLength(1));
  });
}

void _mockAudioplayersChannels() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = StandardMethodCodec();

  void mockEventChannel(String channel) {
    messenger.setMockMessageHandler(channel, (ByteData? message) async {
      final methodCall = codec.decodeMethodCall(message);
      if (methodCall.method == 'listen' || methodCall.method == 'cancel') {
        return codec.encodeSuccessEnvelope(null);
      }
      return null;
    });
  }

  mockEventChannel('xyz.luan/audioplayers.global/events');
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (_) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (MethodCall methodCall) async {
      final args = methodCall.arguments;
      if (methodCall.method == 'create' && args is Map) {
        final playerId = args['playerId']?.toString();
        if (playerId != null) {
          mockEventChannel('xyz.luan/audioplayers/events/$playerId');
        }
      }
      if (methodCall.method == 'getDuration' ||
          methodCall.method == 'getCurrentPosition') {
        return 0;
      }
      return null;
    },
  );
}
