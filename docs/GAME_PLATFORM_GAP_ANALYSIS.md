# MI Academy — Game Platform Gap Analysis

> **Audit date:** 2026-07-17
> **Scope:** Foundation Sprint — Phase A
> **Status:** Complete

---

## Purpose

Compare what the **Game Implementation Blueprint** (§3–§6) requires against what
exists in the repository today. Every gap becomes a work item in the Foundation Sprint.

---

## 1. Package inventory

### Blueprint requirement vs. repository state

| Package                | Blueprint § | Exists? | Language | Notes |
|------------------------|-------------|---------|----------|-------|
| `mi_game_core`         | 3.1         | ❌       | —        | Must build in Dart/Flutter |
| `mi_game_ui`           | 3.2         | ❌       | —        | Must build in Dart/Flutter |
| `mi_game_audio`        | 3.3         | ❌       | —        | Must build in Dart/Flutter |
| `mi_game_progress`     | 3.4         | ❌       | —        | Must build in Dart/Flutter |
| `mi_game_content`      | 3.5         | ❌       | —        | Must build in Dart/Flutter |
| `mi_game_accessibility`| 3.6         | ❌       | —        | Must build in Dart/Flutter |
| `mi_game_analytics`    | 3.7         | ❌       | —        | DEFERRED — not in Foundation Sprint |
| `mi_game_testing`      | 3.7†        | ❌       | —        | Must build (test helpers, fakes) |
| `mi_blocks`            | §9 mech 9   | ❌       | —        | Must build in Dart/Flutter |
| `mi_simulation`        | §6 mech 6   | ❌       | —        | DEFERRED — needed for Math Supermarket |

† `mi_game_testing` not explicitly listed in blueprint §3 but implied by the QA
  loop (Phase F) and quality-score requirements.

### Python packages (existing, reference only)

| Package               | Language | Decision |
|-----------------------|----------|----------|
| `packages/game_core/` | Python   | Keep for server-side reference |
| `packages/game-core/` | Python   | Duplicate — consolidate into `game_core/` |
| `packages/learning_core/` | Python | Empty — no action needed |

---

## 2. MiGame interface

### Blueprint definition (§4)

```dart
abstract interface class MiGame {
  String get gameId;
  Future<void> initialize({required MiGameContext context});
  Future<void> loadLevel({required MiLevel level});
  Future<void> start();
  Future<void> pause();
  Future<void> resume();
  Future<MiActionResult> handleAction(MiGameAction action);
  Future<MiHint> requestHint();
  Future<MiGameSnapshot> saveSnapshot();
  Future<void> restoreSnapshot(MiGameSnapshot snapshot);
  Future<MiCompletionResult> complete();
  Future<void> dispose();
}
```

### Current state

- **Python** `GameEngineBase` and `GameInterface` exist but are completely different
  (sync, no Dart types, no lifecycle state machine).
- No Dart `MiGame` interface.

**Gap: Must create from scratch.**

---

## 3. Game lifecycle state machine

### Blueprint (§3.1)

```
CREATED → INITIALIZING → READY → PLAYING
  ├─ PAUSED
  ├─ HINT_SHOWN
  ├─ RETRYING
  └─ COMPLETED
Error states: LOAD_FAILED, ASSET_MISSING, INVALID_LEVEL, SAVE_FAILED, RECOVERY_REQUIRED
```

### Current state

- Python `GameEngineBase` has basic `ProgressSnapshot` but no lifecycle state machine.

**Gap: Must create from scratch.**

---

## 4. Level content schema

### Blueprint requirements

- Versioned JSON Schema for: game metadata, level, learning objective, prompt,
  answer, hint, completion, asset, localization, accessibility.
- Validator for dev / CI / admin / mobile import.
- Invalid level must not reach production.

### Current state

- `content/vi/words.json` exists (88 entries, flat JSON, no schema versioning).
- `docs/api-specification.md` defines REST contracts but not the content file schema.
- No JSON Schema files.

**Gap: Must create from scratch.**

---

## 5. Game UI components

### Blueprint (§3.2)

| Widget                | Exists? |
|-----------------------|---------|
| GameHeader            | ❌      |
| PauseButton           | ❌      |
| AudioButton           | ❌      |
| HintButton            | ❌      |
| ProgressDots          | ❌      |
| TutorialOverlay       | ❌      |
| FeedbackBubble        | ❌      |
| CompletionOverlay     | ❌      |
| RetryPrompt           | ❌      |
| OfflineIndicator      | ❌      |
| ExitConfirmation      | ❌      |

**Gap: All must be created from scratch.**

---

## 6. Mechanic engines

### Blueprint (§5)

| # | Engine                  | Uses Flame? | Blueprint scope | Foundation Sprint? |
|---|-------------------------|-------------|-----------------|--------------------|
| 1 | Choice Engine           | No          | §5              | ❌ (Sound Match = 0.2) |
| 2 | Drag-and-Drop Engine    | No          | §5              | ❌ (Word Builder = 0.2) |
| 3 | Card and Grid Engine    | No          | §5              | ✅ (Memory Cards)   |
| 4 | Path and Movement       | Yes         | §5              | ❌ (Robot = 0.3)    |
| 5 | Race Engine             | Yes         | §5              | ❌ (Math Race = 0.3)|
| 6 | Simulation Engine       | Yes         | §5              | ❌ (Supermarket = 0.3)|
| 7 | Shape Construction      | Maybe       | §5              | ❌                  |
| 8 | Story Engine            | No          | §5              | ❌                  |
| 9 | Block Command Engine    | No/WebView  | §5              | ❌ (mi_blocks model only)|
| 10| Resource Puzzle Engine  | Yes         | §5              | ❌                  |

**Foundation Sprint scope:** Only Engine #3 (Card and Grid) is built end-to-end.
Engine #9 (Block Command) gets a Dart model only (`mi_blocks`).

---

## 7. Memory Cards — vertical slice gap

| Feature                | Required (§6) | Exists? |
|------------------------|---------------|---------|
| Card flip animation    | Yes           | ❌       |
| Match detection        | Yes           | ❌       |
| Level 1-10 definitions | Yes           | ❌       |
| Level 5+ (mixed match) | Yes           | ❌       |
| Adaptive difficulty    | Yes           | ❌       |
| Save/restore state     | Yes           | ❌       |
| Tutorial overlay       | Yes           | ❌       |
| Vietnamese + English   | Yes           | ❌       |
| Audio (flip, match)    | Yes           | ❌       |
| Accessibility mode     | Yes           | ❌       |
| Parent progress view   | Yes           | ❌       |
| Automated tests        | Yes           | ❌       |

**Gap: All must be created from scratch.**

---

## 8. Documentation gaps

| Doc                        | Blueprint | Exists? |
|----------------------------|-----------|---------|
| CURRENT_ARCHITECTURE.md    | Phase A   | ✅ (this sprint) |
| GAME_PLATFORM_GAP_ANALYSIS.md | Phase A | ✅ (this sprint) |
| OPEN_SOURCE_AUDIT.md       | Phase A   | ✅ (this sprint) |
| LICENSE_DECISIONS.md       | Phase A   | ✅ (this sprint) |
| Level JSON Schema          | Phase D   | ❌       |
| FOUNDATION_SPRINT_REPORT.md| Phase F   | ❌ (end of sprint) |

---

## 9. Priority matrix

| Priority | Item                              | Sprint  |
|----------|-----------------------------------|---------|
| P0       | Flutter monorepo + melos setup    | This    |
| P0       | `mi_game_core`                    | This    |
| P0       | `mi_game_ui`                      | This    |
| P0       | `mi_game_content`                 | This    |
| P0       | `mi_game_audio`                   | This    |
| P0       | `mi_game_progress`                | This    |
| P0       | `mi_game_accessibility`           | This    |
| P0       | `mi_game_testing`                 | This    |
| P0       | `mi_blocks` (model only)          | This    |
| P0       | Level JSON Schema + validator     | This    |
| P0       | Memory Cards vertical slice       | This    |
| P1       | `mi_game_analytics`               | 0.2     |
| P1       | `mi_simulation`                   | 0.3     |
| P1       | Flame integration (Engine 4-6)    | 0.3     |
| P2       | Blockly research / MI Blocks UI   | 0.3+    |
| P2       | Rive/Lottie character animation   | 0.4+    |
