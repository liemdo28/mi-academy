# Phase 2-11 Progress Report - 2026-07-17

Branch: `fix/full-phase-1-to-19`
PR: #4

## Phase 2 - Cleanup

PHASE PARTIAL

Completed:
- Removed stale `shared_models` lockfile/tooling residue in the previous slice.
- Removed dead, unexported, broken `packages/mastery_core/lib/src/offline_fallback.dart` after `rg` showed zero references outside itself.
- Removed unsupported `uses_flutter_rust_bridge` pubspec keys from adaptive packages now wired into mobile.
- Fixed recommendation-core null-safety issues surfaced by actual package analysis.
- Removed unsupported pubspec keys from `adaptive_testing`, `learning_analytics`, `spaced_repetition`, and `ai_safety`.
- Fixed analysis blockers in `learning_analytics`, `spaced_repetition`, and `ai_safety`.

Files changed:
- `packages/mastery_core/lib/src/offline_fallback.dart`
- `packages/mastery_core/pubspec.yaml`
- `packages/recommendation_core/pubspec.yaml`
- `packages/recommendation_core/lib/src/recommendation_types.dart`
- `packages/recommendation_core/lib/src/session_planner.dart`
- `packages/recommendation_core/lib/src/recommendation_engine.dart`
- `packages/adaptive_testing/pubspec.yaml`
- `packages/learning_analytics/pubspec.yaml`
- `packages/learning_analytics/lib/src/parent_insight.dart`
- `packages/learning_analytics/lib/src/parent_insight_generator.dart`
- `packages/spaced_repetition/pubspec.yaml`
- `packages/spaced_repetition/lib/src/spaced_repetition_record.dart`
- `packages/spaced_repetition/lib/src/spaced_repetition_scheduler.dart`
- `packages/ai_safety/pubspec.yaml`
- `packages/ai_safety/lib/src/audit_logger.dart`

Tests added:
- `packages/recommendation_core/test/recommendation_core_test.dart`

Tests executed:
- `rg "offline_fallback|OfflineFallbackEngine" -n packages\mastery_core packages\recommendation_core apps\mobile` - only the deleted file referenced itself.
- `flutter analyze` from `packages/mastery_core` - PASS, 0 issues.
- `flutter test` from `packages/mastery_core` - PASS, 14/14.
- `flutter analyze` from `packages/recommendation_core` - PASS, 0 issues.
- `flutter test` from `packages/recommendation_core` - PASS, 2/2.
- `flutter analyze` from `packages/adaptive_testing` - PASS, 0 issues.
- `flutter analyze` from `packages/learning_analytics` - PASS, 0 issues.
- `flutter analyze` from `packages/spaced_repetition` - PASS, 0 issues.
- `flutter analyze` from `packages/ai_safety` - PASS, 0 issues.

Pass/fail counts:
- Mastery core: 14 passed / 0 failed; analyze 0 issues.
- Recommendation core: 2 passed / 0 failed; analyze 0 issues.
- Adaptive testing, learning analytics, spaced repetition, AI safety: analyze 0 issues.

Evidence:
- Dead broken fallback file was not exported and had no external references.
- Both adaptive packages now analyze cleanly when used by the mobile app.

Remaining blockers:
- A full historical documentation cleanup is still not complete.
- Full dead route/screen audit remains incomplete beyond code touched and referenced sweeps.

Next phase:
- Continue content/admin/route sweep while progressing Phase 12.

## Phase 3 - Contract Unification

PHASE PARTIAL

Completed:
- Added `contracts/contract_manifest.json` covering all required Phase 3 contract families.
- Expanded contract registry from 11 to 23 entries.
- Replaced hardcoded validation class lookup with a registry-class index.
- Updated OpenAPI snapshot schema to v2 with `game_version` and `checksum`.
- Updated `game_snapshot.json` fixture to v2.
- Added tests for manifest coverage, declared fixtures, OpenAPI snapshot drift, forbidden fields, required fields, and unknown-field compatibility.

Files changed:
- `contracts/contract_manifest.json`
- `contracts/shared_contracts.py`
- `contracts/openapi.yaml`
- `integration/fixtures/game_snapshot.json`
- `tests/test_contract_registry.py`

Tests added:
- Contract manifest coverage tests.
- OpenAPI snapshot v2 drift test.

Tests executed:
- `python -m pytest tests/test_contract_registry.py -q` - PASS.
- `python tools\mi_cli\mi.py test contracts` - PASS, 23 contracts loaded.
- `python tools\mi_cli\mi.py validate` - PASS.

Pass/fail counts:
- Contract registry: 23 loaded / 0 failures.
- Focused contract tests included in Python baseline: 139/139 total Python tests passing.

Evidence:
- Required families covered: parent, child, auth/session, lesson, skill, game launch/result/snapshot, progress, reward, sync event, analytics event, mastery evidence, recommendation, content manifest, asset manifest, API errors.

Remaining blockers:
- Full generated OpenAPI-to-Dart model generation is not complete; Dart contracts are centrally maintained and fixture-tested, not generated.

Next phase:
- Continue reducing handwritten mirrors where feasible without introducing a third model layer.

## Phase 8 - Progress, Rewards and Dashboard Idempotency

PHASE PARTIAL

Completed:
- Added unique `(child_id, reward_id)` ORM constraint and Alembic migration.
- Made reward unlock route idempotent under retries/concurrent duplicate requests.
- Fixed first-star badge logic for game-result saves so the first result awards once and later distinct attempts do not double-award.
- Parent report now counts real persisted child reward unlocks instead of using completed lessons as fake star data.

Files changed:
- `apps/api/models/__init__.py`
- `apps/api/alembic/versions/9b7d3f1a6c21_add_child_reward_uniqueness.py`
- `apps/api/routes/games.py`
- `apps/api/routes/rewards.py`
- `apps/api/routes/parent.py`
- `tests/test_api_game_result.py`
- `tests/test_api_parent_data.py`

Tests added:
- First badge awarded once across distinct attempts.
- Parent dashboard reward count based on persisted rewards.

Tests executed:
- `python -m pytest tests/test_api_game_result.py tests/test_api_parent_data.py tests/test_api_child_ownership.py -q` - PASS, 14/14.
- Full Python baseline - PASS, 139/139.

Pass/fail counts:
- Focused backend Phase 8 tests: 14 passed / 0 failed.
- Python baseline: 139 passed / 0 failed.

Evidence:
- Duplicate attempt ID remains idempotent.
- Distinct repeated attempts do not duplicate first-star reward.
- Out-of-order older attempt records audit attempt but does not rewrite mastery/progress/rewards.
- Dashboard total stars are backed by persisted `ChildReward` rows.

Remaining blockers:
- Full Parent Dashboard UI stale/offline/error state verification remains incomplete.

Next phase:
- Continue dashboard UI state tests as part of Phase 14/19 flow validation.

## Phase 9 - Offline Sync Hardening

PHASE PARTIAL

Completed:
- Added queue quarantine state for permanent/malformed failures.
- Added permanent failure classifier support.
- Added malformed game-result validation.
- Added oldest pending visibility.
- Added child-switching and logout queue clearing.
- Retained retry behavior for timeout and 500 failures.
- Added partial-success test evidence.

Files changed:
- `packages/offline_sync/lib/src/sync_queue.dart`
- `packages/offline_sync/lib/src/sync_service.dart`
- `packages/offline_sync/test/offline_sync_test.dart`

Tests added:
- Timeout and 500 remain retryable.
- 401 and malformed game result quarantine.
- Partial success completes accepted item and retains failed item.
- Oldest pending ignores completed/quarantined items.
- Child switching and logout clear scoped queue entries.

Tests executed:
- `flutter test test/offline_sync_test.dart` from `packages/offline_sync` - PASS, 12/12.

Pass/fail counts:
- Offline sync package: 12 passed / 0 failed.

Evidence:
- Queue items are never deleted before successful processing except explicit child/logout clearing.
- Permanent bad records are quarantined, not retried forever.
- Transient failures remain retryable.

Remaining blockers:
- End-to-end 401 refresh with real `ApiService`, OS airplane mode, and network cable-loss tests are still not device/integration verified.

Next phase:
- Carry offline/reconnect scenarios into Phase 19 final validation.

## Phase 10 - Snapshot Versioning and Migrations

PHASE PARTIAL

Completed:
- `MiGameSnapshot` now writes schema v2 with `gameVersion` and deterministic checksum.
- Legacy v1 snapshots still read with default `gameVersion`.
- Added restore predicate that rejects wrong child, wrong game/level, corrupt checksum, and unsupported future schema versions.
- OpenAPI, registry, manifest, and fixture updated to snapshot v2.

Files changed:
- `packages/mi_game_core/lib/src/models/mi_game_snapshot.dart`
- `packages/mi_game_core/test/contracts_test.dart`
- `contracts/openapi.yaml`
- `contracts/shared_contracts.py`
- `contracts/contract_manifest.json`
- `integration/fixtures/game_snapshot.json`

Tests added:
- Legacy v1 snapshot migration.
- Corrupt checksum rejection.
- Wrong-child rejection.
- Future schema rejection.

Tests executed:
- `flutter test` from `packages/mi_game_core` - PASS, 46/46.
- Mobile tests - PASS, 64/64.

Pass/fail counts:
- `mi_game_core`: 46 passed / 0 failed.
- Mobile: 64 passed / 0 failed.

Evidence:
- All existing six-game save/restore tests still pass under snapshot v2.

Remaining blockers:
- Backend snapshot persistence endpoints are still absent.
- Per-game restart-level fallback UX is not fully end-to-end tested.

Next phase:
- Continue server/local snapshot persistence and Phase 19 restore scenarios.

## Phase 11 - Adaptive Learning Integration

PHASE PARTIAL

Completed:
- Added mobile `AdaptiveLearningService` that maps `MiCompletionResult` to `AttemptEvidence`, `MasteryEngine`, `MasteryState`, and `RecommendationEngine` in shadow mode.
- Wired game completion metadata to include adaptive shadow output.
- Adaptive exceptions fall back to a non-blocking shadow metadata entry.
- Added direct mobile test proving mastery and recommendation engines run from a game completion result.
- Fixed/adapted `mastery_core` and `recommendation_core` so both analyze and test cleanly.

Files changed:
- `apps/mobile/lib/services/adaptive_learning_service.dart`
- `apps/mobile/lib/screens/game_screen.dart`
- `apps/mobile/pubspec.yaml`
- `apps/mobile/pubspec.lock`
- `apps/mobile/test/adaptive_learning_service_test.dart`
- `packages/mastery_core/*`
- `packages/recommendation_core/*`

Tests added:
- `apps/mobile/test/adaptive_learning_service_test.dart`
- `packages/recommendation_core/test/recommendation_core_test.dart`

Tests executed:
- `flutter test` from `apps/mobile` - PASS, 64/64.
- `flutter analyze` from `apps/mobile` - PASS, 0 issues.
- `flutter test` from `packages/mastery_core` - PASS, 14/14.
- `flutter analyze` from `packages/mastery_core` - PASS, 0 issues.
- `flutter test` from `packages/recommendation_core` - PASS, 2/2.
- `flutter analyze` from `packages/recommendation_core` - PASS, 0 issues.

Pass/fail counts:
- Mobile: 64 passed / 0 failed; analyze 0 issues.
- Mastery core: 14 passed / 0 failed; analyze 0 issues.
- Recommendation core: 2 passed / 0 failed; analyze 0 issues.
- Adaptive testing, learning analytics, spaced repetition, AI safety: analyze 0 issues; no package-level test directories present.

Evidence:
- Adaptive logic runs locally/offline in shadow mode and cannot block gameplay/result saving.
- Reason codes and engine versions are included.
- No generated AI content is shown to children.

Remaining blockers:
- Persistent mastery state and daily-plan UI replacement are not complete.
- Spaced repetition and learning analytics are not fully wired into the actual daily plan.
- Bias/fairness monitoring remains documented but not fully enforced in code.

Next phase:
- Continue Phase 11 persistence/daily-plan integration and then Phase 12 validators.

## Current Baseline

- Backend/game-core Python: 139/139 passing.
- Mobile Flutter: 64/64 passing.
- Mobile analyze: 0 issues.
- mi_game_core: 46/46 passing.
- offline_sync: 12/12 passing.
- mastery_core: 14/14 passing.
- recommendation_core: 2/2 passing.
- CLI doctor: 19 pass / 0 warn / 0 fail.
- Contract registry: 23 contracts loaded.
