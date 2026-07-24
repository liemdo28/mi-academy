import 'package:json_annotation/json_annotation.dart';

part 'audio_preferences.g.dart';

/// Audio preferences for game sessions.
/// Controls music, SFX, and speech output levels.
@JsonSerializable(explicitToJson: true)
class AudioPreferences {
  final double musicVolume;
  final double sfxVolume;
  final bool speechEnabled;
  final String? voiceGender;
  final double speechRate;

  const AudioPreferences({
    this.musicVolume = 0.7,
    this.sfxVolume = 0.8,
    this.speechEnabled = false,
    this.voiceGender,
    this.speechRate = 1.0,
  });

  factory AudioPreferences.fromJson(Map<String, dynamic> json) =>
      _$AudioPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$AudioPreferencesToJson(this);

  /// Validates volume bounds and speech rate.
  List<String> validate() {
    final errors = <String>[];
    if (musicVolume < 0.0 || musicVolume > 1.0) {
      errors.add('musicVolume must be between 0.0 and 1.0');
    }
    if (sfxVolume < 0.0 || sfxVolume > 1.0) {
      errors.add('sfxVolume must be between 0.0 and 1.0');
    }
    if (speechRate < 0.5 || speechRate > 2.0) {
      errors.add('speechRate must be between 0.5 and 2.0');
    }
    if (voiceGender != null && !['male', 'female'].contains(voiceGender)) {
      errors.add('voiceGender must be male or female');
    }
    return errors;
  }

  AudioPreferences copyWith({
    double? musicVolume,
    double? sfxVolume,
    bool? speechEnabled,
    String? voiceGender,
    double? speechRate,
  }) {
    return AudioPreferences(
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      speechEnabled: speechEnabled ?? this.speechEnabled,
      voiceGender: voiceGender ?? this.voiceGender,
      speechRate: speechRate ?? this.speechRate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioPreferences &&
          runtimeType == other.runtimeType &&
          musicVolume == other.musicVolume &&
          sfxVolume == other.sfxVolume &&
          speechEnabled == other.speechEnabled &&
          voiceGender == other.voiceGender &&
          speechRate == other.speechRate;

  @override
  int get hashCode => Object.hash(
    musicVolume,
    sfxVolume,
    speechEnabled,
    voiceGender,
    speechRate,
  );
}
