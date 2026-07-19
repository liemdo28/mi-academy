# Milestone 2 Completion Report

Date: 2026-07-19
Branch: `integration/m2-games-15-complete`

## Executive Summary

Verdict: **Games 9-15 Conditional — Milestone 2 Conditional**

Milestone 2 now has Games 1-15 registered, launchable, content-backed,
backend-cataloged, and covered by local validation. Engineering completion
remains conditional until final branch CI, Android emulator integration,
fresh release artifacts, and qualified human educational review are complete.

## New Game Matrix

| Game ID | Content | Tiers | Engine | Age bands | Skills | Tests | Status |
|---|---:|---:|---|---|---|---|---|
| `alphabet_explorer` | 95 bilingual levels | 3 | Choice | junior, explorer | uppercase, lowercase, case matching, initial sound, vocabulary | content, registry, launcher, full mobile suite | Built in this slice |
| `missing_letter` | 75 bilingual levels | 3 | Choice | junior, explorer | lowercase recognition, spelling, vocabulary, initial sound | content, registry, launcher, full mobile suite | Built in slice 2 |
| `category_collector` | 60 bilingual levels | 3 | Multi-select | junior, explorer, master | classification, vocabulary | content, registry, backend | Built, human review pending |
| `pattern_parade` | 60 bilingual levels | 3 | Sequence | junior, explorer, master | patterns | content, registry, backend | Built, human review pending |
| `shape_builder` | 45 bilingual levels | 3 | Placement | junior, explorer, master | shapes, spatial reasoning | content, registry, backend | Built, human review pending |
| `word_sorter` | 60 bilingual levels | 3 | Placement | junior, explorer, master | vocabulary, initial sound | content, registry, backend | Built, human review pending |
| `number_balance` | 60 bilingual levels | 3 | Matching | junior, explorer, master | arithmetic equivalence | content, registry, backend | Built, human review pending |
| `logic_detective` | 45 bilingual levels | 3 | Multi-select | explorer, master | conditions, algorithms | content, registry, backend | Built, human review pending |
| `story_steps` | 45 bilingual levels | 3 | Sequence | junior, explorer, master | reading, sequencing | content, registry, backend | Built, human review pending |

## Command Results

| Directory | Command | Result |
|---|---|---|
| `apps/mobile` | `flutter analyze` | PASS, 0 issues |
| `apps/mobile` | `flutter test` | PASS, 123 passed, 6 Windows-only golden skips |
| `apps/mobile` | `flutter test test/missing_letter_content_test.dart test/game_registry_test.dart test/game_screen_test.dart test/widget_test.dart` | PASS, 54 passed |
| `apps/mobile` | `flutter build apk --release` | PASS, built `build/app/outputs/flutter-apk/app-release.apk` |
| `apps/mobile` | `flutter build appbundle --release` | PASS, built `build/app/outputs/bundle/release/app-release.aab` |
| `apps/mobile` | `flutter test integration_test` | NOT RUN locally: no Android/iOS device connected; final Android-emulator CI pending for Games 9-15 |
| repo root | `python tools/content_schema_validator.py` | PASS |
| repo root | `python tools/content_schema_validator.py --check-malformed` | PASS, 13 malformed fixtures checked |
| repo root | `python tools/content_safety_audit.py --json` | PASS, 15 files and 36154 strings scanned, 0 findings |
| repo root | `python tools/localization_audit.py` | PASS for ARB parity, 67 EN / 67 VI keys; WARN for existing hardcoded Vietnamese UI strings |
| repo root | `python -m ruff check .` | PASS |
| repo root | `python -m pytest packages/game_core/tests tests test -q` | PASS, 187 passed |
| repo root | `python -m ruff format --check .` | PASS after targeted generator formatting |
| repo root | `python -m mypy .` | PASS after resolving `math_race_generator.py` tuple-key inference |
| `apps/api` + Postgres/Redis | Alembic upgrade path | Local migration tests pass for `b4f7c2d9e801` and `c9f1a7b2d615`; final Postgres CI evidence pending |

## Missing Letter Content Matrix

| Locale | Tier 1 | Tier 2 | Tier 3 | Total |
|---|---:|---:|---:|---:|
| VI | 25 | 25 | 25 | 75 |
| EN | 25 | 25 | 25 | 75 |

- Unique target words: 75 VI, 75 EN.
- Missing-letter distribution: 50 one-letter items, 25 two-letter items.
- Image cues: 0; all items have text/category and phonics cues.
- Duplicate logical questions: 0 VI, 0 EN.
- Ambiguous malformed items rejected by validator fixtures.
- Vietnamese extended-letter coverage includes `đ`, `ư`, and `ơ`.
- Tier 3 is materially harder than Tier 1 by average word length, missing-letter count, choice count, and distractor similarity assertions in `missing_letter_content_test.dart`.

## Backend Support

The backend catalog now includes Games 1-15, including `alphabet_explorer`,
`missing_letter`, `category_collector`, `pattern_parade`, `shape_builder`,
`word_sorter`, `number_balance`, `logic_detective`, and `story_steps`.
Fresh/upgraded database behavior is covered by the Games 7-8 and Games 9-15
seed migrations plus `tests/test_backend_game_catalog.py`; result saving,
progress aggregation, and idempotency are covered by
`tests/test_api_game_result.py`.

## Release Artifact Evidence

- Android package ID: `com.liemteam.miacademy`.
- App version: `0.9.0-beta.2+2`.
- Local signing state: `apps/mobile/android/key.properties` is absent, so
  release builds used the documented debug-signing fallback, not production
  Play signing.
- APK SHA-256: `0C016F8C7930B7AF4C91325C7E9C505FA13FCCAB587EA27B74CA9586AB997DAB`.
- AAB SHA-256: `BCB8080B5B0BDCEF232B3C451F12689ED52769E22F1C88EEF960403F80F41B8A`.

## Known Gaps

- Games 16-30 are not implemented.
- Games 9-15 Android integration scenarios exist in
  `apps/mobile/integration_test/games_9_15_flow_test.dart`; local execution
  did not run because no supported Android/iOS device was connected, so final
  device proof must come from CI.
- No qualified human language or education review has approved the new
  Games 9-15 content.
- Human content review remains pending for VI language, EN language, and
  educational progression.

## Verdict

Games 9-15 Conditional — Milestone 2 Conditional.
