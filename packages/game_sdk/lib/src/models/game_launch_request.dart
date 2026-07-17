import 'package:json_annotation/json_annotation.dart';
import 'accessibility_config.dart';
import 'audio_preferences.dart';

part 'game_launch_request.g.dart';

/// Request to launch a game session for a child.
/// Contract: mi.game.launch-request / v2
@JsonSerializable(explicitToJson: true)
class GameLaunchRequest {
  final String childProfileId;
  final String gameId;
  final String levelId;
  final String language;
  final String ageGroup;
  final AccessibilityConfig? accessibility;
  final AudioPreferences? audioPreferences;
  final Map<String, dynamic>? levelContent;
  final String? resumeToken;

  const GameLaunchRequest({
    required this.childProfileId,
    required this.gameId,
    required this.levelId,
    required this.language,
    required this.ageGroup,
    this.accessibility,
    this.audioPreferences,
    this.levelContent,
    this.resumeToken,
  });

  factory GameLaunchRequest.fromJson(Map<String, dynamic> json) =>
      _$GameLaunchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GameLaunchRequestToJson(this);

  static const List<String> supportedLanguages = ['en', 'vi'];
  static const List<String> supportedAgeGroups = ['junior', 'mid', 'senior'];

  /// Validates all fields against contract rules.
  List<String> validate() {
    final errors = <String>[];
    if (childProfileId.isEmpty) errors.add('childProfileId is required');
    if (gameId.isEmpty) errors.add('gameId is required');
    if (levelId.isEmpty) errors.add('levelId is required');
    if (!supportedLanguages.contains(language)) {
      errors.add('language must be one of: ${supportedLanguages.join(', ')}');
    }
    if (!supportedAgeGroups.contains(ageGroup)) {
      errors.add('ageGroup must be one of: ${supportedAgeGroups.join(', ')}');
    }
    if (accessibility != null) {
      errors.addAll(accessibility!.validate().map((e) => 'accessibility.$e'));
    }
    if (audioPreferences != null) {
      errors.addAll(audioPreferences!.validate().map((e) => 'audio.$e'));
    }
    return errors;
  }

  GameLaunchRequest copyWith({
    String? childProfileId,
    String? gameId,
    String? levelId,
    String? language,
    String? ageGroup,
    AccessibilityConfig? accessibility,
    AudioPreferences? audioPreferences,
    Map<String, dynamic>? levelContent,
    String? resumeToken,
  }) {
    return GameLaunchRequest(
      childProfileId: childProfileId ?? this.childProfileId,
      gameId: gameId ?? this.gameId,
      levelId: levelId ?? this.levelId,
      language: language ?? this.language,
      ageGroup: ageGroup ?? this.ageGroup,
      accessibility: accessibility ?? this.accessibility,
      audioPreferences: audioPreferences ?? this.audioPreferences,
      levelContent: levelContent ?? this.levelContent,
      resumeToken: resumeToken ?? this.resumeToken,
    );
  }
}
