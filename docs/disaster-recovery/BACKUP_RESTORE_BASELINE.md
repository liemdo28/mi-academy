# Backup & Restore Baseline — MI Academy

**Author:** Dev 6 (DevOps, Security & Reliability Lead)
**Date:** 2026-07-17
**Status:** Baseline snapshot. No backup/restore tooling has been implemented yet.

## 1. Current state

There is **no production database, no deployed environment, and therefore no backup or restore mechanism of any kind today.** The only persistence in the current codebase is:
- Local SQLite (dev default, ephemeral, gitignored).
- A local Postgres container defined in `infrastructure/docker/docker-compose.yml` (dev-only, no volume backup strategy configured beyond whatever default Docker volume persistence exists).

This document exists to record that baseline so that "we have no backup strategy yet" is an explicit, tracked fact rather than a silent gap — and to define what must exist before any real user data (parent accounts, child progress) is stored in a production database.

## 2. What must exist before production data collection begins

Per target architecture §17–18, before any production database goes live:
- Daily full backup, encrypted, stored separately from the primary database credential/location.
- Point-in-time recovery if the eventual hosting platform supports it (needs a hosting decision first — not yet made).
- A tested restore procedure (restore ≠ backup until it has been proven to restore).
- Backup integrity checks.
- Retention policy aligned with the data-retention rules already defined in `docs/security.md` / child-safety docs (owned jointly with Dev 1 and Dev 5, per target architecture §44).

## 3. What is explicitly out of scope right now

- No content-package backup strategy is needed yet — no content delivery/CDN pipeline exists (see [DEPLOYMENT_PIPELINE_AUDIT.md](../deployment/DEPLOYMENT_PIPELINE_AUDIT.md)).
- No model-registry backup — no model service is deployed yet (Dev 5's adaptive learning work is pre-infrastructure).
- No infrastructure-state backup — no Terraform/IaC state exists yet since no IaC is in use.

## 4. Offline-first mitigation (already partially in place)

Because the mobile app is offline-first (local Hive storage, pending-sync queue, no embedded backend URL by default — see [RELIABILITY_GAP_ANALYSIS.md](../reliability/RELIABILITY_GAP_ANALYSIS.md) §2), a backend data-loss event would **not** destroy a child's local progress immediately — only server-side aggregated/synced data would be at risk, and only for data not yet re-synced from surviving devices. This materially lowers the blast radius of a backend disaster relative to a typical online-only app, but it is not a substitute for real backups once parent accounts and cross-device sync become load-bearing.

## 5. Immediate recommendation

Do not provision a production database until:
1. A hosting/database platform decision is made (needs product/Dev 1 input — out of scope for this document to decide unilaterally).
2. The migration strategy gap identified in [INFRASTRUCTURE_AUDIT.md](../infrastructure/INFRASTRUCTURE_AUDIT.md) §5 (Alembic vs. raw SQL) is resolved, since backup/restore drills are meaningless against a schema with no reliable version history.
3. A restore-test runbook (per target architecture §18) is written and rehearsed at least once against a non-production copy, before the first production backup is considered "valid."

No backup or restore tooling has been created as part of this baseline. This is a gap-tracking document, not an implementation.
