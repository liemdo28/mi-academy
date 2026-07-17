import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/src/games/choice/choice_game_session.dart';
import 'package:mi_academy/src/games/robot_commands/robot_commands_session.dart';
import 'package:mi_academy/src/games/sound_match/sound_match_session.dart';
import 'package:mi_academy/src/games/word_builder/word_builder_session.dart';
import 'package:mi_blocks/mi_blocks.dart';
import 'package:mi_game_core/mi_game_core.dart';

import 'game_test_fixtures.dart';

void main() {
  group('Word Builder save/restore', () {
    test('restores a partial offline word and can finish the level', () {
      final session = WordBuilderSession(
        level: wordBuilderLevel,
        childProfileId: 'offline-child',
      );

      _placeLetters(session, ['m', 'è']);
      session.showHint();

      final snapshot = session.saveSnapshot(now: _fixedNow);
      expect(snapshot.gameId, 'word_builder');
      expect(snapshot.levelId, wordBuilderLevel.id);
      expect(snapshot.itemsCompleted, 2);
      expect(snapshot.totalItems, 3);
      expect(snapshot.inProgress, isTrue);

      final restored = WordBuilderSession(
        level: wordBuilderLevel,
        childProfileId: 'offline-child',
      );
      restored.restoreSnapshot(MiGameSnapshot.fromJson(snapshot.toJson()));

      expect(restored.placed, ['m', 'è', null]);
      expect(restored.hintsUsed, 1);
      _placeLetters(restored, ['o']);

      expect(restored.checkAnswer(), isTrue);
      expect(restored.score, 95);
    });

    test('snapshot is privacy-safe', () {
      final session = WordBuilderSession(level: wordBuilderLevel);
      _placeLetters(session, ['m']);

      _expectPrivacySafe(session.saveSnapshot(now: _fixedNow));
    });
  });

  group('Sound Match save/restore', () {
    test('restores transcript and attempt state before completion', () {
      final session = SoundMatchSession(
        level: soundMatchLevel,
        childProfileId: 'offline-child',
      );

      expect(session.choose('B'), isFalse);
      final snapshot = session.saveSnapshot(now: _fixedNow);
      expect(snapshot.gameId, 'sound_match');
      expect(snapshot.inProgress, isTrue);
      expect(snapshot.attemptsUsed, 1);

      final restored = SoundMatchSession(
        level: soundMatchLevel,
        childProfileId: 'offline-child',
      );
      restored.restoreSnapshot(MiGameSnapshot.fromJson(snapshot.toJson()));

      expect(restored.showTranscript, isTrue);
      expect(restored.feedback, contains('nghe lại'));
      expect(restored.choose('A'), isTrue);
      expect(restored.score, 90);
    });

    test('snapshot is privacy-safe', () {
      final session = SoundMatchSession(level: soundMatchLevel);
      session.playPrompt();

      _expectPrivacySafe(session.saveSnapshot(now: _fixedNow));
    });
  });

  group('Choice game save/restore', () {
    test('Math Race restores gentle retry progress and can finish', () {
      final session = ChoiceGameSession(
        level: mathRaceLevel,
        childProfileId: 'offline-child',
      );

      expect(session.choose(_optionByText(session, '4')), isFalse);
      final snapshot = session.saveSnapshot(now: _fixedNow);
      expect(snapshot.gameId, 'math_race');
      expect(snapshot.inProgress, isTrue);
      expect(snapshot.attemptsUsed, 1);

      final restored = ChoiceGameSession(
        level: mathRaceLevel,
        childProfileId: 'offline-child',
      );
      restored.restoreSnapshot(MiGameSnapshot.fromJson(snapshot.toJson()));

      expect(restored.progress, closeTo(0.30, 0.001));
      expect(restored.feedback, contains('Gần đúng'));
      expect(restored.choose(_optionByText(restored, '5')), isTrue);
      expect(restored.progress, 1);
    });

    test('Math Supermarket restores hint state and can finish', () {
      final session = ChoiceGameSession(
        level: mathSupermarketLevel,
        childProfileId: 'offline-child',
      );

      session.showHint();
      final snapshot = session.saveSnapshot(now: _fixedNow);
      expect(snapshot.gameId, 'math_supermarket');
      expect(snapshot.hintsUsed, 1);

      final restored = ChoiceGameSession(
        level: mathSupermarketLevel,
        childProfileId: 'offline-child',
      );
      restored.restoreSnapshot(MiGameSnapshot.fromJson(snapshot.toJson()));

      expect(restored.feedback, 'Cộng giá hai mặt hàng');
      expect(restored.choose(_optionByText(restored, '5 đồng')), isTrue);
      expect(restored.score, 95);
    });

    test('snapshots are privacy-safe', () {
      final race = ChoiceGameSession(level: mathRaceLevel);
      final market = ChoiceGameSession(level: mathSupermarketLevel);
      race.choose(_optionByText(race, '4'));
      market.showHint();

      _expectPrivacySafe(race.saveSnapshot(now: _fixedNow));
      _expectPrivacySafe(market.saveSnapshot(now: _fixedNow));
    });
  });

  group('Robot Commands save/restore', () {
    test('restores a partial command program and can finish the level', () {
      final session = RobotCommandsSession(
        level: robotCommandsLevel,
        childProfileId: 'offline-child',
      );

      session.addCommand(BlockType.moveForward);
      session.showHint();

      final snapshot = session.saveSnapshot(now: _fixedNow);
      expect(snapshot.gameId, 'robot_commands');
      expect(snapshot.levelId, robotCommandsLevel.id);
      expect(snapshot.inProgress, isTrue);
      expect(snapshot.hintsUsed, 1);

      final restored = RobotCommandsSession(
        level: robotCommandsLevel,
        childProfileId: 'offline-child',
      );
      restored.restoreSnapshot(MiGameSnapshot.fromJson(snapshot.toJson()));

      expect(restored.program, [BlockType.moveForward]);
      expect(restored.hintsUsed, 1);
      restored.addCommand(BlockType.moveForward);

      expect(restored.runProgram(), isTrue);
      expect(restored.robotState.x, 2);
      expect(restored.robotState.y, 0);
      expect(restored.score, 95);
    });

    test('restores edited program order and executed robot state', () {
      final session = RobotCommandsSession(
        level: robotCommandsTurnLevel,
        childProfileId: 'offline-child',
      );

      session.addCommand(BlockType.moveForward);
      session.addCommand(BlockType.turnRight);
      session.moveCommand(1, -1);
      expect(session.runProgram(), isFalse);

      final snapshot = session.saveSnapshot(now: _fixedNow);
      final restored = RobotCommandsSession(
        level: robotCommandsTurnLevel,
        childProfileId: 'offline-child',
      );
      restored.restoreSnapshot(MiGameSnapshot.fromJson(snapshot.toJson()));

      expect(restored.program, [BlockType.turnRight, BlockType.moveForward]);
      expect(restored.robotState.x, 0);
      expect(restored.robotState.y, 1);
      expect(restored.robotState.facing, Direction.south);
      expect(restored.feedback, contains('chưa tới'));
    });

    test('snapshot is privacy-safe', () {
      final session = RobotCommandsSession(level: robotCommandsLevel);
      session.addCommand(BlockType.moveForward);

      _expectPrivacySafe(session.saveSnapshot(now: _fixedNow));
    });
  });
}

void _placeLetters(WordBuilderSession session, List<String> letters) {
  for (final letter in letters) {
    final index = session.bank.indexOf(letter);
    expect(index, isNot(-1), reason: 'Letter $letter should be in the bank');
    session.placeLetter(index);
  }
}

ChoiceGameOption _optionByText(ChoiceGameSession session, String text) {
  return session.options.singleWhere((option) => option.text == text);
}

void _expectPrivacySafe(MiGameSnapshot snapshot) {
  final json = snapshot.toJson();
  final encoded = json.toString().toLowerCase();

  expect(json['state'], isA<Map<String, dynamic>>());
  expect(encoded, isNot(contains('parent')));
  expect(encoded, isNot(contains('email')));
  expect(encoded, isNot(contains('token')));
  expect(encoded, isNot(contains('answer')));
}

final _fixedNow = DateTime.utc(2026, 1, 1, 12);
