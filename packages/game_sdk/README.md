# Game SDK

> Game lifecycle SDK for MI Academy — launch, snapshot, result, and resume contracts.

## Contracts

| Contract ID | Schema | Owner | Description |
|---|---|---|---|
| `mi.game.launch` | v1 | game_sdk | Game session launch request |
| `mi.game.result` | v1 | game_sdk | Game completion result |
| `mi.game.snapshot` | v1 | game_sdk | In-progress save/resume |
| `mi.accessibility.config` | v1 | game_sdk | Accessibility settings |
| `mi.audio.preferences` | v1 | game_sdk | Audio preferences |

## Usage

```dart
import 'package:game_sdk/game_sdk.dart';

final client = GameClient(baseUrl: 'https://api.mi-academy.dev');

// Launch a game
final result = await client.launchGame(GameLaunchRequest(
  childProfileId: '...',
  gameId: 'game-memory-01',
  levelId: 'level-memory-01-01',
  language: 'vi',
  ageGroup: 'junior',
));

if (result.success) {
  print('Launched: ${result.data}');
} else {
  print('Error: ${result.error}');
}
```

## Forbidden Fields

Game contracts automatically reject data containing PII or auth tokens:
`accessToken`, `refreshToken`, `password`, `email`, `phoneNumber`, `parentEmail`, `idToken`, `sessionToken`.

## Testing

```bash
cd packages/game_sdk
flutter test
```
