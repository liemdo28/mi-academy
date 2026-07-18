# PR #5 — Internal Beta Hardening Report

**Repository:** liemdo28/mi-academy
**PR:** #5 ("Internal Beta Hardening")
**Base branch (PR #5):** `fix/full-phase-1-to-19` (PR #4's tip — **PR #4 is
not merged**, so this cannot be based on a "final merged state"; see §2)
**Working branch:** `fix/internal-beta-hardening`
**Target release:** v0.9.0-beta.1
**Report date:** 2026-07-18

## 1. Executive Summary

This pass re-verified PR #4's claims from source (not from its own
summary), then hardened the system for internal beta within the bounds of
what's achievable without a physical device or real infrastructure. Two
real, previously-undetected reliability bugs were found and fixed
(concurrent-refresh logout storm; unrecoverable corrupted-storage
startup crash), both with regression tests. A privacy-safe local
diagnostics capture mechanism was added (no external crash service
exists, so this is the honest repository-controlled equivalent). Real
release builds were produced and smoke-tested (web, Android APK, backend
Docker image) — not fabricated. All required beta documentation
(runbook, test plan, risk register, device/network/install matrices,
known issues, rollback plan, release notes) was created, with every
device/infrastructure-dependent item explicitly marked as plan-only, not
executed. **Zero physical-device testing occurred in this environment —
classification is accordingly "GO WITH CAVEATS — LIMITED TECHNICAL
BETA," not a broad-rollout GO, per this task's own stated rule.**

## 2. Entry Conditions

Re-verified, not assumed:

- PR #4 exists: yes (https://github.com/liemdo28/mi-academy/pull/4).
- PR #4 final audit report exists: `docs/final/PR4_FINAL_PRODUCTION_AUDIT_2026-07-18.md`.
- PR #4 P0/P1: 0 remaining (re-confirmed by reading the report and its
  underlying evidence, not just its conclusion).
- PR #4 CI: green (re-confirmed via `gh api`, not just the report's claim).
- **PR #4 merge status: NOT MERGED** (`state: OPEN`, `mergedAt: null` at
  branch-creation time). Per the entry-condition rules: no beta tag was
  created, this PR does not claim to be based on a "final merged state,"
  and it is explicitly based on PR #4's branch tip instead of `main`.
- Internal Beta classification, known caveats, and production
  infrastructure limitations: all documented in the PR #4 report and
  re-confirmed still accurate as of this pass.
- Physical-device QA: still unverified — no device became available
  between PR #4 and this pass.

## 3. Repository and Release Metadata

| Field | Value |
|---|---|
| Base commit (PR #4 tip) | `edea48d87843dddf663832f418c45a558a34ce52` |
| Working branch | `fix/internal-beta-hardening` |
| Final commit (this report) | `c9f9bef0398eefb278c9c205a9321275e94cfac2` |
| Target version | 0.9.0-beta.1 (pubspec.yaml bumped from 0.1.0 this pass) |
| Build number | 1 |

## 4. Baseline Results (captured before any change this pass)

- `pytest tests test packages/game_core/tests -q`: 159/159 passed, ~7s.
- `flutter analyze` (apps/mobile): 0 issues.
- `flutter test` (apps/mobile): 73 passed / 6 failed (known golden diffs).
- `flutter test` (packages/mi_game_core): 46/46 passed.
- `flutter test` (packages/offline_sync): 15/15 passed.
- `pytest tests/test_contract_registry.py`: 8/8 passed.
- `python tools/content_validator/validate_content.py`: ALL CONTENT VALID.

## 5. Changes Implemented

1. Serialized `ApiService._refreshAccessToken()` behind one shared
   in-flight `Future` — concurrent 401s previously each triggered their
   own refresh; since refresh tokens are single-use/rotated server-side,
   only the first succeeded and the rest forced an unnecessary full
   logout via `onSessionExpired`, even with a valid session.
2. `openBoxWithCorruptionRecovery()` (`packages/offline_sync`) — a
   corrupted Hive box file previously threw uncaught out of `initHive()`,
   preventing `runApp` from ever executing. Now recovers by deleting and
   recreating the one corrupted box.
3. `_FatalStartupErrorApp` — last-resort fallback UI in `main()` for a
   more fundamental init failure than one corrupted box.
4. `BetaDiagnostics` (`apps/mobile/lib/services/beta_diagnostics.dart`) —
   bounded (50-record), redacted, exportable local error log, wired via
   `FlutterError.onError`/`PlatformDispatcher.instance.onError`.
5. `pubspec.yaml` version bump to `0.9.0-beta.1+1`.
6. `.gitleaks.toml` — allowlists one confirmed false-positive test
   fixture by exact commit SHA (see §28 for the full story: an earlier
   fix attempt via regex didn't work and was corrected after a second CI
   run confirmed it).
7. Debug-banner fix on the new fatal-startup screen.

## 6. Golden Test Resolution

No new golden failures introduced this pass (still exactly the same 6 as
PR #4, unchanged content). Re-confirmed via the fresh CI run at commit
`c9f9bef`: all 6 pass on the Linux CI runner. Not regenerated — the
existing goldens are correct (CI-rendered), and the local Windows
failures remain a font-rendering environment difference, not a defect.

## 7. Release Build Results

**Real builds produced and verified this pass, not fabricated:**

- `flutter build web --release`: succeeded. Output `build/web`, ~37MB.
  Wasm-compatibility dry-run flagged 2 packages (`flutter_secure_storage_web`,
  `audioplayers_web`) as using `dart:html`/`dart:js_util` — expected for a
  non-Wasm web build target, not a build failure.
- `flutter build apk --release`: succeeded. Output
  `build/app/outputs/flutter-apk/app-release.apk`, ~55MB (57,258,576
  bytes), SHA-256
  `adcf9f818060ca998ceec73feea72cea4a9f8d03949e20448915c0122cd5ab67`.
  **Unsigned/debug-keystore** — no release keystore is configured in this
  environment (matches CI's `android-release-signing` job, which
  correctly no-ops without one).
- `docker build -f infrastructure/docker/Dockerfile.api`: succeeded.
  Image `mi-academy-api:0.9.0-beta.1`. Smoke-tested: ran the container,
  `curl /health/live` → `{"status":"ok"}`, `curl /version` →
  `{"version":"1.0.0","environment":"development"}`, both 200. Structured
  JSON logs confirmed working, no secrets visible in log output.
- iOS build: not attempted locally (no macOS toolchain in this
  environment); CI's `ios-build` job (no-codesign) passed at commit
  `c9f9bef`.

No debug banner in release builds (verified: `debugShowCheckedModeBanner: false`
set on both the production `MiAcademyApp` and the new fatal-startup
fallback screen).

## 8. Environment Configuration Review

Re-confirmed present and correct (from PR #4, re-verified not just
assumed): `APP_ENV`/`SECRET_KEY` production startup guard
(`apps/api/config.py`), `TRUST_PROXY_HEADERS` gate on `X-Forwarded-For`,
`CREATE_TABLES_ON_STARTUP` (should be `false` in any real deployment,
migrations own the schema), `CORS_ORIGINS` (empty by default, no
wildcard). No new environment variables were introduced this pass beyond
what PR #4 already added. `.env.example` was not modified this pass — no
new config surface was added that needs a new example entry.

## 9. Startup Reliability

Audited and fixed this pass (§5 items 2-3). Re-verified: `restoreTokens()`
on a corrupted/garbage secure-storage value doesn't crash (any non-null
string is accepted as "a token," surfaces later as a 401, handled by the
existing interceptor). `getProfile()` hang risk: none — Dio's 10s
connect/receive timeouts apply. Expired-access + expired-refresh: degrades
correctly to `isAuthenticated: false`, routes to `/login`, no unhandled
exception.

## 10. Authentication and Session Reliability

Fixed this pass: concurrent-refresh race (§5 item 1). Re-confirmed
(unchanged from PR #4, re-verified not re-assumed): refresh-token
rotation/revocation, logout requiring auth and revoking all outstanding
tokens, PIN server-side lockout.

## 11. Child Profile Isolation

Re-verified via a dedicated audit this pass: `GameScreen._saveResult()`
enqueues with the widget's own bound `childId`, never the "currently
active" provider state; `ApiSyncProcessor`/`sync_service.dart` never
substitute an active-child reference; server-side ownership checks
(re-verified in PR #4) are the actual enforcement boundary. The one gap
found and fixed in PR #4's own final audit (child selection not cleared
on logout) remains fixed and tested. **No new gap found this pass.**

## 12. Offline Attempt Durability

Re-verified via a dedicated audit this pass, all confirmed already
correct: child-switch-with-pending-attempt uses the item's own stored
identity (no cross-child leak); queue processing is FIFO-per-pass with
backend out-of-order protection covering the one ordering caveat;
poison-item handling quarantines without blocking other items; logout
with pending attempts never deletes the queue.

## 13. Synchronization and Idempotency

Re-confirmed (PR #4, re-verified): `client_attempt_id` unique constraint +
pre-check + `IntegrityError` catch-and-replay; reward issuance
`UniqueConstraint(child_id, reward_id)` + SELECT-before-INSERT.

## 14. Lifecycle Interruption Testing

Code-level review only (no device to physically background/kill/resume
the app). `SnapshotLifecycleMixin` (PR #4) already saves on
`AppLifecycleState.paused/inactive`. No new code-level gap found beyond
what's covered by existing tests.

## 15. Storage and Migration Review

6-migration linear Alembic chain (2 pre-existing + 4 from PR #4), all
additive, all with working `downgrade()`. Re-validated against real
Postgres this pass via the existing `postgres-integration` CI job
(unchanged, re-confirmed still green). Corrupted-cache recovery: new this
pass (§5 item 2), tested (`hive_corruption_recovery_test.dart`).

## 16. Content and Asset Validation

Unchanged from PR #4: `tools/content_validator/validate_content.py` runs
clean, re-confirmed this pass.

## 17. Six-Game Validation

No game-logic changes this pass. Existing coverage (PR #4): all 6 games
emit the canonical `MiCompletionResult` with real per-level `skillIds`.
Device-level play-testing: not executed.

## 18. Crash and Diagnostic Readiness

New this pass: `BetaDiagnostics` (§5 item 4). Not a remote/external
crash-reporting service — explicitly not claimed as one. 4 new tests
(`beta_diagnostics_test.dart`) confirm redaction, retention cap, and
export shape.

## 19. Beta Feedback Readiness

Plan documented (`docs/beta/INTERNAL_BETA_RUNBOOK.md`); no real channel
configured in this environment — explicitly flagged, not fabricated.

## 20. Accessibility Validation

No new accessibility work this pass beyond what PR #4 already did
(`reduceMotion` for Memory Cards, Word Builder semantic labels). Real
screen-reader/device verification: not executed.

## 21. Security, Privacy, and Child Safety

No new gaps found in this pass's dedicated audits (auth/authz/isolation,
offline/reward/migration/secret hygiene) beyond the 2 fixed (§5). Gitleaks
secret scan: 1 confirmed false positive found and allowlisted (§28); no
real secret found anywhere in the diff.

## 22. Performance Findings

No new performance work this pass — PR #4's fixes (N+1 queries, indexes,
connection pool) re-confirmed unchanged. No device-based profiling
possible in this environment.

## 23. Installation and Upgrade Results

Plan-only — see `docs/beta/INSTALL_UPGRADE_MATRIX.md`. Zero scenarios
executed (no device, no prior beta build to upgrade from).

## 24. Device QA Results

Plan-only — see `docs/beta/DEVICE_QA_MATRIX.md`. Zero devices available,
zero rows executed.

## 25. Distribution Readiness

Not ready — no distribution channel configured, Android build unsigned.
See `docs/beta/INTERNAL_BETA_RUNBOOK.md`'s Distribution Procedure.

## 26. Test Results

Fresh, run at final commit `c9f9bef`:
- Backend: 159/159 passing.
- `flutter analyze`: 0 issues.
- Mobile: 78/84 passing (6 known golden diffs, pass on CI).
- `offline_sync` package: 17/17 passing (15 existing + 2 new).
- `python tools/child_safety_audit.py`: pass, 0 failures.

## 27. CI Results

Final green run: `29636607256` at commit `c9f9bef0398eefb278c9c205a9321275e94cfac2`,
all 7 jobs successful (`Secret, dependency, and SAST scans`,
`Postgres + Redis production-config smoke test`, `Python game-core tests`,
`Mobile analyze, tests, web, and Android build`,
`Content and child-safety gates`, `iOS no-codesign build`,
`Android release build (signed)`). Note: PR #5 targets
`fix/full-phase-1-to-19`, not `main`/`develop`, so CI does not trigger
automatically on push/PR for this branch (the workflow's `on:` filters);
every run this pass was manually dispatched via
`gh workflow run ci.yml --ref fix/internal-beta-hardening` and its result
independently confirmed via `gh api`, not assumed from local tests.

## 28. Findings by Severity

**P0:** none found.

**P1 (found and fixed this pass):**
1. Concurrent token-refresh race causing an unnecessary forced logout —
   fixed, tested.
2. Uncaught corrupted-Hive-box startup crash with no recovery path —
   fixed, tested.

**P2:**
1. Gitleaks flagged a fake test-fixture token as a potential secret,
   blocking the "Secret, dependency, and SAST scans" CI job. Not a real
   secret — confirmed by reading the code. First fix attempt (a regex
   allowlist) didn't actually suppress it on the next CI run; corrected to
   an exact-commit-SHA allowlist entry, confirmed working via a subsequent
   green run. This specific action (modifying a security-scan gate) was
   flagged by the session's own safety classifier as requiring explicit
   user approval before proceeding — approval was obtained before either
   allowlist commit was made.
2. `AppBuildInfo` version constants are hand-maintained, not pulled from
   `package_info_plus` or CI-injected commit SHA — documented follow-up,
   not automated this pass.
3. No real distribution channel configured — documented, not built (needs
   real channel access this environment doesn't have).

**P3:** none new this pass (PR #4's P3 items were already fixed there).

## 29. Remaining Repository-Controlled Work

1. Wire a real `package_info_plus`-based (or CI-injected) build identity
   instead of the hand-maintained `AppBuildInfo` constants.
2. Build a tester-facing UI surface to view/export `BetaDiagnostics`
   (currently a service with no screen; a developer can call `.export()`
   directly, but no in-app button exists yet).
3. Everything already listed as open in
   `docs/final/PR4_FINAL_PRODUCTION_AUDIT_2026-07-18.md` §13 (contract
   annotations, orphaned-package keep/retire decision, `apps/admin`
   wiring) remains open and out of this pass's scope.

## 30. External Validation Requirements

Physical iOS/Android devices, a real distribution channel (Firebase App
Distribution / Play Internal Testing / TestFlight), a release Android
keystore, real beta testers, production database/deployment/monitoring/
backup infrastructure. None exist in this environment; none fabricated.

## 31. Risk Acceptance

See `docs/beta/INTERNAL_BETA_RISK_REGISTER.md` — R9 (device
incompatibility), R10 (crash-rate monitoring), R11 (diagnostics
collection from real testers) are explicitly accepted as unresolved
pending device/infrastructure access, not silently passed over.

## 32. Rollback Readiness

Documented (`docs/beta/ROLLBACK_PLAN.md`), **not rehearsed** — no
production database exists to rehearse a real rollback against. Migration
reversibility is a repository-level guarantee (working `downgrade()` on
all 4 new migrations), confirmed by inspection, not by executing a real
downgrade against production data.

## 33. Beta Entry Criteria

- [x] No unresolved P0
- [x] No unresolved P1 (2 found this pass, both fixed)
- [x] Required CI jobs green (manually dispatched and confirmed, since
      auto-trigger doesn't apply to this non-main-targeting PR)
- [x] Release build succeeds (real evidence: web, APK, Docker image)
- [x] Golden differences resolved/approved with evidence (unchanged from
      PR #4, re-confirmed passing on CI at this commit)
- [x] Offline attempt durability verified (re-audited, code-level)
- [x] Duplicate replay verified (re-audited, code-level)
- [x] Child-profile isolation verified (re-audited, code-level)
- [x] Authentication/refresh behavior verified (fixed a real gap this
      pass)
- [x] Logout behavior verified
- [x] Startup recovery behavior verified (fixed a real gap this pass)
- [x] Migration path verified (re-validated against real Postgres)
- [x] Beta diagnostics available (new this pass) and privacy-safe (tested)
- [x] Beta runbook, risk register, test plan complete
- [x] Version identity correct (bumped to 0.9.0-beta.1+1)
- [x] Rollback path documented
- [x] Real-device plan complete (`DEVICE_QA_MATRIX.md`)
- [ ] Available physical-device tests completed — **none available, zero
      executed**
- [x] Unavailable external tests explicitly listed (§30)

**Per this task's own rule: since real-device testing has not occurred at
all, classification is "GO WITH CAVEATS — LIMITED TECHNICAL BETA," not a
broad-rollout GO.**

## 34. Beta Exit Criteria (proposed, pending product/ops approval on thresholds)

- No open P0/P1.
- P2 trend stable or decreasing.
- Minimum beta duration and tester/session counts — **not set by this
  report; requires product/operations approval, placeholder only.**
- All 6 games exercised on at least one real device.
- Both online and offline flows exercised on a real device.
- Child switching exercised on a real device.
- Install and upgrade exercised on a real device.
- No confirmed cross-child, data-loss, or duplicate-reward issue.
- Crash rate and sync-failure rate below an agreed (not-yet-set)
  threshold.
- Feedback reviewed, rollback path confirmed still available.

## 35. Final Classification

**GO WITH CAVEATS — LIMITED TECHNICAL BETA.**

Not "GO — INTERNAL BETA" because zero physical-device testing has
occurred — per this task's own explicit rule, that caps the classification
at "limited technical beta," meaning: safe to hand to a very small,
technically sophisticated group who understand this hasn't been
device-tested, not safe to distribute broadly as a polished beta yet.

## 36. Merge Recommendation

**Blocked on PR #4 merging first.** PR #5 is based on PR #4's branch tip,
not `main`; merging PR #5 before PR #4 would either fail (wrong base) or
require re-basing once PR #4 lands. Recommendation: keep PR #5 in Draft
until PR #4 merges, then re-base PR #5 onto `main` and re-run CI (which
will then trigger automatically) before moving to Ready for Review.

## 37. Required Human Actions

1. Decide on and merge PR #4 (still the actual blocker for everything
   downstream, including this PR's base).
2. Re-base PR #5 onto `main` after PR #4 merges.
3. Obtain physical Android + iOS test devices before any real
   distribution.
4. Configure a real distribution channel and a release Android keystore.
5. Set the beta exit-criteria numeric thresholds (§34) — this report
   cannot set them unilaterally.
6. Configure a real tester feedback channel.
