# Game catalog — MI Academy 1.0 (30-game target)

Status verified directly against the working tree on 2026-07-24 (branch
`integration/m1-m2-baseline`) — not carried over from any prior summary.
**30 of 30 games are now registered, content-backed, and playable.** The
22 games added in the 30-game completion pass started from dedicated
bilingual level packs with 30 levels each and five difficulty tiers. Five
of the highest-impact packs now render through deeper bespoke play
surfaces instead of the plain Choice Engine: Story Comprehension, Logic
Maze, Kids Sudoku, Reasoning Detective, and Free Creativity.

Legend: **Built** = playable, has real content, has tests. **Choice
expansion** = built on the shared Choice Engine with a dedicated bilingual
level pack. **Deep UI** = backed by the same level-pack system but rendered
with a bespoke play surface for that learning mode.

## Update (Milestone 1B): registry + versioned schema

The built games now launch through a central `GameRegistry`
(`apps/mobile/lib/services/game_registry.dart`, see
`docs/game-engine-architecture.md`) instead of a hand-maintained switch
statement, and their level content (`apps/mobile/assets/levels/*.json`)
now conforms to a real versioned schema (`schemas/level.schema.json`, see
`docs/content-schema.md`) with a repository-level validator
(`tools/content_schema_validator.py`). Math Race and Math Supermarket are
expanded to 40 levels each. Since that milestone, Word Builder, Sound
Match, Robot Commands, and Memory Cards have also been expanded to 30
levels. Alphabet Explorer has 95 bilingual levels across three tiers, and
Missing Letter has 75 bilingual levels across three tiers.

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
| 02 | Ghép chữ tạo từ | 5–9 | **Built** | `apps/mobile/lib/src/games/word_builder/`; 30 bilingual levels, 5 difficulty tiers |
| 03 | Nghe âm tìm chữ | 5–7 | **Built** | `apps/mobile/lib/src/games/sound_match/`; 30 bilingual levels, 5 difficulty tiers |
| 04 | Tìm chữ còn thiếu | 6–9 | **Built** | `missing_letter` in `GameRegistry`; `apps/mobile/assets/levels/missing_letter.json` has 75 bilingual Choice Engine levels across 3 tiers; covered by `missing_letter_content_test.dart`, `game_registry_test.dart`, and `game_screen_test.dart` |
| 05 | Nối từ với hình | 5–8 | **Built — Choice expansion** | `picture_word_match`; 30 bilingual levels, 5 difficulty tiers |
| 06 | Vần nào đúng? | 6–9 | **Built — Choice expansion** | `rhyme_picker`; 30 bilingual levels, 5 difficulty tiers |
| 07 | Chính tả nhanh | 8–12 | **Built — Choice expansion** | `speed_spelling`; 30 bilingual levels, 5 difficulty tiers |
| 08 | Sắp xếp câu | 8–12 | **Built — Choice expansion** | `sentence_order`; 30 bilingual levels, 5 difficulty tiers |
| 09 | Đọc hiểu truyện ngắn | 8–12 | **Built — Deep UI** | `story_comprehension`; reading-lab surface, 30 bilingual levels, 5 difficulty tiers |

## Group B — Số và toán học (Numbers & math)

| # | Name | Age | Status | Evidence |
|---|---|---|---|---|
| 10 | Đếm đồ vật | 5–7 | **Built — Choice expansion** | `object_counting`; 30 bilingual levels, 5 difficulty tiers |
| 11 | Ghép số với số lượng | 5–7 | **Built — Choice expansion** | `number_quantity_match`; 30 bilingual levels, 5 difficulty tiers |
| 12 | So sánh lớn và bé | 5–8 | **Built — Choice expansion** | `greater_less`; 30 bilingual levels, 5 difficulty tiers |
| 13 | Đường đua cộng trừ | 6–10 | **Built** | `apps/mobile/lib/src/games/choice/` (shared `ChoiceGameScreen`); 40 levels; expansion complete |
| 14 | Hoàn thành dãy số | 6–10 | **Built — Choice expansion** | `number_sequence`; 30 bilingual levels, 5 difficulty tiers |
| 15 | Siêu thị toán học | 7–11 | **Built** | Same `choice` engine; 40 levels; expansion complete |
| 16 | Bảng nhân phiêu lưu | 8–11 | **Built — Choice expansion** | `multiplication_adventure`; 30 bilingual levels, 5 difficulty tiers |
| 17 | Chia đều kho báu | 8–11 | **Built — Choice expansion** | `treasure_division`; 30 bilingual levels, 5 difficulty tiers |
| 18 | Đồng hồ và thời gian | 7–11 | **Built — Choice expansion** | `clock_time`; 30 bilingual levels, 5 difficulty tiers |
| 19 | Đo lường vui nhộn | 8–12 | **Built — Choice expansion** | `fun_measurement`; 30 bilingual levels, 5 difficulty tiers |
| 20 | Hình học lắp ghép | 6–12 | **Built — Choice expansion** | `shape_builder`; 30 bilingual levels, 5 difficulty tiers |
| 21 | Phân số trực quan | 9–12 | **Built — Choice expansion** | `visual_fractions`; 30 bilingual levels, 5 difficulty tiers |

## Group C — Logic, trí nhớ và suy luận (Logic, memory, reasoning)

| # | Name | Age | Status | Evidence |
|---|---|---|---|---|
| 22 | Ghi nhớ vị trí | 5–12 | **Built** | `apps/mobile/lib/src/games/memory_cards/`; 30 bilingual levels, 5 difficulty tiers |
| 23 | Tìm hình khác biệt | 5–10 | **Built — Choice expansion** | `odd_one_out`; 30 bilingual levels, 5 difficulty tiers |
| 24 | Ghép bóng với vật | 5–8 | **Built — Choice expansion** | `shadow_match`; 30 bilingual levels, 5 difficulty tiers |
| 25 | Robot làm theo lệnh | 6–12 | **Built** | `apps/mobile/lib/src/games/robot_commands/`; 30 bilingual levels, 5 difficulty tiers, including turn/sequence practice and existing loop-command content |
| 26 | Mê cung logic | 6–12 | **Built — Deep UI** | `logic_maze`; maze-planner surface, 30 bilingual levels, 5 difficulty tiers |
| 27 | Tìm quy luật | 7–12 | **Built — Choice expansion** | `pattern_finder`; 30 bilingual levels, 5 difficulty tiers |
| 28 | Sudoku trẻ em | 8–12 | **Built — Deep UI** | `kids_sudoku`; sudoku-grid surface, 30 bilingual levels, 5 difficulty tiers |
| 29 | Thám tử suy luận | 9–12 | **Built — Deep UI** | `reasoning_detective`; clue-board surface, 30 bilingual levels, 5 difficulty tiers |
| 30 | Sáng tạo tự do | 5–12 | **Built — Deep UI** | `free_creativity`; story-lab surface, 30 bilingual levels, 5 difficulty tiers |

## Summary

- **Built: 30/30** target games are registered in `GameRegistry`, have
  bundled level assets, and are covered by loader/registry/taxonomy tests.
- The 22 newer games each contribute 30 bilingual level packs across five
  difficulty tiers. Five now have deeper bespoke play surfaces, while the
  remaining expansion games still use the shared Choice Engine. The already
  expanded games remain:
  Alphabet Explorer (95 levels), Missing Letter (75 levels), Math Race
  (40 levels), Math Supermarket (40 levels), plus Word Builder, Sound
  Match, Memory Cards, and Robot Commands expanded to 30 levels each.
- Remaining product polish gap: the deep surfaces are still powered by the
  current level packs; later content passes can add richer per-level maze
  maps, sudoku givens, detective clue sets, and creative/story artifacts.

## Honest effort estimate

The remaining work is no longer getting to 30 playable games. The next
quality jump is enriching the five new deep surfaces with more structured
per-level data: maze maps, sudoku givens, detective clue sets, reading
passages, and creative/story artifacts.
