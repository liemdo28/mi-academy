# MI Academy — Test Coverage Gap Analysis

> **Date:** 2026-07-17

---

## Current test coverage

| Package | Unit tests | Widget tests | Integration tests |
|---------|-----------|-------------|-------------------|
| mi_game_core | 22 ✅ | 0 ❌ | 0 ❌ |
| mi_game_ui | 0 ❌ | 20 ✅ | 0 ❌ |
| mi_game_content | 16 ✅ | 0 ❌ | 0 ❌ |
| mi_game_audio | 16 ✅ | 0 ❌ | 0 ❌ |
| mi_game_progress | 15 ✅ | 0 ❌ | 0 ❌ |
| mi_game_accessibility | 10 ✅ | 7 ✅ | 0 ❌ |
| mi_game_testing | N/A (test infra) | N/A | N/A |
| mi_blocks | 22 ✅ | 0 ❌ | 0 ❌ |
| offline_sync | 5 ✅ | 0 ❌ | 0 ❌ |
| Content validators | 20 ✅ | N/A | 0 ❌ |
| apps/mobile | 0 ❌ | 40 ✅ | 0 ❌ |

## Critical gaps

No remaining P0 package/tool unit-test gaps from this matrix. Remaining release
gaps are integration/golden coverage, device/runtime proof, and production
asset/sign-off gates tracked in `docs/RELEASE_READINESS_BASELINE.md`.
`mi_game_ui` now meets the shared UI widget and visual baseline target with 12
behavior/widget tests plus 8 golden tests. Game-slice golden and integration
coverage now includes one golden baseline per MVP game slice. Broader
Memory Cards, Word Builder, Sound Match, Math Race, and Math Supermarket
save/restore are covered with privacy-safe offline snapshot roundtrips.
`offline_sync` queue behavior is covered locally for Hive-backed
persistence, privacy-safe payloads, offline retention, FIFO flush, and retry
retention. Robot Commands save/restore, real backend/device sync, integration,
device/runtime, production asset, and sign-off gates remain separate
release-readiness gaps.

## Recommended test targets (pre-release 0.2)

| Package | Minimum unit tests | Priority |
|---------|-------------------|----------|
| mi_game_content | 15 (validator + loader) | ✅ Met with 16 tests |
| mi_blocks | 15 (interpreter + tree) | ✅ Met with 22 tests |
| mi_game_progress | 12 (mastery + tracker) | ✅ Met with 15 tests |
| mi_game_accessibility | 8 (helper + motion) | ✅ Met with 17 tests |
| mi_game_audio | 10 (manager + volume) | ✅ Met with 16 tests |
| offline_sync | 5 (queue + retry + privacy) | ✅ Met with 5 tests |
| mi_game_ui | 8 visual golden tests | ✅ Met with 8 golden tests and 12 behavior/widget tests |
| Content validators | 20 (Python validator rules) | ✅ Met with 20 tests |

**Total target: 110 tests across all packages**
