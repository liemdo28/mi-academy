import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_core/mi_game_core.dart';

void main() {
  // ─── MiGameLaunchRequest ──────────────────────────────────────────────────

  group('MiGameLaunchRequest', () {
    test('toJson and fromJson roundtrip', () {
      final request = MiFixtures.buildLaunchRequest();
      final json = request.toJson();
      final restored = MiGameLaunchRequest.fromJson(json);

      expect(restored.schemaVersion, equals(1));
      expect(restored.childProfileId, equals(MiFixtures.childJunior));
      expect(restored.gameId, equals('word_builder'));
      expect(restored.levelId, equals('level_1'));
      expect(restored.language, equals('vi'));
      expect(restored.ageGroup, equals('junior'));
      expect(restored.levelContent, isNotEmpty);
      expect(restored.restoredState, isNull);
    });

    test('no parent credentials in request', () {
      final json = MiFixtures.buildLaunchRequest().toJson();
      final keys = json.keys.join(' ');
      expect(keys, isNot(contains('email')));
      expect(keys, isNot(contains('password')));
      expect(keys, isNot(contains('token')));
      expect(keys, isNot(contains('access_token')));
    });

    test('restoredState roundtrip', () {
      final request = MiFixtures.buildLaunchRequest(
        restoredState: {'current_question': 3, 'score': 50},
      );
      final json = request.toJson();
      final restored = MiGameLaunchRequest.fromJson(json);
      expect(restored.restoredState, equals({'current_question': 3, 'score': 50}));
    });
  });

  // ─── MiGameResult ──────────────────────────────────────────────────────────

  group('MiGameResult', () {
    test('toJson and fromJson roundtrip', () {
      final result = MiFixtures.buildGameResult();
      final json = result.toJson();
      final restored = MiGameResult.fromJson(json);

      expect(restored.childProfileId, equals(MiFixtures.childJunior));
      expect(restored.gameId, equals('word_builder'));
      expect(restored.attemptCount, equals(10));
      expect(restored.correctCount, equals(8));
      expect(restored.completed, isTrue);
      expect(restored.masteryEvidence, closeTo(0.8, 0.01));
    });

    test('attemptId is present (idempotency key)', () {
      final result = MiFixtures.buildGameResult();
      expect(result.attemptId, isNotEmpty);
    });

    test('correctRate is computed', () {
      final result = MiFixtures.buildGameResult(
        attemptCount: 10,
        correctCount: 7,
      );
      expect(result.correctRate, closeTo(0.7, 0.01));
    });

    test('no parent credentials in result', () {
      final json = MiFixtures.buildGameResult().toJson();
      final keys = json.keys.join(' ');
      expect(keys, isNot(contains('email')));
      expect(keys, isNot(contains('password')));
      expect(keys, isNot(contains('token')));
    });

    test('schemaVersion defaults to 1', () {
      final result = MiGameResult(
        attemptId: 'test',
        childProfileId: 'child',
        gameId: 'test',
        levelId: 'test',
        startedAt: DateTime(2024),
        completedAt: DateTime(2024),
        attemptCount: 5,
        correctCount: 3,
        incorrectCount: 2,
        durationSeconds: 60,
      );
      expect(result.schemaVersion, equals(1));
    });
  });

  // ─── MiGameSnapshot ────────────────────────────────────────────────────────

  group('MiGameSnapshot', () {
    test('toJson and fromJson roundtrip', () {
      final snapshot = MiFixtures.buildSnapshot();
      final json = snapshot.toJson();
      final restored = MiGameSnapshot.fromJson(json);

      expect(restored.gameId, equals('word_builder'));
      expect(restored.levelId, equals('level_1'));
      expect(restored.schemaVersion, equals(1));
      expect(restored.state, isNotEmpty);
    });

    test('state can store arbitrary game data', () {
      final state = {
        'board': [1, 2, 3],
        'score': 100,
        'combo': 5,
      };
      final snapshot = MiFixtures.buildSnapshot(state: state);
      expect(snapshot.state['board'], equals([1, 2, 3]));
      expect(snapshot.state['score'], equals(100));
    });
  });

  // ─── MiProgressGateway (InMemoryProgressGateway) ───────────────────────────

  group('InMemoryProgressGateway', () {
    late MiProgressGateway gateway;

    setUp(() {
      gateway = InMemoryProgressGateway();
    });

    test('saveGameResult stores the result', () async {
      final result = MiFixtures.buildGameResult();
      await gateway.saveGameResult(result);

      // Verify via the mock's helper
      final all = (gateway as InMemoryProgressGateway).getAllResults();
      expect(all.length, equals(1));
      expect(all.first.attemptId, equals(result.attemptId));
    });

    test('saveSnapshot and loadSnapshot roundtrip', () async {
      final snapshot = MiFixtures.buildSnapshot();
      await gateway.saveSnapshot(snapshot);

      final loaded = await gateway.loadSnapshot(
        childProfileId: MiFixtures.childJunior,
        gameId: 'word_builder',
        levelId: 'level_1',
      );

      expect(loaded, isNotNull);
      expect(loaded!.state, equals(snapshot.state));
    });

    test('loadSnapshot returns null for unknown key', () async {
      final loaded = await gateway.loadSnapshot(
        childProfileId: 'unknown',
        gameId: 'unknown',
        levelId: 'unknown',
      );
      expect(loaded, isNull);
    });

    test('snapshot update replaces previous', () async {
      final snap1 = MiFixtures.buildSnapshot(
        state: {'step': 1},
      );
      final snap2 = MiFixtures.buildSnapshot(
        state: {'step': 2},
      );
      await gateway.saveSnapshot(snap1);
      await gateway.saveSnapshot(snap2);

      final loaded = await gateway.loadSnapshot(
        childProfileId: MiFixtures.childJunior,
        gameId: 'word_builder',
        levelId: 'level_1',
      );
      expect(loaded!.state['step'], equals(2));
    });

    test('reset clears all state', () async {
      await gateway.saveGameResult(MiFixtures.buildGameResult());
      await gateway.saveSnapshot(MiFixtures.buildSnapshot());

      final mock = gateway as InMemoryProgressGateway;
      mock.reset();
      expect(mock.getAllResults(), isEmpty);
    });
  });

  // ─── Fixtures ──────────────────────────────────────────────────────────────

  group('MiFixtures', () {
    test('child profile IDs are deterministic', () {
      expect(MiFixtures.childJunior, equals('child_junior_001'));
      expect(MiFixtures.childExplorer, equals('child_explorer_001'));
      expect(MiFixtures.childMaster, equals('child_master_001'));
    });

    test('mvpGames contains 6 games', () {
      expect(MiFixtures.mvpGames.length, equals(6));
    });

    test('levelIdsForGame returns levels for all MVP games', () {
      for (final game in MiFixtures.mvpGames) {
        final levels = MiFixtures.levelIdsForGame(game);
        expect(levels.length, greaterThanOrEqualTo(5));
      }
    });

    test('levelContentFixture has required keys', () {
      final content = MiFixtures.levelContentFixture('word_builder', 'level_1');
      expect(content, contains('game_id'));
      expect(content, contains('level_id'));
      expect(content, contains('word_bank'));
    });

    test('accessibility fixtures are constant', () {
      expect(MiFixtures.accessibilityHighContrast.highContrast, isTrue);
      expect(MiFixtures.accessibilityLargeText.fontSize, equals(1.3));
      expect(MiFixtures.accessibilityReduceMotion.reduceMotion, isTrue);
    });

    test('audio fixtures are constant', () {
      expect(MiFixtures.audioMuted.musicVolume, equals(0.0));
      expect(MiFixtures.audioLoud.sfxVolume, equals(1.0));
      expect(MiFixtures.audioNoSpeech.speechEnabled, isFalse);
    });

    test('ageGroupFromAge works correctly', () {
      expect(MiFixtures.ageGroupFromAge(5), equals('junior'));
      expect(MiFixtures.ageGroupFromAge(8), equals('explorer'));
      expect(MiFixtures.ageGroupFromAge(12), equals('master'));
    });
  });
}
