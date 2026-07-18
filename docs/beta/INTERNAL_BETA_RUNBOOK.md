# Internal Beta Runbook — MI Academy v0.9.0-beta.1

## Purpose

Operate a small, controlled internal beta of MI Academy safely, with a
clear way to detect problems, respond to them, and stop/roll back if
needed. This is not a public-launch runbook.

## Scope

**Included:** the mobile app (all 6 games, auth, offline sync, progress,
rewards, snapshots, parent dashboard), the FastAPI backend as verified in
CI (Postgres+Redis production-config smoke test).

**Excluded:** production deployment operations (no production environment
exists), real monitoring/alerting infrastructure (none configured), any
new feature work.

## Entry Criteria

See `PULL_REQUEST_TEMPLATE`/PR #5 description and
`docs/final/PR5_INTERNAL_BETA_HARDENING_REPORT.md` §33 for the authoritative,
evidence-backed list. Summary: no open P0/P1, CI green, release build
succeeds locally (real evidence, not device-verified), golden differences
reviewed and explained (not silently regenerated).

## Build Procedure

```
# Mobile (web, for a quick smoke check without a device)
cd apps/mobile
flutter build web --release

# Mobile (Android APK, unsigned/debug-keystore in this environment --
# a real release keystore is required before actual distribution)
flutter build apk --release

# Backend (Docker image)
docker build -f infrastructure/docker/Dockerfile.api -t mi-academy-api:0.9.0-beta.1 .
```

## Distribution Procedure

**Not configured in this environment.** No Firebase App Distribution,
Play Internal Testing, or TestFlight access exists here. Whoever runs the
actual beta must:
1. Choose and configure a real channel.
2. Sign the Android build with a real release keystore (currently unsigned
   in this environment — CI's `android-release-signing` job is already
   gated on a configured secret and will no-op without one).
3. Follow that channel's own upload/distribution steps.

## Tester Onboarding

- Testers must be explicitly authorized (small, known group — this is not
  an open beta).
- Provide: what data is collected (see Data Collection below), how to give
  feedback, and the Known Issues doc (`docs/beta/KNOWN_ISSUES.md`).
- No account creation beyond the app's own parent-registration flow is
  required.

## Daily Checks (while beta is active)

- New crashes / unhandled errors (via `BetaDiagnostics` exports collected
  from testers, or direct developer device access — no automated remote
  collection exists yet, see Known Issues).
- Login failures reported by testers.
- Offline queue backlog growing unexpectedly (would indicate sync
  failures) — inspect a tester's exported diagnostics.
- Any cross-child report (**stop condition**, see below).
- Content failures (malformed level, missing asset).
- Reward duplication reports (**stop condition**).
- Progress corruption reports (**stop condition**).
- Accessibility issues reported as severe (blocks a core flow entirely).

## Incident Response

Severity follows this effort's P0-P3 definitions
(`docs/final/PR4_FINAL_PRODUCTION_AUDIT_2026-07-18.md` §6). P0/P1 during
beta → halt distribution immediately, follow Stop Conditions below.

## Stop Conditions

Halt distribution immediately if any of the following is confirmed:

- Cross-child or cross-family data exposure
- Authentication or authorization bypass
- Lost completed (already-synced-locally) attempts
- Duplicated rewards
- Corrupted progress
- Unrecoverable migration failure
- Repeated startup crash
- Broken release build
- Impossible rollback
- Unsafe content exposure to a child
- Sensitive data found in diagnostics/logs
- Server incompatibility with an already-distributed client build

## Rollback

See `docs/beta/ROLLBACK_PLAN.md`.

## Data Collection

- Standard app data: parent account (email, hashed password), child
  profile (nickname, age group, avatar — no last name, no birth date, no
  photo), game progress/attempts/rewards, offline sync queue.
- Beta-specific: `BetaDiagnostics` local export (see
  `apps/mobile/lib/services/beta_diagnostics.dart`) — app version, build
  number, redacted error summaries, screen/operation context. No child
  name, no raw token, no password, no raw exception/stack trace ever
  enters this record.
- No analytics/telemetry service is wired up — nothing is sent anywhere
  automatically.

## Privacy

Never collect: child's real name beyond a chosen nickname, birth date
(only age group), photos, location, contact info, raw exam/answer
content beyond what's already part of normal progress tracking, device
identifiers beyond what the OS/store already requires for installation.

## Support

Testers report issues via the channel documented in
`docs/beta/INTERNAL_BETA_RELEASE_NOTES_v0.9.0-beta.1.md`'s Feedback
Instructions section.

## Exit Criteria

See `docs/final/PR5_INTERNAL_BETA_HARDENING_REPORT.md` §34.
