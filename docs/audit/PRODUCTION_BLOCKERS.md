# Production Blockers — as of fix/full-integration-production

Ranked by severity. "Fixed this session" items are included for traceability but are not blockers anymore.

## P0 — blocks shipping the golden flow as designed

### 1. ~~The shipped app never boots the login → child → dashboard flow~~ — FIXED (fix/full-phase-1-to-19)
`main.dart` now boots `app.dart`'s real `MiAcademyApp` (GoRouter flow), with `SplashScreen` doing auth-state-aware routing (unauthenticated → `/login`; authenticated + child selected → `/home`; authenticated + no child → `/select-child`). The old game-picker shell was renamed `DebugGamePickerApp` and is no longer the boot target, but remains in the tree (imported only by its own test) rather than deleted, since it's still useful for local game-engine iteration and multi-game asset-loading isn't yet replicated in the production flow (only Memory Cards is reachable from `ChildHomeScreen` today — see item #4 below). See `docs/final/INTEGRATION_REPORT.md` Phase 4 section.

Original description kept below for history:
`apps/mobile/lib/main.dart`'s `void main()` runs a standalone `MiAcademyApp`/`HomeScreen` (defined in `main.dart` itself) that goes straight to a 6-game picker using local asset content — it never shows `LoginScreen`, `ChildSelectorScreen`, `ChildHomeScreen`, or `ParentDashboardScreen`. Those screens, plus the GoRouter navigation graph that connects them, live in `apps/mobile/lib/app.dart` (a *second*, unused `MiAcademyApp` class) and `apps/mobile/lib/config/router.dart`, but nothing calls `runApp` on them.

Everything wired this session (real child creation, lesson-launch navigation, save-result + offline-queue calls in `GameScreen`) is real, compiling, tested code — but it is not reachable from the app a user actually installs today.

**Recommendation:** switch `main.dart`'s `main()` to boot `app.dart`'s `MiAcademyApp` (with `initHive()` + a Hive-backed `ParentSettingsStore` override, both of which this session's `main.dart` already sets up), migrate the working asset-loading/game-launch logic from `main.dart`'s `HomeScreen` into the real flow (e.g. behind `ChildHomeScreen`'s lesson launcher), and update or remove the two widget tests (`widget_test.dart`: "MI Academy shell renders the first playable game entries", "Local parent area shows gentle report and opens settings") that currently assert on the old shell. This is a multi-file, test-touching change that needs its own review pass — not done unilaterally this session.

### 2. `SaveGameResultRequest` → mastery → sync pipeline had no server-side owner (fixed this session)
Was: fully-defined Pydantic contract, zero routes used it; the real "finish game" endpoint used a thinner schema with no idempotency and client-trusted mastery scores. Now: `POST /games/{game_id}/result` implements the real contract with server-side mastery calculation and `attempt_id` idempotency. See `INTEGRATION_REPORT.md`.

### 3. `GET /lessons` raised a validation error on every call (fixed this session)
`LessonListItem` requires `subject_id`; the route never passed it. This would have broken lesson selection for every user in production. One-line fix in `apps/api/routes/lessons.py`, two call sites.

### 3b. `/parent` and `/parent/settings` were reachable without PIN verification — FIXED (fix/full-phase-1-to-19)
Discovered this session (not in the original blocker list): the router's own doc comment claimed these routes were "PIN-protected via /parent-pin," but nothing enforced it — `context.go('/parent')` from anywhere, a deep link, or router state restoration would land directly on `ParentDashboardScreen` with no PIN check. Fixed via a `parentGateProvider` set only inside `ParentPinScreen`'s unlock path and a `redirect` guard in `router.dart`. See `docs/final/INTEGRATION_REPORT.md` Phase 5 addendum.

## P1 — should fix before beta

### 4. ~~Only 1 of 6 games produces real completion telemetry~~ — FIXED (fix/full-phase-1-to-19)
All 6 games (`WordBuilderScreen`, `SoundMatchScreen`, `ChoiceGameScreen` for math_race/math_supermarket, `RobotCommandsScreen`, `MemoryCardsScreen`) now report a real `MiCompletionResult` (score, attempts, hints, duration). The production `/game/:gameId` route, which previously showed a hardcoded fake demo regardless of `gameType`, now renders the actual game engine and turns each completion into a real `/games/{id}/result` call with offline-queue fallback. Remaining refinement: skill evidence is one fixed tag per game rather than per-question, and there's still no lesson→game content mapping (see `docs/final/NEXT_PHASE_PLAN.md`).

### 5. Offline sync was built but inert (fixed this session)
`packages/offline_sync`'s `SyncQueue`/`SyncService`/`ApiSyncProcessor` were fully implemented and unit-tested but never instantiated by the app, and `initHive()` never opened any Hive boxes (all commented out) — so even if instantiated, `Hive.box()` calls would have thrown. Both fixed: `initHive()` now opens the real boxes and registers the `SyncQueueItem` adapter; `syncServiceProvider` constructs and starts a `SyncService` with a real `ApiSyncProcessor`. A new `SyncItemType.gameResult` was added end-to-end (queue model → processor → `ApiService.submitGameResult`) so a failed/offline game-result save now queues instead of being silently dropped.

### 6. Rate limiting has a non-prod-safe fallback
`apps/api/middleware/rate_limit.py` has a Redis-backed limiter with an explicitly-documented in-memory fallback that is "per-process only, not for prod multi-replica." If Redis isn't configured in the production deployment, rate limiting silently becomes per-instance rather than global.

### 7. Contract fragmentation beyond MiGameResult
`Lesson`, `Child`, `Parent`, `Skill`, `Progress` each have 2-4 independently hand-maintained definitions across the Python and Dart layers (see `DUPLICATE_ANALYSIS.md`). Only `MiGameResult`/`SaveGameResultRequest` was verified field-for-field this session. No codegen/single-source-of-truth mechanism exists.

### 8. ~~Two dead, non-compiling game screen files remain in the tree~~ — FIXED (fix/full-phase-1-to-19)
`math_race_screen.dart`, `math_race_session.dart`, `math_supermarket_screen.dart`, `math_supermarket_session.dart` deleted after re-confirming zero references outside themselves. `flutter analyze` is now fully clean (0 issues, down from 19).

## P2 — real but lower urgency

- `packages/game_core` (Python game engine) is unused by `apps/api`, which reimplements equivalent logic inline in `routes/games.py`. Worth a design review on whether to consolidate.
- `contracts/shared_contracts.py` is a third, unused-by-the-API contract definition, kept alive only by `tools/mi_cli/mi.py`'s validator commands.
- `adaptive_core`/`mastery_core`/`recommendation_core`/`spaced_repetition` Dart packages are built but not imported anywhere in `apps/mobile` — no adaptive learning or spaced repetition actually runs in the app today.
- Content, assets, localization, admin app, infrastructure, and CI were not audited this session (see `KNOWN_LIMITATIONS.md`).
