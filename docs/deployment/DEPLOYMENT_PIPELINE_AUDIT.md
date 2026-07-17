# Deployment Pipeline Audit — MI Academy

**Author:** Dev 6 (DevOps, Security & Reliability Lead)
**Date:** 2026-07-17
**Status:** Baseline snapshot. No pipeline changes applied yet.

## 1. Current state: no deployment pipeline exists

There is currently **no CD pipeline of any kind** — CI (`.github/workflows/ci.yml`) validates content, runs tests, and produces build artifacts (web build, debug APK, iOS debug build, performance baseline), but nothing publishes, promotes, or deploys any of it. No `deploy/`, `ops/`, `terraform/`, or `kubernetes/` directories exist. This is the single largest gap identified across all five audit documents.

## 2. What exists today (build only, not deploy)

| Stage | Exists? | Detail |
|---|---|---|
| Checkout | ✅ | all jobs |
| Dependency restore | ✅ | pip / flutter pub get |
| Dependency integrity check | ❌ | no hash verification |
| Formatting check | ❌ | not a distinct CI step |
| Static analysis | ⚠️ | `flutter analyze` only; no Python linting (flake8/ruff/mypy) |
| Unit tests | ✅ | Python via pytest, Flutter via `flutter test` |
| Contract tests | ❌ | none identified |
| Content validation | ✅ | `tools/content_validator`, `tools/level_validator` |
| License validation | ⚠️ | referenced in docs (`docs/GAME_LICENSE_REVIEW.md`) but not confirmed as an automated CI gate |
| Secret scan | ❌ | absent |
| Dependency vulnerability scan | ❌ | absent |
| Container scan | ❌ | absent (no image is even built) |
| Backend integration tests | ✅ | via root `tests/` against SQLite |
| Flutter widget tests | ✅ | `flutter test` |
| Build verification | ✅ | web release build, Android debug build, iOS debug build |
| Test report upload | ⚠️ | artifacts uploaded (APK, web build, perf baseline) but no formal test-report publishing step |
| **Sign** | ❌ | no signing configured for any target |
| **Publish artifact** | ❌ | artifacts stay in GitHub Actions storage only |
| **Deploy (dev/staging/prod)** | ❌ | absent entirely |
| **Smoke test post-deploy** | ❌ | absent (nothing to smoke-test) |
| **Canary / rollout control** | ❌ | absent |
| **Rollback** | ❌ | absent |

## 3. Branch protection

Not verified via this repo audit (branch protection is a GitHub repository setting, not a file) — needs to be confirmed/configured directly in GitHub settings for `main`, `develop`, and `release/*` per target architecture §12. Flag as an action item, not something inferable from the working tree.

## 4. Backend deployment readiness

- No `/health/ready` distinguishing dependency-readiness from liveness (see [RELIABILITY_GAP_ANALYSIS.md](../reliability/RELIABILITY_GAP_ANALYSIS.md) §3).
- No versioned migration runner distinct from app boot.
- No container registry target, no image tagging scheme in use yet.
- No environment-specific configuration beyond the single `.env.example`.

## 5. Mobile deployment readiness

- Android: CI produces debug builds only; no version-code/version-name management, no signing keystore, no app bundle (`.aab`) build, no mapping-file upload, no internal-testing-track release, no store metadata handoff.
- iOS: CI produces an unsigned debug archive only (`--no-codesign`); no certificates/provisioning, no TestFlight upload, no symbol upload.
- Web: `flutter build web --release` runs but nothing deploys the output; no CDN, no cache-busting/versioning strategy, no security headers, no CSP.
- Admin app (`apps/admin`): no CI coverage at all — not built, tested, or analyzed.

## 6. Artifact traceability

None of the "must be traceable" fields from the target architecture (commit SHA, build ID, version, environment, migration list, release notes, test result, rollback target, timestamp) are currently captured anywhere outside of GitHub Actions' own run metadata. No release-record document or artifact registry exists.

## 7. Wave 0–1 priorities (deployment-specific)

1. Confirm/configure GitHub branch protection rules for `main`/`develop`.
2. Add a Docker image build step to CI (tagged `sha-<commit>` at minimum), even before any real deploy target exists — this unblocks container scanning and gives Dev 1 a testable artifact.
3. Stand up a `development` deployment target (even a single low-cost container host) so the pipeline has somewhere real to deploy to and smoke-test against, per target architecture Wave 1.
4. Add `/health/live`, `/health/ready`, `/version` before attempting any automated deploy — a deploy pipeline with no readiness signal cannot safely gate rollout.
5. Do not attempt staging/production/canary/rollback automation until items 1–4 are in place and validated in `development`. This matches the target architecture's explicit instruction not to over-build infrastructure ahead of product scale.

No deployment pipeline changes have been made as part of this audit.
