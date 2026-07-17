# Game Shell Specification — shared visual structure for all games

- **Owner:** Dev 4 | **Consumers:** Dev 2 (runtime), Dev 1 (navigation)
- Applies to all 6 MVP games and every future game (§17). Implemented via
  `mi_game_ui` widgets skinned with MI Design System v1.0 tokens.

## 1. Regions (portrait reference)

```text
┌──────────────────────────────────┐
│ HEADER  [✕]  ●●●○○  [🔊][❚❚][💡] │  h64 compact / h72 expanded
├──────────────────────────────────┤
│                                  │
│         MAIN GAMEPLAY AREA       │  canvas: remaining space, centered,
│   (one clear task, feedback      │  gutters in color.background,
│    appears NEAR the object)      │  never stretch game art
│                                  │
├──────────────────────────────────┤
│      BOTTOM INTERACTION TRAY     │  fixed height by family:
│  choices 96–120 / tiles 120–160  │  answer choices · letter tiles ·
│        / command blocks 140      │  command blocks · cart · action btn
└──────────────────────────────────┘
```

## 2. Header contract

- Exit `✕` far LEFT; Hint far RIGHT — never adjacent to each other or to any
  confirm control (§9). Exit always → ExitConfirmation (child-readable copy).
- Level progress = ProgressDots (current level within session).
- Audio button: replay instruction; long-press = slow audio (where applicable).
- Pause → PauseOverlay: Resume (primary, large) / Replay tutorial / Exit.
- All header targets 56×56, gap ≥ 8.

## 3. Feedback rules

- Correct: pop + sparkle at the object + `color.success` + icon + optional
  voice. ≤ 800 ms (MOTION_SYSTEM §4).
- Incorrect: object settles back; MI thinking → hint offer after 2nd miss.
  No X, no shake, no failure sound, no red flood.
- Hints: HintPanel slides from MI side; 1 hint level per miss; hint never
  gives the full answer on first level.

## 4. Tutorial

TutorialOverlay on first play of a game (and on demand from pause): MI +
1 gesture demo + voice line; max 2 steps; "Chơi ngay" skip always visible.

## 5. Completion overlay (§17)

Shows: MI celebrating (skippable 1–3 s) → what the child just learned
(1 line, e.g. "Con đã ghép được 5 từ có vần 'at'") → stars/collectible →
[Tiếp tục] (primary) [Chơi lại] (secondary, when appropriate).
NEVER: "You win/lose", ranks, timers-to-next-reward, purchase prompts, ads.

## 6. System states

- Loading: game-themed skeleton + MI neutral; > 3 s adds "Đang tải…" + voice.
- Error: MiErrorState skin + retry; never lose level progress silently.
- Offline: games run fully offline; OfflineIndicator chip only if a remote
  asset was expected.

## 7. Per-game tray configuration

| Game | Tray content | Orientation | Notes |
|---|---|---|---|
| Memory Cards | none (grid is canvas) | both | grid re-flows 3×4 ↔ 4×3 |
| Word Builder | letter tiles, h120–160 | both | tiles ≥ 64 wide (diacritics) |
| Sound Match | ChoiceCards ×2–4, h96–120 | both | speaker + slow button in canvas |
| Math Race | answer choices h96 | landscape pref | reduced-motion → ProgressBar |
| Math Supermarket | cart + checkout h120 | portrait pref | shelf scroll in canvas |
| Robot Commands | command blocks h140 | both | blocks: icon+text+shape+color |

## 8. Handoff to Dev 2

For each game I deliver: asset kit (manifest with stable IDs), tray height,
animation hooks list, reduced-motion variants, audio cue map. Dev 2 delivers:
canvas dimensions, interaction zones, runtime limits, game-state callbacks
for MI reactions (`onCorrect`, `onMiss`, `onLevelComplete`, `onIdle10s`).
