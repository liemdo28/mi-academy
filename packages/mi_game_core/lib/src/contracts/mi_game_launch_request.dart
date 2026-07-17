/// Shared contracts between the Platform and Game layers.
///
/// These contracts are the canonical interface for game launching,
/// result reporting, and snapshot management. Games MUST NOT
/// access parent credentials, internal storage, or network APIs
/// directly — they communicate exclusively through these contracts.

part of mi_game_core;

// ─── Accessibility & Audio ────────────────────────────────────────────────────

/// User's accessibility preferences. Passed to every game launch.
class MiAccessibilityPreferences {
  final bool highContrast;
  final bool largeText;
  final bool reduceMotion;
  final bool screenReader;
  final double fontSize;

  const MiAccessibilityPreferences({
    this.highContrast = false,
    this.largeText = false,
    this.reduceMotion = false,
    this.screenReader = false,
    this.fontSize = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'high_contrast': highContrast,
        'large_text': largeText,
        'reduce_motion': reduceMotion,
        'screen_reader': screenReader,
        'font_size': fontSize,
      };

  factory MiAccessibilityPreferences.fromJson(Map<String, dynamic> json) {
    return MiAccessibilityPreferences(
      highContrast: json['high_contrast'] as bool? ?? false,
      largeText: json['large_text'] as bool? ?? false,
      reduceMotion: json['reduce_motion'] as bool? ?? false,
      screenReader: json['screen_reader'] as bool? ?? false,
      fontSize: (json['font_size'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// User's audio preferences. Passed to every game launch.
class MiAudioPreferences {
  final double musicVolume; // 0.0 - 1.0
  final double sfxVolume; // 0.0 - 1.0
  final bool speechEnabled;

  const MiAudioPreferences({
    this.musicVolume = 0.8,
    this.sfxVolume = 1.0,
    this.speechEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'music_volume': musicVolume,
        'sfx_volume': sfxVolume,
        'speech_enabled': speechEnabled,
      };

  factory MiAudioPreferences.fromJson(Map<String, dynamic> json) {
    return MiAudioPreferences(
      musicVolume: (json['music_volume'] as num?)?.toDouble() ?? 0.8,
      sfxVolume: (json['sfx_volume'] as num?)?.toDouble() ?? 1.0,
      speechEnabled: json['speech_enabled'] as bool? ?? true,
    );
  }
}

// ─── Game Launch Request ──────────────────────────────────────────────────────

/// The canonical launch request sent from the Platform to a game.
///
/// This object contains everything a game needs to initialize itself:
/// - Child identity (no PII)
/// - Game and level identifiers
/// - Localization settings
/// - Accessibility and audio preferences
/// - Level content payload
/// - Optional restored state for resume
///
/// NO parent credentials, email, or access tokens are included.
class MiGameLaunchRequest {
  /// Schema version for forward/backward compatibility.
  /// Currently always 1.
  final int schemaVersion;

  /// The active child's profile ID. Used for progress attribution.
  /// NOT the parent's ID. Games use this to save progress.
  final String childProfileId;

  /// Which game to launch, e.g. "word_builder", "math_race".
  final String gameId;

  /// Which level within the game, e.g. "level_1", "level_2".
  final String levelId;

  /// Content language for this session: "vi" or "en".
  final String language;

  /// Child's age group: "junior", "explorer", or "master".
  final String ageGroup;

  /// Accessibility preferences for this session.
  final MiAccessibilityPreferences accessibility;

  /// Audio preferences for this session.
  final MiAudioPreferences audioPreferences;

  /// The level content — structure varies by game type.
  /// Games parse this based on gameId.
  final Map<String, dynamic> levelContent;

  /// If non-null, the game should restore this state instead of
  /// starting fresh. Used for resuming after app termination.
  final Map<String, dynamic>? restoredState;

  const MiGameLaunchRequest({
    this.schemaVersion = 1,
    required this.childProfileId,
    required this.gameId,
    required this.levelId,
    required this.language,
    required this.ageGroup,
    required this.accessibility,
    required this.audioPreferences,
    required this.levelContent,
    this.restoredState,
  });

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'child_profile_id': childProfileId,
        'game_id': gameId,
        'level_id': levelId,
        'language': language,
        'age_group': ageGroup,
        'accessibility': accessibility.toJson(),
        'audio_preferences': audioPreferences.toJson(),
        'level_content': levelContent,
        if (restoredState != null) 'restored_state': restoredState,
      };

  factory MiGameLaunchRequest.fromJson(Map<String, dynamic> json) {
    return MiGameLaunchRequest(
      schemaVersion: json['schema_version'] as int? ?? 1,
      childProfileId: json['child_profile_id'] as String,
      gameId: json['game_id'] as String,
      levelId: json['level_id'] as String,
      language: json['language'] as String,
      ageGroup: json['age_group'] as String,
      accessibility: MiAccessibilityPreferences.fromJson(
        json['accessibility'] as Map<String, dynamic>? ?? {},
      ),
      audioPreferences: MiAudioPreferences.fromJson(
        json['audio_preferences'] as Map<String, dynamic>? ?? {},
      ),
      levelContent:
          json['level_content'] as Map<String, dynamic>? ?? {},
      restoredState: json['restored_state'] as Map<String, dynamic>?,
    );
  }
}
