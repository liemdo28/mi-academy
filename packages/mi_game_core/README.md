# mi_game_core

Core game lifecycle, state machine, save/restore, and the **MiGame** interface for MI Academy.

## What's inside

| Layer | File | Purpose |
|-------|------|---------|
| Models | `mi_level.dart`, `mi_hint.dart`, `mi_game_action.dart`, `mi_action_result.dart`, `mi_game_snapshot.dart`, `mi_completion_result.dart` | Data types shared across all games |
| Interfaces | `mi_game.dart` | The contract every game must implement |
| Lifecycle | `game_state.dart`, `game_lifecycle.dart` | State machine with error recovery |
| Context | `mi_game_context.dart` | Game context (child, prefs, services) |
| Base | `base_game.dart` | Boilerplate-free base class for concrete games |

## Quick start

```dart
class MyGame extends BaseGame {
  @override
  String get gameId => 'my_game';

  @override
  Future<MiActionResult> onHandleAction(MiGameAction action) async {
    // your logic here
    return MiActionResult.success(feedback: 'Tuyệt vời!');
  }

  // ... override other hooks as needed
}
```

## License

Proprietary — MI Academy internal use only.
