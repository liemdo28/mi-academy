# Integration Report — fix/full-integration-production

> **Update (fix/full-phase-1-to-19, this session):** see the "Phase 4 addendum" section near the bottom for the production entry-point fix and dead-file cleanup done in the follow-up session. The rest of this document describes the original `fix/full-integration-production` PR (already merged to `main`).

## Scope

Deep integration/fix pass on the golden flow (parent login → create child → choose lesson → launch game → play → finish → save result → update mastery → queue sync → sync server → parent dashboard), plus removal of confirmed-dead duplicate code. Not a full 19-phase production-readiness pass — see `docs/final/KNOWN_LIMITATIONS.md`.

## Files created

- `apps/api/alembic/versions/3aac9694cdd1_add_client_attempt_id.py` — migration adding `attempts.client_attempt_id` (unique, nullable) for idempotency.
- `tests/test_api_game_result.py` — 3 tests for the new `/games/{id}/result` endpoint (create+mastery update, idempotent replay, ownership check).
- `tests/test_golden_flow.py` — 1 end-to-end test: register → create child → list lessons → save game result → mastery updated → session synced → parent reports/weekly report reflect it.
- `apps/mobile/lib/widgets/add_child_dialog.dart` — shared create-child dialog (used by both `ChildSelectorScreen` and `ParentDashboardScreen`).
- `docs/audit/*.md`, `docs/final/*.md` — this audit.

## Files modified (functional changes)

- `apps/api/models/__init__.py` — added `Attempt.client_attempt_id`.
- `apps/api/schemas/progress.py` — added optional `lesson_id` to `SaveGameResultRequest` (additive; the DB has no Game→Lesson FK, so the mobile client supplies it when known).
- `apps/api/routes/games.py` — new `POST /{game_id}/result` endpoint (idempotent attempt log + server-side mastery calc + reward check); extracted `_check_first_star_badge` helper shared with the existing `/complete` endpoint (unchanged behavior, no duplication).
- `apps/api/routes/lessons.py` — fixed `LessonListItem` missing `subject_id` (pre-existing bug, both call sites).
- `packages/offline_sync/lib/src/sync_queue.dart`, `sync_service.dart` — added `SyncItemType.gameResult`.
- `packages/offline_sync/lib/src/hive_boxes.dart` — `initHive()` now actually opens Hive boxes and registers the `SyncQueueItem` adapter (previously all `Hive.openBox` calls were commented out — the sync queue could not have worked at runtime before this).
- `apps/mobile/lib/services/api_service.dart` — fixed `submitGameResult` (previously posted to a nonexistent `/api/v1/progress/game-result`; now posts to the real `/api/v1/games/{id}/result` and returns the response).
- `apps/mobile/lib/services/api_sync_processor.dart` — handles `SyncItemType.gameResult` by calling `submitGameResult`.
- `apps/mobile/lib/providers/providers.dart` — added `gamesCatalogProvider` (game_type → DB id lookup) and `syncServiceProvider` (constructs + starts a real `SyncService`); `connectivityProvider` now does a real `connectivity_plus` check instead of a hardcoded `TODO: return true`.
- `apps/mobile/lib/providers/child_provider.dart` — added `ActiveChildNotifier.createChild`.
- `apps/mobile/lib/screens/child_selector_screen.dart` — rewritten to show real children from `activeChildProvider` (was fully hardcoded fake data) and wire "add child" to a real create-child dialog.
- `apps/mobile/lib/screens/parent_dashboard_screen.dart` — create-child empty-state CTA now opens the real dialog instead of a "coming soon" snackbar.
- `apps/mobile/lib/screens/child_home_screen.dart` — hero CTA and daily-plan item taps now navigate to the game launcher with real `childId`/`lessonId` (previously no-op TODOs).
- `apps/mobile/lib/screens/game_screen.dart` — completion now calls the real `submitGameResult` (with offline-queue fallback via `syncServiceProvider.enqueue`) instead of discarding the session. (One iteration: an in-code comment using the word "failed" tripped `tools/child_safety_audit.py`'s harsh-feedback-wording regex scan — reworded; the scanner checks all file text, not just user-facing strings.)
- `apps/mobile/lib/config/router.dart` — `/game/:gameId` route now threads an optional `lessonId` query param through to `GameScreen`.
- `apps/mobile/lib/main.dart` — calls `initHive()` before `runApp` (required for the sync queue to function).
- 10 `packages/*/pubspec.yaml` + `apps/mobile/pubspec.yaml` + `apps/admin/pubspec.yaml` — removed dangling `shared_models:` dependency entries.

## Files removed

`packages/game-core/` (empty), `packages/shared_contracts/` (dead stub), `packages/mock_services/`, `packages/integration_core/`, `packages/integration_testing/` (empty), `packages/shared_models/` (orphaned Dart package), root scratch files (`_build_sql.py`, `_decode.py`, `_gen*.{py,ps1}`, `_gen2.txt`, `_tmp_write.py`, `_ws_payload.txt`, `3.4.0`), `packages/mi_game_testing/{_check.txt,_gen.py,_gen2.py,_gen_all.py,_single.txt,_test.txt}`. Full rationale in `docs/audit/DUPLICATE_ANALYSIS.md`.

## Risks found / fixed / remaining

**Fixed:**
- Dead `SaveGameResultRequest` contract → now wired end-to-end with idempotency and server-side mastery.
- `GET /lessons` 100%-failure bug → fixed.
- Offline sync queue non-functional (Hive boxes never opened) → fixed.
- Mobile `submitGameResult` posting to a nonexistent endpoint → fixed.
- 5 empty/dead packages and 1 orphaned Dart package (with 12 dangling dependency declarations) → removed.

**Remaining (see `docs/audit/PRODUCTION_BLOCKERS.md` for full detail):**
- P0: the app's actual entry point (`main.dart`) doesn't boot the flow this session wired up — `app.dart`'s real navigation graph is unreachable from `main()`.
- P1: only Memory Cards produces real completion telemetry; the other 5 games have no completion callback at all.
- P1: two dead, non-compiling game screen files remain (deletion was denied by a safety check as out-of-plan-scope).
- P1: rate limiting's in-memory fallback isn't multi-replica safe.
- P2: broader contract fragmentation (Lesson/Child/Parent/Skill/Progress) beyond MiGameResult not verified field-for-field.

## Test evidence

- Backend: `pytest tests test packages/game_core/tests` → **126 → 130 tests, all passing** (4 new: 3 for `/games/{id}/result`, 1 golden-flow end-to-end).
- Mobile: `flutter test` → **54 → 55 tests, all passing** (1 new: `ApiSyncProcessor` routes `gameResult` queue items).
- Mobile: `flutter analyze` → clean on every file touched this session. Two pre-existing dead files (`math_race_screen.dart`, `math_supermarket_screen.dart`, not touched this session) still fail analyze — see blocker #8.
- No manual on-device/emulator run was performed in this environment; verification is test-suite-based. See `docs/final/KNOWN_LIMITATIONS.md`.

## Before / after

**Before:** a game finishing on the "real" navigation graph had no code path to the backend at all (`ChildHomeScreen`'s CTA and plan-item taps were no-ops; `GameScreen`'s completion button just popped the screen). `SaveGameResultRequest` existed only as an unused schema. Offline sync code existed but could not run.

**After:** finishing a game on the GoRouter flow (once reachable — see blocker #1) calls a real, idempotent, mastery-updating backend endpoint, with an offline queue fallback that actually drains. This is proven by an automated golden-flow test that exercises the whole chain from registration through the parent's weekly report.

---

## Phase 4 addendum (fix/full-phase-1-to-19)

**Scope:** production entry point fix (Phase 4 of the user's second 19-phase spec) + deletion of the two dead game files (part of Phase 7), on top of the already-merged work above.

**Root cause fixed:** `apps/mobile/lib/main.dart` defined its own `MiAcademyApp`/`HomeScreen` and `void main()` booted that — a standalone 6-game picker using local asset content. `apps/mobile/lib/app.dart` defined a second, same-named `MiAcademyApp` wired to the real `config/router.dart` GoRouter graph (built in the prior session), but nothing called `runApp` on it.

**Files modified:**
- `apps/mobile/lib/main.dart` — renamed the local `MiAcademyApp` class to `DebugGamePickerApp` (mechanical rename, no behavior change) to resolve the name collision; `void main()` now boots `app.dart`'s real `MiAcademyApp`, wrapped in `ProviderScope` with `parentSettingsStoreProvider` overridden to a Hive-backed store.
- `apps/mobile/lib/providers/providers.dart` — added `parentSettingsStoreProvider` (defaults to in-memory; overridden in `main()`).
- `apps/mobile/lib/config/router.dart` — `/parent/settings` route now resolves `ParentSettingsScreen`'s store from `parentSettingsStoreProvider` instead of silently defaulting to a non-persistent in-memory store.
- `apps/mobile/lib/screens/splash_screen.dart` — replaced the fixed 2-second delay to `/login` with real auth-state routing: calls `AuthNotifier.initialize()` (restores tokens, fetches profile), then routes unauthenticated → `/login`, authenticated-with-child → `/home`, authenticated-no-child → `/select-child`. The routing decision itself is factored into a pure `startRouteFor()` function for direct unit testing.
- `apps/mobile/test/widget_test.dart` — updated the one reference to the renamed `DebugGamePickerApp` (test itself unchanged in behavior, just retargeted + retitled for accuracy).

**Files created:**
- `apps/mobile/test/splash_routing_test.dart` — 3 unit tests covering the `startRouteFor()` decision table.

**Files deleted:**
- `apps/mobile/lib/src/games/math_race/math_race_screen.dart`, `math_race_session.dart`, `apps/mobile/lib/src/games/math_supermarket/math_supermarket_screen.dart`, `math_supermarket_session.dart` — re-verified zero references outside themselves immediately before deletion, per the user explicitly naming these files this session (superseding the prior session's destructive-action block).

**What's still not covered by this fix (see `docs/final/KNOWN_LIMITATIONS.md`):**
- `ChildHomeScreen`'s lesson launcher still always targets `memory_cards` — there is no lesson→game mapping in the backend (`DailyPlanItem` has no `game_id`/`game_type` field), so this is the most honest default available rather than a fabricated mapping.
- Not verified on a real device/emulator (none available in this environment) — verified via `flutter analyze` + `flutter test` + call-graph tracing only.
- Multi-child selection UX (`/select-child` when >1 child exists) exists and was already built in the prior session, but wasn't re-tested end-to-end here beyond the routing decision itself.

**Test evidence:**
- `flutter analyze` (apps/mobile): **19 issues → 0 issues.**
- `flutter test` (apps/mobile): **55 → 58 tests, all passing** (3 new: splash routing decision table).
- `pytest tests test packages/game_core/tests`: **130 passed, unchanged** (no backend files touched this phase — regression check only).

---

## Phase 6/7 addendum (fix/full-phase-1-to-19, same session, continued)

**Scope:** `/game/:gameId` — the production route `ChildHomeScreen` actually navigates to — was still rendering a **hardcoded fake demo** (fixed "Trả lời đúng"/"Thử lại" buttons, no real questions, ignored `gameType` except for the title) even after the Phase 4 entry-point fix. This meant the "golden flow" couldn't play a real game end-to-end in production. Fixed this pass, plus completion telemetry added to 4 of the 5 games that previously had none (Phase 7's "fix five games' missing completion callback").

**Root cause:** the real per-game engines (`WordBuilderScreen`, `SoundMatchScreen`, `ChoiceGameScreen`, `MemoryCardsScreen`, `RobotCommandsScreen`) were only ever instantiated from `main.dart`'s debug game-picker (`HomeScreen`, now `DebugGamePickerApp`) — `screens/game_screen.dart` (the actual production route target) never rendered them.

**Files created:**
- `apps/mobile/lib/services/game_levels.dart` — shared level-asset loader (`gameLevelAssets` map + `loadGameLevels()`), extracted from `main.dart`'s private `_gameAssets`/`_loadLevels` so there's one source of truth for where level content lives, used by both the debug picker and the production launcher.
- `apps/mobile/test/game_screen_test.dart` — 3 widget tests: real Word Builder renders, real Memory Cards renders, unknown game type shows a retryable error state.

**Files modified:**
- `apps/mobile/lib/screens/game_screen.dart` — **rewritten**. Loads real levels via `loadGameLevels()` for the requested `gameType`, renders the matching real game engine (word_builder/sound_match/math_race/math_supermarket/robot_commands/memory_cards), and turns each game's `onComplete(MiCompletionResult)` into a `SaveGameResultRequest` call (idempotent, offline-queued on failure — reuses the same `submitGameResult`/`syncServiceProvider` path built in the original session). A private `_MemoryCardsHost` reproduces the level-advance/completion-overlay logic the debug picker's `_MemoryCardsEntry` already had, since `MemoryCardsScreen` (unlike the other 5) has no built-in completion UI.
- `apps/mobile/lib/src/games/word_builder/word_builder_screen.dart`, `sound_match/sound_match_screen.dart`, `robot_commands/robot_commands_screen.dart`, `choice/choice_game_screen.dart` — added an optional `void Function(MiCompletionResult)? onComplete` param, fired from each screen's existing `_showCompletion()` with real session data (score, attempts, hints, duration — `robot_commands` gained a `Stopwatch` it didn't have before, matching the pattern the other 3 already used). **Games still don't call the backend or Hive themselves** — they only report the result upward, per the "games must not call the API directly" rule; `GameScreen` (the caller) owns turning that into a save.
- `apps/mobile/lib/main.dart` — `DebugGamePickerApp`'s level loading now delegates to the shared `game_levels.dart` helper instead of duplicating the asset-reading logic; removed now-dead `_gameAssets` map and unused `dart:convert`/`mi_game_content` imports.

**What's still not covered:**
- `math_race`/`math_supermarket` (via `ChoiceGameScreen`) and `sound_match`/`robot_commands`/`word_builder` completion telemetry is now real (score/attempts/hints/duration), but coarser than Memory Cards' `skillEvidence` — each just reports one fixed skill tag (`'math'`, `'listening'`, `'sequencing'`, `'vocabulary'`) rather than per-question skill breakdown, since none of these session classes track per-question skill data today.
- `ChildHomeScreen`'s launcher still always opens `memory_cards` regardless of which lesson was tapped — no lesson→game content mapping exists yet (see above).
- Not device-verified — same limitation as the Phase 4 addendum.

**Test evidence:**
- `flutter analyze` (apps/mobile): **0 issues** (unchanged — stayed clean).
- `flutter test` (apps/mobile): **58 → 61 tests, all passing** (3 new: `game_screen_test.dart`).
- `pytest tests test packages/game_core/tests`: **130 passed, unchanged** (no backend files touched — regression check only).

---

## Phase 5 addendum (fix/full-phase-1-to-19, same session, continued)

**Scope:** a real security gap in the parent/child boundary — `/parent` and `/parent/settings` were reachable by direct navigation (`context.go('/parent')`, a deep link, or router state restoration) **without ever going through `ParentPinScreen`**. The route comment in `router.dart` already claimed "PIN-protected via /parent-pin," but nothing enforced it.

**Fix:** added `parentGateProvider` (`StateProvider<bool>`, default `false`) set to `true` only inside `ParentPinScreen._unlock()` (both the PIN-entry and adult-math-fallback paths call it, since both already converge on `_unlock()`), and reset to `false` on `AuthNotifier.logout()` so a fresh sign-in on a shared device re-locks the parent area. `router.dart`'s `GoRouter` now has a `redirect` callback that bounces `/parent` and `/parent/settings` to `/parent-pin` whenever `parentGateProvider` is false.

**Files modified:** `providers.dart` (new provider), `parent_pin_screen.dart` (set flag on unlock), `auth_provider.dart` (reset flag on logout), `config/router.dart` (redirect guard).
**Files created:** `test/parent_route_guard_test.dart` — 2 tests using the real `routerProvider` (not a test-local stand-in): direct `/parent` navigation redirects to the PIN gate when unverified; `/parent` is reachable once the gate provider is true.

**Other Phase 5 items checked, not changed (already correct):**
- **Parent token never reaches games.** Game widgets (`WordBuilderScreen` etc.) only ever receive `MiLevel`/`childId`/`lessonId` as constructor params — never `ApiService` or a token. The JWT lives inside `ApiService`, read only by `GameScreen` (the launcher) and provider-level code, not by anything under `src/games/`. No change needed; verified by re-reading every game screen's constructor.
- **PIN retry limit.** Already implemented and tested (`ParentPinScreen`'s 3-attempt lockout, covered by the pre-existing "Parent PIN locks after three failed attempts" test) — confirmed still passing, not touched.

**Known gap, not fixed this pass:** there's no *global* reaction to a mid-session auth failure (e.g., if the parent's token and refresh token both expire while the app is open, the specific screen's request just errors — nothing redirects the user back to `/login`). Fixing this needs a cross-cutting mechanism (e.g., a Dio interceptor that clears state and triggers navigation on unrecoverable 401), which is a larger change than this pass's scope — added to `docs/final/NEXT_PHASE_PLAN.md`.

**Test evidence:**
- `flutter analyze` (apps/mobile): **0 issues** (stayed clean).
- `flutter test` (apps/mobile): **61 → 63 tests, all passing** (2 new: `parent_route_guard_test.dart`).
- `pytest tests test packages/game_core/tests`: **130 passed, unchanged** (no backend files touched).
