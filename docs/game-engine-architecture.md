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

## Update: Matching Engine built (Milestone 1B, 2026-07-18)

One of the four Milestone 1 WS5 engines — **Matching Engine** — is now a
real, tested, shared component: `packages/mi_game_engines/` (new package,
`lib/src/matching/{matching_content,matching_controller,matching_screen}.dart`).

- **Typed content model**: `MatchingContent`/`MatchingPair`/`MatchingItem`
  (not an untyped `Map`), parsed via `MatchingContent.fromJson` with
  actionable `MatchingContentException` messages for malformed input
  (missing fields, out-of-range difficulty, empty pairs, duplicate pair
  IDs) rather than a bare cast failure.
- **Controller**: `MatchingController` (plain `ChangeNotifier`, no
  dependency on Riverpod/Provider/any child-profile repository) — tap-to-
  match selection state, attempt counting, 3/2/1-star scoring (same
  formula shape as the five Python game engines'
  `calculate_stars`), hint show/dismiss, pause/resume, retry.
- **Renderer**: `MatchingScreen` — two shuffled columns (deterministic
  per-content-id shuffle, not `dart:math`'s `Random` directly, so tests are
  reproducible), correct/incorrect feedback banner, hint banner, pause
  overlay, completion view with stars, and a recoverable error screen for
  malformed content (verified via a widget test that deliberately pumps
  broken JSON and asserts the error state renders instead of throwing).
  Responsive via `LayoutBuilder` (wider padding above 600 logical pixels);
  `reducedMotion` collapses `AnimatedContainer` durations to zero
  (verified by a widget test asserting every `AnimatedContainer.duration`
  is `Duration.zero`); every tappable item has a `Semantics` label.
- **Example content**: one Vietnamese and one English example (a letter↔
  picture matching level), used directly in the test suite, not left as an
  untested placeholder.
- **Tests**: `packages/mi_game_engines/test/matching_engine_test.dart` — 19
  tests covering content parsing (valid VI, valid EN, missing field,
  invalid difficulty, empty pairs, duplicate IDs), controller behavior
  (correct/incorrect pair, no-op on re-selecting a matched item, retry,
  perfect-run 3 stars, degraded-attempts fewer stars, pause/resume, hint
  toggle), and widget behavior (renders instruction + both columns, error
  state for malformed content, full completion flow calling `onComplete`,
  reduced-motion durations). All 19 pass; `flutter analyze` on the package
  is clean.

## Update: Sequence Engine built (Milestone 1C, 2026-07-18)

The second of the four Milestone 1 WS5 engines is now real and tested:
`packages/mi_game_engines/lib/src/sequence/{sequence_content,sequence_controller,sequence_screen}.dart`.

- **Typed content model**: `SequenceContent`/`SequenceItem`/`SequenceRule`.
  Supports both interaction modes required by the spec — full reorder
  (child reconstructs a scrambled sequence) and missing-item (one or more
  blanks filled from a choice list) — and five rule types: `fixed`,
  `ascending`, `descending`, `alternating`, `repeating`. `fromJson`
  cross-validates the authored `correctOrder` against the declared rule
  (e.g. an `ascending` rule with `step: 2` is rejected if the authored
  order doesn't actually increase by 2 each step), catching authoring
  mistakes at load time rather than silently accepting a nonsensical
  level.
- **Controller**: `SequenceController` (`ChangeNotifier`, no framework/
  child-profile dependency) — `moveItem` (shared by drag and tap-based
  reordering), `submitReorder`/`submitMissingItems`, 3/2/1-star scoring,
  hint, pause/resume, retry. Reorder mode's initial shuffle uses the same
  deterministic-per-content-id PRNG pattern as Matching Engine.
- **Renderer**: `SequenceScreen` — `ReorderableListView` for drag
  reordering, plus explicit move-left/move-right buttons on every item as
  the accessibility fallback the spec requires (verified by a widget test
  that drives reordering *only* through those buttons, never a raw drag
  gesture); missing-item mode renders known values as chips and blanks as
  tappable slots with a shuffled choice row; recoverable error screen for
  malformed content.
- **Examples**: Vietnamese ascending (2,4,6,8), English descending
  (12,9,6), a fixed-order Vietnamese picture-story sequence, and a
  Vietnamese alternating-pattern missing-item level — four real samples,
  not one.
- **Tests**: 23 (10 content-parsing incl. 5 malformed-input cases testing
  each rule type's own validation, 8 controller behavior, 5 widget incl.
  the error state and the button-only reorder path). All pass; `flutter
  analyze` clean.

## Update: Drag-and-drop Placement Engine built (2026-07-19)

The third of the four Milestone 1 WS5 engines is now real and tested:
`packages/mi_game_engines/lib/src/placement/{placement_content,placement_controller,placement_screen}.dart`.

- **Typed content model**: `PlacementItem`/`PlacementTarget`/
  `PlacementRule`/`PlacementConfiguration`/`PlacementContent`. Supports
  one-to-one placement (each item names exactly one target, each target
  has capacity 1), many-to-one/category-sorting placement (several
  items share one target with capacity > 1), and rotation-aware items
  (`rotationDegrees`, validated against a configured allowed set).
  `PlacementRule` supports two matching strategies: explicit id lists
  (`item.acceptedTargetIds` / `target.acceptedItemIds`) or a shared
  `metadata` category key, so category sorting doesn't require
  repeating a target id on every item.
- **Validation**: `PlacementContent.fromJson` rejects, with an
  actionable message naming the content id and specific item/target at
  fault, rather than a bare cast failure or a later assertion: duplicate
  item/target ids, empty items/targets, unknown item/target references,
  non-positive capacity, total demand exceeding total supply, an item
  with no valid target, a target with no valid item, contradictory
  explicit item/target rules, exclusive-demand impossible-completion
  states (an item that can *only* go on one target, stacked past that
  target's capacity — a stronger check than the blanket total-supply
  one), unsupported rotation, invalid position/size metadata, and
  unsupported schema versions.
- **Controller**: `PlacementController` (`ChangeNotifier`, no framework/
  child-profile dependency) — `selectItem`/`placeItem`/`moveItem`/
  `removeItem`/`reset`/`restart`/`useHint` (as `requestHint`)/`pause`/
  `resume`/`complete`. A failed placement or move never corrupts state:
  the item's previous target is tentatively released and restored
  exactly if the new placement fails validation. Completion requires
  every item to be *validly* placed — not merely every target having at
  least one item (the spec's own explicit warning against that
  shortcut). 3/2/1 stars by incorrect-attempt count (same shape as
  Matching/Sequence), a 0-100 score with moderate deductions floored at
  0, and a `Duration` computed from an injectable clock (real
  `DateTime.now` by default, a fake clock in tests).
- **Normalized result**: `PlacementResult` (`engineId`/`contentId`/
  `attempts`/`correctCount`/`incorrectCount`/`hintCount`/`score`/
  `stars`/`duration`/`completed`/`placements`), delivered via an
  `onComplete` callback — the engine never writes to Hive, a backend
  API, or analytics itself.
- **Renderer**: `PlacementScreen` — a `LayoutBuilder`-driven layout that
  stacks target/source areas vertically on narrow phones and
  side-by-side on wider/tablet screens, both built on `Wrap` rather than
  a fixed-width `Row` for the dynamic item/target collections (the same
  lesson learned from the `ProgressDots` overflow bug — see
  `docs/final/MILESTONE_1C_REPORT_2026-07-19.md` §3.2 — dynamic
  collection sizes must not depend on a layout that only worked for a
  small sample). Drag interaction always accepts the drop itself (an
  invalid drop still registers as an attempt and shows feedback, rather
  than being silently swallowed by Flutter's own accept-gating); tap
  accessibility (select an item, tap a target) makes every level
  completable without any drag gesture. Reduced motion collapses the
  target-highlight animation duration to zero without removing the
  highlight itself. **Zero hardcoded Vietnamese/English production text
  in the engine's own source** — every UI string is supplied by the host
  via a required `PlacementLocalization`.
- **Examples**: a Vietnamese one-to-one letter-placement level ("MÈO"),
  an English one-to-one shape-placement level, a Vietnamese many-to-one
  category-sorting level (animals/food, matched via shared metadata),
  and an English rotation-aware shape level (text-only, no asset
  dependency) — four real samples, not one.
- **Tests**: 57 in `test/placement_engine_test.dart` (19 content-
  validation, 18 controller, 20 widget covering both locales, drag and
  tap interaction, capacity/move/remove, reduced motion, sound-disabled,
  semantics, narrow-phone and tablet layouts, and malformed content).
  All pass; `flutter analyze` on the package is clean.
- **Shared engine contract suite**: `test/engine_contract_test.dart` now
  checks Matching, Sequence, and Placement together — stable distinct
  `engineId` (added as a purely additive constant to
  `MatchingController`/`SequenceController`, changing nothing about
  either's existing API), attempt counting, completion, star bounds for
  all three, Placement's full normalized-result shape, and an automated
  check that no engine source file imports a storage/backend/analytics
  package.

## Update: Multi-select Engine built (2026-07-19)

The fourth and final Milestone 1 WS5 engine is now real and tested:
`packages/mi_game_engines/lib/src/multi_select/{multi_select_content,multi_select_controller,multi_select_screen}.dart`.

- **Typed content model**: `MultiSelectOption`/`MultiSelectConfiguration`/
  `MultiSelectContent`, plus typed validation errors, state, attempts,
  evaluations, hints, outcomes, and normalized result objects. Content has
  `schemaVersion`, `contentId`, `instruction`, `prompt`, `options`,
  `configuration`, and `metadata`; options support text, image, mixed
  text/image, semantic labels, explanations, correctness, and metadata.
- **Configuration**: explicit or automatic submission
  (`MultiSelectSubmissionMode`, with `MultiSelectSubmitMode` alias for
  compatibility), exact-match or partial-credit evaluation, deterministic
  shuffle (`shuffleOptions`/`shuffleSeed`), min/max selections,
  `allowDeselect`, retry enablement/mode/max attempts, reveal policy,
  selection-count display, auto-submit count, hint modes, and scoring
  penalties.
- **Validation**: `MultiSelectContent.fromJson` rejects with typed,
  actionable `MultiSelectValidationError`s (`contentId`, field, code,
  optional `optionId`, reason). Covered rejections include unsupported
  schema version, blank required ids/instruction/prompt, empty options,
  duplicate ids, duplicate visible options, no correct answer, invalid
  min/max, impossible exact-match windows, invalid auto-submit counts,
  invalid attempts, image-only options without semantics, missing visible
  content, blank/unsupported asset ids, invalid penalty ranges, and
  impossible completion states.
- **Controller**: `MultiSelectController` (`ChangeNotifier`, no
  framework/child-profile dependency) — `select`/`deselect`/`toggle`/
  `clear`, explicit or auto-triggered `submit`, typed hint sequencing
  (`authoredHint`, `expectedSelectionCount`, `revealCorrectOption`,
  `eliminateIncorrectOption`), `revealCorrectAnswers`, `pause`/`resume`
  with injected-clock duration accounting, `retry` (honors `retryMode`)
  vs. `restart` (always clears), reset, idempotent `complete`, max-attempt
  terminal exhaustion, and callback-once completion.
  `exactMatch` only completes on an exact selection match (retryable
  otherwise); `partialCredit` completes on any valid-size submission,
  with score using the documented formula:
  `correctRatio - (incorrectRatio * incorrectSelectionPenalty)`, clamped
  to 0..1, then converted to 0..100 and reduced by attempt/hint penalties.
  Both modes floor score at 0 and share one score-to-stars mapping so "3
  stars" means the same thing regardless of evaluation mode.
- **Normalized result**: `MultiSelectResult` (`engineId`/`contentId`/
  `attempts`/`correctSubmissionCount`/`incorrectSubmissionCount`/
  `hintCount`/`score`/`stars`/`duration`/`completed`/
  `selectedOptionIds`/`correctOptionIds`/`missedCorrectOptionIds`/
  `incorrectlySelectedOptionIds`/`evaluationMode`/`submissionMode`) via
  an `onComplete` callback — no persistence dependency, verified by the
  same automated check as the other three engines.
- **Renderer**: `MultiSelectScreen` — options render as Material
  `FilterChip`s (selection state, an avatar slot for asset-flavored
  options, eliminated options visually greyed and disabled), chosen
  because `FilterChip` already provides real keyboard focus/activation
  and selection semantics built into the framework rather than
  reimplementing that by hand. A `Wrap`, not a fixed-width `Row`, for the
  same dynamic-collection-size reason as Placement/ProgressDots. Submit/
  clear buttons are hidden entirely in auto-submit mode. **Zero
  hardcoded Vietnamese/English production text** — every UI string comes
  from a required `MultiSelectLocalization`.
- **Examples**: Vietnamese vowels (exact match), English animals (exact
  match, category sorting), English even numbers (partial credit —
  score prorated rather than requiring an exact match to complete),
  English quadrilaterals (asset-flavored options, no real asset file
  dependency), and a Vietnamese auto-submit sample (submits the moment 2
  of 3 options are selected, no submit button rendered) — five real
  samples.
- **Tests**: 58 in `test/multi_select_engine_test.dart` (5 valid-parse +
  15 rejection, 26 controller, 12 widget covering both extra locale
  samples, asset avatars, auto-submit, all three hint actions, reduced
  motion, sound-disabled, semantics, narrow-phone and tablet layouts,
  and malformed content). All pass; `flutter analyze` clean.
- **Shared engine contract suite**: `test/engine_contract_test.dart`
  extended to a 4th engine — Multi-select's stable `engineId` joins the
  distinctness check, its own attempt-counting/completion test, and its
  full normalized-result shape alongside Placement's.

**All four Milestone 1 WS5 engines are now real and tested: Matching,
Sequence, Placement, Multi-select.** 165 tests total in
`packages/mi_game_engines` (19 + 23 + 57 + 58 + 8 shared contract).

**Not wired into any of the six (or eight) existing games or the game
registry this pass** — `packages/mi_game_engines` is a standalone
package with its own tests; migrating an existing game onto it, or
building a new game against it, is separate follow-up work (see
docs/game-catalog.md and WS6 in docs/release-audit.md).

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
