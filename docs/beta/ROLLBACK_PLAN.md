# Internal Beta Rollback Plan

**Status:** Documented, **not rehearsed** — no production/staging deployment
exists in this environment to rehearse against. This is a plan, not a
verified drill.

## Trigger

Any stop condition in `docs/beta/INTERNAL_BETA_RUNBOOK.md` §Stop Conditions,
or a tester-reported issue matching a P0/P1 severity pattern.

## Rollback layers

### 1. Client (mobile app)

Internal beta distribution (whichever channel is actually configured — see
`docs/beta/INTERNAL_BETA_RELEASE_NOTES_v0.9.0-beta.1.md`'s Distribution
section) must support reverting testers to the last known-good build:

- If using Firebase App Distribution / TestFlight / Play Internal Testing:
  stop distributing the new build, re-promote the previous build's release
  to the active testing group. This is a channel-configuration action, not
  a code change — **verify the specific channel supports this before
  distributing v0.9.0-beta.1** (external validation requirement, not yet
  confirmed since no channel is configured in this environment).
- The app has no auto-update-forcing mechanism today, so testers on an
  older build are not automatically broken by a server-side rollback,
  *unless* the server-side API contract changed in a backward-incompatible
  way (see §3).

### 2. Backend code

Revert path: `git revert` the merge commit that introduced the
problematic change on whichever branch is deployed, or redeploy the
previous commit's build artifact. No live deployment exists to test this
against in this environment.

### 3. Database migrations

All migrations added through this effort (`5f2a8c14e9b7`, `7c1d3e9a2f45`,
`9b7d3f1a6c21`, `a3e6f0b8c1d2`, plus any added in this PR) have a working
`downgrade()`:

```
cd apps/api && python -m alembic downgrade -1   # step back one revision
```

repeated as needed, or `python -m alembic downgrade <revision>` to a known
point. None of the existing migrations DROP a table/column that held
pre-existing user data without also being additive-only in the forward
direction — confirmed in `docs/final/PR4_FINAL_PRODUCTION_AUDIT_2026-07-18.md`
§5/§12. **Not yet run against a real database with real data** — this is a
repository-level guarantee (the SQL is reversible), not a rehearsed
operational drill.

### 4. Offline client data

Because the app is offline-first, a backend-side rollback does **not**
destroy a tester's local progress/queued attempts — only server-side
aggregated data for the rolled-back window is affected. This is a
structural mitigation already documented in
`docs/disaster-recovery/BACKUP_RESTORE_BASELINE.md` §4, re-confirmed
applicable here.

## What rollback does NOT cover

- A schema change that's `downgrade()`-reversible in SQL doesn't
  automatically mean an already-synced client won't misbehave against an
  older API version if the API's request/response contract changed
  incompatibly. Contract compatibility across a rollback has not been
  explicitly tested in this pass — flagged as a gap for PR #5's exit
  criteria, not silently assumed safe.

## Explicit stop-and-rollback authority

Per the runbook: the beta coordinator (a named human role, not this
document) has authority to halt distribution and initiate rollback. This
plan does not itself trigger anything automatically.
