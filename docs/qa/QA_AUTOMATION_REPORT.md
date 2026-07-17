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
| Production audio audit | `tools/production_audio_audit.py` | Fail release readiness until bundled audio is non-placeholder, reviewed, and approved |

## Files created

- `tools/content_validator/validate_content.py`
- `tools/level_validator/solve_levels.py`
- `tools/content_safety_audit.py`
- `tools/game_network_audit.py`
- `tools/production_audio_audit.py`

## Validation results

Run manually with:
```
python tools/content_validator/validate_content.py
python tools/level_validator/solve_levels.py
python tools/content_safety_audit.py --json
python tools/game_network_audit.py --json
python tools/production_audio_audit.py --json
```

Expected for development: content validation, level solver, content safety audit, and game network audit exit 0.
Expected for current release readiness: production audio audit exits 1 until
placeholder WAVs are replaced with reviewed recordings.

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
```

CI must fail if any content or safety gate returns exit code 1.

## Coverage

| Validator | Games covered |
|-----------|--------------|
| Content validator | All 6 MVP games plus audio placeholder manifest |
| Content validator unit tests | `tests/test_content_validator_tool.py` has 20 tests covering base level rules, card pairs, game-specific content, Robot Commands path simulation, game-file JSON failures, audio-key collection, and audio placeholder checks |
| Level solver | All 6 MVP games: Word Builder letter construction, Sound Match answer/options, math choice uniqueness, Memory Cards pairs, Robot Commands BFS reachability |
| Content safety audit | All 6 MVP level JSON files; 1,904 authored strings plus pressure metadata such as `timeLimitSec` |
| Game network audit | All 6 child-facing game source directories under `apps/mobile/lib/src/games`; 6 Dart files scanned, 0 findings |
| Production audio audit | All bundled audio assets in `apps/mobile/assets/audio/audio_manifest.json` |
| MI Blocks unit tests | `packages/mi_blocks` has 22 tests covering command names, block JSON, tree validation, direction math, grid walkability, interpreter movement, repeats, conditionals, collection, goal checks, and runaway-program protection |
| Game content package tests | `packages/mi_game_content` has 16 tests covering Dart-side level validation, duplicate IDs, loader parsing, provider caching, and invalid-content rejection |
| Game audio unit tests | `packages/mi_game_audio` has 16 tests covering playback groups, ducking, muting, slow speech, cache, stop-all, persisted audio prefs, and metadata serialization |
| Game progress unit tests | `packages/mi_game_progress` has 15 tests covering attempt persistence, mastery scoring, difficulty recommendation, spaced recall, tracker persistence, and mastered-skill listing |
| Offline sync unit tests | `packages/offline_sync` has 5 tests covering Hive-backed queue persistence, privacy-safe payloads, offline retention, FIFO online flush, retry retention without deleting local data, and sync type wire mapping |
| Shared game UI widget/golden tests | `packages/mi_game_ui` has 20 tests covering shared game header, hint, retry, completion, offline indicator, feedback, progress, audio toggle, pause overlay, exit confirmation, tutorial overlay, loading/error states, and 8 visual golden baselines |
| Mobile widget/golden/save-restore tests | `apps/mobile` has 40 tests covering exploration hub, child profile/rewards summary, parent entry/report/settings path, six MVP game smoke paths, six game-slice golden baselines, all-six completion paths, gentle retry/hint interactions, Memory Cards privacy-safe offline snapshot save/restore, Word Builder/Sound Match/Math Race/Math Supermarket privacy-safe session snapshot roundtrips, Robot command editing, parent PIN, and parent settings persistence/export/delete |
| Backend parent-data tests | Parent report summary, weekly report entries, privacy-safe export, and child-data deletion cascade across sessions, progress, attempts, and child rewards; full Python suite currently passes at `91 passed` |

## Blockers

- Production audio audit currently fails by design because 18 assets are silent placeholders

## Risks

- Validators are Python; game runs on Dart. Content is validated pre-build, which
  is the correct gate point. Dart-side `ContentValidator` (in mi_game_content)
  provides runtime validation as second layer.

## Next actions

1. Run `tools/production_audio_audit.py` as a required release gate after production recordings land
2. Add runtime/device-level proof for offline play and save/restore
3. Add Robot Commands save/restore coverage and real backend/device offline-sync verification
