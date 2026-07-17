# Security Baseline — MI Academy

**Author:** Dev 6 (DevOps, Security & Reliability Lead)
**Date:** 2026-07-17
**Status:** Baseline snapshot against existing `docs/security.md` policy. No changes applied yet.

This document records the gap between the security policy already defined in [`docs/security.md`](../security.md) (owned by product/child-safety) and what is actually implemented in infrastructure and CI today. It does not replace that policy — it tracks operational compliance with it.

## 1. Secrets

| Item | Status | Note |
|---|---|---|
| `.env` excluded from git | ✅ | `.gitignore` covers `.env*` |
| `.env.example` present and documented | ✅ | root `.env.example` |
| No live secrets committed | ✅ | grep swept, no matches |
| Default `SECRET_KEY` rejected at startup in non-dev env | ❌ | `apps/api/config.py:21` ships a guessable fallback with no runtime guard |
| Secrets manager / CI secret store | ❌ | not applicable yet — no deployment target exists |
| Secret rotation policy | ❌ | not defined |
| Secret scanning in CI | ❌ | no gitleaks/trufflehog step |

## 2. Dependency & supply chain

| Item | Status | Note |
|---|---|---|
| Python deps pinned | ✅ | `requirements.txt`, exact `==` pins |
| Python deps hash-locked | ❌ | no lock file |
| `pip-audit` in CI | ❌ | required by `docs/security.md` §6, not implemented |
| Flutter/Dart deps pinned | ✅ | `pubspec.lock` committed per package |
| `flutter pub outdated` check in CI | ❌ | required by policy, not implemented |
| Container scanning | ❌ | no image scan step, and no image is even built in CI today |
| SBOM generation | ❌ | not implemented |
| Dependabot / automated update PRs | ❌ | no `dependabot.yml` |

## 3. Transport & network

| Item | Status | Note |
|---|---|---|
| HTTPS enforced | N/A | no deployed environment yet |
| CORS restricted | ✅ | `CORS_ORIGINS` defaults empty (deny by default) |
| Rate limiting | ⚠️ | in-memory only, per-process — will not hold under multiple replicas; Redis is provisioned but unused for this |
| Public DB/Redis exposure | N/A | no deployed environment yet; docker-compose ports are local-only |
| Admin API isolation from public API | ❌ | both are the same FastAPI app/process today (`/admin/api/v1` prefix, not a separate service) |

## 4. Application-layer security

| Item | Status | Note |
|---|---|---|
| Password hashing | ✅ (assumed bcrypt per `BCRYPT_ROUNDS` config) | not independently re-verified in this audit; owned by Dev 1 |
| JWT-based auth | ✅ | HS256 per `docs/BACKEND_API_REPORT.md` |
| Constant-time PIN compare | ⚠️ unverified | policy requires it; not confirmed in this audit pass, flag for Dev 1 follow-up |
| SAST in CI | ❌ | not implemented |
| Error tracking (GlitchTip per policy) | ❌ | not wired into `apps/api` |
| Structured logging with redaction | ❌ | no logging config found in `apps/api` at all |

## 5. Container security

| Item | Status | Note |
|---|---|---|
| Non-root container user | ❌ | `Dockerfile.api` runs as root |
| `.dockerignore` | ❌ | absent; entire repo (including `.git`, docs, mobile source) is copied into the API image |
| `HEALTHCHECK` | ❌ | absent |
| Minimal base image | ⚠️ | `python:3.12-slim` is reasonable but version-mismatched from CI's Python 3.13 |
| Image tagging by version + commit SHA | ❌ | no image is built/tagged in CI at all yet |

## 6. Mobile security

| Item | Status | Note |
|---|---|---|
| No ad/analytics/social SDKs bundled | ✅ | confirmed via `pubspec.yaml` dependency review, matches policy |
| Secure local storage | ✅ | `flutter_secure_storage`, `hive`/`hive_flutter` present |
| Biometric/local auth support | ✅ | `local_auth` present |
| Release signing pipeline | ❌ | CI only produces debug/no-codesign builds; no keystore or provisioning management exists |
| Backend URL not baked into release builds by default | ✅ | confirmed via `docs/RELEASE_READINESS_BASELINE.md` — requires explicit `MI_ACADEMY_API_BASE_URL` at build time |

## 7. Severity classification of open items

**Critical (block any production deployment):**
- Default `SECRET_KEY` fallback with no startup rejection.
- Missing `asyncpg` dependency despite async Postgres URL scheme in use (functional break, documented in [INFRASTRUCTURE_AUDIT.md](../infrastructure/INFRASTRUCTURE_AUDIT.md) §5).
- No secret scanning in CI.

**High:**
- No dependency vulnerability scanning (`pip-audit`, Flutter equivalent).
- No container scanning / no `.dockerignore` / root container user.
- Rate limiter not viable across multiple replicas.

**Medium:**
- No SAST.
- No structured logging / redaction middleware.
- No error tracking integration.
- Admin API not network-isolated from public API.

**Low:**
- Root-level scratch script clutter (non-security, hygiene only).

## 8. Immediate recommendations (Wave 0)

1. Add a startup check in `apps/api/config.py`/`main.py` that refuses to boot with the default `SECRET_KEY` unless `APP_ENV=local`.
2. Add `asyncpg` to `requirements.txt` (or switch the async URL scheme to match the pinned driver — needs a decision, not a unilateral change, since it affects Dev 1's ORM usage).
3. Add a `secret-scan` CI job (e.g. gitleaks) as a required check.
4. Add `pip-audit` and `flutter pub outdated`/`dart pub outdated` as CI jobs, non-blocking initially (report-only) until a triage owner is assigned, then promote to blocking on Critical/High.
5. Add `.dockerignore` and a non-root `USER` + `HEALTHCHECK` to `Dockerfile.api`.

No code or CI changes have been made as part of this baseline document. These are recommendations pending review.
