# Next Phase Plan

Prioritized follow-up after `fix/full-integration-production`. Ordered by what blocks the golden flow from actually running in a shipped build.

## P0 — do first

1. **Merge the two app shells.** Switch `apps/mobile/lib/main.dart`'s `main()` to boot `app.dart`'s `MiAcademyApp` (GoRouter-based). Migrate the working multi-game asset-loading/launch logic from `main.dart`'s `HomeScreen` into the real flow (e.g. `ChildHomeScreen`'s lesson launcher already added this session can grow to support all 6 games, not just Memory Cards). Update or remove the two widget tests that currently assert on the old shell (`widget_test.dart`: "MI Academy shell renders the first playable game entries", "Local parent area shows gentle report and opens settings"). This is the single highest-leverage change — everything else wired this session becomes reachable once this lands.
2. **Delete the two dead, non-compiling files** `apps/mobile/lib/src/games/math_race/math_race_screen.dart` and `math_supermarket_screen.dart` (with explicit sign-off — a safety check declined this in the current session since they weren't named in the approved plan).

## P1 — before beta

3. **Instrument the other 5 games** to produce real `MiCompletionResult`/`MiGameResult` data (currently only Memory Cards does). Without this, mastery evidence for word_builder/sound_match/math_race/math_supermarket/robot_commands will always be the demo-level placeholder data `GameScreen` currently sends, not real gameplay signal.
4. **Wire `adaptive_core`/`mastery_core`/`recommendation_core`/`spaced_repetition`** into the mobile app now that a real result-save path exists to trigger them from (per the original request: "adaptive engine ... only runs after GameResult has been saved successfully" — the save now exists; the adaptive trigger doesn't yet).
5. **Fix rate limiting for multi-replica production** (`apps/api/middleware/rate_limit.py`'s in-memory fallback) or ensure Redis is a hard requirement in production config.
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
