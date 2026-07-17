import 'package:json_annotation/json_annotation.dart';

part 'game_snapshot.g.dart';

/// Snapshot of a game session for save/resume.
/// Contract: mi.game.snapshot / v2
@JsonSerializable(explicitToJson: true)
class GameSnapshot {
  final String gameId;
  final String levelId;
  final String childProfileId;
  final Map<String, dynamic> state;
  final DateTime? savedAt;
  final int? score;
  final int? livesRemaining;
  final int? currentRound;
  final String? difficulty;

  const GameSnapshot({
    required this.gameId,
    required this.levelId,
    required this.childProfileId,
    required this.state,
    this.savedAt,
    this.score,
    this.livesRemaining,
    this.currentRound,
    this.difficulty,
  });

  factory GameSnapshot.fromJson(Map<String, dynamic> json) =>
      _$GameSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$GameSnapshotToJson(this);

  /// A snapshot is stale if saved more than 7 days ago.
  bool get isStale {
    if (savedAt == null) return false;
    return DateTime.now().difference(savedAt!).inDays > 7;
  }

  /// Validates snapshot against contract rules.
  List<String> validate() {
    final errors = <String>[];
    if (gameId.isEmpty) errors.add('gameId is required');
    if (levelId.isEmpty) errors.add('levelId is required');
    if (state.isEmpty) errors.add('state must not be empty');
    if (livesRemaining != null && livesRemaining! < 0) {
      errors.add('livesRemaining must be non-negative');
    }
    if (score != null && score! < 0) {
      errors.add('score must be non-negative');
    }
    return errors;
  }

  GameSnapshot copyWith({
    String? gameId,
    String? levelId,
    String? childProfileId,
    Map<String, dynamic>? state,
    DateTime? savedAt,
    int? score,
    int? livesRemaining,
    int? currentRound,
    String? difficulty,
  }) {
    return GameSnapshot(
      gameId: gameId ?? this.gameId,
      levelId: levelId ?? this.levelId,
      childProfileId: childProfileId ?? this.childProfileId,
      state: state ?? this.state,
      savedAt: savedAt ?? this.savedAt,
      score: score ?? this.score,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      currentRound: currentRound ?? this.currentRound,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}
