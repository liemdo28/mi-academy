# MI Academy — Game Platform Architecture

> **Doc date:** 2026-07-17
> **Owner:** Game & Experience Lead
> **Status:** Architecture specification for MVP

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     apps/mobile (Flutter)                   │
│                                                             │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │ GameScreen  │  │ Game Engines │  │ Shared Services │  │
│  │  (Shell)    │  │              │  │                 │  │
│  │             │  │ MemoryCards  │  │ mi_game_ui      │  │
│  │  Header     │  │ WordBuilder  │  │ mi_game_audio   │  │
│  │  Footer     │  │ SoundMatch   │  │ mi_game_access  │  │
│  │  Overlay    │  │ MathRace     │  │ mi_game_testing │  │
│  │             │  │ MathSupermkt │  │                 │  │
│  │             │  │ RobotCmds    │  │                 │  │
│  └─────────────┘  └──────────────┘  └─────────────────┘  │
│                            │                               │
│         ┌──────────────────┼──────────────────┐           │
│         │                  │                  │           │
│  ┌──────▼──────┐  ┌───────▼──────┐  ┌──────▼──────┐      │
│  │mi_game_core │  │mi_game_content│  │mi_game_prog │      │
│  │             │  │              │  │             │      │
│  │MiGame I/F   │  │Level Loader  │  │Progress     │      │
│  │Lifecycle    │  │Content Repos │  │Tracking     │      │
│  │Snapshot     │  │Localization  │  │Achievement  │      │
│  └─────────────┘  └──────────────┘  └─────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │  apps/api (FastAPI)  │
                 │                     │
                 │  Dev 1 owns this    │
                 │  Game results sent  │
                 │  from mobile to API │
                 └─────────────────────┘
```

---

## 2. Package Responsibilities

### 2.1 Game & Experience Lead Ownership

| Package | Responsibility |
|---------|---------------|
| `mi_game_core` | MiGame interface, lifecycle, state machine, snapshot, context |
| `mi_game_ui` | Reusable game UI components (header, overlays, buttons) |
| `mi_game_audio` | Audio service (voice, SFX, music, volume groups) |
| `mi_game_accessibility` | Accessibility service, screen reader, reduced motion |
| `mi_game_testing` | Test harness, fake games, game lifecycle tests |
| `mi_blocks` | Block model, program AST, interpreter, Flutter block editor |

### 2.2 Dev 1 Ownership

| Package | Responsibility |
|---------|---------------|
| `mi_game_progress` | Progress tracking, achievements, mastery calculation |
| `mi_game_content` | Level content repository, localization loader |
| Platform layer | Navigation, routing, parent dashboard, offline sync |

### 2.3 Shared (Both)

| Package | Responsibility |
|---------|---------------|
| `shared_models` | Cross-package models (ChildProfile, Lesson, etc.) |
| `design_system` | Shared design tokens, typography, spacing |
| `mi_contract_tests` | Integration tests between game and platform |

---

## 3. MiGame Interface Contract

Every game must implement `MiGame`:

```dart
abstract interface class MiGame {
  String get gameId;
  GameState get currentState;

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

### 3.1 Game Lifecycle States

```
CREATED
  │ initialize()
  ▼
INITIALIZING ──(fail)──► LOAD_FAILED
  │ loadLevel()
  ▼
READY
  │ start()
  ▼
PLAYING
  │ pause()        │ complete()
  ▼               ▼
PAUSED          COMPLETED
  │ resume()       │
  └───────────────┘

Error states:
  LOAD_FAILED → RECOVERY_REQUIRED
  ASSET_MISSING → RECOVERY_REQUIRED
  INVALID_LEVEL → RECOVERY_REQUIRED
  SAVE_FAILED → RECOVERY_REQUIRED
```

### 3.2 Game Context (what game receives)

```dart
class MiGameContext {
  final String childProfileId;
  final String locale;           // 'vi' or 'en'
  final String ageGroup;         // '5-6', '7-8', '9-10', '11-12'
  final MiAccessibilityPrefs accessibility;
  final MiAudioPrefs audio;
  final MiDifficulty difficulty; // platform-defined difficulty parameters
}
```

**What game NEVER receives:** auth tokens, parent passwords, payment info, GPS, contacts.

---

## 4. Game Architecture Patterns

### 4.1 Pure Flutter Games (Waves 1-2)

```
┌──────────────────────────────────────────┐
│ GameScreen (Flutter Widget)               │
│                                          │
│  ┌────────────┐  ┌──────────────────┐  │
│  │ GameHeader │  │                  │  │
│  └────────────┘  │  GameBoardWidget │  │
│                  │                  │  │
│  ┌────────────┐  │  (GridView /     │  │
│  │ PauseBtn   │  │   Stack / etc.)  │  │
│  └────────────┘  │                  │  │
│                  └──────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ GameOverlay (pause/completion)    │  │
│  └──────────────────────────────────┘  │
└──────────────────────────────────────────┘

State: ChangeNotifier / Riverpod
No game engine dependency.
```

### 4.2 Flame Games (Waves 3-4)

```
┌──────────────────────────────────────────┐
│ GameScreen (Flutter Widget)               │
│                                          │
│  ┌────────────┐  ┌──────────────────┐  │
│  │ GameHeader │  │ FlameGameWidget  │  │
│  └────────────┘  │  ┌────────────┐  │  │
│                  │  │ FlameGame  │  │  │
│  ┌────────────┐  │  │ (sprites,  │  │  │
│  │ PauseBtn   │  │  │  loop)     │  │  │
│  └────────────┘  │  └────────────┘  │  │
│                  └──────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ GameOverlay (pause/completion)    │  │
│  └──────────────────────────────────┘  │
└──────────────────────────────────────────┘

FlameGame implements MiGame.
State: Flame component internal + ChangeNotifier for Flutter UI.
```

---

## 5. Data Flow

### 5.1 Game Launch Flow

```
1. GameScreen calls MiGameFactory.create(gameId)
2. Platform creates MiGameContext (childId, locale, age, prefs)
3. Platform calls game.initialize(context)
4. Platform calls game.loadLevel(level)
5. Platform calls game.start()
6. Game emits state via Stream<MiGameState>
7. Platform displays GameScreen with game widget
```

### 5.2 Game Completion Flow

```
1. Game detects completion condition
2. Game calls game.complete() → returns MiCompletionResult
3. Game emits state COMPLETED
4. Platform receives result
5. Platform sends result to backend (via offline queue)
6. Platform shows CompletionOverlay
7. Platform navigates to next level or home
```

### 5.3 Save/Restore Flow

```
SAVE:
  Platform → game.saveSnapshot() → MiGameSnapshot
  Platform serializes snapshot → JSON
  Platform stores in Hive

RESTORE:
  Platform loads snapshot from Hive
  Platform deserializes → MiGameSnapshot
  Platform → game.restoreSnapshot(snapshot)
  Platform → game.resume()
```

---

## 6. Content Schema

### 6.1 Level JSON Structure

```json
{
  "schemaVersion": "1.0",
  "id": "mc_01",
  "gameId": "memory_cards",
  "levelNumber": 1,
  "locale": "vi",
  "difficulty": {
    "cardCount": 4,
    "matchType": "image_to_image"
  },
  "learningObjective": "Practice visual matching and memory",
  "content": {
    "cards": [
      {"id": "c1", "pairId": "p1", "content": "🐱", "type": "image"},
      {"id": "c2", "pairId": "p1", "content": "🐱", "type": "image"},
      ...
    ]
  },
  "hints": [
    {"hintNumber": 1, "content": "Try to remember where you saw each card!"}
  ],
  "metadata": {
    "estimatedMinutes": 2,
    "skillTags": ["memory", "visual_matching"]
  }
}
```

---

## 7. Shared UI Components

All games use these from `mi_game_ui`:

| Component | Purpose |
|-----------|---------|
| `GameHeader` | Level indicator, progress dots |
| `PauseButton` | Pause game |
| `AudioButton` | Toggle sound |
| `HintButton` | Request hint |
| `TutorialOverlay` | First-time instructions |
| `FeedbackBubble` | Correct/incorrect feedback |
| `CompletionOverlay` | Level complete celebration |
| `RetryPrompt` | Failed attempt retry |
| `OfflineIndicator` | Offline mode banner |
| `ExitConfirmation` | Confirm exit dialog |
| `LoadingState` | Asset loading spinner |
| `ErrorState` | Error with recovery action |

---

## 8. Audio Architecture

### 8.1 Volume Groups

| Group | Contents | Default |
|-------|---------|---------|
| `voice` | Narration, word pronunciation | 100% |
| `music` | Background music | 50% |
| `effects` | SFX, feedback sounds | 100% |

### 8.2 Audio Service API

```dart
class MiAudioService {
  Future<void> playVoice(String assetKey);
  Future<void> playSfx(String assetKey);
  Future<void> playMusic(String assetKey);
  Future<void> setVolume(AudioGroup group, double volume); // 0.0-1.0
  Future<void> setPlaybackSpeed(double speed); // 0.5-1.5
  Future<void> stopAll();
  Future<void> duckMusic(); // lower music volume during voice
}
```

---

## 9. Accessibility Architecture

### 9.1 Preferences

```dart
class MiAccessibilityPrefs {
  final bool largeTouchTargets;    // 48dp → 64dp
  final bool highContrast;          // dark borders, bold colors
  final bool reducedMotion;         // disable animations
  final bool screenReader;          // NVDA/VoiceOver support
  final bool subtitles;             // show text for audio
  final bool tapAlternative;        // drag-drop → tap-to-place
  final int extendedResponseTime;   // 0 = normal, 1 = +2s, 2 = +5s
}
```

### 9.2 Screen Reader Support

All interactive elements have:
- Semantic labels (`Semantics(label:)`)
- Hint text for actions
- Live region for dynamic feedback

---

## 10. Game Result Schema

```dart
class MiGameResult {
  final String attemptId;
  final String childProfileId;
  final String gameId;
  final String levelId;
  final DateTime startTime;
  final DateTime completionTime;
  final int attemptCount;
  final int correctCount;
  final int incorrectCount;
  final int hintCount;
  final Duration duration;
  final CompletionStatus status;
  final List<MiSkillEvidence> skillEvidence;
  final Map<String, dynamic> metadata;
}

enum CompletionStatus {
  completed,
  abandoned,
  failed,
  recovered,
}
```

---

## 11. Offline Architecture

```
┌─────────────────────┐
│   apps/mobile       │
│                     │
│  ┌───────────────┐  │
│  │ Hive Database │  │
│  │               │  │
│  │ • game_snap   │  │
│  │ • progress    │  │
│  │ • offline_q   │  │
│  └───────────────┘  │
│         │           │
│         ▼           │
│  ┌───────────────┐  │
│  │ Sync Queue   │  │ ← Queue game results
│  └───────────────┘  │   when offline
│         │           │
└─────────│───────────┘
          │ (when online)
          ▼
   ┌─────────────┐
   │ apps/api    │ (Dev 1)
   │ POST /results│
   └─────────────┘
```

---

## 12. Game Quality Gates

| Gate | Requirement |
|------|-------------|
| Code complete | All levels playable, no TODO |
| Unit tests | >80% coverage on game logic |
| Widget tests | All components tested |
| Save/restore | All states restored correctly |
| Offline | No network calls during gameplay |
| Accessibility | Screen reader passes all elements |
| Localization | All 6 games in Vietnamese and English |
| Performance | <30ms per frame on target devices |
| Safety | No external URLs, no trackers |
| Contract tests | MiGame interface compliance |
