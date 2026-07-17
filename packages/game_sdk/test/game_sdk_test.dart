import 'package:flutter_test/flutter_test.dart';
import 'package:game_sdk/game_sdk.dart';

void main() {
  group('GameLaunchRequest', () {
    test('validates required fields', () {
      const request = GameLaunchRequest(
        childProfileId: '550e8400-e29b-41d4-a716-446655440001',
        gameId: 'game-memory-01',
        levelId: 'level-memory-01-01',
        language: 'vi',
        ageGroup: 'junior',
      );
      expect(request.validate(), isEmpty);
    });

    test('catches invalid language', () {
      const request = GameLaunchRequest(
        childProfileId: 'test-id',
        gameId: 'test-game',
        levelId: 'test-level',
        language: 'fr',
        ageGroup: 'junior',
      );
      expect(request.validate(), contains('language must be'));
    });

    test('catches invalid ageGroup', () {
      const request = GameLaunchRequest(
        childProfileId: 'test-id',
        gameId: 'test-game',
        levelId: 'test-level',
        language: 'vi',
        ageGroup: 'adult',
      );
      expect(request.validate(), contains('ageGroup must be'));
    });

    test('JSON round-trip', () {
      const request = GameLaunchRequest(
        childProfileId: 'id-1',
        gameId: 'game-1',
        levelId: 'level-1',
        language: 'en',
        ageGroup: 'senior',
      );
      final json = request.toJson();
      final restored = GameLaunchRequest.fromJson(json);
      expect(restored.childProfileId, equals('id-1'));
      expect(restored.language, equals('en'));
    });
  });

  group('GameResult', () {
    test('calculates accuracy', () {
      final result = GameResult(
        attemptId: 'att-001',
        childProfileId: 'child-001',
        gameId: 'game-001',
        levelId: 'level-001',
        startedAt: DateTime(2026, 7, 17, 8, 30),
        completedAt: DateTime(2026, 7, 17, 8, 31),
        correctCount: 8,
        incorrectCount: 2,
      );
      expect(result.accuracy, closeTo(0.8, 0.01));
    });

    test('validates mastery evidence bounds', () {
      final result = GameResult(
        attemptId: 'att-001',
        childProfileId: 'child-001',
        gameId: 'game-001',
        levelId: 'level-001',
        startedAt: DateTime(2026, 7, 17, 8, 30),
        completedAt: DateTime(2026, 7, 17, 8, 31),
        masteryEvidence: 1.5,
      );
      expect(result.validate(), contains('masteryEvidence'));
    });

    test('catches inverted timestamps', () {
      final result = GameResult(
        attemptId: 'att-001',
        childProfileId: 'child-001',
        gameId: 'game-001',
        levelId: 'level-001',
        startedAt: DateTime(2026, 7, 17, 9, 0),
        completedAt: DateTime(2026, 7, 17, 8, 30),
      );
      expect(result.validate(), contains('completedAt must be after'));
    });
  });

  group('GameSnapshot', () {
    test('detects stale snapshots', () {
      final snapshot = GameSnapshot(
        gameId: 'game-1',
        levelId: 'level-1',
        childProfileId: 'child-1',
        savedAt: DateTime(2026, 7, 15, 8, 0),
        state: {'score': 100},
      );
      expect(snapshot.isStale, isTrue);
    });

    test('rejects empty state', () {
      const snapshot = GameSnapshot(
        gameId: 'game-1',
        levelId: 'level-1',
        childProfileId: 'child-1',
        savedAt: null,
        state: {},
      );
      expect(snapshot.validate(), contains('state must not be empty'));
    });
  });

  group('GameContracts', () {
    test('detects forbidden fields', () {
      final violations = GameContracts.checkForbiddenFields({
        'gameId': 'game-1',
        'accessToken': 'secret-token',
      });
      expect(violations, contains('accessToken'));
    });

    test('all contracts have valid metadata', () {
      for (final contract in GameContracts.all) {
        expect(contract.contractId, startsWith('mi.'));
        expect(contract.schemaVersion, greaterThan(0));
        expect(contract.owner, isNotEmpty);
      }
    });
  });
}
