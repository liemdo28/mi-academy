import 'package:mastery_core/mastery_core.dart';
import 'struggle_signal.dart';

/// Detects when a child may be struggling during a game session.
///
/// Per blueprint §12: Detects struggle signals and responds with
/// gentle, helpful suggestions. Never labels the child negatively.
class StruggleDetector {
  const StruggleDetector();

  /// Detect struggle signals from session evidence.
  List<StruggleSignal> detect({
    required AttemptEvidence currentAttempt,
    required List<AttemptEvidence> recentAttempts,
    required List<int> hintHistory,
    required List<int> pauseDurations,
    required int retryCount,
    required String skillId,
    required String levelId,
  }) {
    final signals = <StruggleSignal>[];

    // Signal 1: Repeated error
    final recentWrongSameDifficulty = recentAttempts
        .where((a) => !a.correct && a.difficulty == currentAttempt.difficulty)
        .length;
    if (recentWrongSameDifficulty >= 3) {
      signals.add(StruggleSignal(
        signalType: StruggleSignalType.repeatedError,
        severity: StruggleSignalSeverity.moderate,
        skillId: skillId,
        levelId: levelId,
        timestamp: currentAttempt.attemptedAt,
        hintLevelRecommended: 3,
        suggestedAction: const SuggestedAction(
          type: SuggestedActionType.showExample,
          titleVi: 'Xem thêm ví dụ',
          titleEn: 'See an example',
          descriptionVi: 'Thử xem thêm ví dụ trước khi làm bài.',
          descriptionEn: 'Try seeing an example before answering.',
        ),
        reasonCodes: ['REPEATED_WRONG_SAME_DIFFICULTY'],
      ));
    }

    // Signal 2: Hint flood
    final totalHints = hintHistory.fold<int>(0, (a, b) => a + b);
    if (totalHints >= 4 && hintHistory.length <= 3) {
      signals.add(StruggleSignal(
        signalType: StruggleSignalType.hintFlood,
        severity: StruggleSignalSeverity.mild,
        skillId: skillId,
        levelId: levelId,
        timestamp: currentAttempt.attemptedAt,
        hintLevelRecommended: 2,
        suggestedAction: const SuggestedAction(
          type: SuggestedActionType.gentleHint,
          titleVi: 'Gợi ý nhẹ',
          titleEn: 'Gentle hint',
          descriptionVi: 'Thử làm lại với một gợi ý nhỏ.',
          descriptionEn: 'Try again with a small hint.',
        ),
        reasonCodes: ['HINT_FLOOD'],
      ));
    }

    // Signal 3: Long pause
    final avgPause = pauseDurations.isNotEmpty
        ? pauseDurations.reduce((a, b) => a + b) / pauseDurations.length
        : 0;
    if (avgPause > 20) {
      signals.add(StruggleSignal(
        signalType: StruggleSignalType.longPause,
        severity: StruggleSignalSeverity.mild,
        skillId: skillId,
        levelId: levelId,
        timestamp: currentAttempt.attemptedAt,
        hintLevelRecommended: 2,
        suggestedAction: const SuggestedAction(
          type: SuggestedActionType.gentleHint,
          titleVi: 'Chậm thôi, không sao!',
          titleEn: "It's okay to take your time!",
          descriptionVi: 'Có thể nhờ MI giúp một chút.',
          descriptionEn: 'You can ask MI for a little help.',
        ),
        reasonCodes: ['LONG_PAUSE'],
      ));
    }

    // Signal 4: Level retry
    if (retryCount >= 2) {
      signals.add(StruggleSignal(
        signalType: StruggleSignalType.levelRetry,
        severity: StruggleSignalSeverity.moderate,
        skillId: skillId,
        levelId: levelId,
        timestamp: currentAttempt.attemptedAt,
        hintLevelRecommended: 3,
        suggestedAction: const SuggestedAction(
          type: SuggestedActionType.splitTask,
          titleVi: 'Làm từng bước nhỏ',
          titleEn: 'Break it into small steps',
          descriptionVi: 'Thử chia nhỏ bài thành các bước để dễ hơn.',
          descriptionEn: 'Try breaking the task into smaller steps.',
        ),
        reasonCodes: ['LEVEL_RETRY'],
      ));
    }

    // Signal 5: Rapid random tapping
    if (recentAttempts.length >= 3) {
      final recentDurations = <int>[];
      for (var i = 0; i < recentAttempts.length - 1; i++) {
        final diff = recentAttempts[i]
            .attemptedAt
            .difference(recentAttempts[i + 1].attemptedAt)
            .inSeconds
            .abs();
        recentDurations.add(diff);
      }
      if (recentDurations.isNotEmpty &&
          recentDurations.every((d) => d < 3) &&
          recentAttempts.take(3).any((a) => !a.correct)) {
        signals.add(StruggleSignal(
          signalType: StruggleSignalType.randomTapping,
          severity: StruggleSignalSeverity.high,
          skillId: skillId,
          levelId: levelId,
          timestamp: currentAttempt.attemptedAt,
          hintLevelRecommended: 4,
          suggestedAction: const SuggestedAction(
            type: SuggestedActionType.suggestBreak,
            titleVi: 'Thử nghỉ ngơi một chút',
            titleEn: 'Try taking a break',
            descriptionVi: 'Có thể chơi game nhẹ nhàng hoặc nghỉ ngơi.',
            descriptionEn: 'You can try a light game or take a break.',
          ),
          reasonCodes: ['RAPID_RANDOM_TAPPING'],
        ));
      }
    }

    return signals;
  }

  /// Recommend hint level based on accumulated struggle signals.
  int recommendHintLevel(List<StruggleSignal> signals) {
    if (signals.isEmpty) return 1;
    final maxSeverity = signals
        .map((s) => s.severity)
        .reduce((a, b) => a.index > b.index ? a : b);
    switch (maxSeverity) {
      case StruggleSignalSeverity.high:
        return 5;
      case StruggleSignalSeverity.moderate:
        return 3;
      case StruggleSignalSeverity.mild:
        return 2;
    }
  }
}
