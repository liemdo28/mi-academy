# mi_game_audio

Audio management for MI Academy games.

## Overview

Provides voice narration, word pronunciation, background music, and sound
effects with per-group volume control (voice, music, effects), auto-ducking
of music during narration, slow playback for pronunciation help, and
audio asset preloading.

## Components

| Component | Purpose |
|-----------|---------|
| `AudioManager` | Core audio state machine with volume groups and ducking |
| `AudioBackend` | Abstract interface for audio playback (testable) |
| `AudioplayersBackend` | Production backend using audioplayers package |
| `MiAudioService` | High-level service with convenience methods |
| `VolumeSettings` | Per-group volume levels (0.0-1.0) + master mute |
| `AudioPrefs` | Persistent preferences with serialization |
| `AudioMetadata` | Per-asset metadata (language, transcript, review) |
| `AudioGroup` | Volume group enum (voice, music, effects) |

## Usage

```dart
import 'package:mi_game_audio/mi_game_audio.dart';

final audioService = MiAudioService();

// Preload assets during level init
await audioService.preloadAssets([
  'audio/voice/word_hello_vi.mp3',
  'audio/sfx/correct.mp3',
]);

// Play voice with auto-ducking
await audioService.playVoice('audio/voice/word_hello_vi.mp3');

// Play sound effects
await audioService.playCorrect();
await audioService.playIncorrect();

// Slow playback for pronunciation
await audioService.playVoiceSlow('audio/voice/word_hello_vi.mp3');

// Clean up
await audioService.dispose();
```

## Audio Policy

- No audio streaming from network (offline-first)
- All assets bundled in the app
- Voice recordings: Vietnamese + English native speakers
- Metadata tracks language, speaker, review status
- Ducking: music auto-lowers to 30% during narration
