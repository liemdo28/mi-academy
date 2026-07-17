# MVP Games Implementation Report

**Date:** 2026-07-17
**Status:** COMPLETE

## 1. Game Inventory

| # | Game | ID | Levels | Tech | Status |
|---|------|-----|--------|------|--------|
| 1 | Memory Cards | memory_cards | 10 | Flutter-native | DONE |
| 2 | Word Builder | word_builder | 10/vi + 10/en | Flutter-native | DONE |
| 3 | Sound Match | sound_match | 10 | Flutter-native | DONE |
| 4 | Math Race | math_race | MVP | ChoiceGameScreen | DONE |
| 5 | Math Supermarket | math_supermarket | MVP | ChoiceGameScreen | DONE |
| 6 | Robot Commands | robot_commands | 20 | mi_blocks + Flutter | DONE |

## 2. Memory Cards (`apps/mobile/lib/src/games/memory_cards/`)

Full `MiGame` implementation. Card grid with flip animation. Shuffle via Fisher-Yates. Match detection via pairId. Mismatch auto-flip after 1200ms. Score: +10 per match. Stars: 3 if score >= pairs*15, 2 if >= pairs*10, else 1. Snapshot saves card states, matched pairs, score.

## 3. Word Builder (`apps/mobile/lib/src/games/word_builder/`)

Letter bank + answer slot mechanic. Letter placement by tapping. Remove by tapping placed letter. Check validates complete word. Score: 100 - (attempts-1)*10 - hintsUsed*5. Stars: 3 if 1 attempt + no hints.

## 4. Sound Match (`apps/mobile/lib/src/games/sound_match/`)

Audio prompt card with replay button. Transcript reveal on replay. Multiple choice options. Hint shows transcript early. Score/stars same formula.

## 5. Math Race + Math Supermarket

Both use `ChoiceGameScreen` — a reusable multiple-choice game widget with progress bar, hint button, star rating, next/replay/exit. Configured via `title`, `heroIcon`, `primaryColor` props.

## 6. Robot Commands (`apps/mobile/lib/src/games/robot_commands/`)

Uses mi_blocks package. Grid-based robot navigation. Program editor: add/remove/reorder commands. `BlockInterpreter` executes with maxSteps=1000. Vietnamese error messages for obstacles.

## 7. Shared Patterns

- All games: bilingual (vi/en), child-friendly strings, Semantic labels
- All games: pause/resume support, tutorial overlay, hint system
- All games: completion overlay with 1-3 stars, next/replay/exit
- All games: ProgressDots for level progression
- No floating-point for Math Supermarket (integer cents)
- No auth tokens, GPS, contacts, or payment info to any game
