# Game engine architecture

The MI Academy 1.0 master spec (§5) requires ~10–12 reusable engines rather
than 30 bespoke codebases. This document maps the **6 existing games**
against the spec's 12 named engine types and records what already exists
vs. what would need to be built for the 24 missing games. This is an
architectural assessment, not a claim that the refactor has been done.

## Current reality

There is no formal shared-engine abstraction today. Each of the 6 existing
games has its own `*Session` class (`WordBuilderSession`,
`SoundMatchSession`, `ChoiceGameSession`, `RobotCommandsSession`,
`MemoryCardsGame`) implementing the common `mi_game_core` contracts
(`MiGameContext`, `MiGameResult`, `MiGameSnapshot`, `MiCompletionResult` —
see `packages/game_core`) directly, with substantial duplicated
scaffolding between them (score/stars formulas, hint counters, snapshot
save/restore, locale-content lookup are each reimplemented per game rather
than shared). `ChoiceGameScreen`/`ChoiceGameSession` is the one place two
games (Math Race, Math Supermarket) already share one implementation —
that's the closest existing precedent for the spec's engine-reuse model.

## Mapping existing games to the spec's 12 engine types

| Spec engine | Existing game(s) using this shape | Notes |
|---|---|---|
| 1. Choice Engine | Math Race, Math Supermarket (`ChoiceGameSession`) | Already shared between 2 games — closest thing to a real "engine" today |
| 2. Multi-select Engine | none | Not built |
| 3. Drag-and-drop Engine | Word Builder (letter placement is drag-like but implemented as tap-to-place, not a generic drag engine) | Partial precedent only |
| 4. Matching Engine | none formally, but Sound Match's "pick the option matching the audio" is matching-shaped | Not extracted as a shared engine |
| 5. Memory Engine | Memory Cards (`MemoryCardsGame`) | Single-game implementation, not yet generalized (e.g. can't easily spin up "Ghép bóng với vật" (Game 24) from it without duplicating the flip/match logic) |
| 6. Sequence Engine | none | Not built (needed for Game 14 dãy số, Game 27 tìm quy luật) |
| 7. Grid and Maze Engine | Robot Commands (`RobotGrid`, `RobotState`, `BlockInterpreter` in `packages/mi_blocks`) | Real grid/pathing logic exists but is coupled to the command-program interaction model; a plain maze game (Game 26) would need the grid/collision logic decoupled from the block-programming UI |
| 8. Text Input Engine | none | Not built (needed for Game 07 chính tả, Game 08 sắp xếp câu) |
| 9. Story and Quiz Engine | none | Not built (needed for Game 09 đọc hiểu) |
| 10. Simulation Engine | none | Not built (needed for Game 30's garden/room design mode) |
| 11. Puzzle Placement Engine | none | Not built (needed for Game 20 hình học lắp ghép) |
| 12. Logic Grid Engine | none | Not built (needed for Game 28 Sudoku, Game 29 thám tử suy luận) |

**4 of 12 engine types have any real precedent; 8 have none.** Building
the missing 8 engines generically (rather than as 24 one-off
implementations) is itself a multi-week architecture effort before any of
the 24 missing games' content can be authored against them.

## What a real consolidation would require

1. Extract the duplicated cross-cutting concerns (score/stars formula,
   hint budget tracking, snapshot save/restore, locale-content lookup,
   pause/resume/exit state machine) out of the 5 existing `*Session`
   classes into a shared base — this alone is a non-trivial refactor of
   working, tested code and must preserve all currently-passing tests
   (`flutter test`'s 86 passing tests exercise this logic today).
2. Design each of the 8 missing engines' public contract (what content
   schema it consumes, what actions it accepts, what result shape it
   produces) *before* writing games against it, so games 07–09, 14, 16–21,
   23–24, 26–30 aren't each hand-rolled again.
3. Only then author the 24 games' content and thin per-game
   configuration/skin on top of the shared engines.

## Recommendation

Do not attempt this refactor opportunistically while also trying to ship
24 new games in the same pass — the existing 6 games' tests (86 passing,
0 failing) are the only regression safety net today, and a broad
engine-consolidation refactor done under time pressure risks silently
breaking them (violates the working rule against rewriting working
architecture without a scoped, reviewed reason). This should be its own
dedicated phase (matches the master spec's own §35 Phase 3 "Core
architecture" step, sequenced *before* Phase 5's "Build game 7–15") with
its own test-preservation plan, not folded into this session.
