# Game catalog - MI Academy Milestone 3

Status verified on 2026-07-20 against branch
`integration/m3-games-30-release-candidate`.
The canonical count source is `python tools/release_counts.py --json`.

## Summary

- Built games: 30/30 for the Milestone 3 target.
- Production level packs: 30.
- Production levels: 1655.
- Shared engines used: Matching, Sequence, Placement, Multi-select.
- Games 31+ are not in scope.
- Human educational/language review remains pending.
- Manual TalkBack/VoiceOver release sign-off remains pending.

## Games 1-15

| # | Game | ID | Engine | Levels |
|---|---|---|---|---:|
| 01 | Word Builder | `word_builder` | Drag/drop game screen | 10 |
| 02 | Sound Match | `sound_match` | Listen/choice game screen | 10 |
| 03 | Math Race | `math_race` | Choice game screen | 40 |
| 04 | Math Supermarket | `math_supermarket` | Choice game screen | 40 |
| 05 | Robot Commands | `robot_commands` | Grid/command game screen | 10 |
| 06 | Memory Cards | `memory_cards` | Memory game screen | 10 |
| 07 | Alphabet Explorer | `alphabet_explorer` | Choice game screen | 95 |
| 08 | Missing Letter | `missing_letter` | Choice game screen | 75 |
| 09 | Category Collector | `category_collector` | Multi-select | 60 |
| 10 | Pattern Parade | `pattern_parade` | Sequence | 60 |
| 11 | Shape Builder | `shape_builder` | Placement | 45 |
| 12 | Word Sorter | `word_sorter` | Placement | 60 |
| 13 | Number Balance | `number_balance` | Matching | 60 |
| 14 | Logic Detective | `logic_detective` | Multi-select | 45 |
| 15 | Story Steps | `story_steps` | Sequence | 45 |

## Games 16-30

| # | Game | ID | Engine | Levels |
|---|---|---|---|---:|
| 16 | Picture Detective | `picture_detective` | Matching | 60 |
| 17 | Color Builder | `color_builder` | Placement | 60 |
| 18 | Animal Homes | `animal_homes` | Matching | 60 |
| 19 | Daily Routine | `daily_routine` | Sequence | 60 |
| 20 | Healthy Foods | `healthy_foods` | Multi-select | 60 |
| 21 | Letter Hunt | `letter_hunt` | Placement | 75 |
| 22 | Number Train | `number_train` | Sequence | 75 |
| 23 | Emotion Match | `emotion_match` | Matching | 60 |
| 24 | Puzzle Parts | `puzzle_parts` | Placement | 60 |
| 25 | Odd One Out | `odd_one_out` | Multi-select | 75 |
| 26 | Opposites | `opposites` | Matching | 60 |
| 27 | Weather Today | `weather_today` | Matching | 60 |
| 28 | Memory Journey | `memory_journey` | Sequence | 75 |
| 29 | Category Expert | `category_expert` | Multi-select | 75 |
| 30 | Build the Story | `build_the_story` | Sequence | 75 |

## Verification Coverage

Games 16-30 are registered in `GameRegistry`, loaded from
`apps/mobile/assets/levels/*.json`, cataloged in the backend, seeded by
Alembic revision `d2a4f8e9b730`, and covered by deterministic content
generation in `tools/content_generators/games_16_30_generator.py`.

Automated gates cover schema validation, malformed fixtures, deterministic
regeneration, solvability, safety audit, backend catalog/migration idempotency,
mobile registry tests, shared-engine regression tests, and Android
integration-test scenarios for offline completion and queueing.

Human review checklists live at
`docs/content-review/milestone-3-games-16-30-review-checklist.csv`.
