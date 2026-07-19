# Testing

Status as of the MI Academy 1.0 audit (2026-07-19), verified directly against
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
| Shared game engines (Matching/Sequence/Placement/Multi-select) format | `dart format --set-exit-if-changed .` | `packages/mi_game_engines` |
| Shared game engines analyze | `flutter analyze` | `packages/mi_game_engines` |
| Shared game engines tests | `flutter test` | `packages/mi_game_engines` |

`packages/mi_game_engines` is a standalone package (its own `pubspec.yaml`),
not part of `apps/mobile`'s own `flutter test` run -- it must be verified
separately with the working directory set to the package itself. It also
has its own dedicated CI job (`shared-engines-test` in
`.github/workflows/ci.yml`), added during the Games 7-8/Placement Engine
consolidation pass so CI can't silently skip this package while still
reporting green overall. As of the Multi-select Engine pass (2026-07-19)
this package has 165 passing tests: 19 Matching, 23 Sequence, 57
Placement, 58 Multi-select, and 8 in a shared
`test/engine_contract_test.dart` that checks all four engines against one
"common engine contract" (stable engine id, attempt counting, completion,
star bounds, and -- for Placement and Multi-select specifically, whose
normalized results are the most complete of the four -- the full result
shape and an automated check that no engine source file imports a
storage/backend/analytics package). Games 9-15 now consume Matching,
Sequence, Placement, and Multi-select through the public
`mi_game_engines` barrel; see docs/game-engine-architecture.md.

The Multi-select pass also fixed the full seed transaction boundary in
`infrastructure/seed/seed_data.py`: successful seeding now exits through
the sessionmaker transaction context, which commits once, while exceptions
roll back. `tests/test_backend_game_catalog.py` covers canonical Games
1-8, `seed_built_games` idempotency, full-seed persistence across a new
session, and rollback after a forced seed failure.

CI (`.github/workflows/ci.yml`) is the authoritative environment for all of
these — it runs on `ubuntu-latest` (mobile/backend jobs) and `macos-latest`
(iOS build), matching the constraints below. `flutter test` and
`flutter analyze` are also expected to be clean on a contributor's own
machine (Windows/macOS/Linux); the one documented platform-dependent
exception is golden/pixel tests, covered next.

## Database migrations — PostgreSQL is canonical

`apps/api/alembic`'s migration chain includes operations (e.g.
`op.create_unique_constraint` in `3aac9694cdd1_add_client_attempt_id.py`)
that SQLite's `ALTER` support doesn't implement — running `alembic upgrade
head` against a local SQLite file fails with `NotImplementedError: No
support for ALTER of constraints in SQLite dialect`. This is expected, not
a bug: **SQLite is a dev/test-only convenience for the app itself** (the
non-Postgres-specific pytest suite uses it), **it is never the environment
migrations are verified against.** PostgreSQL is canonical because:

1. Production runs Postgres (see `apps/api/config.py`'s `DATABASE_URL`),
   not SQLite.
2. Several migrations use Postgres-only DDL that SQLite silently can't
   perform at all, so a SQLite-only verification pass would never have
   caught a broken migration in those revisions.

Two ways to verify the migration chain against real Postgres:

- **Locally**, via the disposable Docker Compose service in
  `infrastructure/docker/docker-compose.yml`:
  ```bash
  docker compose -f infrastructure/docker/docker-compose.yml up -d db redis
  cd apps/api
  DATABASE_URL=postgresql+asyncpg://mi_user:mi_dev_password@localhost:5432/mi_academy \
    python -m alembic upgrade head
  ```
  Verified directly during the Milestone 1 audit (2026-07-18): a fresh
  `docker compose up -d db` container running PostgreSQL 16.13, migrated
  from empty to head (`27676b1dea5d` → `3aac9694cdd1` → `9b7d3f1a6c21` →
  `5f2a8c14e9b7` → `7c1d3e9a2f45` → `a3e6f0b8c1d2`, confirmed via `alembic
  current` → `a3e6f0b8c1d2 (head)`), then the app itself was booted against
  that same database with `APP_ENV=production` and `CREATE_TABLES_ON_STARTUP=false`
  (so only the migrations, not the dev `create_all()` fallback, could have
  created the schema) — `/health/live` returned `{"status": "ok"}` and
  `/health/ready` returned `{"status": "ready"}` (the latter runs a real
  `SELECT 1` against Postgres, not just a process-alive check).
  Re-verified during Game 8 closure (2026-07-19) through the new
  `b4f7c2d9e801` Games 7-8 seed migration; `alembic current` reported
  `b4f7c2d9e801 (head)`, the database contained `alphabet_explorer` and
  `missing_letter`, and API readiness returned `live=ok; ready=ready`.
- **In CI**, the `postgres-integration` job in `.github/workflows/ci.yml`
  runs the same migration-then-boot sequence against real `postgres:16` and
  `redis:7` service containers on every dispatch — this is the CI proof
  or WS8's acceptance criteria, and has been green on every recent run on
  this branch (see `docs/release-audit.md` RA-23 for the exact run IDs).

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

**Verification:** `flutter test` on this Windows dev machine reports `108
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

## Integration tests (Milestone 1 WS2)

`apps/mobile/integration_test/` exists with real, deterministic tests
(`first_launch_locale_test.dart` + `helpers/app_launch.dart`), covering the
part of the required scenario matrix that needs no backend: fresh install
shows language selection, selecting VI/EN persists across a simulated
relaunch (a fresh widget tree against the same on-device Hive storage,
since `flutter test integration_test` cannot kill and restart the OS
process mid-test), and a full local-data reset returns to language
selection. Verified: `flutter analyze` and `dart format --set-exit-if-changed .`
are both clean on `integration_test/`, and `flutter test integration_test`
correctly *discovers* these tests (confirmed via `flutter test integration_test
-d chrome`/`-d windows`, which fail for unrelated platform-support reasons —
this project only targets Android/iOS, so neither a desktop nor a web
runner exists — but the failure message in both cases is a platform error,
not "no tests found", proving the test file itself loads and parses).

**Verified green on a real Android emulator in CI**, not merely written:
`.github/workflows/ci.yml`'s `mobile-integration-test` job runs these
tests against a real, hardware-accelerated Android emulator (API 34,
`google_apis`, `x86_64`, `pixel_6` profile) via
`reactivecircus/android-emulator-runner`, with an explicit pre-flight step
that fails the job if zero `integration_test/*_test.dart` files are
discovered (guards against the "green because nothing ran" failure mode)
and uploads `build/`/`integration_test/` as artifacts on failure. CI run
`29645095716` (2026-07-18): **4 tests passed, 0 failed** — confirmed via
the job's own log (`🎉 4 tests passed.`), not inferred from a green
checkmark alone. Getting to this point took three real, logged failures
and fixes, each instructive:

1. Run `29643058794`: emulator booted successfully (proving KVM
   acceleration + the whole pipeline works), but a post-boot
   `adb shell setprop persist.sys.locale vi-VN` step failed — the stock,
   non-rooted `google_apis` system image doesn't allow that property to be
   set after boot. Fixed by removing the forced OS locale entirely (the
   app's own `LocaleSelectionScreen` doesn't depend on it).
2. Run `29643846502`: got as far as installing and launching the real
   app, but every test failed with `HiveError: The box "sync_queue" is
   already open and of type Box<SyncQueueItem>` — `initHive()` opens that
   one box with a typed adapter while every other box is untyped, and the
   test helper's cleanup code used the untyped accessor for all boxes
   uniformly. Fixed by giving `sync_queue` its own correctly-typed
   `Hive.box<SyncQueueItem>()` call in `resetLocalState()`.
3. Run `29644469867`: 2 of 4 tests passed; the other 2 failed with
   "0 widgets found" for the locale-selection buttons after a simulated
   relaunch. Root cause: `routerProvider` (`config/router.dart`) is a
   top-level `GoRouter` singleton, not scoped per `ProviderScope` —
   re-pumping `MiAcademyApp` to simulate a relaunch reattaches to the
   *same* GoRouter instance, which still remembered whatever route the
   previous simulated launch had navigated to. Fixed by calling
   `routerProvider.go('/')` before each simulated relaunch in the
   `launchApp()` helper, forcing `SplashScreen`'s cold-start redirect
   logic to actually re-run instead of silently resuming.

This progression — real boot, then a real Hive typing bug, then a real
router-singleton bug, each fixed in turn — is itself evidence this is a
genuine on-device run, not a mocked or trivially-passing stand-in.

**Not covered by `first_launch_locale_test.dart`** — Suites B (multi-
profile management), C (parent PIN protection beyond what
`test/parent_route_guard_test.dart` already covers as a widget test), D
(six-game completion end-to-end), F (offline play), and G (time-limit
break screen) from the Milestone 1 spec's full A-H matrix. Each of B/D/F/G
requires either a real or mocked backend reachable from the test device
(the app's auth flow calls a live API to reach child home) — standing that
up (a test-mode backend server, or a request-mocking layer reachable from
an Android emulator) is itself a real, separate piece of infrastructure
that was not built this pass. Treat the current integration-test coverage
as a real, working foundation and pattern (reusable `launchApp`/
`resetLocalState` helpers, deterministic IDs, no arbitrary sleeps), not the
complete required matrix.

### Milestone 2 Slice 2 local verification

On 2026-07-19, Missing Letter added
`apps/mobile/test/missing_letter_content_test.dart`,
`apps/mobile/integration_test/missing_letter_flow_test.dart`, plus registry
and launcher coverage. Local command results:

- `dart format --set-exit-if-changed .` from `apps/mobile`: pass.
- `flutter analyze` from `apps/mobile`: pass, 0 issues.
- `flutter test` from `apps/mobile`: pass, 108 passed and 6 Windows-only
  golden skips.
- `flutter test integration_test` from `apps/mobile`: not run locally because
  no Android/iOS device was connected; Flutter listed desktop/web targets
  instead. The Missing Letter integration scenario is verified by CI run
  `29659041334` on the `mobile-integration-test` Android emulator job
  (`success`, 5 tests passed).
- `python -m pytest packages/game_core/tests tests test -q` from repo root:
  pass, 179 passed.
- `python -m ruff check .` from repo root: pass.
- `python -m ruff format --check .` from repo root: pass after targeted
  formatting of Math Race and Math Supermarket generators.
- `python -m mypy .` from repo root: pass after resolving the Math Race
  generator tuple-key type inference issue.
- `python -m alembic upgrade head` from `apps/api` against local disposable
  Postgres: pass through revision `b4f7c2d9e801`.
- API readiness against the migrated Postgres database: pass,
  `/health/live` returned `ok` and `/health/ready` returned `ready`.
- **Automated translation-key parity check in CI.** `packages/localization/lib/l10n/app_en.arb`
  and `app_vi.arb` currently match exactly (67/67 keys both ways), and
  `tools/localization_audit.py` enforces parity in CI. The same audit still
  warns about hardcoded Vietnamese UI strings, which remains RA-05 scope.
- ~~Backend Python tooling (`ruff`, `mypy`) has no project configuration~~
  **Fixed** (Milestone 1, WS7): `pyproject.toml` now has `[tool.ruff]` and
  `[tool.mypy]` sections. All four canonical backend commands
  (`ruff format --check .`, `ruff check .`, `mypy .`, `pytest`) exit 0 from
  the repo root on Python 3.11+ (declared `requires-python`, matching the
  actual `datetime.UTC` usage in `apps/api/time.py` and
  `apps/api/routes/parent.py`, and CI's Python 3.13). See
  `docs/release-audit.md` RA-19 for what was fixed vs. narrowly suppressed
  and why (SQLAlchemy's `== True`/`== None` idiom is the one deliberate
  ignore; everything else is a real fix, not a broadened ignore list).
  Not yet added to `.github/workflows/ci.yml` as a required job in this
  pass — see RA-19's status.

### Supported Python version and setup

- Python **3.11+** (see `pyproject.toml`'s `requires-python`; CI runs 3.13).
- `pip install -r apps/api/requirements.txt` installs the app + test
  dependencies (pytest/pytest-asyncio/aiosqlite are pinned there already).
- `ruff` and `mypy` are dev-only tools, not in `requirements.txt` (the app
  doesn't need them at runtime) — install with `pip install ruff mypy` to
  run them locally; both read their config from the repo-root
  `pyproject.toml` automatically.
### Games 9-15 local verification

Updated 2026-07-19 on `integration/m2-games-15-complete`:

| Command | Result |
|---|---|
| `flutter test` (`apps/mobile`) | PASS, 123 passed, 6 expected Windows golden skips |
| `apps/mobile/integration_test/games_9_15_flow_test.dart` | ADDED, 7 new Android-emulator scenarios pending final CI |
| `flutter test --reporter expanded` (`packages/mi_game_engines`) | PASS, 165 passed |
| `python -m pytest packages/game_core/tests tests test -q` | PASS, 187 passed |
| `python tools/content_schema_validator.py` | PASS for Games 1-15 |
| `python tools/content_schema_validator.py --check-malformed` | PASS, 13 malformed fixtures rejected |
| `python tools/level_validator/solve_levels.py` | PASS, 665/665 production levels solvable |
| `python tools/localization_audit.py` | PASS ARB parity; existing hardcoded-string warning count remains 245 |
