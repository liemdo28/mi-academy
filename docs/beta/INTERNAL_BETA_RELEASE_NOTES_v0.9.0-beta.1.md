# MI Academy — Internal Beta v0.9.0-beta.1 Release Notes

**Release scope:** Internal, controlled technical beta for a small,
explicitly authorized group of testers. **Not a public release.**

## What's in this build

- Full golden flow: parent registration/login → child creation/selection
  → all 6 games → progress/rewards → parent dashboard, working offline
  with a durable sync queue.
- Snapshot save/resume across all 6 games.
- Server-side adaptive lesson ranking (mastery-based, not client-trusted).
- Security hardening: revocable/rotated refresh tokens, server-side PIN
  brute-force lockout, rate-limiter spoofing fix.
- This pass's reliability hardening: serialized token refresh (prevents a
  false-logout race under concurrent requests), corrupted-local-storage
  recovery at startup, privacy-safe local diagnostics capture.

## Test results (at commit `c9f9bef0398eefb278c9c205a9321275e94cfac2`)

- Backend: 159/159 passing.
- Mobile: 78/84 passing (6 known golden-image diffs — pass on CI, fail
  locally on Windows only, font-rendering difference, not a regression).
- `flutter analyze`: 0 issues.
- CI: 7/7 jobs green, including a Postgres+Redis production-config smoke
  test.

## Known limitations

See `docs/beta/KNOWN_ISSUES.md` for the full list. Headline items:

- **No physical-device testing has occurred.** Everything above is
  verified via automated tests and manual code review, not a real phone
  or tablet. See `docs/beta/DEVICE_QA_MATRIX.md`.
- **No production database, deployment, monitoring, or backup
  infrastructure exists.** This beta is not backed by production
  operations.
- Android build in this environment is unsigned (debug keystore) — a real
  release keystore is required before actual distribution.

## Rollback guidance

See `docs/beta/ROLLBACK_PLAN.md`. Summary: revert path exists for both
client distribution (re-promote the previous build on whichever channel
is configured) and backend (all migrations have working `downgrade()`,
confirmed reversible, not yet rehearsed against a real database).

## Feedback instructions

Not yet configured with a real channel in this environment. Before
distributing this build, the beta coordinator must set up one of: an
in-app feedback form, a support email, or an issue template — see
`docs/beta/INTERNAL_BETA_RUNBOOK.md`'s Support section.

## Critical stop conditions

If a tester reports any of the following, halt distribution immediately:
cross-child/cross-family data exposure, auth/authz bypass, lost offline
attempts, duplicate rewards, corrupted progress, unrecoverable migration
failure, repeated startup crashes, inability to roll back. Full list:
`docs/beta/INTERNAL_BETA_RUNBOOK.md`.
