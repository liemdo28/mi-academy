# Milestone 2 Release-Candidate Status

Date: 2026-07-19
Branch: `integration/m2-games-15-release-candidate`
Base branch: `origin/integration/m2-games-15-complete`
Base SHA: `25eb9fc9c2f11203063208c3b911d2c286b53e29`

Historical note: this file records the Milestone 2 branch only. The current
Milestone 3 branch implements Games 16-30; see
`docs/milestone-3-completion.md` and `docs/game-catalog.md`.

## Executive Summary

Verdict: **Games 1-15 Engineering Complete — External Release Gates Pending**

Milestone 2 has Games 1-15 registered, launchable, content-backed,
backend-cataloged, and covered by automated validation. This document is a
release-candidate status record, not a Play-ready claim. The exact final CI
run ID for this RC is recorded in the handoff report because embedding a run
ID here would require a post-CI commit and make the embedded run stale.

## Game and Content Scope

`python tools/release_counts.py --json` is the canonical count source for
release-scope content. Current regression target:

- Games implemented: 15
- Production levels: 665
- Games 16-30: not implemented

## New Game Matrix

| Game ID | Content | Tiers | Engine | Age bands | Status |
|---|---:|---:|---|---|---|
| `alphabet_explorer` | 95 bilingual levels | 3 | Choice | junior, explorer | Built |
| `missing_letter` | 75 bilingual levels | 3 | Choice | junior, explorer | Built |
| `category_collector` | 60 bilingual levels | 3 | Multi-select | junior, explorer, master | Built, human review pending |
| `pattern_parade` | 60 bilingual levels | 3 | Sequence | junior, explorer, master | Built, human review pending |
| `shape_builder` | 45 bilingual levels | 3 | Placement | junior, explorer, master | Built, human review pending |
| `word_sorter` | 60 bilingual levels | 3 | Placement | junior, explorer, master | Built, human review pending |
| `number_balance` | 60 bilingual levels | 3 | Matching | junior, explorer, master | Built, human review pending |
| `logic_detective` | 45 bilingual levels | 3 | Multi-select | explorer, master | Built, human review pending |
| `story_steps` | 45 bilingual levels | 3 | Sequence | junior, explorer, master | Built, human review pending |

## Backend Support

The backend catalog includes Games 1-15. The Games 7-8 Alembic migration
`b4f7c2d9e801` inserts `alphabet_explorer` and `missing_letter`
idempotently; `c9f1a7b2d615` adds Games 9-15. Progress/result aggregation is
covered by backend tests and by the Postgres + Redis CI smoke job.

## Release Artifact Policy

- Android package ID: `com.liemteam.miacademy`.
- App version: `0.9.0-beta.2+2`.
- Local release APK/AAB builds without `android/key.properties` use the
  documented debug-signing fallback. They are not Play-upload-ready.
- The CI job `Android release signing readiness` reports whether all signing
  secrets are configured. `Android signed Play artifact` runs only when all
  required secrets exist and sets `requireReleaseSigning=true`.
- Fresh RC APK/AAB hashes are recorded in the final handoff report for the
  exact build artifacts generated from this branch.
- Fresh local APK SHA-256:
  `B358CFD8805432ACBCC616A2AF358F4095275B8CCDE72775D45AAF41F34A31F7`.
- Fresh local AAB SHA-256:
  `8B790874F432D12228F9B91D9A61BEE7035ED4C1E1795B34F04BE44003FB530E`.

## Required Validation

The RC handoff must record the outcome of:

- Shared package: `dart format --set-exit-if-changed .`, `flutter analyze`,
  `flutter test`.
- Mobile app: `dart format --set-exit-if-changed .`, `flutter analyze`,
  `flutter test`, release APK/AAB builds.
- Repository: `python -m ruff format --check .`, `python -m ruff check .`,
  `python -m mypy .`, `python -m pytest packages/game_core/tests tests test -q`.
- Content: schema validator, malformed fixtures, safety audit,
  localization audit, solvability.
- Backend: Alembic upgrade to head against Postgres, including
  `b4f7c2d9e801`.
- Integration: Android emulator CI job with non-zero test discovery.

## Known Gaps

- Games 16-30 are not implemented.
- Human educational/language review is pending for the generated Milestone 2
  content.
- Repository-wide hardcoded-string localization cleanup remains pending even
  though ARB key parity is complete.
- Production Android signing secrets and Play Console upload are not verified
  in this repository.
- `pip-audit` currently reports dependency vulnerabilities as an advisory
  scanner; triage and promotion policy remain pending.
