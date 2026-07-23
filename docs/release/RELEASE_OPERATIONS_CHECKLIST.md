# Mi Academy Release Operations Checklist

Last updated: 2026-07-23

## Local Build

Use:

```powershell
.\tools\build_release_artifacts.ps1
```

For a hard failure when Android signing is missing:

```powershell
.\tools\build_release_artifacts.ps1 -RequireSignedAndroid
```

The script runs Flutter's Android config-only workaround before release builds so `integration_test` does not leak into the release plugin registrant.

## Android Signing

Local upload keystore files are gitignored:

- `apps/mobile/android/upload-keystore.jks`
- `apps/mobile/android/key.properties`

Check local signing config:

```powershell
.\tools\check_android_release_signing.ps1
```

Back up the keystore and passwords outside the repo. Losing the upload key can block future app updates unless Play App Signing upload-key reset is available.

## Store Metadata

Draft files:

- `docs/store/GOOGLE_PLAY_LISTING.md`
- `docs/store/PRIVACY_POLICY.md`
- `docs/store/VISUAL_ASSET_APPROVAL_CHECKLIST.md`

Before submission:

- Publish privacy policy to a stable public URL.
- Choose final screenshots and feature graphic.
- Complete Play Console Data Safety form from `docs/child-safety/PRIVACY_DATA_MAP.md`.
- Confirm target age and families policy answers.

## Web

JavaScript Web build passes. WebAssembly currently does not compile because transitive web plugins import unsupported browser interop libraries:

- `flutter_secure_storage_web`
- `audioplayers_web`

Flutter's Wasm guidance requires dependencies to avoid `dart:html`, `dart:js`, and `package:js`.

## iOS

Requires macOS and Xcode. This Windows machine cannot produce or sign iOS builds.
