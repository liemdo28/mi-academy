# Game catalog — MI Academy 1.0 (30-game target)

Status verified directly against the working tree on 2026-07-19 (branch
`integration/m1-m2-baseline`) — not carried over from any prior summary.
**8 of 30 games exist; 22 do not.** This is the single largest gap against
the master spec and should not be understated.

Legend: **Built** = playable, has real content, has tests. **Not started**
= no code, no content, no tests exist for this game.

## Update (Milestone 1B): registry + versioned schema

The built games now launch through a central `GameRegistry`
(`apps/mobile/lib/services/game_registry.dart`, see
`docs/game-engine-architecture.md`) instead of a hand-maintained switch
statement, and their level content (`apps/mobile/assets/levels/*.json`)
now conforms to a real versioned schema (`schemas/level.schema.json`, see
`docs/content-schema.md`) with a repository-level validator
(`tools/content_schema_validator.py`). Math Race and Math Supermarket are
expanded to 40 levels each. Word Builder, Sound Match, Robot Commands,
and Memory Cards still need expansion. Alphabet Explorer has 95 bilingual
levels across three tiers, and Missing Letter has 75 bilingual levels
across three tiers. See `docs/release-audit.md` for the remaining open
finding.

## Update (Milestone 2 slice): Alphabet Explorer

`alphabet_explorer` is now registered and playable through the existing
Choice Engine path. It ships as `apps/mobile/assets/levels/alphabet_explorer.json`
with 95 bilingual levels, three difficulty tiers, English A-Z coverage,
Vietnamese extended-letter coverage (`Ă`, `Â`, `Đ`, `Ê`, `Ô`, `Ơ`, `Ư`),
uppercase recognition, lowercase recognition, case matching, first-letter
items, and visual-discrimination items. Evidence: `flutter analyze`,
`flutter test`, `python tools/content_schema_validator.py`, and
`python tools/content_safety_audit.py --json` all pass on 2026-07-18.

## Update (Milestone 2 slice 2): Missing Letter

`missing_letter` is now registered and playable through the existing Choice
Engine path. It ships as `apps/mobile/assets/levels/missing_letter.json`
with 75 bilingual levels, three difficulty tiers, missing-position metadata,
exactly one correct choice per locale, and validator coverage for ambiguous
multi-gap items, answer length mismatches, missing correct choices, and
out-of-range positions. Evidence on 2026-07-19: `flutter analyze`,
`flutter test`, `python tools/content_schema_validator.py`,
`python tools/content_schema_validator.py --check-malformed`, and
`python tools/content_safety_audit.py --json` pass.

## Group A — Chữ và ngôn ngữ (Letters & language)

| # | Name | Age | Status | Evidence |
|---|---|---|---|---|
| 01 | Khám phá chữ cái | 5–7 | **Built** | `alphabet_explorer` in `GameRegistry`; `apps/mobile/assets/levels/alphabet_explorer.json` has 95 bilingual Choice Engine levels across 3 tiers; covered by `alphabet_explorer_content_test.dart`, `game_registry_test.dart`, and `game_screen_test.dart` |
| 02 | Ghép chữ tạo từ | 5–9 | **Built** | `apps/mobile/lib/src/games/word_builder/`; 10/10 levels solvable (`tools/level_validator/solve_levels.py`); VI content only in test fixtures — production level content locale coverage not separately re-verified this pass beyond the `contentForLocale` plumbing fix |
| 03 | Nghe âm tìm chữ | 5–7 | **Built** | `apps/mobile/lib/src/games/sound_match/`; 10/10 levels solvable |
| 04 | Tìm chữ còn thiếu | 6–9 | **Built** | `missing_letter` in `GameRegistry`; `apps/mobile/assets/levels/missing_letter.json` has 75 bilingual Choice Engine levels across 3 tiers; covered by `missing_letter_content_test.dart`, `game_registry_test.dart`, and `game_screen_test.dart` |
| 05 | Nối từ với hình | 5–8 | Not started | — |
| 06 | Vần nào đúng? | 6–9 | Not started | — |
| 07 | Chính tả nhanh | 8–12 | Not started | — |
| 08 | Sắp xếp câu | 8–12 | Not started | — |
| 09 | Đọc hiểu truyện ngắn | 8–12 | Not started | — |

## Group B — Số và toán học (Numbers & math)

| # | Name | Age | Status | Evidence |
|---|---|---|---|---|
| 10 | Đếm đồ vật | 5–7 | Not started | — |
| 11 | Ghép số với số lượng | 5–7 | Not started | — |
| 12 | So sánh lớn và bé | 5–8 | Not started | — |
| 13 | Đường đua cộng trừ | 6–10 | **Built** | `apps/mobile/lib/src/games/choice/` (shared `ChoiceGameScreen`); 40 levels; expansion complete |
| 14 | Hoàn thành dãy số | 6–10 | Not started | — |
| 15 | Siêu thị toán học | 7–11 | **Built** | Same `choice` engine; 40 levels; expansion complete |
| 16 | Bảng nhân phiêu lưu | 8–11 | Not started | — |
| 17 | Chia đều kho báu | 8–11 | Not started | — |
| 18 | Đồng hồ và thời gian | 7–11 | Not started | — |
| 19 | Đo lường vui nhộn | 8–12 | Not started | — |
| 20 | Hình học lắp ghép | 6–12 | Not started | — |
| 21 | Phân số trực quan | 9–12 | Not started | — |

## Group C — Logic, trí nhớ và suy luận (Logic, memory, reasoning)

| # | Name | Age | Status | Evidence |
|---|---|---|---|---|
| 22 | Ghi nhớ vị trí | 5–12 | **Built** | `apps/mobile/lib/src/games/memory_cards/`; 10/10 levels solvable |
| 23 | Tìm hình khác biệt | 5–10 | Not started | — |
| 24 | Ghép bóng với vật | 5–8 | Not started | — |
| 25 | Robot làm theo lệnh | 6–12 | **Built** | `apps/mobile/lib/src/games/robot_commands/`; 10/10 maps solvable; only straight-line moves implemented per current content — spec's "mức cao: vòng lặp đơn giản, lệnh lặp" (loop commands) not yet in the engine or content |
| 26 | Mê cung logic | 6–12 | Not started | Distinct from Robot Commands' grid — needs its own maze/trap/collectible content, not just a relabeled Robot Commands map |
| 27 | Tìm quy luật | 7–12 | Not started | — |
| 28 | Sudoku trẻ em | 8–12 | Not started | — |
| 29 | Thám tử suy luận | 9–12 | Not started | — |
| 30 | Sáng tạo tự do | 5–12 | Not started | — |

## Summary

- **Built: 8/30** (alphabet_explorer, missing_letter, word_builder,
  sound_match, math_race, math_supermarket, memory_cards, robot_commands) —
  all pass `flutter analyze`. Alphabet Explorer contributes 95 bilingual,
  schema-validated levels; Missing Letter contributes 75 bilingual,
  schema-validated levels; the earlier six remain at 10 levels each.
- **Not started: 22/30** — no engine code, no content, no tests exist. This
  is not a content-authoring gap alone; several of these games map to
  engine types that don't exist yet at all (see
  `docs/game-engine-architecture.md`): Text Input Engine (07, 08), Story
  and Quiz Engine (09), Grid and Maze Engine distinct from Robot Commands
  (26), Logic Grid Engine (28, 29), Simulation Engine (30's
  garden/room-design mode), Puzzle Placement Engine (20's shape assembly).
- Per-game minimum content bars from spec §7 (≥60 quiz items, ≥30 puzzle
  levels, ≥15 stories, ≥30 maze maps, ≥30 logic puzzles, 3 difficulty
  tiers, bilingual) have **not** been verified against the 6 built games
  either — the existing games currently ship with far fewer items (10
  levels each, used for both difficulty progression and content variety
  combined, not 60+ distinct quiz items). This is a real gap on the 6
  "built" games too, not just the 22 missing ones — see
  `docs/release-audit.md` RA-15.

## Honest effort estimate

Building one new game to the full Definition-of-Done bar in §38 (engine
implementation or reuse, ≥3 difficulty tiers, ≥20–60 content items per
spec's per-genre minimum, bilingual authored content, hint/retry/pause/
resume/exit/completion/stars/badges wiring, offline persistence,
accessibility, unit+widget+integration tests, no TODOs) is comparable in
scope to how the 6 existing games were originally built — each represents
multiple engineering days of dedicated work, not something safely
compressed into a shared session alongside 40 other requirements. Treat the
24 "Not started" rows as a multi-week backlog, not a checklist to rush.
