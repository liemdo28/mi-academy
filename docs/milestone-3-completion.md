# Milestone 3 Games 16-30 Status

Date: 2026-07-20
Branch: `integration/m3-games-30`
Base branch: `origin/integration/m2-games-15-release-candidate`

## Executive Summary

Games 16-30 are implemented as production game entries by reusing the
existing shared engines: Matching, Sequence, Placement, and Multi-select.
No new gameplay engine was added for this milestone.

This document is an engineering-completion record, not a Play-ready release
claim. Human educational/language review, production Android signing,
dependency-vulnerability triage, and repository-wide localization cleanup
remain external release gates.

## Game and Content Scope

`python tools/release_counts.py --json` is the canonical count source.

- Games implemented: 30
- Production levels: 1655
- New Games 16-30 levels: 990
- Games 31+: not in scope

## Games 16-30 Matrix

| Game | ID | Engine | Levels | Status |
|---|---|---|---:|---|
| Picture Detective | `picture_detective` | Matching | 60 | Built, human review pending |
| Color Builder | `color_builder` | Placement | 60 | Built, human review pending |
| Animal Homes | `animal_homes` | Matching | 60 | Built, human review pending |
| Daily Routine | `daily_routine` | Sequence | 60 | Built, human review pending |
| Healthy Foods | `healthy_foods` | Multi-select | 60 | Built, human review pending |
| Letter Hunt | `letter_hunt` | Placement | 75 | Built, human review pending |
| Number Train | `number_train` | Sequence | 75 | Built, human review pending |
| Emotion Match | `emotion_match` | Matching | 60 | Built, human review pending |
| Puzzle Parts | `puzzle_parts` | Placement | 60 | Built, human review pending |
| Odd One Out | `odd_one_out` | Multi-select | 75 | Built, human review pending |
| Opposites | `opposites` | Matching | 60 | Built, human review pending |
| Weather Today | `weather_today` | Matching | 60 | Built, human review pending |
| Memory Journey | `memory_journey` | Sequence | 75 | Built, human review pending |
| Category Expert | `category_expert` | Multi-select | 75 | Built, human review pending |
| Build the Story | `build_the_story` | Sequence | 75 | Built, human review pending |

## Backend Support

The backend catalog includes Games 1-30. Alembic revision
`d2a4f8e9b730` inserts Games 16-30 idempotently after
`c9f1a7b2d615`.

## Content and Review

Games 16-30 are generated deterministically by
`tools/content_generators/games_16_30_generator.py`. The generator writes
level packs and the human review checklist:

`docs/content-review/milestone-3-games-16-30-review-checklist.csv`

The checklist has one row per level per locale, with correctness, language,
age, cultural, and accessibility review columns.

## Required Validation

The final handoff must record:

- Shared package: format, analyze, tests.
- Mobile app: format, analyze, widget tests, release APK/AAB builds.
- Android integration: emulator tests for Games 16-30.
- Repository: ruff format/check, mypy, pytest.
- Content: schema, malformed fixtures, legacy validator, solvability,
  safety audit, localization audit.
- Backend: Alembic upgrade to head against PostgreSQL.

## Known External Gates

- Human educational/language review is pending.
- Repository-wide hardcoded-string localization cleanup remains pending.
- Production Android signing secrets and Play upload are not verified.
- Dependency vulnerability triage remains pending.
