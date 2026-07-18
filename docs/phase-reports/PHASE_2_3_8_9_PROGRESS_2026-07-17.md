# Phase 2/3/8/9 Progress Report - 2026-07-17

Branch: `fix/full-phase-1-to-19`
PR: #4

## Phase 2 - Cleanup

PHASE PARTIAL

Completed:
- Performed a focused duplicate/dead-code follow-up sweep around removed `shared_models` residue and developer tooling.
- Removed stale `shared_models` path entries from remaining lockfiles.
- Updated `mi doctor` so it no longer expects the removed `packages/shared_models` package.
- Confirmed no `shared_models:` declarations remain in pubspecs/lockfiles/Melos.

Files changed:
- `apps/admin/pubspec.lock`
- `packages/progress_core/pubspec.lock`
- `tools/mi_cli/mi.py`

Tests added:
- None for lockfile cleanup.

Tests executed:
- `python tools\mi_cli\mi.py doctor` - PASS, 19 checks, 0 warnings, 0 failures.
- `rg "shared_models:" -n . -g pubspec.yaml -g pubspec.lock -g melos.yaml` - PASS, zero matches.
- `python -m pytest tests packages/game_core/tests -q` - PASS, 135/135.
- `flutter analyze` from `apps/mobile` - PASS, 0 issues.
- `flutter test` from `apps/mobile` - PASS, 63/63.
- `flutter test test/offline_sync_test.dart` from `packages/offline_sync` - PASS, 7/7.

Pass/fail counts:
- Doctor: 19 pass / 0 warn / 0 fail.
- Backend/game-core Python baseline: 135 passed / 0 failed.
- Mobile Flutter baseline: 63 passed / 0 failed; analyze 0 issues.
- Offline sync package: 7 passed / 0 failed.

Evidence:
- `mi doctor` now resolves Flutter/Dart/Node/Docker correctly on Windows.
- Stale generated/cache-only `packages/shared_models` directory is ignored unless package source files reappear.

Remaining blockers:
- Full repo-wide dead-route/dead-screen/orphan-test audit is not complete.
- Historical docs still contain references to removed packages as archived findings; they were not rewritten as part of this partial slice.

Next phase:
- Continue Phase 3 contract unification and broaden Phase 2 sweep if new duplicate clusters appear.

## Phase 3 - Contract Unification

PHASE PARTIAL

Completed:
- Fixed the shared contract registry so registered classes receive `__contract_id__` and `validate_contract_data()` can resolve them.
- Added backend contract tests for registry resolution, required fields, forbidden secret/parent fields, and unknown additive fields.
- Wired documented CLI targets `mi test contracts` and `mi test integration`.
- Made CLI output ASCII-safe for Windows shells.

Files changed:
- `contracts/shared_contracts.py`
- `tests/test_contract_registry.py`
- `tools/mi_cli/mi.py`

Tests added:
- `tests/test_contract_registry.py`

Tests executed:
- `python -m pytest tests/test_contract_registry.py tests/test_api_game_result.py -q` - PASS, 8/8.
- `python tools\mi_cli\mi.py test contracts` - PASS, 11 contracts loaded.
- `python tools\mi_cli\mi.py validate` - PASS, schemas and fixtures valid.
- `python -m pytest tests packages/game_core/tests -q` - PASS, 135/135.

Pass/fail counts:
- Pytest focused contract/API: 8 passed / 0 failed.
- CLI contract registry: 11 contracts loaded.
- Backend/game-core Python baseline: 135 passed / 0 failed.

Evidence:
- `mi.game.result` validates successfully with required fields.
- Missing `attemptId` is rejected.
- Forbidden `accessToken` and `parentEmail` fields are rejected.
- Unknown additive fields are accepted as backward-compatible v1 behavior.

Remaining blockers:
- Full OpenAPI-to-Dart generated contract pipeline is not complete.
- No compatibility matrix update beyond existing registry metadata and docs.
- Parent/child/auth/lesson/skill/reward/sync/analytics/content/asset/API-error contracts still need full field-by-field unification.

Next phase:
- Continue expanding authoritative API/Pydantic contracts and shared fixtures without adding a third handwritten model layer.

## Phase 8 - Progress, Rewards and Parent Dashboard Idempotency

PHASE PARTIAL

Completed:
- Added backend guard for out-of-order game results: older completions are persisted as attempts but do not rewrite mastery, progress counters, or rewards.
- Added regression test proving duplicate `attempt_id` remains idempotent and out-of-order attempts do not roll mastery backward.

Files changed:
- `apps/api/routes/games.py`
- `tests/test_api_game_result.py`

Tests added:
- `test_save_game_result_does_not_rewrite_mastery_for_out_of_order_attempt`

Tests executed:
- `python -m pytest tests/test_contract_registry.py tests/test_api_game_result.py -q` - PASS, 8/8.
- `python -m pytest tests packages/game_core/tests -q` - PASS, 135/135.

Pass/fail counts:
- Focused backend API/contract: 8 passed / 0 failed.
- Backend/game-core Python baseline: 135 passed / 0 failed.

Evidence:
- Duplicate `attempt_id` returns `idempotent_replay=True` and keeps one attempt/progress increment.
- Out-of-order older attempt returns `out_of_order=True`, saves the audit attempt, and leaves mastery/total attempts unchanged.

Remaining blockers:
- Parent Dashboard stale/offline/error UI states not reverified in this slice.
- Reward/star duplication needs broader endpoint and dashboard coverage.
- Full child-profile isolation path through mobile local stores and dashboard queries still needs end-to-end validation.

Next phase:
- Extend backend and Flutter tests for rewards, parent dashboard reads, partial failure recovery, and child switching.

## Phase 9 - Offline Sync Hardening

PHASE PARTIAL

Completed:
- Added deterministic queue tests for duplicate queue IDs and process-restart persistence.
- Reverified offline retention, FIFO online processing, failed-item retry, and privacy-safe payload tests still pass.

Files changed:
- `packages/offline_sync/test/offline_sync_test.dart`

Tests added:
- `enqueue with duplicate id replaces the queued payload once`
- `queued items survive Hive close and reopen process restart`

Tests executed:
- `flutter test test/offline_sync_test.dart` from `packages/offline_sync` - PASS, 7/7.
- `flutter analyze` from `apps/mobile` - PASS, 0 issues.
- `flutter test` from `apps/mobile` - PASS, 63/63.

Pass/fail counts:
- Offline sync package: 7 passed / 0 failed.
- Mobile Flutter baseline: 63 passed / 0 failed; analyze 0 issues.

Evidence:
- Duplicate queue ID stores one queue item with the newest payload.
- Pending queue item survives Hive close/reopen.
- Failed items remain in local storage and retry state.

Remaining blockers:
- Airplane mode/reconnect integration tests are not complete.
- 401/token refresh, 500, timeout, connection-loss, partial batch success, malformed queue-entry quarantine, and oldest-pending UI visibility still need coverage.

Next phase:
- Continue Phase 9 hardening, then proceed to Phase 10 snapshot versioning/migrations.
