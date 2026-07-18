# Mobile Release Pipeline — Status Report

**Author:** Dev 6 (DevOps, Security & Reliability Lead)
**Date:** 2026-07-17
**Status:** Android release-signing scaffold added and structurally sound; not yet exercised with real credentials. iOS release signing is not yet implemented — documented gap, not a silent one.

## Android

**What exists now:**
- `apps/mobile/android/app/build.gradle.kts` reads an optional `key.properties` file (repo-root of the Flutter project, gitignored, never committed) to configure release signing. If the file is absent — true for every local dev machine and every CI run today — release builds fall back to the debug signing key exactly as before, so this change is non-breaking to the existing `flutter build apk --debug` CI step.
- A new CI job, `android-release-signing` in `.github/workflows/ci.yml`, is gated on the `ANDROID_KEYSTORE_BASE64` repo secret being set (`if: ${{ secrets.ANDROID_KEYSTORE_BASE64 != '' }}`). Until that secret exists, the job simply doesn't run — it costs nothing and breaks nothing.
- When configured, the job decodes a base64-encoded keystore into a file, writes `key.properties` from three more secrets (`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`), builds a signed `.aab` via `flutter build appbundle --release`, uploads the bundle plus its ProGuard/R8 mapping file as a workflow artifact, then deletes the decoded keystore file regardless of build outcome.
- Secret names and ownership are recorded in [SECRET_INVENTORY.md](../security/SECRET_INVENTORY.md).

**What does NOT exist yet:**
- No actual keystore has been generated or provisioned — this is scaffolding only, verified by YAML syntax validation and by confirming the debug-fallback path is unaffected. It has **not** been exercised end-to-end because doing so requires a real Android signing keystore, which nobody should generate casually inside an agent session.
- No automated Play Store upload (`fastlane supply` or the Play Developer API) — the job stops at producing a signed artifact for manual upload.
- No internal-testing-track automation.
- ~~`applicationId = "com.example.mi_academy"`~~ **Resolved** (Milestone 1B): `applicationId`/`namespace` is now `com.liemteam.miacademy` (Android) and `PRODUCT_BUNDLE_IDENTIFIER` is `com.liemteam.miacademy` (iOS) — see `docs/release-audit.md` RA-21 and `docs/android-signing.md`.

## iOS

**What exists now:** the pre-existing CI step (`flutter build ios --debug --no-codesign`) — unsigned, debug-only, unchanged by this work.

**What does NOT exist yet, and why it wasn't attempted here:**
- No distribution certificate, no provisioning profile, no App Store Connect API key.
- Proper iOS release automation typically needs `fastlane match` (or equivalent) to manage certificates across machines/CI, which is a meaningfully larger setup (a separate certificates repo or storage, Apple Developer Portal access, App Store Connect API key management) than the Android keystore-as-a-secret pattern above. Scaffolding this without a real Apple Developer account to test against would produce untested, unverifiable YAML — not something to hand off as "done." This is deferred as an explicit, tracked gap rather than a guessed implementation.

**Recommended next step:** once an Apple Developer account and App Store Connect API key exist, add a `fastlane` setup under `apps/mobile/ios/fastlane/` with a `match` lane for certificate management and a `beta` lane for TestFlight upload, wired into a new gated CI job following the same secret-presence pattern used for Android.

## Web

Unchanged by this work — see [DEPLOYMENT_PIPELINE_AUDIT.md](DEPLOYMENT_PIPELINE_AUDIT.md) §5 for the existing gaps (no CDN deploy, no cache-busting/versioning, no CSP).
