import 'package:equatable/equatable.dart';

import '../volume_group.dart';

/// Persistent audio preferences that can be saved/loaded.
///
/// Extends [VolumeSettings] with serialization and equality for
/// storage in Hive/SharedPreferences.
class AudioPrefs extends Equatable {
  const AudioPrefs({
    this.voice = 1.0,
    this.music = 0.5,
    this.effects = 0.8,
    this.masterMuted = false,
    this.speechEnabled = true,
  });

  /// Voice narration volume (0.0 - 1.0).
  final double voice;

  /// Background music volume (0.0 - 1.0).
  final double music;

  /// Sound effects volume (0.0 - 1.0).
  final double effects;

  /// Master mute toggle.
  final bool masterMuted;

  /// Whether speech/narration is enabled at all.
  final bool speechEnabled;

  /// Convert to [VolumeSettings] for use with [AudioManager].
  VolumeSettings toVolumeSettings() => VolumeSettings(
        voice: voice,
        music: music,
        effects: effects,
        masterMuted: masterMuted,
      );

  AudioPrefs copyWith({
    double? voice,
    double? music,
    double? effects,
    bool? masterMuted,
    bool? speechEnabled,
  }) {
    return AudioPrefs(
      voice: voice ?? this.voice,
      music: music ?? this.music,
      effects: effects ?? this.effects,
      masterMuted: masterMuted ?? this.masterMuted,
      speechEnabled: speechEnabled ?? this.speechEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'voice': voice,
        'music': music,
        'effects': effects,
        'master_muted': masterMuted,
        'speech_enabled': speechEnabled,
      };

  factory AudioPrefs.fromJson(Map<String, dynamic> json) {
    return AudioPrefs(
      voice: (json['voice'] as num?)?.toDouble() ?? 1.0,
      music: (json['music'] as num?)?.toDouble() ?? 0.5,
      effects: (json['effects'] as num?)?.toDouble() ?? 0.8,
      masterMuted: json['master_muted'] as bool? ?? false,
      speechEnabled: json['speech_enabled'] as bool? ?? true,
    );
  }

  /// Default preferences.
  static const AudioPrefs defaults = AudioPrefs();

  @override
  List<Object?> get props =>
      [voice, music, effects, masterMuted, speechEnabled];
}
