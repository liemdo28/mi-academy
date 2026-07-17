# MI Academy - Release Evidence Ledger

> **Generated:** 2026-07-17
> **Status:** blocked

This ledger summarizes automated local evidence and the remaining proof required before release. It does not replace manual QA, real-device testing, deployed API verification, or remote CI evidence.

## Local Automated Gates

| Gate | Status | Source | Summary |
|------|--------|--------|---------|
| Content validation | pass | `python.exe tools/content_validator/validate_content.py` | All bundled MVP content and placeholder audio references are valid. |
| Level solvability | pass | `python.exe tools/level_validator/solve_levels.py` | All six MVP game level sets are solvable. |
| Content safety audit | pass | `tools/content_safety_audit.py --json` | 6 files, 1879 strings, 0 failures, 0 warnings. |
| Game offline-only audit | pass | `tools/game_network_audit.py --json` | 10 game Dart files, 0 failures. |
| Static child-safety audit | pass | `tools/child_safety_audit.py --json` | 32 files, 0 failures, 2 expected warnings. |
| Mobile platform privacy audit | pass | `tools/mobile_platform_privacy_audit.py --json` | 8 files, 0 failures, 2 debug/profile Internet warnings. |
| Child-safety pre-signoff | pass | `tools/child_safety_signoff.py --json` | 6 MVP games have automated pass evidence; 6 manual game reviews remain pending. |
| Artifact-size baseline | pass | `tools/performance_baseline.py --json` | Android debug APK 147.98 MiB; web build 34.98 MiB. |
| Production audio audit | blocked | `tools/production_audio_audit.py --json` | 18 assets, 18 placeholders, 0 approved, 72 failures. |

## Pending External Evidence

| Gate | Status | Evidence required |
|------|--------|-------------------|
| Manual per-game child-safety sign-off | pending | Completed human checklist for all six MVP games on a real device or emulator, attached to the release PR. |
| Real device/emulator smoke test | pending | Recorded Android/iOS run covering app launch, all six MVP games, parent gate, offline mode, and no child-facing network requirement. |
| Runtime performance proof | pending | Device or emulator measurements for cold start, game load, frame timing, memory, save latency, and restore latency. |
| Deployed parent API verification | pending | Live API proof for parent reports, weekly report, privacy-safe export, and child-data deletion. |
| Deployed backend/device offline sync | pending | A real queued offline play session syncing progress, attempts, and session summaries to a deployed backend. |
| Real-device accessibility audit | pending | Screen reader, touch target, reduced motion, contrast, subtitle, and non-drag alternative checks on target devices. |
| Remote GitHub Actions release workflow | pending | Successful remote workflow run URL including content/safety gates, Python tests, mobile builds, artifacts, and iOS no-codesign build. |

## Release Blockers

- Production audio audit: 18 assets, 18 placeholders, 0 approved, 72 failures.
- Manual per-game child-safety sign-off: Evidence not present in the local workspace.
- Real device/emulator smoke test: Evidence not present in the local workspace.
- Runtime performance proof: Evidence not present in the local workspace.
- Deployed parent API verification: Evidence not present in the local workspace.
- Deployed backend/device offline sync: Evidence not present in the local workspace.
- Real-device accessibility audit: Evidence not present in the local workspace.
- Remote GitHub Actions release workflow: Evidence not present in the local workspace.
