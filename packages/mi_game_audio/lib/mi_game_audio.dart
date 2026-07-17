/// MI Academy — Audio management for games.
///
/// Provides voice narration, word pronunciation, background music,
/// sound effects, volume groups, audio cache, slow playback, stop-all,
/// ducking (lowering music while speaking), and audioplayers backend.
library mi_game_audio;

// Core
export 'src/audio_manager.dart';
export 'src/volume_group.dart';
export 'src/audio_metadata.dart';

// Enums
export 'src/enums/audio_group.dart';

// Models
export 'src/models/audio_prefs.dart';

// Services
export 'src/services/mi_audio_service.dart';
