import 'attempt_record.dart';
import 'reward_definition.dart';
import 'reward_rule.dart';

/// Evaluates a [RewardCatalog] against a child's attempt history and
/// returns which rewards are newly earned.
///
/// Pure computation, no I/O, no network -- same offline-first contract as
/// the rest of this package (see `mastery_core`'s doc comment for why that
/// matters: a child playing on a plane must earn rewards exactly as
/// reliably as one with a live connection). Callers own persistence of the
/// result and of [alreadyUnlocked].
class RewardEngine {
  const RewardEngine();

  /// [gameCategories] maps `gameId` -> `GameRegistryEntry.category`
  /// ('letters' | 'math' | 'logic' today). Passed in rather than imported
  /// so this package has no dependency on the app's game registry.
  List<String> evaluate({
    required RewardCatalog catalog,
    required List<AttemptRecord> attempts,
    required Map<String, String> gameCategories,
    required Set<String> alreadyUnlocked,
  }) {
    final correct = attempts.where((a) => a.isCorrect).toList();
    final newlyUnlocked = <String>[];

    for (final reward in catalog.rewards) {
      if (alreadyUnlocked.contains(reward.id)) continue;
      if (_satisfies(reward.rule, correct, gameCategories)) {
        newlyUnlocked.add(reward.id);
      }
    }
    return newlyUnlocked;
  }

  bool _satisfies(
    RewardRule rule,
    List<AttemptRecord> correct,
    Map<String, String> gameCategories,
  ) {
    switch (rule.type) {
      case RewardRuleType.firstCompletion:
        return correct.isNotEmpty;

      case RewardRuleType.completionCount:
        return correct.length >= (rule.count ?? 1);

      case RewardRuleType.categoryCompleted:
        final gamesInCategory = gameCategories.entries
            .where((e) => e.value == rule.category)
            .map((e) => e.key)
            .toSet();
        if (gamesInCategory.isEmpty) return false;
        final completedGames = correct.map((a) => a.gameId).toSet();
        return gamesInCategory.every(completedGames.contains);

      case RewardRuleType.streakDays:
        return _longestStreakDays(correct) >= (rule.count ?? 1);

      case RewardRuleType.allCategoriesExplored:
        final categories = gameCategories.values.toSet();
        if (categories.isEmpty) return false;
        final playedCategories = correct
            .map((a) => gameCategories[a.gameId])
            .whereType<String>()
            .toSet();
        return categories.every(playedCategories.contains);
    }
  }

  /// Longest run of consecutive calendar days with >=1 correct completion.
  int _longestStreakDays(List<AttemptRecord> correct) {
    final days = correct
        .map((a) => DateTime(
              a.attemptedAt.year,
              a.attemptedAt.month,
              a.attemptedAt.day,
            ))
        .toSet()
        .toList()
      ..sort();
    if (days.isEmpty) return 0;

    var longest = 1;
    var current = 1;
    for (var i = 1; i < days.length; i++) {
      final gap = days[i].difference(days[i - 1]).inDays;
      if (gap == 1) {
        current++;
        if (current > longest) longest = current;
      } else if (gap > 1) {
        current = 1;
      }
    }
    return longest;
  }
}
