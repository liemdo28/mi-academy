import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_core/mi_game_core.dart';

/// Custom matchers for validating [MiGameResult] objects.
class MiGameResultMatcher {
  MiGameResultMatcher._();

  /// Result must have been successful (completed = true).
  static Matcher<MiGameResult> beSuccessful() => _SuccessfulResult();

  /// Result must show low mastery (masteryEvidence < 0.5).
  static Matcher<MiGameResult> haveLowMastery() => _LowMasteryResult();

  /// Result must show high mastery (masteryEvidence >= 0.8).
  static Matcher<MiGameResult> haveHighMastery() => _HighMasteryResult();

  /// Result must show hint-heavy behavior (hintCount > correctCount).
  static Matcher<MiGameResult> beHintHeavy() => _HintHeavyResult();

  /// Result accuracy must be at least the given threshold (0-1).
  static Matcher<MiGameResult> haveAccuracyAtLeast(double threshold) =>
      _AccuracyAtLeast(threshold);

  /// Result must include evidence for the given skill category.
  static Matcher<MiGameResult> haveSkillEvidence(String category) =>
      _HasSkillEvidence(category);
}

class _SuccessfulResult extends Matcher<MiGameResult> {
  @override
  Description describe(Description description) =>
      description.add('a completed MiGameResult');

  @override
  bool matches(MiGameResult item, Map matchState) => item.completed;
}

class _LowMasteryResult extends Matcher<MiGameResult> {
  @override
  Description describe(Description description) =>
      description.add('a low-mastery result (mastery < 0.5)');

  @override
  bool matches(MiGameResult item, Map matchState) => item.masteryEvidence < 0.5;
}

class _HighMasteryResult extends Matcher<MiGameResult> {
  @override
  Description describe(Description description) =>
      description.add('a high-mastery result (mastery >= 0.8)');

  @override
  bool matches(MiGameResult item, Map matchState) =>
      item.masteryEvidence >= 0.8;
}

class _HintHeavyResult extends Matcher<MiGameResult> {
  @override
  Description describe(Description description) =>
      description.add('a hint-heavy result (hints > correct)');

  @override
  bool matches(MiGameResult item, Map matchState) =>
      item.hintCount > item.correctCount;
}

class _AccuracyAtLeast extends Matcher<MiGameResult> {
  _AccuracyAtLeast(this.threshold);
  final double threshold;

  @override
  Description describe(Description description) =>
      description.add('result with accuracy >= $threshold');

  @override
  bool matches(MiGameResult item, Map matchState) {
    final total = item.correctCount + item.incorrectCount;
    if (total == 0) return false;
    return (item.correctCount / total) >= threshold;
  }
}

class _HasSkillEvidence extends Matcher<MiGameResult> {
  _HasSkillEvidence(this.category);
  final String category;

  @override
  Description describe(Description description) =>
      description.add('result with skill evidence for "$category"');

  @override
  bool matches(MiGameResult item, Map matchState) =>
      item.skillEvidence.containsKey(category);
}

/// Shortcut matchers to keep test files readable.
Matcher<MiGameResult> isGameSuccess() => MiGameResultMatcher.beSuccessful();
Matcher<MiGameResult> isGameLowMastery() =>
    MiGameResultMatcher.haveLowMastery();
Matcher<MiGameResult> isGameHighMastery() =>
    MiGameResultMatcher.haveHighMastery();
Matcher<MiGameResult> isGameHintHeavy() => MiGameResultMatcher.beHintHeavy();
Matcher<MiGameResult> hasAccuracy(double threshold) =>
    MiGameResultMatcher.haveAccuracyAtLeast(threshold);
