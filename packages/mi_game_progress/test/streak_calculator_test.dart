import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_progress/mi_game_progress.dart';

AttemptRecord _attempt(DateTime day, {bool correct = true}) {
  return AttemptRecord(
    childId: 'child-1',
    gameId: 'math_race',
    levelId: 'lv-${day.toIso8601String()}',
    correct: correct,
    attemptedAt: day,
    duration: const Duration(seconds: 30),
  );
}

void main() {
  final today = DateTime.utc(2026, 7, 21);

  test('no attempts at all is a zero streak', () {
    expect(StreakCalculator.currentStreakDays(const [], now: today), 0);
  });

  test('practiced today extends the streak through consecutive prior days', () {
    final attempts = [
      _attempt(today),
      _attempt(today.subtract(const Duration(days: 1))),
      _attempt(today.subtract(const Duration(days: 2))),
    ];
    expect(StreakCalculator.currentStreakDays(attempts, now: today), 3);
  });

  test(
      'practiced through yesterday but not yet today still counts -- a '
      'streak does not reset the instant midnight passes', () {
    final attempts = [
      _attempt(today.subtract(const Duration(days: 1))),
      _attempt(today.subtract(const Duration(days: 2))),
    ];
    expect(StreakCalculator.currentStreakDays(attempts, now: today), 2);
  });

  test('a gap of a full missed day breaks the streak back to zero', () {
    final attempts = [
      _attempt(today.subtract(const Duration(days: 2))),
      _attempt(today.subtract(const Duration(days: 5))),
    ];
    expect(StreakCalculator.currentStreakDays(attempts, now: today), 0);
  });

  test(
      'a gap further in the past does not truncate the still-active '
      'current run', () {
    final attempts = [
      _attempt(today),
      _attempt(today.subtract(const Duration(days: 1))),
      // Gap here (day 2 missing) -- irrelevant to the *current* streak.
      _attempt(today.subtract(const Duration(days: 3))),
    ];
    expect(StreakCalculator.currentStreakDays(attempts, now: today), 2);
  });

  test(
      'only counts correct attempts -- an incorrect-only attempt today '
      'does not itself extend the streak past what correct days already '
      'earned', () {
    final attempts = [
      _attempt(today, correct: false),
      _attempt(today.subtract(const Duration(days: 1))),
    ];
    // Today has no *correct* completion, but yesterday's still keeps the
    // streak alive at 1 -- same "hasn't opened the app yet today" rule
    // as the practiced-through-yesterday case above.
    expect(StreakCalculator.currentStreakDays(attempts, now: today), 1);
  });

  test('an incorrect-only attempt does not fabricate a streak on its own', () {
    final attempts = [_attempt(today, correct: false)];
    expect(StreakCalculator.currentStreakDays(attempts, now: today), 0);
  });

  test(
      'multiple attempts on the same day count as one streak day, not '
      'multiple', () {
    final attempts = [
      _attempt(today),
      _attempt(today.add(const Duration(hours: 3))),
      _attempt(today.subtract(const Duration(days: 1))),
    ];
    expect(StreakCalculator.currentStreakDays(attempts, now: today), 2);
  });
}
