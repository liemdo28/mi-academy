# Network Test Matrix — Internal Beta v0.9.0-beta.1

**Status: repository-controlled logic re-verified this pass (see evidence
column); real-device network-condition testing (physically toggling
airplane mode, throttling on a real carrier connection, etc.) not executed
— no device available.**

## Conditions

| Condition | Repository-level evidence | Real-device evidence |
|---|---|---|
| Normal Wi-Fi | Implicit in every passing integration test | ❌ Not executed |
| High latency | Not simulated in this pass | ❌ Not executed |
| Low bandwidth | Not simulated in this pass | ❌ Not executed |
| Intermittent connectivity | `offline_sync` backoff/retry tests cover reconnect-after-failure at the queue level | ❌ Not executed on a real flaky connection |
| Complete offline | `packages/offline_sync/test/offline_sync_test.dart` + `game_screen_test.dart`'s offline-child path | ❌ Not executed (real airplane mode) |
| Request timeout | `ApiService`'s Dio `connectTimeout`/`receiveTimeout` (10s each) — code-level, not device-timed | ❌ Not executed |
| DNS failure | Not simulated | ❌ Not executed |
| Server 500 | `offline_sync_test.dart`: "timeout and 500 failures remain retryable" | ❌ Not executed |
| Server 502/503 | Not distinguished from 500 in current retry logic (treated as generic failure → retryable) | ❌ Not executed |
| Dropped response | Not simulated | ❌ Not executed |
| Duplicated response | Backend idempotency (`client_attempt_id` unique constraint) covers this at the API level regardless of transport-level duplication | ❌ Not executed |
| Delayed response | Covered by connectTimeout/receiveTimeout at the code level | ❌ Not executed |
| Out-of-order response | Backend's `_compare_datetimes` out-of-order guard (`apps/api/routes/games.py`) protects mastery correctness even if client-side ordering isn't guaranteed (re-verified this pass) | ❌ Not executed |
| Connection restored after several minutes | `offline_sync`'s exponential backoff (capped 300s) + quarantine-after-5-retries logic | ❌ Not executed |

## Critical flows to verify under each condition (once device testing is possible)

Startup, login, token refresh (concurrency-serialized as of this pass —
see the hardening report), child selection, content load, game launch,
attempt completion, progress update, reward update, snapshot fetch,
offline queue replay, logout.

## UI invariants (re-verified at the code level this pass)

- No infinite retry loop: `SyncQueueItem.markFailed()` quarantines after
  `maxRetries = 5`.
- No repeated duplicate submission: `client_attempt_id` idempotency
  (server-side unique constraint + pre-check + `IntegrityError` catch).
- No premature success before durable local persistence: `GameScreen`
  enqueues to the local Hive-backed queue *before* attempting the network
  call — the local write is durable regardless of network outcome.
- No stale-child cached result shown: re-verified this pass —
  `ApiSyncProcessor`/`sync_service.dart` always use the queue item's own
  stored `childProfileId`, never the currently-active child.

## Consequence for beta classification

Repository-level logic is sound and tested; real-network-condition
verification on physical devices/networks remains an external validation
requirement, consistent with the overall "GO WITH CAVEATS — LIMITED
TECHNICAL BETA" classification.
