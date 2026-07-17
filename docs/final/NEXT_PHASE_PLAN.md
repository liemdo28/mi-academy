# Next Phase Plan

Prioritized follow-up after `fix/full-integration-production`. Ordered by what blocks the golden flow from actually running in a shipped build.

## P0 — do first

1. ~~Merge the two app shells~~ — **DONE (fix/full-phase-1-to-19).** `main()` now boots `app.dart`'s real `MiAcademyApp`, with auth-state-aware splash routing. Remaining follow-up: the multi-game asset-loading/launch logic from the old `HomeScreen` (now `DebugGamePickerApp`, debug-only) still hasn't been migrated into the production flow — `ChildHomeScreen`'s lesson launcher only reaches Memory Cards today (see #3 below). The two widget tests that asserted on the old shell were updated (renamed), not removed.
2. ~~Delete the two dead, non-compiling files~~ — **DONE (fix/full-phase-1-to-19).** `math_race_screen.dart`/`math_race_session.dart`/`math_supermarket_screen.dart`/`math_supermarket_session.dart` removed; `flutter analyze` is fully clean.

## P1 — before beta

3a. **No global reaction to mid-session auth failure.** If the parent's access + refresh tokens both expire while the app is open, the specific screen's request just errors — nothing redirects to `/login`. Needs a cross-cutting mechanism (e.g. a Dio interceptor that clears auth state and triggers navigation on an unrecoverable 401). Found during this session's Phase 5 pass; not fixed (see `docs/final/INTEGRATION_REPORT.md` Phase 5 addendum).
3. ~~Instrument the other 5 games~~ — **DONE (fix/full-phase-1-to-19).** All 6 games now emit `MiCompletionResult` with real score/attempts/hints/duration, and `/game/:gameId` renders the actual game engines instead of a fake demo. Remaining refinement: per-question `skillEvidence` (currently one fixed tag per game) and a real lesson→game content mapping so `ChildHomeScreen` doesn't always default to Memory Cards.
4. **Wire `adaptive_core`/`mastery_core`/`recommendation_core`/`spaced_repetition`** into the mobile app now that a real result-save path exists to trigger them from (per the original request: "adaptive engine ... only runs after GameResult has been saved successfully" — the save now exists; the adaptive trigger doesn't yet).
5. ~~**Fix rate limiting for multi-replica production**~~ — **DONE (fix/full-phase-1-to-19).** `APP_ENV=production` now requires `REDIS_URL` at settings validation and middleware construction, preventing silent per-process rate limiting in production.
6. **Unify remaining contracts** (`Lesson`, `Child`, `Parent`, `Skill`, `Progress`) — consider generating both the Pydantic and Dart models from one OpenAPI/JSON-Schema source rather than hand-mirroring.

## P2 — production readiness sweep

7. Security review (auth flows, PIN, JWT rotation, child-privacy/PII handling) — the CI `security-scans` job is currently non-blocking (`continue-on-error: true`); decide whether to make it blocking once findings are triaged.
8. Performance pass: startup, asset/game loading, snapshot restore, sync, parent dashboard.
9. Accessibility verification: screen reader, high contrast, reduced motion, large text, color blindness — `mi_game_accessibility` exists but wasn't verified against real usage.
10. Content/curriculum schema validation, asset audit (duplicates, missing, licensing, localization).
11. CI hardening: add a job that fails the build if a Pydantic schema is defined but never reachable from a route (would have caught the dead `SaveGameResultRequest` contract earlier) and a contract-drift check between the Python and Dart `MiGameResult` mirrors.
12. Release readiness: signing, rollback, monitoring/logging, backup/restore, health endpoints.

## Design questions to resolve before more integration work

- Should `apps/api/routes/games.py`'s inline game logic be migrated onto `packages/game_core` (the Python engine package that already exists but is unused by the API), or should `game_core` be retired in favor of the current inline approach?
- Should `packages/game_sdk` (network DTOs used by `api_client`) be merged into `mi_game_core`'s contracts, or kept as a separate layer? They currently define semantically-overlapping but structurally different `GameResult`-shaped types.
