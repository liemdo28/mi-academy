import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../audio_manager.dart';
import '../volume_group.dart';

enum MiAudioIntent {
  correct,
  incorrect,
  hint,
  levelComplete,
  cardFlip,
  starEarned,
  creativePrompt,
  selectionSoft,
  creativeComplete,
  gentleAttention,
}

/// Production audio backend using audioplayers.
///
/// Implements [AudioBackend] and wraps the audioplayers package.
/// Handles asset loading, playback, volume control, and caching.
class AudioplayersBackend implements AudioBackend {
  AudioplayersBackend();

  final Map<String, AudioPlayer> _players = {};
  final Map<String, String> _playerGroups = {};

  AudioPlayer _getOrCreate(String playerId) {
    return _players.putIfAbsent(
      playerId,
      () => AudioPlayer(),
    );
  }

  @override
  Future<void> play(
    String assetPath, {
    required double volume,
    double rate = 1.0,
  }) async {
    final playerId = assetPath;
    final player = _getOrCreate(playerId);
    _playerGroups[playerId] = playerId;

    await player.setVolume(volume.clamp(0.0, 1.0));
    await player.setPlaybackRate(rate.clamp(0.5, 2.0));
    await player.play(AssetSource(assetPath));
  }

  @override
  Future<void> stopAll() async {
    for (final player in _players.values) {
      await player.stop();
    }
  }

  @override
  Future<void> setVolume(String playerId, double volume) async {
    final player = _players[playerId];
    if (player != null) {
      await player.setVolume(volume.clamp(0.0, 1.0));
    }
  }

  /// Preload an audio asset for faster playback.
  Future<void> preload(String assetPath) async {
    final player = _getOrCreate(assetPath);
    await player.setSource(AssetSource(assetPath));
  }

  /// Release resources. Call when game session ends.
  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    _playerGroups.clear();
  }
}

/// High-level audio service that games use directly.
///
/// Wraps [AudioManager] with convenience methods for common game sounds.
/// All methods are no-ops when audio is not available (web fallback).
class MiAudioService {
  MiAudioService({
    AudioplayersBackend? backend,
    VolumeSettings? volumeSettings,
  }) {
    _backend = backend ?? AudioplayersBackend();
    _manager = AudioManager(
      backend: _backend,
      settings: volumeSettings ?? VolumeSettings(),
    );
  }

  late final AudioplayersBackend _backend;
  late final AudioManager _manager;

  AudioManager get manager => _manager;

  /// Current volume settings.
  VolumeSettings get volumeSettings => _manager.settings;

  /// Update volume settings (e.g., from parent controls).
  void updateVolumeSettings(VolumeSettings settings) {
    _manager.updateSettings(settings);
  }

  /// Preload audio assets for a game level.
  ///
  /// Call during level initialization to prevent delays during play.
  Future<void> preloadAssets(List<String> assetPaths) async {
    for (final path in assetPaths) {
      await _backend.preload(path);
      _manager.preload(path);
    }
  }

  /// Play voice narration with auto-ducking of music.
  Future<void> playVoice(String assetPath, {double rate = 1.0}) async {
    await _manager.playVoice(assetPath, rate: rate);
  }

  /// Play voice at slow speed for pronunciation help.
  Future<void> playVoiceSlow(String assetPath) async {
    await _manager.playVoiceSlow(assetPath);
  }

  /// Play background music.
  Future<void> playMusic(String assetPath) async {
    await _manager.playMusic(assetPath);
  }

  /// Play a sound effect (correct, incorrect, card flip, etc.).
  Future<void> playEffect(String assetPath) async {
    await _manager.playEffect(assetPath);
  }

  /// Play a semantic sound intent so game code can describe feedback without
  /// binding itself to a file path or assessment model.
  Future<void> playIntent(MiAudioIntent intent) async {
    await playEffect(_assetForIntent(intent));
  }

  /// Stop all currently playing audio.
  Future<void> stopAll() async {
    await _manager.stopAll();
  }

  /// Restore music volume after narration finishes.
  Future<void> unduckMusic() async {
    await _manager.unduckMusic();
  }

  // ─── Convenience: Common Game Sounds ─────────────────────────────────────

  /// Play the "correct answer" sound effect.
  Future<void> playCorrect() async {
    await playEffect('audio/sfx/correct.mp3');
  }

  /// Play the "incorrect answer" sound effect.
  Future<void> playIncorrect() async {
    await playEffect('audio/sfx/incorrect.mp3');
  }

  /// Play the "hint used" sound effect.
  Future<void> playHint() async {
    await playEffect('audio/sfx/hint.mp3');
  }

  /// Play the "level complete" fanfare.
  Future<void> playLevelComplete() async {
    await playEffect('audio/sfx/level_complete.mp3');
  }

  /// Play the "card flip" sound effect.
  Future<void> playCardFlip() async {
    await playEffect('audio/sfx/card_flip.mp3');
  }

  /// Play the "star earned" sound effect.
  Future<void> playStarEarned() async {
    await playEffect('audio/sfx/star_earned.mp3');
  }

  /// Release all audio resources. Call when game session ends.
  Future<void> dispose() async {
    await _backend.dispose();
  }

  static String _assetForIntent(MiAudioIntent intent) {
    return switch (intent) {
      MiAudioIntent.correct => 'audio/correct.wav',
      MiAudioIntent.incorrect => 'audio/try_again.wav',
      MiAudioIntent.hint => 'audio/try_again.wav',
      MiAudioIntent.levelComplete => 'audio/correct.wav',
      MiAudioIntent.cardFlip => 'audio/card_flip.wav',
      MiAudioIntent.starEarned => 'audio/match_correct.wav',
      MiAudioIntent.creativePrompt => 'audio/card_flip.wav',
      MiAudioIntent.selectionSoft => 'audio/card_flip.wav',
      MiAudioIntent.creativeComplete => 'audio/match_correct.wav',
      MiAudioIntent.gentleAttention => 'audio/card_flip.wav',
    };
  }
}
