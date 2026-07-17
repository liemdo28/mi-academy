# MI Academy Performance Baseline — 2026-07-17

## Scope

Local artifact-size baseline for the current MVP Flutter app. This is not a device runtime FPS/memory audit; it records build artifacts that exist on this Windows machine after verified web and Android builds.

## Commands

- `flutter build web --release` in `apps/mobile`
- `flutter build apk --debug` in `apps/mobile`
- `python tools/performance_baseline.py --json`

## Results

| Metric | Result | Threshold | Status |
|--------|--------|-----------|--------|
| Android debug APK | 147.98 MiB | Warn above 200 MiB | Pass |
| Web build directory | 34.98 MiB | Warn above 50 MiB | Pass |

## Largest Web Files

| File | Size |
|------|------|
| `apps/mobile/build/web/canvaskit/canvaskit.wasm` | 6.82 MiB |
| `apps/mobile/build/web/canvaskit/chromium/canvaskit.wasm` | 5.42 MiB |
| `apps/mobile/build/web/canvaskit/skwasm_heavy.wasm` | 4.90 MiB |
| `apps/mobile/build/web/canvaskit/skwasm.wasm` | 3.39 MiB |
| `apps/mobile/build/web/canvaskit/wimp.wasm` | 3.30 MiB |
| `apps/mobile/build/web/main.dart.js` | 2.12 MiB |

## Release Notes

- Current artifact sizes are within warning thresholds.
- Android measurement is a debug APK, not a release/AAB size.
- Web build still reports Wasm dry-run incompatibilities for `flutter_secure_storage_web` and `audioplayers_web`; this baseline measures the JavaScript web build output.
- Runtime FPS, memory, cold-start, and real-device touch/scroll performance are still unmeasured and remain release QA work.
