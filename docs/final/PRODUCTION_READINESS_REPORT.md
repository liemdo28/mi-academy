# MI Academy Production Readiness Report

Date: 2026-07-24
Branch: `integration/m1-m2-baseline`

## Verdict

**Family-test ready; not final public store release ready.**

The app now has 30 of 30 target games registered, bundled bilingual level
content, validated brand assets, passing local analyzer/tests, and local
web/APK/AAB release builds. The remaining blockers are not code-count
blockers: they are release-governance gates that need human QA, full UI
localization cleanup, real-device evidence, and final brand/content approval.

Live family-test preview: https://2fa44f54.mi-academy.pages.dev

## Verified Scope

- 30 registered playable games.
- 1030 bundled production levels.
- 37 required production brand source assets present and accepted by the strict validator.
- Home Screen phone/tablet Vietnamese/English golden previews exist.
- Android release signing configuration exists.

## Command Battery

| Gate | Result |
|------|--------|
| `dart format --set-exit-if-changed apps\mobile packages tools tests` | Pass, 320 files checked, 0 changed after cleanup |
| `python -m ruff format --check .` | Pass, 97 files already formatted |
| `python -m ruff check .` | Pass |
| `python -m mypy .` | Pass, 102 source files |
| `python -m pytest packages\game_core\tests tests test -q` | Pass, 177 passed |
| `flutter analyze` in `apps/mobile` | Pass, no issues |
| `flutter test --reporter compact` in `apps/mobile` | Pass, 192 passed, 6 skipped platform-limited golden tests |
| `flutter build web --release --no-pub --pwa-strategy=none` | Pass, built `apps/mobile/build/web` |
| `flutter build apk --release` | Pass, built `app-release.apk` 57.1 MB |
| `flutter build appbundle --release` | Pass, built `app-release.aab` 44.5 MB |
| `python tools/content_validator/validate_content.py` | Pass |
| `python tools/content_schema_validator.py --json` | Pass |
| `python tools/content_schema_validator.py --check-malformed --json` | Pass |
| `python tools/level_validator/solve_levels.py` | Pass for deterministic solver coverage |
| `python tools/content_safety_audit.py --json` | Pass, 30 files, 31264 strings, 0 findings |
| `python tools/game_network_audit.py --json` | Pass, 15 scanned files, 0 findings |
| `python tools/child_safety_audit.py --json` | Pass with 2 expected network dependency warnings |
| `python tools/mobile_platform_privacy_audit.py --json` | Pass with 2 expected debug/profile INTERNET warnings |
| `python tools/localization_audit.py --json` | ARB parity pass, hardcoded scan warning remains |
| `dart run tools/validate_brand_assets.dart --strict` | Pass, production asset gate ready |
| `tools/check_android_release_signing.ps1` | Pass, signing config exists |
| Local Playwright smoke against `http://127.0.0.1:8787` | Pass, shell routes and all 30 game routes rendered |
| Live Playwright smoke against Cloudflare Pages | Pass, shell routes and all 30 game routes rendered |

## Open Release Gates

- Manual child-safety/device QA signoff.
- Full hardcoded UI-string localization cleanup.
- First localization cleanup pass reduced hardcoded mobile findings from 379 to 211 while keeping ARB parity green.
- Human brand ownership/licensing approval.
- iOS build/signing/device verification on macOS.
- Store policy submission review if publishing beyond family testing.
