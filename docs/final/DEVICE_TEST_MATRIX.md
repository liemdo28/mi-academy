# Device Test Matrix

Date: 2026-07-24

## Verified Locally

| Surface | Evidence | Status |
|---------|----------|--------|
| Home phone Vietnamese | `apps/mobile/test/goldens/home_phone_vi.png` | Pass |
| Home phone English | `apps/mobile/test/goldens/home_phone_en.png` | Pass |
| Home tablet Vietnamese | `apps/mobile/test/goldens/home_tablet_vi.png` | Pass |
| Home tablet English | `apps/mobile/test/goldens/home_tablet_en.png` | Pass |
| Flutter widget/golden suite | 192 passed, 6 skipped on Windows | Pass |
| Web release build | `apps/mobile/build/web` | Pass |
| Android APK release build | `build/app/outputs/flutter-apk/app-release.apk` | Pass |
| Android AAB release build | `build/app/outputs/bundle/release/app-release.aab` | Pass |
| Local browser smoke | Shell routes and all 30 game routes | Pass |
| Cloudflare browser smoke | `https://2fa44f54.mi-academy.pages.dev` shell routes and all 30 game routes | Pass |

## Still Needed Before Public Release

- Android physical-device or emulator playthrough across all 30 games.
- iOS Simulator/device build and smoke test on macOS.
- Accessibility pass with large text, reduced motion, screen reader, and high contrast.
- Deeper family playthrough sessions with real children/parents after deployment.
