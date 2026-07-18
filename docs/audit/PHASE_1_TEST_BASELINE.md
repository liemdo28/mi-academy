# Phase 1 — Test Baseline

**Captured:** 2026-07-17, on `main` @ `3b65f14` (immediately after checking out `fix/full-phase-1-to-19`, before any changes this session).

## Backend

```
pytest tests test packages/game_core/tests -q
```
**130 passed, 0 failed.**

## Mobile

```
flutter analyze   (apps/mobile)
```
**19 issues: 17 errors + 2 warnings, all confined to two files** — `apps/mobile/lib/src/games/math_race/math_race_screen.dart` and `math_supermarket_screen.dart` (undefined `GameScaffold`/`QuestionCard`/`AnswerButton`/`AnimatedFeedback`, missing required constructor arguments, unused imports). Zero issues elsewhere.

```
flutter test   (apps/mobile)
```
**55 passed, 0 failed** (indices 0-54).

## Conclusion

Matches what `docs/final/INTEGRATION_REPORT.md` and `docs/audit/PRODUCTION_BLOCKERS.md` from the prior session claimed. No drift detected between the merged PR and current `main` — the prior reports' test evidence is still accurate as of this baseline. This baseline is the reference point for all Phase 1+ changes in this session; any regression must be justified or reverted before proceeding.
