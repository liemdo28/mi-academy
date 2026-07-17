# Repository Audit — fix/full-integration-production

**Date:** 2026-07-17
**Scope:** Full-repo audit requested as Phase 1 of a 19-phase production-readiness pass. This document reflects what was actually found by direct code inspection this session — it supersedes the "shell only" / "not wired" claims in older docs under `docs/` (see "Docs freshness" below), which were stale relative to current code.

## What this session covered vs. did not

This session (branch `fix/full-integration-production`) did a **deep audit + fix pass on the golden flow** (parent login → create child → choose lesson → play → save result → mastery → sync → parent dashboard), not the full 19-phase scope. See [`docs/final/KNOWN_LIMITATIONS.md`](../final/KNOWN_LIMITATIONS.md) for what was explicitly out of scope, and [`docs/final/NEXT_PHASE_PLAN.md`](../final/NEXT_PHASE_PLAN.md) for prioritized follow-up.

## Backend (`apps/api`, FastAPI)

- Routes exist and are DB-backed (not stubs) for: auth (register/login/refresh), children CRUD, lessons (list/detail/start/complete), games (list/detail/start/attempt/complete), progress (read-only), sync (content/progress/attempts/sessions), parent (profile/PIN/reports/weekly report/export).
- **Found and fixed this session:** `SaveGameResultRequest` (the `MiGameResult` contract) was fully defined in `apps/api/schemas/progress.py` but never used by any route — the actual "finish game" endpoint (`POST /games/{id}/complete`) used a much thinner schema with no idempotency and no server-side mastery calculation. A new `POST /games/{game_id}/result` endpoint now implements the real contract: idempotent by `attempt_id`, persists an `Attempt`, computes mastery server-side, and updates `Progress`. See [`INTEGRATION_REPORT.md`](../final/INTEGRATION_REPORT.md) for details.
- **Found and fixed this session:** `list_lessons`/`get_recommended` in `apps/api/routes/lessons.py` never passed `subject_id` to `LessonListItem`, so `GET /lessons` raised a Pydantic `ValidationError` on every call — a pre-existing, undetected-by-tests bug that would break lesson selection in production. Fixed (one-line addition, two call sites).
- Auth (JWT + bcrypt + refresh tokens), parent PIN (bcrypt-hashed), and per-request rate limiting exist and look sound; see [`docs/audit/PRODUCTION_BLOCKERS.md`](PRODUCTION_BLOCKERS.md) for the one real gap (in-memory rate-limit fallback isn't multi-replica safe).
- 130 backend tests pass (126 pre-existing + 4 added this session): `pytest tests test packages/game_core/tests`.

## Mobile (`apps/mobile`, Flutter)

- **Major finding:** the app has two parallel, non-integrated app shells. `lib/main.dart`'s `void main()` boots a standalone game-picker (`HomeScreen`) that launches all 6 games from local asset JSON — this is what actually ships. `lib/app.dart` defines a *second*, unused `MiAcademyApp` (same class name, different file) wired to `lib/config/router.dart`'s GoRouter flow (splash → login → child-selector → child-home → parent-dashboard) — this is the intended production navigation graph, but it is never referenced by `main()` or by any test that exercises app boot. This is the single biggest gap between "the golden flow is coded" and "the golden flow runs." See `PRODUCTION_BLOCKERS.md`.
- Within the GoRouter flow (real code, just not the boot target), this session wired what were previously no-op TODOs: lesson launch from `ChildHomeScreen`, child creation from `ChildSelectorScreen`/`ParentDashboardScreen`, and save-result + offline-queue calls from `GameScreen`.
- Offline sync (`packages/offline_sync`) was fully built and unit-tested but never instantiated at runtime — no provider constructed a `SyncQueue`/`SyncService`, and `initHive()` never actually opened any Hive boxes (all `Hive.openBox` calls were commented out). Both fixed this session.
- 6 games are implemented under `lib/src/games/` (word_builder, sound_match, math_race-via-`ChoiceGameScreen`, math_supermarket-via-`ChoiceGameScreen`, memory_cards, robot_commands) with real widget tests. Two files, `lib/src/games/math_race/math_race_screen.dart` and `math_supermarket_screen.dart`, are **dead code that doesn't compile** (`flutter analyze` errors: undefined `GameScaffold`/`QuestionCard`/`AnswerButton` etc.) — they're superseded by `ChoiceGameScreen` and referenced nowhere, but were left in place this session rather than deleted (see `DUPLICATE_ANALYSIS.md` for why).
- 55 mobile tests pass (`flutter test`), `flutter analyze` is clean except for the two pre-existing dead files above.
- `adaptive_core`, `mastery_core`, `recommendation_core`, `spaced_repetition` (Dart packages) are not imported anywhere in `apps/mobile` — built but unused.

## Packages

37 packages under `packages/`. Confirmed dead and removed this session: `packages/game-core` (empty stub), `packages/shared_contracts` (empty stub pyproject), `packages/mock_services`, `packages/integration_core`, `packages/integration_testing` (untracked empty dirs), `packages/shared_models` (Dart package with zero actual imports anywhere despite being declared as a pubspec dependency in 10 other packages — all 10 dependency declarations removed too). Details in `DUPLICATE_ANALYSIS.md`.

`adaptive_core`, `mastery_core`, `recommendation_core`, `spaced_repetition`, `learning_core`, `learning_analytics` are legitimately distinct (no overlapping responsibilities found) — not duplicates, just currently unwired to the app (see above).

## Content, assets, localization, admin, infrastructure, CI

**Not audited this session** — out of scope for the golden-flow-focused pass. See `KNOWN_LIMITATIONS.md`.

## Docs freshness

`docs/PLATFORM_REPOSITORY_AUDIT.md` and `docs/GAME_REPOSITORY_AUDIT.md` describe the mobile app as a single-game "starter" and several packages as "shell only" — this is stale and contradicted by current code (6 games, populated packages with real tests). `docs/RELEASE_READINESS_BASELINE.md` was closest to ground truth. `docs/PLATFORM_GAP_ANALYSIS.md`'s claim that parent login/PIN/child CRUD are "not wired" is also contradicted (they're real, DB-backed). None of these older docs were rewritten this session; treat them as historical rather than current.
