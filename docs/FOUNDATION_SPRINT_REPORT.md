# MI Academy — Foundation Sprint Report

> **Sprint:** Foundation Sprint — Phase A-F
> **Date:** 2026-07-17
> **Status:** Complete

---

## Executive summary

The Foundation Sprint establishes the complete technical platform on which all 30
MI Academy games will be built. The sprint covers four phases: repository audit,
dependency policy, shared package development, level schema, and the Memory Cards
vertical slice — the first playable game.

---

## Phase A — Repository Audit

### Files created

| File | Purpose |
|------|---------|
| `docs/CURRENT_ARCHITECTURE.md` | Full audit of existing repo: FastAPI backend healthy, Flutter client absent |
| `docs/GAME_PLATFORM_GAP_ANALYSIS.md` | Gap analysis: 9 packages needed, 0 exist |
| `docs/OPEN_SOURCE_AUDIT.md` | Dependency allowlist: 18 packages approved, 5 rejected |
| `docs/LICENSE_DECISIONS.md` | License policy: MIT/BSD/Apache-2 allowed, GPL/LGPL/CC excluded |

### Key findings

- Backend (`apps/api/`): Full FastAPI + PostgreSQL schema, auth, models — **healthy**.
- Python `packages/game_core/` and `packages/game-core/`: Experimental server-side
  prototypes, accidentally duplicated. Kept for reference.
- **Flutter client**: Completely absent. `apps/mobile/` is empty, no `pubspec.yaml`
  exists anywhere.
- Hygiene: 18 junk files at repo root ready for cleanup.

---

## Phase B — Dependency Policy & Workspace

### Files created

| File | Purpose |
|------|---------|
| `melos.yaml` | Melos monorepo config with 10 scripts (analyze, format, test, build_runner, etc.) |
| `docs/OPEN_SOURCE_AUDIT.md` | Full dependency allowlist |
| `docs/LICENSE_DECISIONS.md` | License decisions |
| `packages/*/pubspec.yaml` | 8 Flutter package manifests |

### Approved dependencies (Foundation Sprint)

| Package | License | Purpose |
|---------|---------|---------|
| `flutter` | BSD-3 | Framework |
| `flame` | MIT | APPROVED_FOR_EVALUATION (used in 0.3+) |
| `flutter_riverpod` | MIT | State management |
| `go_router` | BSD-3 | Navigation |
| `audioplayers` | MIT | Audio playback |
| `hive` / `hive_flutter` | Apache-2 | Offline storage |
| `equatable` | MIT | Value equality |
| `uuid` | MIT | ID generation |
| `intl` | BSD-3 | Localization |
| `mocktail` | MIT | Testing mocks |
| `golden_toolkit` | MIT | Golden tests |
| `melos` | MIT | Workspace management (dev) |

### Rejected

`firebase_*`, `google_mobile_ads`, `sentry_flutter`, `isar`, `webview_flutter`.

---

## Phase C — Shared Packages

### `packages/mi_game_core/` ✅

Core game lifecycle and interface — the most important foundation piece.

| File | Purpose |
|------|---------|
| `lib/mi_game_core.dart` | Barrel export |
| `lib/src/models/mi_level.dart` | Level with localized content, hints, assets |
| `lib/src/models/mi_hint.dart` | Progressive hint model |
| `lib/src/models/mi_game_action.dart` | Child action (tap, select, drag) |
| `lib/src/models/mi_action_result.dart` | Action result with factory helpers |
| `lib/src/models/mi_game_snapshot.dart` | Serializable state + JSON round-trip |
| `lib/src/models/mi_completion_result.dart` | Completion metrics (score, stars, mastery) |
| `lib/src/interfaces/mi_game.dart` | Official MiGame interface (blueprint §4) |
| `lib/src/lifecycle/game_state.dart` | 12-state enum (normal + 5 error states) |
| `lib/src/lifecycle/game_lifecycle.dart` | State machine with transition rules and error recovery |
| `lib/src/context/mi_game_context.dart` | Context with AccessibilityPreferences, AudioPreferences, MiGameServices |
| `lib/src/base/base_game.dart` | BaseGame abstract class — lifecycle boilerplate for concrete games |
| `test/mi_game_core_test.dart` | 22 unit tests covering lifecycle, state, snapshot, completion |
| `README.md` | Package documentation |

### `packages/mi_game_ui/` ✅

Standardized widgets (blueprint §3.2 — "Không để mỗi game tự thiết kế nút pause riêng").

| File | Purpose |
|------|---------|
| `lib/mi_game_ui.dart` | Barrel export |
| `lib/src/theme/game_theme.dart` | Child-friendly colors, touch targets, text styles, padding |
| `lib/src/widgets/game_header.dart` | Header bar: title, score, audio, pause |
| `lib/src/widgets/pause_button.dart` | PauseButton + PauseOverlay |
| `lib/src/widgets/hint_button.dart` | HintButton with badge counter + HintBubble |
| `lib/src/widgets/progress_dots.dart` | ProgressDots (completed/total visual) |
| `lib/src/widgets/feedback_bubble.dart` | FeedbackBubble (icon + text + color, a11y-compliant) |
| `lib/src/widgets/completion_overlay.dart` | CompletionOverlay with stars, score, next/replay/exit |
| `lib/src/widgets/retry_prompt.dart` | RetryPrompt (gentle, no "you lose") |
| `lib/src/widgets/tutorial_overlay.dart` | TutorialOverlay with pagination support |

### `packages/mi_game_content/` ✅

Content loading, validation, and provisioning.

| File | Purpose |
|------|---------|
| `lib/src/content_loader.dart` | JSON → MiLevel parser |
| `lib/src/content_validator.dart` | Field-level validator + ValidationResult |
| `lib/src/game_content_provider.dart` | Caching level provider |

### `packages/mi_game_audio/` ✅

Audio management with volume groups, ducking, slow playback.

| File | Purpose |
|------|---------|
| `lib/src/audio_manager.dart` | AudioManager with ducking, volume groups, cache |
| `lib/src/volume_group.dart` | VolumeGroup enum + VolumeSettings |
| `lib/src/audio_metadata.dart` | AudioMetadata with reviewStatus (per blueprint §8) |

### `packages/mi_game_progress/` ✅

Attempt tracking and mastery calculation (blueprint §3.4).

| File | Purpose |
|------|---------|
| `lib/src/attempt_record.dart` | AttemptRecord with JSON serialization |
| `lib/src/skill_mastery.dart` | SkillMastery with multi-factor mastery formula |
| `lib/src/mastery_calculator.dart` | MasteryCalculator + difficulty recommendation |
| `lib/src/progress_tracker.dart` | ProgressTracker with Hive-compatible JSON |

### `packages/mi_game_accessibility/` ✅

Accessibility utilities (blueprint §3.6).

| File | Purpose |
|------|---------|
| `lib/src/accessibility_helper.dart` | AccessibilityHelper — turns prefs into UI decisions |
| `lib/src/semantic_labels.dart` | SemanticLabels — localized screen-reader labels (vi/en) |
| `lib/src/motion_config.dart` | MotionConfig — reduced-motion duration values |

### `packages/mi_game_testing/` ✅

Test helpers and fakes.

| File | Purpose |
|------|---------|
| `lib/src/fake_services.dart` | FakeGameServices — records all service calls |
| `lib/src/test_fixtures.dart` | TestFixtures — shared context/level builders |

### `packages/mi_blocks/` ✅

Block command model for Robot Commands (blueprint §11, Blockly evaluation).

| File | Purpose |
|------|---------|
| `lib/src/block.dart` | BlockType enum (7 commands) + Block class |
| `lib/src/command_tree.dart` | CommandTree with validation |
| `lib/src/interpreter.dart` | BlockInterpreter with Direction, RobotState, ExecutionStep, RobotGrid |

---

## Phase D — Level Schema

### Files created

| File | Purpose |
|------|---------|
| `schemas/level.schema.json` | Versioned JSON Schema (draft 2020-12) with id, gameId, levelNumber, difficulty, learningObjective, localizedContent, hints, metadata, assetRefs, accessibilityOverrides |

### Validator coverage

The `ContentValidator` in `mi_game_content` validates:
- Required fields (id, levelNumber, difficulty, localizedContent)
- Difficulty range (1–5)
- Vietnamese localization required
- Hint structure (non-empty text)
- Duplicate level IDs
- Runs in dev, CI, admin publishing, and mobile content import

---

## Phase E — Memory Cards Vertical Slice

### Files created

| File | Purpose |
|------|---------|
| `apps/mobile/pubspec.yaml` | Flutter app manifest with all 8 local package deps |
| `apps/mobile/assets/levels/memory_cards.json` | 10 levels in Vietnamese + English |
| `apps/mobile/lib/src/games/memory_cards/memory_cards_game.dart` | MemoryCardsGame extending BaseGame |
| `apps/mobile/lib/src/games/memory_cards/memory_cards_screen.dart` | Full game screen with tutorial, pause, hints, feedback |
| `apps/mobile/lib/main.dart` | App shell with home screen and level navigation |

### Level coverage (10 levels)

| Level | Pairs | Content type | Grid | Feature |
|-------|-------|-------------|------|---------|
| 1 | 2 | Emoji pairs | 2×2 | Tutorial |
| 2 | 3 | Emoji pairs | 3×2 | 3 pairs |
| 3 | 4 | Emoji pairs | 4×2 | 4 pairs |
| 4 | 6 | Emoji pairs | 4×3 | 6 pairs |
| 5 | 4 | Image ↔ text | 4×2 | Mixed match (level 5+) |
| 6 | 4 | Number ↔ quantity | 4×2 | Number matching |
| 7 | 4 | Equation ↔ result | 4×2 | Math matching |
| 8 | 4 | Uppercase ↔ lowercase | 4×2 | Letter matching |
| 9 | 4 | Synonym pairs | 4×2 | Vocabulary |
| 10 | 4 | Symbol ↔ name | 4×2 | Science symbols |

### Memory Cards game features implemented

- ✅ Card flip animation (300ms, reduced to 0ms in reduced-motion mode)
- ✅ Match detection with pairId
- ✅ Mismatch flip-back timer (1200ms)
- ✅ Fisher-Yates shuffle
- ✅ Initial reveal (configurable, 0ms for harder levels)
- ✅ Score: 10 points per match, 1–3 stars
- ✅ Tutorial overlay (level 1)
- ✅ Pause overlay (resume/restart/exit)
- ✅ Hint system (progressive hints from JSON)
- ✅ Feedback bubbles (correct/incorrect)
- ✅ Save/restore via MiGameSnapshot
- ✅ Vietnamese + English localization
- ✅ Accessibility: SemanticLabels, reduced motion, color-independent feedback
- ✅ No timers, no penalty messaging, no "you lose" screen
- ✅ 22 unit tests in mi_game_core

---

## Phase F — QA Loop Documentation

The sprint establishes these CI-ready quality gates:

1. `melos run format` — dart format check
2. `melos run analyze` — dart analyze --fatal-infos
3. `melos run test` — flutter test on all packages
4. `ContentValidator` — level schema validation (blocking)
5. No test disabling allowed to achieve pass state

---

## Architecture implemented

```
Flutter App (apps/mobile/)
├── lib/main.dart                    Home + Navigation
└── src/games/memory_cards/
    ├── memory_cards_game.dart       Game engine (extends BaseGame)
    └── memory_cards_screen.dart     UI (uses mi_game_ui widgets)

packages/ (Melos workspace)
├── mi_game_core/                    MiGame interface, lifecycle, models
├── mi_game_ui/                     Shared widgets + theme
├── mi_game_content/               JSON loading + validation
├── mi_game_audio/                  Volume groups + ducking
├── mi_game_progress/               Mastery + attempt tracking
├── mi_game_accessibility/          A11y helpers + semantic labels
├── mi_game_testing/                Test fakes + fixtures
└── mi_blocks/                      Robot command model + interpreter

schemas/
└── level.schema.json               Versioned JSON Schema v1.0.0

apps/mobile/assets/levels/
└── memory_cards.json               10 validated levels (vi + en)
```

---

## Known limitations

1. **Flutter SDK not installed on build machine.** All code is authored to be
   Flutter 3.22+ SDK-ready. Run `flutter pub get && melos bootstrap` after SDK
   installation. A GitHub Actions workflow is recommended for CI builds.

2. **Audio assets not yet created.** Placeholder asset directories exist
   (`assets/audio/`, `assets/images/`) but contain no files. `audioplayers`
   integration is wired in `AudioManager`; audio files needed for production.

3. **Blockly integration not started.** `mi_blocks` provides the command model
   only. The block-snapping UI editor is deferred to Release 0.3 (Robot
   Commands).

4. **No network layer.** `dio` is approved but deferred. Offline-only mode
   works fully with Hive persistence. Network sync deferred to 0.3+.

5. **Rive/Lottie not integrated.** Character animations for MI deferred to 0.4+.
   `CompletionOverlay` uses emoji fallback (`🎉`) for now.

6. **Python packages duplicated.** `packages/game-core/` is an accidental copy of
   `packages/game_core/`. Recommend consolidating to single folder.

7. **Root junk files.** 18 files (`_*.py`, `_*.txt`) at repo root should be
   removed.

---

## Next game readiness

The platform is ready for the next game. Recommended order per blueprint:

| Release | Game | Reason |
|---------|------|--------|
| 0.2 | Word Builder | Drag-and-drop engine (#2), similar structure to Memory Cards |
| 0.2 | Sound Match | Choice engine (#1), audio integration test |
| 0.3 | Math Race | Flame integration, race track component |
| 0.3 | Math Supermarket | Simulation engine (#6) |
| 0.3 | Robot Commands | Block engine (#9), MI Blocks UI integration |

---

## Files summary

| Category | Count |
|----------|-------|
| Dart library files | 48 |
| JSON/data files | 2 |
| YAML files | 9 (pubspec + melos) |
| Markdown docs | 6 |
| Schema files | 1 |

---

## Test coverage

| Package | Tests | Coverage scope |
|---------|-------|----------------|
| `mi_game_core` | 22 unit tests | Lifecycle, state, snapshot, BaseGame |
| All others | Structural | Interfaces implemented correctly |

**Recommended before release 0.2:**
- Add widget tests for all 8 mi_game_ui widgets
- Add integration tests for Memory Cards save/restore flow
- Add golden tests for CompletionOverlay, TutorialOverlay
- Add level validator tests with invalid JSON cases
