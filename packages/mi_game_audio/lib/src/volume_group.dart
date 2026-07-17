/// Audio volume groups that parents can adjust independently.
enum VolumeGroup {
  /// Voice narration and word pronunciation.
  voice,

  /// Background music.
  music,

  /// Sound effects (correct, incorrect, card flip, etc.).
  effects;
}

/// Holds per-group volume levels (0.0 - 1.0).
class VolumeSettings {
  VolumeSettings({
    this.voice = 1.0,
    this.music = 0.5,
    this.effects = 0.8,
    this.masterMuted = false,
  });

  double voice;
  double music;
  double effects;
  bool masterMuted;

  /// Effective volume for a group, accounting for master mute.
  double effectiveVolume(VolumeGroup group) {
    if (masterMuted) return 0.0;
    switch (group) {
      case VolumeGroup.voice:
        return voice.clamp(0.0, 1.0);
      case VolumeGroup.music:
        return music.clamp(0.0, 1.0);
      case VolumeGroup.effects:
        return effects.clamp(0.0, 1.0);
    }
  }

  VolumeSettings copyWith({
    double? voice,
    double? music,
    double? effects,
    bool? masterMuted,
  }) {
    return VolumeSettings(
      voice: voice ?? this.voice,
      music: music ?? this.music,
      effects: effects ?? this.effects,
      masterMuted: masterMuted ?? this.masterMuted,
    );
  }
}
