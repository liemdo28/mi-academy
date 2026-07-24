import 'package:equatable/equatable.dart';

/// Context passed to a game during initialization.
///
/// Contains only what the game needs — never auth tokens, parent data,
/// payment info, contacts, or location.
class MiGameContext extends Equatable {
  const MiGameContext({
    required this.childProfileId,
    required this.language,
    required this.ageGroup,
    required this.accessibility,
    required this.audio,
    required this.services,
  });

  /// Child's profile ID.
  final String childProfileId;

  /// Language code (e.g., "vi", "en").
  final String language;

  /// Age group (e.g., "5-7", "8-10", "11-12").
  final String ageGroup;

  /// Accessibility preferences.
  final AccessibilityPreferences accessibility;

  /// Audio preferences.
  final AudioPreferences audio;

  /// Services available to the game.
  final MiGameServices services;

  @override
  List<Object?> get props => [
        childProfileId,
        language,
        ageGroup,
        accessibility,
        audio,
        services,
      ];
}

/// Accessibility settings the game must respect.
class AccessibilityPreferences extends Equatable {
  const AccessibilityPreferences({
    this.textScaleFactor = 1.0,
    this.highContrast = false,
    this.reducedMotion = false,
    this.screenReaderEnabled = false,
    this.tapAlternativeForDrag = false,
    this.extendedResponseTime = false,
    this.colorIndependentFeedback = false,
    this.subtitlesEnabled = false,
  });

  /// Text scale factor (1.0 = normal, up to 2.0 for large text).
  final double textScaleFactor;

  /// High contrast mode.
  final bool highContrast;

  /// Disable animations / reduce motion.
  final bool reducedMotion;

  /// Screen reader is active.
  final bool screenReaderEnabled;

  /// Use tap-to-place instead of drag-and-drop.
  final bool tapAlternativeForDrag;

  /// Give more time for responses.
  final bool extendedResponseTime;

  /// Don't rely on color alone for feedback (use icons + text too).
  final bool colorIndependentFeedback;

  /// Show subtitles for audio content.
  final bool subtitlesEnabled;

  @override
  List<Object?> get props => [
        textScaleFactor,
        highContrast,
        reducedMotion,
        screenReaderEnabled,
        tapAlternativeForDrag,
        extendedResponseTime,
        colorIndependentFeedback,
        subtitlesEnabled,
      ];
}

/// Audio settings the game must respect.
class AudioPreferences extends Equatable {
  const AudioPreferences({
    this.voiceVolume = 1.0,
    this.musicVolume = 0.5,
    this.effectsVolume = 0.8,
    this.narrationEnabled = true,
    this.backgroundMusicEnabled = true,
    this.soundEffectsEnabled = true,
  });

  final double voiceVolume;
  final double musicVolume;
  final double effectsVolume;
  final bool narrationEnabled;
  final bool backgroundMusicEnabled;
  final bool soundEffectsEnabled;

  @override
  List<Object?> get props => [
        voiceVolume,
        musicVolume,
        effectsVolume,
        narrationEnabled,
        backgroundMusicEnabled,
        soundEffectsEnabled,
      ];
}

/// Services available to the game (abstract — provided by the app shell).
///
/// Games use these to save data, log analytics, etc. without depending
/// on concrete implementations.
class MiGameServices extends Equatable {
  const MiGameServices({
    required this.saveSnapshot,
    required this.loadSnapshot,
    required this.logEvent,
    required this.playAudio,
    required this.stopAudio,
  });

  /// Save a snapshot to persistent storage.
  final Future<void> Function(String key, Map<String, dynamic> data)
      saveSnapshot;

  /// Load a snapshot from persistent storage.
  final Future<Map<String, dynamic>?> Function(String key) loadSnapshot;

  /// Log an educational analytics event.
  final Future<void> Function(String event, Map<String, dynamic> data) logEvent;

  /// Play an audio asset by reference key.
  final Future<void> Function(String audioRef, {double? volume}) playAudio;

  /// Stop all currently playing audio.
  final Future<void> Function() stopAudio;

  @override
  List<Object?> get props =>
      [saveSnapshot, loadSnapshot, logEvent, playAudio, stopAudio];
}
