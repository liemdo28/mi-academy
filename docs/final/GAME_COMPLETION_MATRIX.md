# Game Completion Matrix

Date: 2026-07-25

## Summary

- Target games: 30
- Registered games: 30
- Level files: 30
- Total bundled levels: 1030
- Locales: Vietnamese and English content present across production level packs.

## Status

| Group | Games | Status |
|-------|-------|--------|
| Letters and language | 9 | Built and content-backed |
| Numbers and math | 12 | Built and content-backed |
| Logic, memory, reasoning | 9 | Built and content-backed |

## Level Counts

| Game | Levels | Notes |
|------|--------|-------|
| Alphabet Explorer | 95 | Bilingual, 3 tiers |
| Missing Letter | 75 | Bilingual, 3 tiers |
| Math Race | 40 | Bilingual, 5 tiers |
| Math Supermarket | 40 | Bilingual, 5 tiers |
| Other 26 games | 30 each | Bilingual, 5 tiers |

## Interaction Depth

- Bespoke/deeper surfaces: Story Comprehension, Reasoning Detective, Memory Cards, Robot Commands, Word Builder, Sound Match, Math Race, Math Supermarket.
- Logic Maze now uses a dedicated movement engine (`logic_maze_movement`) with command queue, simulation, collision/out-of-bounds feedback, undo, reset, save/restore, widget tests, session tests, and 30/30 authored command paths validated against goal reachability.
- Kids Sudoku now uses a dedicated interactive grid engine (`kids_sudoku_grid`) with editable blank cells, fixed givens, row/column/region validation, erase, hints, save/restore, widget tests, session tests, and 30/30 authored answers validated against the grid rules.
- Free Creativity now uses a dedicated participation-based story lab (`creative_story_lab`) with scene, character, feeling, and story-idea composition; it does not grade creativity as right/wrong and saves composition state through the standard snapshot path.
- Shared Choice Engine surfaces remain acceptable for family testing on the remaining expansion games, with richer bespoke interactions recommended as the next quality phase.
