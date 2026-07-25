import 'attempt_record.dart';

/// Computes a child's *current* learning streak -- consecutive calendar
/// days up to and including today (or yesterday, so a streak survives
/// until the child has actually missed a whole day) with at least one
/// correct completion.
///
/// Distinct from [RewardEngine]'s private `_longestStreakDays`, which
/// answers a different question ("what's the longest run ever,
/// regardless of whether it's still active") for the `streakDays` reward
/// rule. A parent-facing "learning streak" needs the *current* one --
/// conflating the two would either overstate a streak that already
/// broke, or never let a new streak in progress be reported below its
/// eventual longest length.
abstract final class StreakCalculator {
  /// [now] is injectable for deterministic tests; defaults to the real
  /// current time.
  static int currentStreakDays(List<AttemptRecord> attempts, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final practicedDays = attempts
        .where((a) => a.isCorrect)
        .map((a) => _dateOnly(a.attemptedAt))
        .toSet();
    if (practicedDays.isEmpty) return 0;

    // A streak is still "current" if today or yesterday was practiced --
    // a child who played every day through yesterday and hasn't opened
    // the app yet today shouldn't see their streak reset to zero the
    // moment midnight passes.
    var cursor = practicedDays.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    if (!practicedDays.contains(cursor)) return 0;

    var streak = 0;
    while (practicedDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
