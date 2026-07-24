import 'package:json_annotation/json_annotation.dart';

part 'accessibility_config.g.dart';

/// Accessibility configuration for game sessions.
/// Ensures games are playable by children with diverse needs.
@JsonSerializable(explicitToJson: true)
class AccessibilityConfig {
  final bool highContrast;
  final bool largeText;
  final bool reduceMotion;
  final bool screenReader;
  final double fontSize;

  const AccessibilityConfig({
    this.highContrast = false,
    this.largeText = false,
    this.reduceMotion = false,
    this.screenReader = false,
    this.fontSize = 16.0,
  });

  factory AccessibilityConfig.fromJson(Map<String, dynamic> json) =>
      _$AccessibilityConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AccessibilityConfigToJson(this);

  /// Validates configuration constraints.
  List<String> validate() {
    final errors = <String>[];
    if (fontSize < 12.0 || fontSize > 32.0) {
      errors.add('fontSize must be between 12.0 and 32.0');
    }
    return errors;
  }

  AccessibilityConfig copyWith({
    bool? highContrast,
    bool? largeText,
    bool? reduceMotion,
    bool? screenReader,
    double? fontSize,
  }) {
    return AccessibilityConfig(
      highContrast: highContrast ?? this.highContrast,
      largeText: largeText ?? this.largeText,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      screenReader: screenReader ?? this.screenReader,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccessibilityConfig &&
          runtimeType == other.runtimeType &&
          highContrast == other.highContrast &&
          largeText == other.largeText &&
          reduceMotion == other.reduceMotion &&
          screenReader == other.screenReader &&
          fontSize == other.fontSize;

  @override
  int get hashCode => Object.hash(
    highContrast,
    largeText,
    reduceMotion,
    screenReader,
    fontSize,
  );
}
