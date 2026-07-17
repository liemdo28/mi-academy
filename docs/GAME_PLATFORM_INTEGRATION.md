# Game-Platform Integration Guide

This document explains how Dev 2 (Game Developer) integrates games with the MI Academy platform.

## Quick Start

```dart
import 'package:shared_models/shared_models_barrel.dart';

// 1. Use the mock gateway to develop without backend
final gateway = MiFixtures.freshGateway();

// 2. Get a launch request with sample data
final request = MiFixtures.sampleLaunchRequest();

// 3. Build your game using the request data
// - request.childProfileId: identify the child
// - request.language: 'vi' or 'en'
// - request.ageGroup: 'junior', 'explorer', or 'master'
// - request.accessibility: accessibility preferences
// - request.audioPreferences: audio settings
// - request.levelContent: game-specific level data

// 4. When game ends, send result back
final result = MiGameResult(/* ... */);
await gateway.saveGameResult(result);
```

## Game Contract Version

All contracts use `kGameContractVersion = 1`.

If the platform sends a different schema version, the game should log a warning and attempt to process the request.

## Security Rules

Games MUST NOT:
- Store or log access tokens
- Store or log parent passwords or emails
- Store child PII beyond profile ID
- Make network calls directly (go through the gateway)

Games MAY:
- Read childProfileId for per-child state
- Read language and age group for content adaptation
- Read accessibility/audio preferences for UI settings
- Save/load game snapshots

## Request from Platform → Game

```dart
class MiGameLaunchRequest {
  final int schemaVersion;         // = 1
  final String childProfileId;     // e.g. "child-0001"
  final String gameId;             // e.g. "game-word-builder"
  final String levelId;            // e.g. "level-01"
  final String language;           // "vi" or "en"
  final String ageGroup;           // "junior", "explorer", "master"
  final AccessibilityPreferences accessibility;
  final AudioPreferences audioPreferences;
  final Map<String, dynamic> levelContent;  // game-specific
  final Map<String, dynamic>? restoredState; // for resume
}
```

## Result from Game → Platform

```dart
class MiGameResult {
  final String attemptId;           // generate with UUID
  final String childProfileId;     // echo from request
  final String gameId;             // echo from request
  final String levelId;            // echo from request
  final DateTime startedAt;
  final DateTime completedAt;
  final int attemptCount;
  final int correctCount;
  final int incorrectCount;
  final int hintCount;
  final int durationSeconds;
  final bool completed;
  final double masteryEvidence;    // 0.0 - 1.0
  final Map<String, dynamic> skillEvidence;
  final Map<String, dynamic> metadata;
}
```

## Snapshot (Save/Resume)

```dart
class MiGameSnapshot {
  final String gameId;
  final String levelId;
  final String childProfileId;
  final DateTime savedAt;
  final Map<String, dynamic> state;  // game-specific
}

// Save: gateway.saveSnapshot(snapshot)
// Resume: gateway.loadSnapshot(childProfileId, gameId, levelId)
```

## MVP Games Reference

| Game | Game ID | Status |
|------|---------|--------|
| Word Builder | `game-word-builder` | ✓ Active |
| Sound Match | `game-sound-match` | ✓ Active |
| Math Race | `game-math-race` | ✓ Active |
| Math Supermarket | `game-math-supermarket` | Planned |
| Memory Cards | `game-memory-cards` | Planned |
| Robot Commands | `game-robot-commands` | Planned |

## Testing

Use `MiFixtures` for deterministic test data:

```dart
final gateway = InMemoryProgressGateway();
final request = MiFixtures.sampleLaunchRequest();
final result = MiFixtures.sampleGameResult();

// Assert gateway stores correctly
await gateway.saveGameResult(result);
assert(gateway.allResults.length == 1);
assert(gateway.resultById(result.attemptId) != null);
```

## Production Deployment

When deploying to production, replace `InMemoryProgressGateway` with the real platform implementation:

```dart
// In production app initialization:
late final MiProgressGateway gateway = HttpProgressGateway(apiBaseUrl);
```

The gateway interface never changes — only the implementation swaps.
