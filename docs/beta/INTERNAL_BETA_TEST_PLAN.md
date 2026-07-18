# Internal Beta Test Plan — v0.9.0-beta.1

## Objectives

Confirm the app survives realistic internal-beta conditions: real devices,
real (imperfect) networks, real installs/upgrades, and normal
parent/child usage patterns — without losing data, mixing children's
state, or becoming unusable.

## Scope

Mobile app (all 6 games) + backend, as they exist at the base commit of
PR #5. See `docs/final/PR5_INTERNAL_BETA_HARDENING_REPORT.md` for what
was code-level-hardened vs. what remains plan-only pending a device.

## Exclusions

New features, production deployment, real monitoring/alerting
infrastructure, penetration testing beyond the targeted security review
already done in PR #4.

## Environments

- **Local/dev**: this environment, used for all repository-controlled
  verification (`flutter test`, `pytest`, `docker build`+smoke test).
- **Real device**: not available in this environment — see
  `docs/beta/DEVICE_QA_MATRIX.md`.
- **Staging/production**: not provisioned — see
  `docs/infrastructure/ENVIRONMENT_STRATEGY.md`.

## Builds

See `docs/beta/INTERNAL_BETA_RUNBOOK.md`'s Build Procedure. Real evidence
this pass: `flutter build web --release` (succeeded, `build/web`, ~37MB),
`flutter build apk --release` (succeeded, `app-release.apk`, ~55MB,
unsigned), backend Docker image (built and smoke-tested: `/health/live`
and `/version` both return 200 against the real container).

## Device matrix

See `docs/beta/DEVICE_QA_MATRIX.md` — plan only, zero devices available.

## User roles

Parent (authenticated), Child (profile-scoped, no direct auth).

## Child-profile matrix

- Single child under one parent.
- Multiple children under one parent (switching between them).
- Zero children (first-run empty state).

## Network matrix

See `docs/beta/NETWORK_TEST_MATRIX.md`.

## Installation matrix

See `docs/beta/INSTALL_UPGRADE_MATRIX.md`.

## Lifecycle matrix

Backgrounding/killing/restoring during: login, token refresh, gameplay,
completion, sync, migration, child switch. Code-level review this pass
(see hardening report §14) found no gaps beyond what was already fixed
(startup crash recovery, refresh serialization) — device-level
confirmation still pending.

## Game matrix

All 6 games (Word Builder, Sound Match, Math Race, Math Supermarket,
Memory Cards, Robot Commands) — each already has automated widget-test
coverage for render/complete/retry/reduce-motion(Memory Cards only, the
one game with real animation)/accessibility-label(Word Builder) per prior
PR #4 work; device-level play-testing still pending.

## Accessibility matrix

Screen reader, text scaling, reduced motion (Memory Cards) — see
`docs/final/PR4_FINAL_PRODUCTION_AUDIT_2026-07-18.md` §8. Real
screen-reader (TalkBack/VoiceOver) verification requires a device — not
executed.

## Security matrix

See `docs/final/PR4_FINAL_PRODUCTION_AUDIT_2026-07-18.md` §6 — auth,
authz, child isolation, rate limiting, refresh-token revocation all
re-verified from source across two audit passes.

## Privacy matrix

See `docs/beta/INTERNAL_BETA_RUNBOOK.md`'s Data Collection/Privacy
sections.

## Migration matrix

6-migration linear Alembic chain, all additive/reversible, validated
against real Postgres via CI's `postgres-integration` job. Upgrade-path
testing with real pre-existing tester data is plan-only (no prior beta
build exists yet to upgrade from).

## Offline matrix

See `docs/beta/NETWORK_TEST_MATRIX.md` and the offline-attempt-lifecycle
scenarios in `docs/final/PR5_INTERNAL_BETA_HARDENING_REPORT.md` §12.

## Performance matrix

See hardening report §22 — code-level review only (N+1 queries, indexes,
connection pool from PR #4; no device-based profiling possible here).

## Evidence requirements

Every test case below must record: date, environment/device, tester,
actual result, and a link/reference to supporting evidence (test output,
screenshot, log). A case without evidence is not "done."

## Defect workflow

Found issue → classify severity (P0-P3) → if P0/P1, follow the runbook's
Stop Conditions → record in `docs/beta/KNOWN_ISSUES.md` → fix or
explicitly accept with owner+follow-up.

## Entry criteria

See hardening report §33.

## Exit criteria

See hardening report §34.

## Sample test case format

| ID | Priority | Precondition | Steps | Expected | Actual | Evidence | Status | Defect | Retest |
|---|---|---|---|---|---|---|---|---|---|
| TC-001 | P1 | Fresh install | Register → create child → play Word Builder → complete | Result saved, star awarded, dashboard reflects it | — | — | Not run (no device) | — | — |
| TC-002 | P0 | Two children under one parent | Child A completes a game, switch to Child B, check Child B's home screen | Child B sees only Child B's data | — | — | Not run (no device); server-side isolation re-verified at code level, see PR#4 audit §6 | — | — |
| TC-003 | P1 | Airplane mode on | Complete a game fully offline, reconnect | Result syncs exactly once, no duplicate reward | — | — | Not run (no device); `offline_sync` test suite covers this at the code level | — | — |

(Full case list to be populated once device access exists — this plan
defines the matrix, not a fabricated "completed" run.)
