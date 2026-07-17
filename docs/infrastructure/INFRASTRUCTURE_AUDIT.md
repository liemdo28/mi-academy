# Infrastructure Audit — MI Academy

**Author:** Dev 6 (DevOps, Security & Reliability Lead)
**Date:** 2026-07-17
**Scope:** Full repository audit prior to any infrastructure change, per Wave 0 requirements.
**Status:** Baseline snapshot. No infrastructure changes have been made yet.

## 1. Repository & branch state

- Branch: `main` (git status snapshot); a parallel `design/wave0-foundation` branch also observed with uncommitted work.
- Uncommitted changes present at audit time touch CI (`.github/workflows/ci.yml`), backend sync routes/schemas, mobile API service, and several docs. This is a cohesive, not-yet-committed feature slice (new `/sessions` sync endpoint + tests + a new CI privacy-audit step). It has **not** been committed, so current CI on `main` does not yet exercise it.
- Root-level scratch clutter: `_build_sql.py`, `_decode.py`, `_gen.ps1`, `_gen.py`, `_gen2.txt`, `_gen_robot.py`, `_gen_ws.py`, `_tmp_write.py`, `_ws_payload.txt`, `tapped`, `3.4.0`, plus duplicate stray packages `routes/`, `schemas/`, `middleware/` at repo root (near-empty, shadow the real `apps/api/*` packages). Recommend cleanup — these are not part of any build and risk import confusion.
- Possible duplicate/stale package dirs: `packages/game-core` vs `packages/game_core` vs `packages/mi_game_core` — needs owner confirmation on which is live.

## 2. Build & CI

Single workflow: `.github/workflows/ci.yml` ("MI Academy CI"), triggers on push/PR to `main`/`develop` plus manual dispatch.

Jobs today:
1. `content-and-safety` — content, level, child-safety, network, and mobile-privacy audit scripts.
2. `python-tests` — pytest over `packages/game_core/tests`, `tests`, `test`.
3. `mobile-test-build` — Flutter analyze/test/build (web release, Android debug) + performance baseline artifact.
4. `ios-build` — Flutter iOS debug build, no signing.

**Gaps:**
- No lint/type-check job dedicated to `apps/api` (covered indirectly by pytest only).
- No Docker image build/push step — images are never built in CI.
- No deployment job of any kind (dev/staging/prod).
- No secret scanning, dependency vulnerability scanning, container scanning, or SAST — despite `docs/security.md` requiring all four.
- No admin app (`apps/admin`) build/test coverage at all.
- Artifacts (APK, web build, perf baseline) are uploaded but never published or promoted anywhere.

## 3. Docker & local environment

- No root `Dockerfile`/`docker-compose.yml`; both live under `infrastructure/docker/`.
- `infrastructure/docker/docker-compose.yml`: `db` (postgres:16-alpine), `redis` (redis:7-alpine), `api` (built from `Dockerfile.api`). Dev credentials are inline plaintext in the compose file (`mi_dev_password`, a dev `SECRET_KEY`) — acceptable for local-only use but should move to an untracked `.env` referenced via `env_file:` for consistency with the "no secrets in files under version control" principle, even for dev placeholders.
- `infrastructure/docker/Dockerfile.api`: `python:3.12-slim` base (mismatched with CI's Python 3.13), `COPY . .` copies the entire monorepo into the image (no `.dockerignore` present), runs as root, no `HEALTHCHECK`, no multi-stage build, no pinned digest.
- No `Makefile` and no single "one command to start local stack" entry point exists yet (`make dev` / `docker compose up` referenced in the target design does not yet exist as a documented, working command).
- No mock object storage, mock email, or seed-on-boot wiring confirmed beyond `infrastructure/scripts/seed.py` / `infrastructure/seed/seed_data.py` (not yet verified runnable end-to-end).

## 4. Environments

Only one environment is implicitly modeled today: local/dev via docker-compose and `.env.example` (SQLite default). There is **no** development, staging, or production environment defined, no environment-specific configuration set, and no deployment target of any kind. This is the largest gap relative to the target architecture.

## 5. Database & migrations

- SQLAlchemy 2.x async ORM against SQLite (default, aiosqlite) or Postgres (docker-compose).
- Migrations are a single hand-written SQL file (`infrastructure/migrations/001_initial.sql`), not Alembic — no version table, no rollback path, and it is not invoked by docker-compose or CI. The app instead calls `Base.metadata.create_all` on startup when `CREATE_TABLES_ON_STARTUP=true`, so the checked-in SQL migration is effectively unused and already drifting from the ORM models.
- **Driver mismatch:** `apps/api/requirements.txt` pins `psycopg2-binary` (sync driver) but the async engine and docker-compose `DATABASE_URL` use `postgresql+asyncpg://`; `asyncpg` is not declared anywhere. This will fail at runtime against Postgres as currently pinned — a functional bug, not just a hygiene issue.

## 6. Secrets

- No live/production secrets found committed. `.gitignore` correctly excludes `.env*`, `*.db`/`*.sqlite*`, `.venv/`, `build/`.
- Dev-placeholder secrets exist in three places: `infrastructure/docker/docker-compose.yml`, `apps/api/config.py` (`SECRET_KEY` default), `.env.example`. None are live, but `config.py`'s fallback means the app **boots silently with a well-known key** if an operator forgets to set `SECRET_KEY` — no startup guard rejects the placeholder in a non-dev environment.
- No secrets manager or CI secret store integration exists yet (nothing to configure until an actual deployment target exists).

## 7. Monitoring, logging, alerting

None exist. No structured logging in `apps/api`, no request-ID/correlation-ID middleware, no error tracking (policy calls for self-hosted GlitchTip, none present), no metrics, no dashboards, no alert routes.

## 8. Dependency & container security

- Python: `requirements.txt` only, exact pins, no lock file with hashes, no `pip-audit` in CI.
- Dart/Flutter: `pubspec.lock` committed per package — good, dependencies are pinned.
- No Node/`package.json` anywhere in the repo.
- No container scanning, no SBOM generation, no CodeQL/SAST anywhere in CI.

## 9. Network boundaries

Not yet applicable — there is no deployed environment, so no gateway, no public/internal split, and no rate-limit-at-the-edge exists. The only defense today is an **in-process, in-memory** rate limiter (`apps/api/middleware/rate_limit.py`) which will not function correctly once more than one API process/replica is running; Redis is already provisioned in docker-compose but unused for this purpose.

## 10. Rollback

No deployment exists, so no rollback mechanism exists. This must be designed alongside the first real deployment pipeline, not bolted on after.

## 11. Mobile build pipeline

- CI produces debug-only Android/web/iOS(no-codesign) builds. No signing configuration, no keystore/provisioning management, no store metadata handoff, no TestFlight/internal-track publishing.
- `apps/admin` has zero CI coverage.

## 12. Cost

Not yet assessable — no cloud infrastructure is provisioned. Revisit once staging/production environments exist.

## 13. Summary of Wave 0 priorities implied by this audit

1. Fix the `asyncpg` dependency gap (blocks any real Postgres deployment).
2. Add a startup guard against the default `SECRET_KEY`.
3. Introduce `.dockerignore` + non-root user + `HEALTHCHECK` in `Dockerfile.api`.
4. Stand up `.env.example` completeness check and a `make`-based local workflow.
5. Add secret scanning, dependency scanning (`pip-audit`), and basic SAST to CI.
6. Design environment strategy (local/dev/staging/prod) before any deploy automation.
7. Add structured logging + a `/health/live`, `/health/ready`, `/version` contract (an unversioned `/api/v1/health` already exists and should be reconciled with this contract, not duplicated).
8. Replace the raw-SQL migration file with Alembic, wired to the same models.
9. Clean up root-level scratch scripts and duplicate stray packages (non-blocking, low-risk).

No infrastructure has been modified as part of this audit. See companion documents:
[SECURITY_BASELINE.md](../security/SECURITY_BASELINE.md), [RELIABILITY_GAP_ANALYSIS.md](../reliability/RELIABILITY_GAP_ANALYSIS.md), [DEPLOYMENT_PIPELINE_AUDIT.md](../deployment/DEPLOYMENT_PIPELINE_AUDIT.md), [BACKUP_RESTORE_BASELINE.md](../disaster-recovery/BACKUP_RESTORE_BASELINE.md).
