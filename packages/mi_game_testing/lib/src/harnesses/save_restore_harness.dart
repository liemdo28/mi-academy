import 'package:mi_game_core/mi_game_core.dart';

/// Test harness for verifying snapshot save/restore behavior.
///
/// A game must persist state that allows resuming mid-level after
/// an interruption (pause, crash, or app backgrounding).
class SaveRestoreHarness {
  SaveRestoreHarness({required this.game});

  final MiGame game;

  /// Capture a snapshot mid-play, then verify the game can resume.
  Future<MiGameSnapshot> captureAndRestore() async {
    await game.initialize();
    await game.start();

    final snapshot = game.captureSnapshot();
    expect(snapshot, isNotNull, reason: 'Snapshot must not be null');
    expect(snapshot!.levelId, isNotEmpty,
        reason: 'Snapshot must identify level');

    await game.pause();

    final restored = game.restoreSnapshot(snapshot);
    expect(restored, isTrue, reason: 'Game must accept its own snapshot');
    expect(game.state, MiGameState.paused,
        reason: 'Restored game stays paused');

    await game.resume();
    expect(game.state, MiGameState.playing, reason: 'Resumes to PLAYING');

    return snapshot;
  }

  /// Verify a game does NOT restore a snapshot from a different level.
  Future<void> expectRejectsMismatchedSnapshot() async {
    await game.initialize();

    final foreignSnapshot = MiGameSnapshot(
      levelId: 'unrelated_level',
      state: MiGameState.paused,
      data: {'score': 99},
      capturedAt: DateTime.now(),
    );

    final result = game.restoreSnapshot(foreignSnapshot);
    expect(result, isFalse,
        reason: 'Must reject snapshot from different level');
  }
}
