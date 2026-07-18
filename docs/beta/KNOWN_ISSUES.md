# Known Issues — Internal Beta v0.9.0-beta.1

Living document. Update as new issues are found/resolved during the beta.

## Fixed this hardening pass (PR #5)

- Concurrent token-refresh requests could force an unnecessary full logout
  even with a valid session (race between simultaneous 401s). Fixed by
  serializing refresh behind one in-flight `Future`.
- A corrupted local Hive box file could permanently block app startup with
  no recovery path. Fixed with per-box corruption recovery
  (`openBoxWithCorruptionRecovery`) plus a last-resort fatal-startup
  fallback screen.

## Known, accepted, not blocking beta

- **Golden-image tests fail locally on Windows, pass on Linux CI.**
  Font-rendering difference between environments, not a UI regression —
  confirmed via CI job logs at every relevant commit. See
  `docs/final/PR4_FINAL_PRODUCTION_AUDIT_2026-07-18.md` §11.
- **No real i18n infrastructure** — Vietnamese UI text is hardcoded, not
  ARB/`Intl.message`-based. Not applicable until a second UI language is
  planned.
- **Mobile shadow-mode adaptive-learning output is not consumed** by the
  backend's real recommendation ranking — a deliberate trust-boundary
  decision (client-reported data shouldn't silently drive what content a
  child sees next without a validation design), not an oversight. See
  `docs/final/NEXT_PHASE_PLAN.md` item 4.
- **`apps/admin` is a UI-only scaffold** with zero backend HTTP calls wired
  up — the backend admin endpoints exist and are role-gated, but nothing
  in the admin app calls them yet.
- **6 orphaned-but-substantial adaptive-learning Dart packages**
  (`adaptive_core`, `adaptive_testing`, `api_client`, `content_intelligence`,
  `model_evaluation`, `ai_safety`) exist with no referencing `pubspec.yaml`
  — plausibly deliberate future-phase infrastructure, pending a keep/retire
  product decision.

## Explicitly not yet verified (external, device/infra-dependent)

- Real-device behavior for any of the 6 games, any network condition, any
  install/upgrade scenario. See `DEVICE_QA_MATRIX.md`, `NETWORK_TEST_MATRIX.md`,
  `INSTALL_UPGRADE_MATRIX.md` — all plan-only, zero rows executed.
- Production deployment, backup/restore, monitoring/alerting — no
  production environment exists.

## Reporting a new issue during beta

See `docs/beta/INTERNAL_BETA_RUNBOOK.md`'s Support section.
