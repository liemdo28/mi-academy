# mi_game_ui

Shared UI widgets for MI Academy games.

## Overview

Provides standardized, child-friendly widgets that every MI Academy game uses.
All widgets follow the MI Academy design system with:
- Minimum 48x48 touch targets
- Rounded corners
- Child-friendly colors and messaging
- Vietnamese + English semantic labels
- Accessibility support (semantics, screen reader)

## Widgets

| Widget | Purpose |
|--------|---------|
| `GameHeader` | Top bar with back, title, score, audio, pause |
| `PauseButton` / `PauseOverlay` | Pause controls and overlay |
| `AudioButton` | Audio mute/unmute toggle |
| `HintButton` | Request hint button |
| `ProgressDots` | Level progress indicator |
| `FeedbackBubble` | Correct/incorrect feedback |
| `CompletionOverlay` | Level complete screen with stars |
| `RetryPrompt` | Retry after incorrect answer |
| `TutorialOverlay` | First-time tutorial overlay |
| `OfflineIndicator` | Offline status bar |
| `ExitConfirmation` | Exit confirmation dialog |
| `LoadingState` | Loading spinner with message |
| `ErrorState` | Error screen with retry |

## Theme

- `GameTheme` — Text styles, padding, shadows, touch targets
- `MiGameColors` — Brand and semantic color palette

## Usage

```dart
import 'package:mi_game_ui/mi_game_ui.dart';

// In your game build method:
GameHeader(
  title: 'Memory Cards',
  score: _score,
  onPause: _pause,
  onAudioToggle: _toggleAudio,
  onExit: _exit,
  isMuted: _isMuted,
),
```

## Design Principles

1. **Child-safe**: No scary error messages, no "lose" wording
2. **Accessible**: All widgets include Semantics labels
3. **Bilingual**: Labels in Vietnamese with English support
4. **Consistent**: Same look and feel across all games
5. **48x48 minimum**: All interactive elements meet WCAG touch target size
