# Testing

Status as of the MI Academy 1.0 audit (2026-07-18), verified directly against
this repository's working tree and CI — not carried over from prior report
summaries.

## Canonical commands

| Layer | Command | Working directory |
|---|---|---|
| Flutter format | `dart format --set-exit-if-changed .` | `apps/mobile` |
| Flutter analyze | `flutter analyze` | `apps/mobile` |
| Flutter unit/widget tests | `flutter test` | `apps/mobile` |
| Flutter integration tests | `flutter test integration_test` | `apps/mobile` |
| Python game-core + backend tests | `python -m pytest packages/game_core/tests tests test -q` | repo root |
| Alembic migrations (real schema validation) | `python -m alembic upgrade head` | `apps/api`, against Postgres |

CI (`.github/workflows/ci.yml`) is the authoritative environment for all of
these — it runs on `ubuntu-latest` (mobile/backend jobs) and `macos-latest`
(iOS build), matching the constraints below. `flutter test` and
`flutter analyze` are also expected to be clean on a contributor's own
machine (Windows/macOS/Linux); the one documented platform-dependent
exception is golden/pixel tests, covered next.

## Golden tests

`apps/mobile/test/game_slice_golden_test.dart` renders each of the six MVP
games and compares against a stored PNG per game (`goldens/*.png`).

### Root cause of the cross-platform failures

These tests originally failed non-deterministically depending on which OS
ran them, for two compounding reasons:

1. **Font mismatch.** Without an explicit font load, Flutter's test harness
   falls back to whatever font the host OS provides (Windows: Segoe UI/
   Arial substitutes; Linux: DejaVu; macOS: Arial). Different glyph metrics
   between these fonts alone produced multi-percent pixel diffs. This was
   already fixed in a prior pass by bundling a repo-controlled font
   (`assets/fonts/nunito/Nunito-VariableFont_wght.ttf`, OFL-licensed) and
   loading it into the `Roboto` family override before every test via
   `FontLoader`, plus loading `MaterialIcons-Regular.otf` from the local
   Flutter SDK cache (identical bytes on every platform since it ships with
   the SDK, not the OS).
2. **OS-level text rasterization.** Even with byte-identical font data
   loaded, a 0.2–0.6% pixel diff remained on Windows against goldens
   generated on Linux CI. This is a documented Flutter/Skia limitation:
   golden file tests are only guaranteed bit-exact when generated and
   compared on the same operating system, because text hinting and
   anti-aliasing are applied by the platform's rendering backend, not just
   determined by the font bytes. This is not a font-loading bug and cannot
   be fixed by bundling more assets.

### Resolution

Rather than accept these as silently-known local failures (unacceptable —
see below) or delete the tests (would lose real visual-regression coverage),
each golden test now does two things on every platform:

- Runs the exact same widget-building and interaction code as before, plus
  **real widget/semantic assertions** (visible prompt text, option labels,
  rendered controls) that hold regardless of host OS. These are new
  assertions, not a reduction of existing coverage.
- Performs the **pixel `matchesGoldenFile` comparison only when
  `Platform.isLinux`** (see `_expectMatchesGoldenOnLinux` in
  `game_slice_golden_test.dart`). On any other host OS, the test calls
  `markTestSkipped(...)` with an explicit, human-readable reason instead of
  silently passing or opaquely failing.

Linux — specifically `ubuntu-latest`, matching the `mobile-test-build` job in
CI — remains the sole source of truth for the pixel comparison. This
satisfies the goal without weakening coverage: any contributor or CI run on
Linux still gets full pixel-level regression detection; everyone else still
gets meaningful functional coverage and an explicit (not silent) skip
instead of a false failure.

**Verification:** `flutter test` on this Windows dev machine reports `86
passed, 6 skipped` with the 6 skips being exactly these golden tests, each
printing its skip reason. CI's `mobile-test-build` job (`ubuntu-latest`) was
re-dispatched against the branch containing this change and passed with the
pixel comparisons executed for real — see
`gh run list --branch fix/internal-beta-hardening` / the corresponding job
IDs recorded in `docs/release-audit.md`.

### Regenerating goldens

If a game's UI intentionally changes, regenerate goldens **on Linux CI or an
actual Linux machine only** — never on Windows/macOS — using
`flutter test --update-goldens`, then inspect the diff (`git diff` on the
PNGs won't be readable directly; use the CI job's uploaded
`golden-failures` artifact or a local Linux run) before committing. Do not
regenerate blindly just to silence a failure.

## Known test-pyramid gaps (open, not silently accepted)

- **`integration_test/` directory does not exist.** `flutter test
  integration_test` currently fails immediately (no tests to run) and, even
  once tests exist, requires a connected device or emulator — this
  environment has the Android SDK and emulator tooling installed but no
  emulator was booted for this audit pass, so true on-device integration
  testing was not exercised here. Widget tests in `apps/mobile/test/`
  substitute for a meaningful fraction of this today (full six-game
  playthrough assertions, parent PIN gate, dashboard states, splash
  routing) but do not replace a real device/emulator run.
- **No automated translation-key parity check in CI.** `packages/localization/lib/l10n/app_en.arb`
  and `app_vi.arb` currently match exactly (57/57 keys both ways, verified
  by direct diff during this audit) but nothing enforces that going forward.
- **Backend Python tooling (`ruff`, `mypy`) has no project configuration**
  (no `pyproject.toml` `[tool.ruff]`/`[tool.mypy]` section, not installed via
  `requirements.txt`, not run in CI). Running them ad hoc against
  `apps/api` surfaces findings but there is no enforced baseline — see
  `docs/release-audit.md` for exact counts.
