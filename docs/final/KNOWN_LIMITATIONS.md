# Known Limitations — as of fix/full-integration-production

This session scoped down from the originally requested 19-phase full-repo production-readiness pass to a deep fix on the golden flow (see the plan context in the PR). Everything below was **not attempted** this session — it's listed explicitly so silence isn't mistaken for "done."

## Not attempted this session

- **Security**: no penetration testing, no dependency/CVE audit beyond what the existing CI `security-scans` job already does (gitleaks, pip-audit, bandit — all `continue-on-error: true`, i.e. non-blocking today), no auth/PIN/JWT design review beyond the read-only observations in `docs/audit/PRODUCTION_BLOCKERS.md`.
- **Performance**: no profiling of startup, game/asset loading, snapshot restore, sync, or parent dashboard; no memory/CPU/jank measurement.
- **Accessibility**: no screen-reader, high-contrast, reduced-motion, large-text, or color-blindness testing. `packages/mi_game_accessibility` exists but its actual behavior wasn't verified this session.
- **Content/curriculum validation**: lesson/level/question schema validation, skill-id consistency, curriculum completeness — not audited.
- **Assets**: asset-id audit, duplicate/missing asset detection, license/localization completeness — not audited.
- **Localization**: translation completeness beyond what's visible in the Vietnamese strings already in the touched files.
- **CI**: no changes to `.github/workflows/ci.yml`. It was read (see `docs/audit/REPOSITORY_AUDIT.md`) but not modified, extended, or verified to actually pass end-to-end in this environment.
- **Release/production readiness**: no work on release builds, signing, rollback, monitoring, logging infrastructure, or backup/restore.
- **Admin app** (`apps/admin`): not audited beyond removing its dangling `shared_models` dependency.
- **Snapshot versioning/migration**: `docs/PLATFORM_GAP_ANALYSIS.md` flags that `MiGameSnapshot` needs a version field for migration; not verified or fixed this session.
- **Adaptive learning / spaced repetition**: `adaptive_core`, `mastery_core`, `recommendation_core`, `spaced_repetition` packages exist and are internally coherent (see `docs/audit/DUPLICATE_ANALYSIS.md`) but are not imported anywhere in `apps/mobile` — no adaptive behavior runs in the app.

## Structural gaps discovered but not resolved

- **The app's real entry point doesn't boot the golden flow.** `apps/mobile/lib/main.dart` runs a standalone game-picker shell; the login/child/dashboard navigation graph in `apps/mobile/lib/app.dart` + `config/router.dart` — which this session wired up — is unreachable from `main()`. This is the top item in `docs/final/NEXT_PHASE_PLAN.md`.
- **5 of 6 games have no completion telemetry.** Only Memory Cards reports a full result; the other games' internal completion state doesn't reach a callback at all. Extending them is game-engine work, not integration work.
- **Two dead, non-compiling files remain**: `apps/mobile/lib/src/games/math_race/math_race_screen.dart` and `math_supermarket_screen.dart`. A destructive-action safety check declined their deletion since they weren't named in the pre-approved session plan.
- **Contract fragmentation beyond MiGameResult** (`Lesson`, `Child`, `Parent`, `Skill`, `Progress` each have 2-4 hand-maintained definitions) was catalogued but not unified.

## Environment constraints

- No iOS/Android device or emulator was available in this environment; mobile verification is `flutter analyze` + `flutter test` only, not a running app.
- Backend verification is `pytest` against SQLite in-memory, not a full Postgres + Redis production-like stack.
