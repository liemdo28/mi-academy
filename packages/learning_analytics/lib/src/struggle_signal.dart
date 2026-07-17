import 'package:equatable/equatable.dart';

/// Signal that a child may be struggling during a session.
///
/// Per blueprint §12: These signals trigger gentle help responses,
/// NOT negative labels for the child.
class StruggleSignal extends Equatable {
  const StruggleSignal({
    required this.signalType,
    required this.severity,
    required this.skillId,
    required this.levelId,
    required this.timestamp,
    this.hintLevelRecommended = 1,
    this.suggestedAction,
    this.reasonCodes,
  });

  final StruggleSignalType signalType;
  final StruggleSignalSeverity severity;
  final String skillId;
  final String levelId;
  final DateTime timestamp;
  final int hintLevelRecommended;
  final SuggestedAction? suggestedAction;
  final List<String>? reasonCodes;

  @override
  List<Object?> get props => [
        signalType,
        severity,
        skillId,
        levelId,
        timestamp,
        hintLevelRecommended,
        suggestedAction,
        reasonCodes,
      ];
}

enum StruggleSignalType {
  /// Same mistake repeated multiple times
  repeatedError,
  /// Many hints requested in short span
  hintFlood,
  /// Long pause at a step
  longPause,
  /// Child exited and re-entered the same level
  levelRetry,
  /// Rapid random tapping detected
  randomTapping,
  /// Too many attempts at one question
  attemptFlood,
  /// Level abandoned after multiple tries
  levelAbandon,
}

enum StruggleSignalSeverity {
  /// Mild — may need gentle hint
  mild,
  /// Moderate — suggest easier activity or more guidance
  moderate,
  /// High — suggest pausing or switching activity
  high,
}

class SuggestedAction extends Equatable {
  const SuggestedAction({
    required this.type,
    required this.titleVi,
    required this.titleEn,
    required this.descriptionVi,
    required this.descriptionEn,
    this.levelId,
    this.gameId,
  });

  final SuggestedActionType type;
  final String titleVi;
  final String titleEn;
  final String descriptionVi;
  final String descriptionEn;
  final String? levelId;
  final String? gameId;

  @override
  List<Object?> get props => [
        type,
        titleVi,
        titleEn,
        descriptionVi,
        descriptionEn,
        levelId,
        gameId,
      ];
}

enum SuggestedActionType {
  gentleHint,
  showExample,
  reduceOptions,
  splitTask,
  suggestBreak,
  switchToEasierActivity,
  switchToVisualActivity,
  continueEncouraging,
}
