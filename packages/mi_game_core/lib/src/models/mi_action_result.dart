import 'package:equatable/equatable.dart';

/// Result of processing a MiGameAction.
///
/// Games return this to communicate feedback to the UI layer.
class MiActionResult extends Equatable {
  const MiActionResult({
    required this.correct,
    this.feedback,
    this.audioRef,
    this.animationRef,
    this.shouldRetry = false,
    this.isLevelComplete = false,
    this.metadata = const {},
  });

  /// Whether the action was correct.
  final bool correct;

  /// Localized feedback message.
  final String? feedback;

  /// Audio to play as feedback (e.g., "correct_chime", "try_again").
  final String? audioRef;

  /// Animation reference (celebration, retry, etc.).
  final String? animationRef;

  /// Whether the child should be allowed to retry.
  final bool shouldRetry;

  /// Whether this action completed the level.
  final bool isLevelComplete;

  /// Additional data (e.g., score change, progress update).
  final Map<String, dynamic> metadata;

  /// Create a success result.
  factory MiActionResult.success({
    String? feedback,
    bool isLevelComplete = false,
    Map<String, dynamic> metadata = const {},
  }) {
    return MiActionResult(
      correct: true,
      feedback: feedback,
      audioRef: 'correct',
      isLevelComplete: isLevelComplete,
      metadata: metadata,
    );
  }

  /// Create an incorrect result with retry allowed.
  factory MiActionResult.incorrect({
    String? feedback,
    Map<String, dynamic> metadata = const {},
  }) {
    return MiActionResult(
      correct: false,
      feedback: feedback ?? 'Thử lại nhé!',
      audioRef: 'try_again',
      shouldRetry: true,
      metadata: metadata,
    );
  }

  @override
  List<Object?> get props => [
        correct,
        feedback,
        audioRef,
        animationRef,
        shouldRetry,
        isLevelComplete,
        metadata,
      ];
}
