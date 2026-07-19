# Milestone 2 Completion Report

Date: 2026-07-19
Branch: `integration/m1-m2-baseline`

## Executive Summary

Verdict: **Milestone 2 Not Ready**

Milestone 2 slices 1-2 implement Game 7, `alphabet_explorer`, and Game 8,
`missing_letter`, as real playable games using the existing Choice Engine
path. The repository now has 8 registered playable games, not the 15
required for Milestone 2 completion. Games 9-15 are still unfinished and
must not be represented as complete.

## New Game Matrix

| Game ID | Content | Tiers | Engine | Age bands | Skills | Tests | Status |
|---|---:|---:|---|---|---|---|---|
| `alphabet_explorer` | 95 bilingual levels | 3 | Choice | junior, explorer | uppercase, lowercase, case matching, initial sound, vocabulary | content, registry, launcher, full mobile suite | Built in this slice |
| `missing_letter` | 75 bilingual levels | 3 | Choice | junior, explorer | lowercase recognition, spelling, vocabulary, initial sound | content, registry, launcher, full mobile suite | Built in slice 2 |
| `word_picture_match` | 0 | 0 | n/a | 5-8 | n/a | none | Not started |
| `count_objects` | 0 | 0 | n/a | 5-7 | n/a | none | Not started |
| `number_quantity_match` | 0 | 0 | n/a | 5-7 | n/a | none | Not started |
| `compare_numbers` | 0 | 0 | n/a | 5-9 | n/a | none | Not started |
| `number_sequence` | 0 | 0 | n/a | 6-10 | n/a | none | Not started |
| `odd_one_out` | 0 | 0 | n/a | 5-10 | n/a | none | Not started |
| `shadow_match` | 0 | 0 | n/a | 5-8 | n/a | none | Not started |

## Command Results

| Directory | Command | Result |
|---|---|---|
| `apps/mobile` | `flutter analyze` | PASS, 0 issues |
| `apps/mobile` | `flutter test` | PASS, 108 passed, 6 Windows-only golden skips |
| `apps/mobile` | `flutter test test/missing_letter_content_test.dart test/game_registry_test.dart test/game_screen_test.dart test/widget_test.dart` | PASS, 54 passed |
| `apps/mobile` | `flutter build apk --release` | PASS, built `build/app/outputs/flutter-apk/app-release.apk` |
| `apps/mobile` | `flutter build appbundle --release` | PASS, built `build/app/outputs/bundle/release/app-release.aab` |
| `apps/mobile` | `flutter test integration_test` | NOT RUN locally: no Android/iOS device connected; Android emulator proof passed in CI run `29659041334` |
| repo root | `python tools/content_schema_validator.py` | PASS |
| repo root | `python tools/content_schema_validator.py --check-malformed` | PASS, 9 malformed fixtures checked |
| repo root | `python tools/content_safety_audit.py --json` | PASS, 8 files and 9320 strings scanned, 0 findings |
| repo root | `python tools/localization_audit.py` | PASS for ARB parity, 67 EN / 67 VI keys; WARN for existing hardcoded Vietnamese UI strings |
| repo root | `python -m ruff check .` | PASS |
| repo root | `python -m pytest packages/game_core/tests tests test -q` | PASS, 177 passed |
| repo root | `python -m ruff format --check .` | PASS after targeted generator formatting |
| repo root | `python -m mypy .` | PASS after resolving `math_race_generator.py` tuple-key inference |
| `apps/api` + Postgres/Redis | `python -m alembic upgrade head`; `python -m alembic current`; API `/health/live` + `/health/ready` | PASS, current revision `b4f7c2d9e801 (head)`, readiness returned `live=ok; ready=ready` |

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

The backend catalog now includes `alphabet_explorer` and `missing_letter`.
Fresh/upgraded database behavior is covered by the Games 7-8 data migration
and `tests/test_backend_game_catalog.py`; result saving and idempotency are
covered by `tests/test_api_game_result.py`.

## Release Artifact Evidence

- Android package ID: `com.liemteam.miacademy`.
- App version: `0.9.0-beta.2+2`.
- Local signing state: `apps/mobile/android/key.properties` is absent, so
  release builds used the documented debug-signing fallback, not production
  Play signing.
- APK SHA-256: `319309B61162D35ECD513A28266602C16786A943F467F21542E7FE39D2EC83BF`.
- AAB SHA-256: `7AA2A9108CD92AF5903564E34DEEFE0AED10E3D703B62E61BC5CB6DA0B4FE829`.

## Known Gaps

- Games 9-15 are not implemented.
- Multi-select Engine is not implemented.
- Missing Letter Android integration coverage exists in
  `apps/mobile/integration_test/missing_letter_flow_test.dart`. Local
  execution did not run because no supported Android/iOS device was connected;
  CI run `29659041334` verified the scenario on the Android emulator.
- No qualified human language or education review has approved the new
  Alphabet Explorer or Missing Letter content.
- Human content review remains pending for VI language, EN language, and
  educational progression.

## Verdict

Game 8 Engineering Complete — Human Content Review Pending — Milestone 2
Not Ready.
