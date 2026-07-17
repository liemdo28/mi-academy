# Environment Strategy — MI Academy

**Author:** Dev 6 (DevOps, Security & Reliability Lead)
**Date:** 2026-07-17
**Status:** Design baseline. `local` exists today; `development`/`staging`/`production` are not yet provisioned as real infrastructure — this document defines what they must look like when they are.

## 1. Four environments

| Environment | Purpose | Data | Backend deploy target | Exists today? |
|---|---|---|---|---|
| `local` | Individual dev machine | SQLite or local docker-compose Postgres, throwaway | `docker compose up` / `make dev` | ✅ |
| `development` | Continuous integration target, shared testing | Synthetic/seeded, resettable | Single low-cost container instance | ❌ not provisioned |
| `staging` | Pre-production validation, as close to prod as possible | Synthetic test data only, **never** real child/parent data | Mirrors production deployment model | ❌ not provisioned |
| `production` | Real users | Real parent/child data | Production deployment target | ❌ not provisioned |

Production is never used as staging. Staging never holds real child data — this is a hard rule, not a preference, because staging is used for load/fault-injection testing that could corrupt or leak data.

## 2. `APP_ENV` values

`apps/api/config.py` currently supports `"development"` and `"production"` as the recognized values for `APP_ENV`, with a startup guard that refuses to boot with the default `SECRET_KEY` when `APP_ENV=production`. This should be extended to four recognized values as real environments are provisioned: `local`, `development`, `staging`, `production`. Until `staging` is provisioned, treat it as an alias of `production` for the purposes of the secret-key guard (i.e. staging must also reject the default key), since it will hold internet-reachable infrastructure even though it holds only synthetic data.

## 3. Configuration differences per environment

All configuration flows through environment variables per `.env.example` — no environment-specific code branches, only environment-specific values. Reference: [SECRET_INVENTORY.md](../security/SECRET_INVENTORY.md) for which of these are secrets vs. plain config.

| Variable | local | development | staging | production |
|---|---|---|---|---|
| `APP_ENV` | `local` | `development` | `staging` | `production` |
| `DEBUG` | `true` | `true` | `false` | `false` |
| `DATABASE_URL` | sqlite or local postgres | dedicated dev Postgres | dedicated staging Postgres | dedicated prod Postgres (separate credentials, separate instance from staging) |
| `CREATE_TABLES_ON_STARTUP` | `true` | `false` (use Alembic) | `false` | `false` |
| `SECRET_KEY` | dev placeholder acceptable | unique per-env secret | unique per-env secret | unique per-env secret, rotated per policy |
| `CORS_ORIGINS` | `localhost:*` | dev app URLs | staging app URLs | production app URLs only |
| `REDIS_URL` | optional (compose service) | required | required | required |
| `LOG_LEVEL` | `DEBUG` | `INFO` | `INFO` | `WARNING`/`INFO` |
| `SENTRY_DSN` / GlitchTip DSN | unset | dev project | staging project | production project (separate from staging so alerts don't cross-contaminate) |

## 4. Never share between environments

- Never share a database instance between `development`/`staging`/`production`.
- Never share `SECRET_KEY`, JWT signing keys, or encryption keys between environments.
- Never copy real production data into `staging` or `development`. Use synthetic/seeded data (`infrastructure/scripts/seed.py`, `infrastructure/seed/seed_data.py`) instead.
- Never point a mobile release build at anything other than production `MI_ACADEMY_API_BASE_URL` (per `docs/RELEASE_READINESS_BASELINE.md`, the mobile app requires explicit build-time API base URL configuration — this must be locked to the correct environment per build channel: debug/dev builds may point at `development`, internal-testing builds at `staging`, store releases at `production` only).

## 5. Promotion flow

Per target architecture §13: `development` → `staging` → `production`, promoting the **same build artifact** rather than rebuilding at each stage. This cannot be implemented until a CI image-build step and a container registry exist (tracked in [DEPLOYMENT_PIPELINE_AUDIT.md](../deployment/DEPLOYMENT_PIPELINE_AUDIT.md) §7).

## 6. Sequencing

Do not provision `staging` or `production` before:
1. `development` exists and has been exercised by at least one real deploy + smoke test cycle.
2. The Alembic migration path (tracked separately) is in place — deploying with the current unversioned raw-SQL migration approach to a real environment would be unsafe.
3. Secrets management for that environment is decided (which secret store, who has access) — not decided yet, needs a hosting-platform choice first.

This document defines the target shape. No `development`, `staging`, or `production` infrastructure has been provisioned yet.
