# Phase 10/11 + Auth Hardening Progress Report - 2026-07-18

Branch: `fix/full-phase-1-to-19`
PR: #4

This slice continues from `docs/phase-reports/PHASE_2_TO_11_PROGRESS_2026-07-17.md`,
closing several of its "Remaining blockers" for Phase 10 and Phase 11, plus fixing
`docs/final/NEXT_PHASE_PLAN.md` P1 item 3a (mid-session auth failure).

## Phase 10 - Snapshot Versioning and Migrations

Previous blocker closed: "Per-game restart-level fallback UX is not fully
end-to-end tested" / snapshot persistence was modeled (`MiGameSnapshot` v2,
checksum, restore predicate) but never wired into any game screen.

Completed this slice:
- Added `SnapshotStore` abstraction (`HiveSnapshotStore` real, `InMemorySnapshotStore`
  test-only) so games never touch Hive directly.
- Added `SnapshotLifecycleMixin` (save-on-background/dispose) for word_builder,
  sound_match, choice, robot_commands; equivalent async pattern for memory_cards.
- `GameScreen` loads any existing snapshot before first build, passes it down as
  `initialSnapshot`, and clears it once a level is completed.
- Fixed a teardown crash surfaced by the new wiring: `State.mounted` alone doesn't
  guard against ancestor lookups during whole-tree deactivation (mounted stays true
  until `unmount()`, after `dispose()` returns) -- the best-effort save now swallows
  that failure instead of crashing.

Still open: backend snapshot persistence endpoints (cloud backup of local
snapshots) remain absent -- local persistence only. Full corruption/migration test
matrix (concurrent save, interrupted write, migration failure) beyond what
`mi_game_core`'s existing v1->v2 tests cover is not attempted.

Tests: `flutter test test/game_screen_test.dart` PASS 3/3; full mobile suite
61/61 (only the 6 known/expected golden-image diffs remain, Linux-CI-rendered vs
local Windows rendering).

## Phase 11 - Adaptive Learning Integration

Previous blocker closed: "Persistent mastery state and daily-plan UI replacement
are not complete" -- confirmed via audit that adaptive output was write-only
telemetry (`AdaptiveLearningService`'s shadow-mode result was serialized into
game-result metadata and never read back anywhere).

Completed this slice:
- Added `apps/api/adaptive_ranking.py`: a shared ranking that uses each lesson's
  existing `Progress.status`/`mastery_score` for the child -- content marked
  `needs_practice` resurfaces first, mastered content is deprioritized, and
  new/continuing content targets a difficulty matching the child's demonstrated
  average mastery instead of always starting at difficulty 1.
- `GET /lessons/recommended` and `GET /progress/children/{id}/daily-plan` (the
  endpoint that actually drives `ChildHomeScreen`'s hero CTA and mission list)
  both now use this ranking.
- Found and fixed a real, previously-hidden bug while touching `parent.py`:
  `GET /parent/reports`'s "stars earned today" compared a UTC reward timestamp
  against day boundaries built from the server's *local* calendar date mislabeled
  as UTC -- in any timezone ahead of UTC (including Vietnam, this app's own
  locale) during evening/night hours, this silently undercounted to 0. Confirmed
  via `git stash` that this pre-existed on the branch before this slice.

Still open: the mobile `AdaptiveLearningService` shadow-mode output (mastery/
recommendation computed client-side per completion) is still never consumed --
the backend ranking above is driven by server-side `Progress` bookkeeping, not
by bridging the mobile shadow output into the backend signal. No mobile UI
surface exists yet for `/lessons/recommended` specifically (only the daily-plan
surface, which was already wired to the child home screen, benefits directly).

Tests: `tests/test_api_lessons_recommended.py` (new, 4/4 PASS) covering
no-history baseline, struggling-content-resurfaces, mastered-content-deprioritized,
and difficulty-targets-mastery. Full backend baseline 148/148 PASS.

## NEXT_PHASE_PLAN P1 item 3a - Mid-session auth failure

Previously: "If the parent's access + refresh tokens both expire while the app
is open, the specific screen's request just errors — nothing redirects to
/login." Confirmed by reading `apps/mobile/lib/services/api_service.dart`'s 401
interceptor: on unrecoverable refresh failure it only propagated the error,
never touching `AuthState` or navigation.

Completed this slice:
- `ApiService.onSessionExpired` fires only when a 401 truly means the session
  is over (refresh failed, or no refresh token existed for an already-authenticated
  session) -- never for requests that were never authenticated (e.g. offline-child
  gameplay).
- Wired in `providers.dart` to call `AuthNotifier.forceLogout()` (new -- resets
  state without the network call/sync flush a user-initiated `logout()` does,
  since the session is already dead server-side) and navigate to `/login` via
  the app's global router.
- While writing the test for this, found a second, more serious bug in the same
  code path: the token-refresh POST itself went through the *same* interceptor,
  so a refresh token rejected by the backend triggered another refresh attempt
  with the same known-bad token -- an unbounded recursive retry loop in
  production, not just a missed test case. Fixed by excluding the refresh call
  from the 401-triggers-refresh branch.
- Extracted token persistence behind a `TokenStore` interface
  (`SecureTokenStore`/`InMemoryTokenStore`), mirroring the `SnapshotStore`
  pattern, so `ApiService` is testable without a real platform channel.

Tests: `apps/mobile/test/api_service_session_expiry_test.dart` (new, 4/4 PASS).

## Current Baseline (this slice)

- Backend/game-core Python: 148/148 passing.
- Mobile Flutter: 61/61 passing (6 known/expected golden-image diffs excluded,
  documented as Linux-CI-rendered vs local-Windows-rendered, not a regression).
- Mobile analyze: 0 issues.
- CI (`fix/full-phase-1-to-19`, GitHub Actions): all 6 jobs green as of this
  slice's push.

## Remaining blockers (unchanged from prior report unless noted above)

Phases 2-3 (contract/cleanup follow-ups), 5-9 (partial gaps noted in the prior
report), 12-19 remain outside this slice's scope. See
`docs/final/NEXT_PHASE_PLAN.md` for the prioritized list of what's next.
