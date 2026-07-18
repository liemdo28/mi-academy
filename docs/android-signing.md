# Android release signing

## Current state (verified 2026-07-18)

- `apps/mobile/android/app/build.gradle.kts` supports optional release
  signing via `android/key.properties` (gitignored, never committed —
  confirmed via `apps/mobile/android/.gitignore`: `key.properties`,
  `**/*.keystore`, `**/*.jks`).
- If `key.properties` is absent, `flutter build apk --release` /
  `flutter build appbundle --release` fall back to the debug signing key so
  local/dev release builds keep working. Verified: `flutter build apk
  --release` succeeds with no `key.properties` present, producing
  `app-release.apk` (debug-signed).
- A `-PrequireReleaseSigning=true` Gradle property fails the build clearly
  when release signing is explicitly requested but `key.properties` is
  missing, instead of silently falling back to the debug key. Verified
  directly:
  ```
  $ ./gradlew.bat :app:assembleRelease -PrequireReleaseSigning=true
  FAILURE: Build failed with an exception.
  * Where: Build file '...build.gradle.kts' line: 76
  * What went wrong:
  requireReleaseSigning=true was set but android/key.properties is
  missing. Generate it from android/key.properties.example (see
  docs/android-signing.md) or supply the signing secrets this CI job
  expects before requesting a production-signed build.
  ```
  Without the flag, the same command succeeds using the debug-key fallback.
- `.github/workflows/ci.yml`'s `android-release-signing` job already builds
  a real production-signed AAB when the `ANDROID_KEYSTORE_BASE64` secret is
  configured — this is not hypothetical: the most recent CI runs on this
  branch show that job with conclusion `success`, meaning the secret-backed
  signed build path is live and proven, not just documented.

## Application ID — resolved (Milestone 1B, 2026-07-18)

~~`applicationId`/`namespace` were still the Flutter scaffold default~~
**Fixed**: both are now `com.liemteam.miacademy` (Android
`apps/mobile/android/app/build.gradle.kts`, iOS
`PRODUCT_BUNDLE_IDENTIFIER` in `Runner.xcodeproj/project.pbxproj`), no
longer `com.example.*`. Verified directly against the built artifact:
`aapt dump badging app-release.apk` reports
`package: name='com.liemteam.miacademy' versionCode='2' versionName='0.9.0-beta.2'`.
See `docs/release-audit.md` RA-21. If this package name is not the org's
final intended one, it can still be changed freely up until the first real
Play Console upload — after that, it's permanent.

## Generating an upload keystore

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Store the resulting `.jks` file and its passwords somewhere secure (a
password manager or secrets vault) — never in the repository. Then create
`apps/mobile/android/key.properties` from
`apps/mobile/android/key.properties.example`, filling in the real
`storeFile` path and passwords.

## Play App Signing

Upload the keystore above as your **upload key** when you create the app
in Play Console and enable Play App Signing. Google then re-signs your
uploaded AAB with its own **app signing key** before distributing it to
devices — you keep the upload key for future uploads, but Google (not you)
holds the key that actually signs what end users install. This means:

- Losing the upload key is recoverable (Google has an upload-key-reset
  process); losing the app signing key without Play App Signing enabled is
  not.
- The keystore generated above is the *upload* key, not the final signing
  key — this repo/CI never needs to hold Google's app signing key.

## CI secret names

`.github/workflows/ci.yml`'s `android-release-signing` job expects these
repository secrets (already configured for this repo, per the green CI
runs referenced above):

| Secret | Purpose |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | The upload keystore `.jks` file, base64-encoded |
| `ANDROID_KEYSTORE_PASSWORD` | `storePassword` |
| `ANDROID_KEY_ALIAS` | `keyAlias` (e.g. `upload`) |
| `ANDROID_KEY_PASSWORD` | `keyPassword` |

The job decodes `ANDROID_KEYSTORE_BASE64` to `android/app/release.jks` and
writes `android/key.properties` from the other three secrets at CI time —
neither the decoded keystore nor `key.properties` is ever committed; both
exist only in the ephemeral CI runner's filesystem.

## Verifying a signed artifact locally

To confirm which key actually signed a built APK/AAB (useful after any
signing-config change, or before manually uploading to Play Console):

```bash
# For an APK:
apksigner verify --print-certs app-release.apk

# For an AAB (bundletool required):
java -jar bundletool.jar validate --bundle=app-release.aab
```

Compare the printed certificate fingerprint (SHA-256) against your known
upload-key fingerprint (`keytool -list -v -keystore upload-keystore.jks`).

## Confirmed: no localhost/debug endpoints in release builds

Verified via `grep -rn "localhost\|127\.0\.0\.1\|http://" apps/mobile/lib
--include=*.dart` (excluding test files) → no matches. The app's API base
URL is configurable, not hardcoded to a local/debug endpoint.
