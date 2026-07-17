import 'dart:async';

import 'volume_group.dart';

/// Abstraction over the audio backend so games and tests don't depend on a
/// concrete player. The app wires this to [audioplayers] in production.
abstract interface class AudioBackend {
  Future<void> play(String assetPath, {required double volume, double rate});
  Future<void> stopAll();
  Future<void> setVolume(String playerId, double volume);
}

/// Manages all audio for a game session.
///
/// Handles volume groups, caching, slow playback, stop-all, and ducking
/// (lowering music while voice narration plays).
class AudioManager {
  AudioManager({
    required AudioBackend backend,
    VolumeSettings? settings,
  })  : _backend = backend,
        _settings = settings ?? VolumeSettings();

  final AudioBackend _backend;
  VolumeSettings _settings;

  VolumeSettings get settings => _settings;

  /// Cache of preloaded audio asset keys.
  final Set<String> _cache = {};

  /// Whether music is currently ducked (lowered) for narration.
  bool _isDucked = false;

  /// Duck factor applied to music while voice plays.
  static const double _duckFactor = 0.3;

  /// Update volume settings (from parent controls).
  void updateSettings(VolumeSettings settings) {
    _settings = settings;
  }

  /// Preload an asset into the cache.
  Future<void> preload(String assetKey) async {
    _cache.add(assetKey);
  }

  bool isCached(String assetKey) => _cache.contains(assetKey);

  /// Play voice narration, ducking music automatically.
  Future<void> playVoice(String assetPath, {double rate = 1.0}) async {
    await _duckMusic();
    final volume = _settings.effectiveVolume(VolumeGroup.voice);
    await _backend.play(assetPath, volume: volume, rate: rate);
  }

  /// Play voice at slow speed (for pronunciation help).
  Future<void> playVoiceSlow(String assetPath) async {
    await playVoice(assetPath, rate: 0.6);
  }

  /// Play background music.
  Future<void> playMusic(String assetPath) async {
    final base = _settings.effectiveVolume(VolumeGroup.music);
    final volume = _isDucked ? base * _duckFactor : base;
    await _backend.play(assetPath, volume: volume, rate: 1.0);
  }

  /// Play a sound effect.
  Future<void> playEffect(String assetPath) async {
    final volume = _settings.effectiveVolume(VolumeGroup.effects);
    await _backend.play(assetPath, volume: volume, rate: 1.0);
  }

  /// Stop all currently playing audio.
  Future<void> stopAll() async {
    await _backend.stopAll();
    _isDucked = false;
  }

  Future<void> _duckMusic() async {
    if (_isDucked) return;
    _isDucked = true;
    final duckedVolume =
        _settings.effectiveVolume(VolumeGroup.music) * _duckFactor;
    await _backend.setVolume('music', duckedVolume);
  }

  /// Restore music volume after narration finishes.
  Future<void> unduckMusic() async {
    if (!_isDucked) return;
    _isDucked = false;
    await _backend.setVolume(
      'music',
      _settings.effectiveVolume(VolumeGroup.music),
    );
  }

  bool get isDucked => _isDucked;
}
