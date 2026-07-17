/// MI Academy — Core Game Platform
///
/// Provides game lifecycle management, state machine, save/restore,
/// and the MiGame interface that every game must implement.
///
/// Also provides the canonical contracts for Platform ↔ Game communication:
/// - [MiGameLaunchRequest] — sent from platform to game at launch
/// - [MiGameResult] — returned from game to platform at session end
/// - [MiGameSnapshot] — save/restore state
/// - [MiProgressGateway] — interface for games to save progress
library mi_game_core;

import 'src/models/mi_game_snapshot.dart';

export 'src/models/models.dart';
export 'src/interfaces/mi_game.dart';
export 'src/lifecycle/game_state.dart';
export 'src/lifecycle/game_lifecycle.dart';
export 'src/context/mi_game_context.dart';
export 'src/base/base_game.dart';

// Platform ↔ Game contracts
part 'src/contracts/mi_game_launch_request.dart';
part 'src/contracts/mi_game_result.dart';
part 'src/contracts/mi_progress_gateway.dart';
part 'src/contracts/mi_fixtures.dart';
