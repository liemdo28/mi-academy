# Milestone 1 — Completion Report

Date: 2026-07-18, updated 2026-07-19 for baseline consolidation
(`integration/m1-m2-baseline`). See `docs/game-engine-architecture.md`
for engine detail and `docs/milestone-2-completion.md` for Games 7-8.
This document is
the required summary of delivered workstreams, architecture, content
counts, test coverage, remaining limitations, and command evidence for
Milestone 1 as actually executed — not a restatement of the original
Milestone 1 spec's intentions. Every claim below cites a command, a file,
or a CI run ID; anything not verifiable this way is listed under
"Remaining limitations," not silently omitted.

## Verdict: Milestone 1 Conditional

Not **Complete**: the completion gate (master spec §11) requires zero
unsuppressed hardcoded UI strings, four real reusable engines, six games
each meeting the content minimum with three real difficulty tiers, and
full Suite A-H integration coverage. None of those four are fully true
yet (see "Remaining limitations"). Not **Not Ready**: every backend and
mobile canonical command is green, the application-identity blocker is
resolved, a versioned content schema exists and validates all production
content, a real (if partial) integration-test suite passes on a real
Android emulator in CI, three of four required engines are fully real and
tested, and Math Race / Math Supermarket have been expanded.

## Delivered workstreams

### Application identity — resolved
`applicationId`/`namespace` (Android) and `PRODUCT_BUNDLE_IDENTIFIER`
(iOS) changed from the `com.example.*` Flutter scaffold default to
`com.liemteam.miacademy`. Verified against the built artifact itself:
`aapt dump badging app-release.apk` → `package: name='com.liemteam.miacademy'
versionCode='2' versionName='0.9.0-beta.2'`. Version bumped from
`0.9.0-beta.1+1` to `0.9.0-beta.2+2` (still explicitly beta).

### WS7 — Backend quality (complete)
`ruff format --check .`, `ruff check .`, `mypy .` all exit 0 from a clean
config; one real runtime bug (a Pydantic validation error on every call to
`GET /lessons/{lesson_id}`) was caught and fixed as a direct result of
turning mypy on for real.

### WS8 — PostgreSQL migrations (complete)
`alembic upgrade head` verified directly against a real, disposable
PostgreSQL 16.13 (not just asserted): empty database → head across all 6
revisions, then the app booted successfully against that migrated
database in production config.

### WS9 — Android signing (complete)
`-PrequireReleaseSigning=true` fails clearly when signing is requested
without credentials (verified directly); normal unsigned builds
unaffected; `docs/android-signing.md` documents keystore generation, Play
App Signing, and CI secret names.

### WS4 — Game registry (complete)
`GameRegistry` (`apps/mobile/lib/services/game_registry.dart`) is the
central mobile registry. The consolidated baseline registers exactly 8
games, in canonical order: Word Builder, Sound Match, Math Race, Math
Supermarket, Robot Commands, Memory Cards, Alphabet Explorer, Missing
Letter.

### WS3 — Versioned content schema (complete)
`schemas/level.schema.json` (JSON Schema draft 2020-12) formalizes the
real content shape already in use, extended with `contentVersion`/
`estimatedSeconds`/`publicationState`. Dart (`MiLevel`/`ContentLoader`)
and Python (`apps/api/schemas/content_item.py`, Pydantic) both validate
against the same rules — proven by tests, not asserted. All current
production levels validate: 10 Word Builder, 10 Sound Match, 40 Math
Race, 40 Math Supermarket, 10 Robot Commands, 10 Memory Cards, 95
Alphabet Explorer, and 75 Missing Letter. 9 deliberately malformed
fixtures are proven to fail with actionable messages
(`tools/content_schema_validator.py --check-malformed`). A genuine content
bug was found and fixed along the way: 12 of 23 skill IDs authored in
real level content didn't match `content/skills/skill_taxonomy.json`'s
naming convention (e.g. `math.addition_within_10` vs. the taxonomy's
`math.addition.within_10`) — silently broken skill-evidence tracking,
now aligned.

### WS5 — Reusable engines (partial: 3 of 4, updated 2026-07-19)
**Matching Engine**, **Sequence Engine**, and **Drag-and-drop Placement
Engine** (`packages/mi_game_engines/`) are all fully real: typed content
models, `ChangeNotifier` controllers (no framework/child-profile
dependency), responsive/accessible/reduced-motion-aware renderers, VI+EN
example content each, and a shared `test/engine_contract_test.dart`
verifying all three against one common contract (stable engine id,
attempt counting, completion, star bounds, and — for Placement, whose
result is the most complete of the three — the full normalized-result
shape and an automated no-persistence-dependency check). 105 tests total
across the package (19 Matching + 23 Sequence + 57 Placement + 6
contract), all passing; `flutter analyze` clean. **Multi-select Engine
was not built** — it still needs its own real interaction-model design
(min/max selection-set validation), comparable in scope to what the
other three each took. None of the three built engines are wired into
the game registry or any production game yet.

### WS2 — Integration-test harness (partial, CI-verified)
`apps/mobile/integration_test/` (previously did not exist): 4 real,
deterministic tests covering the backend-independent slice of the
required scenario matrix (fresh install shows locale selection, VI/EN
selection persists across a simulated relaunch, full local-data reset
returns to locale selection). **Verified passing on a real Android
emulator in CI** (run `29645095716`: `🎉 4 tests passed.`) after three
real bugs were found and fixed via the actual CI log/fix cycle (a
fragile OS-locale `setprop`, a Hive box-type mismatch, a GoRouter-
singleton relaunch bug — see `docs/testing.md` for detail). **Suites
B/D/F/G** (multi-profile management, six-game completion, offline play,
time limits) are not covered — each needs a real or mocked backend
reachable from the test device, not built this pass.

### WS1 — Localization (partial)
`.arb` key parity (67/67) is real and now CI-enforced
(`tools/localization_audit.py`, wired into `content-and-safety`). Game
*content* locale (prompts/hints/feedback from JSON) and the app-shell
locale were fixed in the prior session. **UI-chrome strings are not
localized**: the hardcoded-string scanner currently reports 245 findings
across 39 files, unchanged this pass — full retrofit to
`AppLocalizations`/`L10nService` was not attempted given the scope of
everything else in this pass.

### WS6 — Existing-game stabilization and content expansion (partial)
All built games launch through the registry and their content conforms to
the versioned schema. Math Race and Math Supermarket have been expanded
to 40 levels each across the intended difficulty spread. Word Builder,
Sound Match, Robot Commands, and Memory Cards still need expansion.

## Content counts (verified)

| Game | Levels | Locales/level | Difficulty tiers | Schema-valid |
|---|---|---|---|---|
| word_builder | 10 | vi+en | pending expansion | yes |
| sound_match | 10 | vi+en | pending expansion | yes |
| math_race | 40 | vi+en | expanded | yes |
| math_supermarket | 40 | vi+en | expanded | yes |
| robot_commands | 10 | vi+en | pending expansion | yes |
| memory_cards | 10 | vi+en | pending expansion | yes |
| alphabet_explorer | 95 | vi+en | 3 | yes |
| missing_letter | 75 | vi+en | 3 | yes |

Math Race and Math Supermarket are complete for the current existing-game
expansion scope; Word Builder, Sound Match, Robot Commands, and Memory
Cards remain pending.

## Test coverage (verified)

| Suite | Count | Result |
|---|---|---|
| `pytest packages/game_core/tests tests test -q` | 177 | all passed |
| `flutter test` (apps/mobile) | 108 | all passed + 6 skipped (Linux-only goldens on Windows) |
| `flutter test` (packages/mi_game_content) | 24 | all passed |
| `flutter test` (packages/mi_game_engines) | 105 | all passed (updated 2026-07-19 for Sequence + Placement) |
| `flutter test integration_test` (CI, real Android emulator) | 4 | all passed |

## Remaining limitations (honest, not hidden)

- **RA-05**: 245 hardcoded Vietnamese UI-chrome strings across 39 files —
  full localization retrofit not done.
- **Engines**: Multi-select is the only remaining engine that doesn't
  exist (Matching, Sequence, and Placement are now all real and tested —
  see the updated WS5 section above); none of the three are wired into
  the game registry or any production game yet.
- **Content expansion**: Word Builder, Sound Match, Robot Commands, and
  Memory Cards still need expansion.
- **Integration suites B/D/F/G**: need a real or mocked backend reachable
  from the test device — not built.
- **RA-08**: 5-child-profile boundary is real and enforced but untested.
- **RA-11/12/13 tooling**: fixed. **Games 7-30**: out of Milestone 1 scope
  by the master spec's own instruction ("do not start games 7-30").

## Exact command evidence

See the "Command results" table in the accompanying final chat response
for the full command-by-command exit codes and pass/fail counts; the key
ones: `ruff format --check .` (0), `ruff check .` (0), `mypy .` (0),
`pytest` (170 passed), `flutter analyze` (0 issues), `flutter test` (92,
6 skipped), `flutter build apk/appbundle --release` (both succeed,
SHA-256 checksums recorded), `alembic upgrade head` against real Postgres
(head reached), CI run `29645095716` (all 8 jobs green, including the new
Android-emulator integration-test job).
