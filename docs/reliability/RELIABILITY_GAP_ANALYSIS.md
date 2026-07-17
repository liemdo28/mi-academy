# Reliability Gap Analysis — MI Academy

**Author:** Dev 6 (DevOps, Security & Reliability Lead)
**Date:** 2026-07-17
**Status:** Baseline snapshot. No infrastructure changes applied yet.

## 1. Guiding constraint

Per project principle, **child-mode offline learning must never depend on backend availability.** This audit specifically checks whether that constraint is currently upheld by the mobile architecture, and separately assesses backend reliability on its own terms.

## 2. Offline-first posture (mobile)

- `apps/mobile` already depends on `hive`/`hive_flutter` for local storage, `connectivity_plus` for network-state awareness, and a dedicated `offline_sync` local package plus a new (uncommitted) `apps/mobile/lib/services/api_sync_processor.dart`. This indicates the offline-first architecture is actively being built out, which is the right direction.
- `docs/RELEASE_READINESS_BASELINE.md` confirms the mobile app does **not** embed a backend URL by default and requires explicit build-time configuration — good, this prevents accidental hard-dependency on a specific backend instance.
- Not yet verified in this pass (requires Dev 1 coordination, out of infra scope): whether pending-sync queue survives app kill, whether snapshot/progress writes are atomic, whether sync failures surface a child-friendly (not technical) message. Flagging as an open verification item rather than asserting a gap.

## 3. Backend reliability primitives

| Primitive | Status |
|---|---|
| Liveness endpoint (`/health/live`) | ❌ not present — only an unversioned `/api/v1/health` exists, semantics undefined (doesn't distinguish liveness vs readiness) |
| Readiness endpoint (`/health/ready`) | ❌ not present |
| Version endpoint (`/version`) | ❌ not present — `/api/v1/health` hardcodes `"version": "1.0.0"` in source, not derived from build metadata |
| Graceful shutdown / connection draining | ❌ not configured (no deployment target exists to configure it against yet) |
| Migration control separate from app boot | ❌ app auto-creates tables on startup via `CREATE_TABLES_ON_STARTUP`; no separate migration-runner step |
| Structured error responses | ⚠️ unverified in this pass |

## 4. Single points of failure

1. **In-memory rate limiter** (`apps/api/middleware/rate_limit.py`) — state is per-process. Any horizontal scaling or process restart resets/duplicates limits. Redis is already provisioned in docker-compose but not used for this. This is the most concrete near-term reliability risk once more than one API instance exists.
2. **No migration versioning** — the single raw SQL file in `infrastructure/migrations/001_initial.sql` is disconnected from the SQLAlchemy models and from `CREATE_TABLES_ON_STARTUP`. A schema change today has no reproducible, auditable path to production.
3. **No observability** — without logging/metrics, a production incident would be diagnosed blind. This is a reliability gap as much as a security one (see [SECURITY_BASELINE.md](../security/SECURITY_BASELINE.md) §4).
4. **`asyncpg` missing from requirements.txt** while the app's Postgres URL scheme requires it — this is a latent reliability bug: the app would fail at the point Postgres is actually used, not at code-review time.

## 5. Testing coverage relevant to reliability

Existing test suite (`tests/`, `packages/game_core/tests`) covers content validation, child safety, sync API behavior, and mobile privacy audit — good breadth on correctness/compliance. **No fault-injection or resilience tests exist**: no test simulates DB unavailability, network interruption, partial/corrupted content download, duplicate sync, or out-of-order events. This matches the target architecture's §49 (Reliability testing) and is a Wave 2+ item, not a Wave 0 blocker.

## 6. SLO readiness

No SLOs can be meaningfully defined yet because there is no deployed environment to measure against. Recommend deferring formal SLO definition (API availability, latency, sync success rate) until a staging environment exists and baseline traffic patterns can be observed, per target architecture §25.

## 7. Wave 0 reliability priorities

1. Add `/health/live`, `/health/ready`, `/version` per target architecture §14, reconciled with (not duplicating) the existing `/api/v1/health`.
2. Move rate limiting to Redis-backed storage before any multi-process/replica deployment is attempted.
3. Introduce Alembic-based migrations with a version table, replacing the disconnected raw SQL file.
4. Add structured logging as a prerequisite for any future alerting.
5. Fix the `asyncpg` dependency gap (shared item with [INFRASTRUCTURE_AUDIT.md](../infrastructure/INFRASTRUCTURE_AUDIT.md) §5 and [SECURITY_BASELINE.md](../security/SECURITY_BASELINE.md) §8).

No code changes have been made as part of this analysis.
