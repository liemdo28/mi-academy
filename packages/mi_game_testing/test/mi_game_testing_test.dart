import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_testing/mi_game_testing.dart';

void main() {
  group('FakeGameServices', () {
    test('records snapshots, events, audio, and stop calls', () async {
      final fake = FakeGameServices();
      final services = fake.build();

      await services.saveSnapshot('snap-1', {'score': 10});
      await services.logEvent('game_started', {'game': 'memory_cards'});
      await services.playAudio('correct', volume: 0.5);
      await services.stopAudio();

      expect(fake.savedSnapshots['snap-1'], {'score': 10});
      expect(fake.hasLoggedEvent('game_started'), isTrue);
      expect(fake.hasPlayedAudio('correct'), isTrue);
      expect(fake.stopAudioCallCount, 1);
    });
  });

  group('TestFixtures', () {
    test('builds a safe game context and localized level', () {
      final context = TestFixtures.context(childProfileId: 'child-1');
      final level = TestFixtures.level(gameId: 'memory_cards');

      expect(context.childProfileId, 'child-1');
      expect(level.gameId, 'memory_cards');
      expect(level.contentForLocale('vi')['prompt'], 'Bài kiểm tra');
    });
  });
}
