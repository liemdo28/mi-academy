# MI Academy — Release Readiness Baseline

> **Date:** 2026-07-17
> **Owner:** Dev 3

---

## Current state (Foundation Sprint complete)

| Component | Status | Notes |
|-----------|--------|-------|
| Flutter app shell | ✅ | `apps/mobile/` with exploration hub, child profile/reward summary, parent-area entry point, six MVP game entries, generated Android/iOS/web scaffolds |
| Word Builder game | ✅ | 10 validated levels, playable Flutter vertical slice, hints/retry/completion loop |
| Sound Match game | ⚠️ | 10 validated levels, playable Flutter vertical slice; uses placeholder/transcript audio behavior until production recordings land |
| Math Race game | ✅ | 10 validated levels, playable Flutter vertical slice, non-punitive choice loop |
| Math Supermarket game | ✅ | 10 validated levels, playable Flutter vertical slice, money/math choice loop |
| Memory Cards game | ✅ | 10 levels, full UI, full pair-completion coverage, privacy-safe offline snapshot save/restore coverage |
| Robot Commands game | ⚠️ | 10 validated levels, playable Flutter command-sequencing slice using `mi_blocks`; command editor now supports move/remove/reset/retry interactions and game-slice golden coverage, but still needs device/integration proof |
| Skill taxonomy | ✅ | 62 skills, 5 subjects |
| Curriculum map | ✅ | 3 age groups, documented |
| Content validator | ✅ | Python tool covers all six MVP game files and audio placeholders/manifest |
| Level solver | ✅ | `python tools/level_validator/solve_levels.py` verifies all six MVP games: 10/10 levels solvable for each game |
| Content safety audit | ✅ | `python tools/content_safety_audit.py --json` passes across all six MVP level files: 1,904 strings scanned, 0 failures, 0 warnings; Math Race countdown metadata is disabled |
| Game network audit | ✅ | `python tools/game_network_audit.py --json` passes across 6 child-facing game Dart files: 0 outbound network/link/webview findings |
| Production audio audit | ❌ | `python tools/production_audio_audit.py --json` fails as expected: 18/18 bundled audio assets are silent placeholders, 0 approved |
| Child safety checklist | ✅ | 10-item checklist |
| Static child-safety audit | ⚠️ | `python tools/child_safety_audit.py --json` passes with 0 failures; 2 network/offline-review dependency warnings remain |
| Localization style guide | ✅ | vi/en rules, MI voice |
| QA test plan | ✅ | 7 test layers defined |
| Content validator unit tests | ✅ | `tests/test_content_validator_tool.py` has 20 passing tests for base level rules, game-specific content validation, Robot Commands path simulation, game-file JSON failures, audio key collection, and placeholder audio checks |
| Release scorecard | ✅ | 6 categories, 85/100 threshold |
| Open-source inventory | ✅ | 7 algorithm references documented |
| Asset manifest | ✅ | Structure defined, minimal assets |
| Monorepo dependency resolution | ✅ | Direct `flutter pub get` sweep passed across apps/packages; `melos` CLI not installed |
| Monorepo analyzer | ✅ | Direct `dart analyze` sweep passed across apps/packages |
| Package test sweep | ✅ | Direct `flutter test` sweep passed for packages with tests |
| Game content package tests | ✅ | `packages/mi_game_content` has 16 passing tests for Dart-side level validation, duplicate handling, loader parsing, provider caching, and invalid-content rejection |
| MI Blocks tests | ✅ | `packages/mi_blocks` has 22 passing tests for command names, block JSON, tree validation, direction math, grid walkability, interpreter movement, repeats, conditionals, collection, goal checks, runaway-program protection, and renderer compile compatibility |
| Game audio unit tests | ✅ | `packages/mi_game_audio` now has 16 passing tests for playback groups, ducking, muting, slow speech, cache, stop-all, persisted audio prefs, and metadata serialization |
| Game progress tests | ✅ | `packages/mi_game_progress` has 15 passing tests for attempt persistence, mastery scoring, difficulty recommendation, spaced recall, tracker persistence, and mastered-skill listing |
| Game accessibility tests | ✅ | `packages/mi_game_accessibility` has 17 passing tests for child-safe prefs, motion timing, semantic labels, and accessible button touch targets |
| Offline sync tests | ✅ | `packages/offline_sync` has 5 passing tests for Hive-backed queue persistence, privacy-safe payloads, offline retention, FIFO online flush, retry retention, and sync type wire mapping |
| Shared game UI widget/golden tests | ✅ | `packages/mi_game_ui` now has 20 tests: 12 behavior/widget tests plus 8 real-font golden baselines for completion, tutorial, pause, exit confirmation, retry, error, loading, and compact control states |
| Mobile web build | ✅ | `flutter build web --release` passed for `apps/mobile`; Wasm dry-run warnings remain for web plugin dependencies |
| Android debug build | ✅ | `flutter build apk --debug` passed and produced `build/app/outputs/flutter-apk/app-debug.apk` |
| Performance baseline | ⚠️ | Artifact-size baseline recorded in `docs/qa/PERFORMANCE_BASELINE_2026-07-17.md`; runtime FPS/memory/device performance still unmeasured |
| CI release gates | ⚠️ | `.github/workflows/ci.yml` now runs content validation, level solvability, content safety audit, game network audit, static child-safety audit, Python tests, mobile analyze/tests, web/APK builds, performance artifact baseline, and iOS no-codesign build; remote GitHub run proof still pending |
| Parent gate | ⚠️ | Parent PIN screen now supports 4-digit PIN entry, 3-attempt lockout, adult math fallback, biometric entry, shell entry point, and scroll-safe layout; backend/live auth and device verification still pending |
| Parent local report | ⚠️ | Offline-safe local parent summary shows gentle progress, skill strengths, practice suggestions, offline status, and settings access; backend weekly report is locally tested, but deployed API proof is still pending |
| Parent settings | ⚠️ | Daily time limit, language, sound/subtitle toggles, offline-content state, privacy-safe export state, guarded child-data delete confirmation, and local Hive-backed persistence are implemented and widget-tested; backend privacy-safe export endpoint is locally tested, but deployed API proof is still pending |
| Backend parent data flows | ⚠️ | FastAPI app imports cleanly; local async API tests verify parent reports/weekly summaries, privacy-safe export, and child deletion cascades through sessions, progress, attempts, and child rewards; deployed API proof still pending |
| Offline-first API default | ✅ | Mobile app no longer embeds a backend URL; parent/sync API access requires explicit `MI_ACADEMY_API_BASE_URL` build-time configuration |

## Blockers for Release 0.2

| Blocker | Owner | Status |
|---------|-------|--------|
| Flutter SDK installed | Dev 1 | ✅ verified with Flutter 3.41.6 |
| Audio assets created | Dev 3 | ❌ silent placeholder WAVs + manifest created; production recordings still needed and strict production audio audit currently fails |
| Word Builder content | Dev 3 | ✅ 10 starter levels, VI/EN, covered by content validator |
| Sound Match content | Dev 3 | ✅ 10 starter levels, VI/EN, covered by content/audio validator |
| Math Race content | Dev 3 | ✅ 10 starter levels, VI/EN, covered by content validator |
| Math Supermarket content | Dev 3 | ✅ 10 starter levels, VI/EN, covered by content validator |
| Robot Commands content | Dev 3 | ✅ 10 starter levels, VI/EN, covered by content validator and required-path simulation |
| Unit tests for mi_game_* | Dev 1 | ⚠️ package smoke/core tests, 22 block tests, 16 content tests, 16 audio unit tests, 15 progress tests, 17 accessibility tests, and 20 shared UI widget/golden tests pass; broader app integration coverage still needed |
| Mobile game widget/golden/save-restore tests | Dev 2 | ⚠️ hub + profile/reward/parent-entry coverage, local parent report coverage, six game render smoke coverage, six MVP game-slice golden baselines, completion-path smoke tests for all six MVP games, gentle retry/hint coverage for Word Builder, Sound Match, Math Race, Math Supermarket, and Robot Commands, privacy-safe offline snapshot save/restore coverage for Memory Cards plus Word Builder, Sound Match, Math Race, and Math Supermarket session state, Robot command-editor move/remove/reset/retry coverage, parent PIN lockout/adult-gate coverage, and parent settings offline/export/delete/persistence coverage; Robot Commands save/restore and device/runtime coverage still needed |
| Accessibility widget tests | Dev 3 | ✅ prefs + accessible button widget tests added |
| Mobile platform scaffolds | Dev 1 | ⚠️ Android/iOS/web scaffolds generated; Android debug APK and web release build pass; iOS build remains unproven on Windows |
| Child-safety automation | Dev 3 | ⚠️ Content safety audit passes with 0 findings and static mobile audit passes with 0 hard failures plus 2 expected network dependency warnings; manual per-game checklist/sign-off still required |

## Release 0.2 readiness estimate

Based on current completion: **~94%** toward release 0.2 gate criteria.

### Latest verification (2026-07-17)

- `python tools/content_validator/validate_content.py` — pass (`ALL CONTENT VALID`)
- `python tools/level_validator/solve_levels.py` — pass (`10/10` levels solvable for Word Builder, Sound Match, Math Race, Math Supermarket, Memory Cards, and Robot Commands)
- `python tools/content_safety_audit.py --json` — pass (`6` files scanned, `1,904` strings scanned, `0` failures, `0` warnings)
- `python tools/game_network_audit.py --json` — pass (`6` child-facing game Dart files scanned, `0` failures, `0` warnings)
- `python tools/production_audio_audit.py --json` — fail by design (`18` assets scanned, `18` placeholders, `0` approved, `72` failures)
- `python -m pytest packages/game_core/tests tests test -q` — pass (`91 passed`; includes content validator unit tests, parent report/weekly summary, privacy-safe export, and child-data deletion cascade tests)
- FastAPI import smoke — pass (`from apps.api.main import app`)
- `flutter analyze` in `packages/mi_blocks` — pass (`No issues found`)
- `flutter test` in `packages/mi_blocks` — pass (`22 tests passed`; covers command names, block JSON, tree validation, direction math, grid walkability, interpreter movement, repeats, conditionals, collection, goal checks, runaway-program protection, and renderer compile compatibility)
- `flutter analyze` in `packages/mi_game_content` — pass (`No issues found`)
- `flutter test` in `packages/mi_game_content` — pass (`16 tests passed`; covers validator errors, duplicate IDs, loader parsing, provider cache, and invalid-content rejection)
- `flutter analyze` in `packages/mi_game_audio` — pass (`No issues found`)
- `flutter test` in `packages/mi_game_audio` — pass (`16 tests passed`; covers playback groups, volume clamping/mute, settings updates, ducking, slow voice, stop-all, preload cache, audio prefs, and metadata)
- `flutter analyze` in `packages/mi_game_progress` — pass (`No issues found`)
- `flutter test` in `packages/mi_game_progress` — pass (`15 tests passed`; covers attempt persistence, mastery scoring, difficulty recommendation, spaced recall, tracker persistence, and mastered-skill listing)
- `flutter analyze` in `packages/offline_sync` — pass (`No issues found`)
- `flutter test` in `packages/offline_sync` — pass (`5 tests passed`; covers Hive-backed queue persistence, privacy-safe payloads, offline retention, FIFO online flush, retry retention without deleting local attempt data, and sync type wire mapping)
- `flutter test` in `packages/mi_game_accessibility` — pass (`17 tests passed`; covers child-safe accessibility prefs, reduced motion, semantic labels, and 48/64dp accessible buttons)
- `flutter test` in `packages/mi_game_ui` — pass (`20 tests passed`; covers shared game header, hint, retry, completion, offline indicator, feedback, progress, audio toggle, pause overlay, exit confirmation, tutorial overlay, loading/error states, and 8 visual golden baselines with real text/icon fonts)
- `flutter analyze` in `apps/mobile` — pass (`No issues found`)
- `flutter test` in `apps/mobile` — pass (`40 tests passed`; covers hub, profile/reward/parent-entry surface, local parent report/settings path, six MVP game render smoke tests, six MVP game-slice golden baselines, completion-path smoke tests for all six MVP games, gentle retry/hint coverage, Memory Cards privacy-safe offline snapshot save/restore, Word Builder/Sound Match/Math Race/Math Supermarket privacy-safe session snapshot roundtrips, Robot command-editor move/remove/reset/retry coverage, parent PIN lockout/adult-gate coverage, and parent settings offline/export/delete/persistence coverage)
- `flutter build web --release` in `apps/mobile` — pass (`Built build\web`); Wasm dry-run warnings remain for `flutter_secure_storage_web` and `audioplayers_web`
- `flutter build apk --debug` in `apps/mobile` — pass (`Built build\app\outputs\flutter-apk\app-debug.apk`)
- `python tools/performance_baseline.py --json` — pass (Android debug APK `147.98 MiB`, web build `34.98 MiB`)
- `python tools/child_safety_audit.py --json` — pass (0 failures, 2 network/offline-review dependency warnings)
- `.github/workflows/ci.yml` — configured locally with release gates; not yet verified by a remote GitHub Actions run

### What's done
- Platform foundation (8 packages)
- Word Builder playable vertical slice
- Sound Match playable vertical slice with placeholder/transcript audio behavior
- Math Race playable vertical slice
- Math Supermarket playable vertical slice
- Memory Cards vertical slice with full pair-completion widget coverage and privacy-safe offline snapshot restore proof
- Robot Commands 10-level vertical slice using native block interpreter, Material-icon grid markers, and command-editor move/remove/reset/retry interactions
- All docs & validation infrastructure
- MVP level solvability gate across all six games, wired into the local GitHub Actions workflow config
- Authored level content safety gate across all six MVP games, with Math Race countdown-pressure metadata disabled
- Python content-validator unit coverage for level structure, game-specific content, Robot Commands path simulation, audio-key collection, and audio placeholder checks
- Child-facing game code network audit proving current game screens do not contain outbound clients, links, webviews, or embedded URLs
- Strict production audio audit that blocks release while placeholder audio remains
- Skill taxonomy & curriculum
- Child safety framework
- Static child-safety/privacy audit automation with dated evidence
- Offline-first API default with no embedded backend URL; parent/sync backend access requires explicit build-time configuration
- GitHub Actions release-gate workflow configured for content, safety, tests, builds, and artifact baseline
- Parent PIN gate with 3-attempt lockout, adult math fallback, biometric entry path, and scroll-safe mobile layout
- Exploration shell profile/reward summary plus parent-area entry point
- Offline-safe local parent report with gentle progress wording and settings access
- Parent settings controls for time limit, language, audio/subtitles, offline content state, privacy-safe export state, guarded child-data deletion, and local Hive-backed persistence
- Backend parent-data tests for reports, weekly summaries, privacy-safe export, and deletion cleanup of child-owned rows
- `mi_blocks` unit coverage for Robot Commands command trees, interpreter movement, repeats, conditionals, collection, and runaway-program protection
- `mi_game_content` unit coverage for Dart-side level validation, loader parsing, provider caching, and invalid-content rejection
- `mi_game_audio` unit coverage for playback groups, volume controls, ducking, cache, stop-all, persisted preferences, and production-review metadata
- `mi_game_progress` unit coverage for attempt records, mastery scoring, difficulty recommendation, spaced recall, tracker persistence, and mastered-skill listing
- `offline_sync` queue coverage for privacy-safe local queue persistence, offline no-op retention, FIFO flush, retry retention, and sync type wire mapping
- `mi_game_accessibility` unit/widget coverage for child-safe accessibility prefs, reduced motion, semantic labels, and accessible touch targets
- Shared `mi_game_ui` widget and golden coverage for child-safe feedback, retry, hint, completion, offline, progress, header controls, audio toggle, pause overlay, exit confirmation, tutorial overlay, loading/error states, and visual baseline images
- Six MVP game-slice golden baselines for Word Builder, Sound Match, Math Race, Math Supermarket, Memory Cards, and Robot Commands
- Broader MVP game interaction coverage for gentle incomplete/wrong-answer recovery, hints, and Memory Cards full completion
- Memory Cards save/restore coverage proving a JSON-round-tripped offline snapshot can resume and finish the level without parent/email/token/raw-answer data
- Word Builder, Sound Match, Math Race, and Math Supermarket session save/restore coverage proving JSON-round-tripped offline snapshots can resume progress without parent/email/token/raw-answer data
- Android/iOS/web scaffolds, Android debug APK proof, and web release build proof for `apps/mobile`
- Artifact-size performance baseline for Android debug APK and web build

### What's remaining
- Production audio recordings to replace placeholder WAVs and make `tools/production_audio_audit.py` pass
- Runtime FPS/memory/cold-start performance measurement on device or emulator
- Manual per-game child-safety checklist and sign-off
- Deployed API verification for backend parent data flows, including report/export/delete
- Full accessibility audit on real device
- Remote GitHub Actions proof for the CI release-gate workflow, including iOS no-codesign build on macOS
- Robot Commands save/restore coverage and real backend/device offline-sync verification
- Real device/emulator smoke test for Android/iOS

## Recommended next sprint priorities

1. Install or activate `melos` CLI, then run `melos bootstrap`
2. Run the GitHub Actions release-gate workflow remotely and save the run URL/evidence
3. Complete manual per-game safety checklist and sign-off
4. Add Robot Commands save/restore coverage and real backend/device offline-sync verification
5. Replace silent placeholder WAV files with reviewed production audio
6. Expand parent/backend integration proof for report/export/delete flows
7. Run Android emulator/device smoke test with runtime performance capture
8. Run full QA loop before release 0.2
