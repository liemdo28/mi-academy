# MI Academy — QA Automation Report

> **Date:** 2026-07-17
> **Owner:** Dev 3

---

## Scope

QA automation infrastructure created in this sprint.

## Completed work

| Tool | Path | Purpose |
|------|------|---------|
| Content validator | `tools/content_validator/validate_content.py` | Validate all game content JSON, schema, skill refs, localization, card pairs |
| Level solver | `tools/level_validator/solve_levels.py` | Verify every MVP level is solvable across Word Builder, Sound Match, Math Race, Math Supermarket, Memory Cards, and Robot Commands |
| Content safety audit | `tools/content_safety_audit.py` | Scan authored level text and metadata for external links, social language, purchase language, harsh feedback, privacy requests, and countdown pressure |
| Game network audit | `tools/game_network_audit.py` | Fail if child-facing game code imports networking/link/webview packages, embeds URLs, or creates outbound clients |
| Mobile platform privacy audit | `tools/mobile_platform_privacy_audit.py` | Fail if Android/iOS manifests or dependency files include sensitive permissions, tracking prompts, ad SDKs, IAP SDKs, social SDKs, or release Internet permission |
| Child-safety pre-signoff | `tools/child_safety_signoff.py` | Generate per-game automated safety evidence while keeping manual release sign-off pending |
| Release evidence ledger | `tools/release_evidence.py` | Aggregate local gates and explicit pending external proof into a blocking release-readiness ledger |
| Production audio audit | `tools/production_audio_audit.py` | Fail release readiness until bundled audio is non-placeholder, reviewed, and approved |

## Files created

- `tools/content_validator/validate_content.py`
- `tools/level_validator/solve_levels.py`
- `tools/content_safety_audit.py`
- `tools/game_network_audit.py`
- `tools/mobile_platform_privacy_audit.py`
- `tools/child_safety_signoff.py`
- `tools/release_evidence.py`
- `tools/production_audio_audit.py`

## Validation results

Run manually with:
```
python tools/content_validator/validate_content.py
python tools/level_validator/solve_levels.py
python tools/content_safety_audit.py --json
python tools/game_network_audit.py --json
python tools/mobile_platform_privacy_audit.py --json
python tools/child_safety_signoff.py --json
python tools/release_evidence.py --write --json
python tools/production_audio_audit.py --json
```

Expected for development: content validation, level solver, content safety audit, game network audit, mobile platform privacy audit, and child-safety pre-signoff exit 0.
Expected for current release readiness: release evidence and production audio
audits exit 1 until production audio plus manual/device/deployed/remote CI proof
are complete.

## CI integration (recommended)

Add to CI pipeline before build:
```yaml
- name: Content validation
  run: python tools/content_validator/validate_content.py
- name: Level solver
  run: python tools/level_validator/solve_levels.py
- name: Content safety audit
  run: python tools/content_safety_audit.py --json
- name: Game network audit
  run: python tools/game_network_audit.py --json
- name: Mobile platform privacy audit
  run: python tools/mobile_platform_privacy_audit.py --json
- name: Child-safety pre-signoff
  run: python tools/child_safety_signoff.py --json
```

CI must fail if any content or safety gate returns exit code 1.

## Coverage

| Validator | Games covered |
|-----------|--------------|
| Content validator | All 6 MVP games plus audio placeholder manifest |
| Content validator unit tests | `tests/test_content_validator_tool.py` has 20 tests covering base level rules, card pairs, game-specific content, Robot Commands path simulation, game-file JSON failures, audio-key collection, and audio placeholder checks |
| Level solver | All 6 MVP games: Word Builder letter construction, Sound Match answer/options, math choice uniqueness, Memory Cards pairs, Robot Commands BFS reachability |
| Content safety audit | All 6 MVP level JSON files; 1,889 authored strings plus pressure metadata such as `timeLimitSec` |
| Game network audit | All 6 child-facing game source directories under `apps/mobile/lib/src/games`; 10 Dart files scanned, 0 findings |
| Mobile platform privacy audit | Android/iOS manifests, Flutter dependency files, and Gradle files; 8 files scanned, 0 failures, 2 expected debug/profile Internet warnings |
| Child-safety pre-signoff | Six MVP games, 10 categories each; automated status passes for every game, manual status remains pending |
| Release evidence ledger | Local automated gates plus pending external/manual proof; current ledger status is `blocked`, with production audio and external release proof still open |
| Production audio audit | All bundled audio assets in `apps/mobile/assets/audio/audio_manifest.json` |
| MI Blocks unit tests | `packages/mi_blocks` has 22 tests covering command names, block JSON, tree validation, direction math, grid walkability, interpreter movement, repeats, conditionals, collection, goal checks, and runaway-program protection |
| Game content package tests | `packages/mi_game_content` has 16 tests covering Dart-side level validation, duplicate IDs, loader parsing, provider caching, and invalid-content rejection |
| Game audio unit tests | `packages/mi_game_audio` has 16 tests covering playback groups, ducking, muting, slow speech, cache, stop-all, persisted audio prefs, and metadata serialization |
| Game progress unit tests | `packages/mi_game_progress` has 15 tests covering attempt persistence, mastery scoring, difficulty recommendation, spaced recall, tracker persistence, and mastered-skill listing |
| Offline sync unit tests | `packages/offline_sync` has 5 tests covering Hive-backed queue persistence, privacy-safe payloads, offline retention, FIFO online flush, retry retention without deleting local data, and sync type wire mapping |
| Shared game UI widget/golden tests | `packages/mi_game_ui` has 20 tests covering shared game header, hint, retry, completion, offline indicator, feedback, progress, audio toggle, pause overlay, exit confirmation, tutorial overlay, loading/error states, and 8 visual golden baselines |
| Mobile widget/golden/save-restore/sync tests | `apps/mobile` has 47 tests covering exploration hub, child profile/rewards summary, parent entry/report/settings path, six MVP game smoke paths, six game-slice golden baselines, all-six completion paths, gentle retry/hint interactions, privacy-safe offline snapshot save/restore for all six MVP game slices, mobile queue-to-API sync adapter routing for progress/attempt/session-end items, Robot command editing, parent PIN, and parent settings persistence/export/delete |
| Backend parent/sync-data tests | Parent report summary, weekly report entries, privacy-safe export, child-data deletion cascade, progress sync upsert, idempotent attempt sync, valid JSON answer persistence, and daily session sync upsert; full Python suite currently passes at `112 passed` |

## Blockers

- Production audio audit currently fails by design because 18 assets are silent placeholders

## Risks

- Validators are Python; game runs on Dart. Content is validated pre-build, which
  is the correct gate point. Dart-side `ContentValidator` (in mi_game_content)
  provides runtime validation as second layer.

## Next actions

1. Run `tools/production_audio_audit.py` as a required release gate after production recordings land
2. Add runtime/device-level proof for offline play and save/restore
3. Add deployed backend/device offline-sync verification
