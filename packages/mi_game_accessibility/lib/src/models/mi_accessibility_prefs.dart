import 'package:equatable/equatable.dart';

/// Comprehensive accessibility preferences for MI Academy games.
///
/// Extends the core [AccessibilityPreferences] from mi_game_core
/// with additional preferences for save/load.
class MiAccessibilityPrefs extends Equatable {
  const MiAccessibilityPrefs({
    this.highContrast = false,
    this.largeText = false,
    this.reduceMotion = false,
    this.screenReader = false,
    this.fontSize = 1.0,
    this.tapAlternativeForDrag = false,
    this.colorIndependentFeedback = true,
    this.subtitlesEnabled = false,
    this.extendedResponseTime = false,
  });

  /// High contrast mode for visually impaired children.
  final bool highContrast;

  /// Large text mode.
  final bool largeText;

  /// Reduce or disable animations.
  final bool reduceMotion;

  /// Screen reader active (TalkBack/VoiceOver).
  final bool screenReader;

  /// Text scale factor (1.0 = normal, 1.5 = 50% larger, etc.).
  final double fontSize;

  /// Use tap-to-place instead of drag-and-drop.
  final bool tapAlternativeForDrag;

  /// Feedback must not rely on color alone (use icons + patterns).
  final bool colorIndependentFeedback;

  /// Show subtitles for audio content.
  final bool subtitlesEnabled;

  /// Double the response timeout for children who need more time.
  final bool extendedResponseTime;

  /// Clamped text scale factor (never below 1.0, never above 2.0).
  double get textScaleFactor => fontSize.clamp(1.0, 2.0);

  /// Animation duration adjusted for reduced-motion.
  Duration animationDuration(Duration normal) {
    return reduceMotion ? Duration.zero : normal;
  }

  /// Response timeout adjusted for extended time.
  Duration responseTimeout(Duration base) {
    return extendedResponseTime ? base * 2 : base;
  }

  /// Minimum touch target size — larger when screen reader is active.
  double get minTouchTarget => screenReader ? 56.0 : 48.0;

  MiAccessibilityPrefs copyWith({
    bool? highContrast,
    bool? largeText,
    bool? reduceMotion,
    bool? screenReader,
    double? fontSize,
    bool? tapAlternativeForDrag,
    bool? colorIndependentFeedback,
    bool? subtitlesEnabled,
    bool? extendedResponseTime,
  }) {
    return MiAccessibilityPrefs(
      highContrast: highContrast ?? this.highContrast,
      largeText: largeText ?? this.largeText,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      screenReader: screenReader ?? this.screenReader,
      fontSize: fontSize ?? this.fontSize,
      tapAlternativeForDrag: tapAlternativeForDrag ?? this.tapAlternativeForDrag,
      colorIndependentFeedback: colorIndependentFeedback ?? this.colorIndependentFeedback,
      subtitlesEnabled: subtitlesEnabled ?? this.subtitlesEnabled,
      extendedResponseTime: extendedResponseTime ?? this.extendedResponseTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'high_contrast': highContrast,
        'large_text': largeText,
        'reduce_motion': reduceMotion,
        'screen_reader': screenReader,
        'font_size': fontSize,
        'tap_alternative_for_drag': tapAlternativeForDrag,
        'color_independent_feedback': colorIndependentFeedback,
        'subtitles_enabled': subtitlesEnabled,
        'extended_response_time': extendedResponseTime,
      };

  factory MiAccessibilityPrefs.fromJson(Map<String, dynamic> json) {
    return MiAccessibilityPrefs(
      highContrast: json['high_contrast'] as bool? ?? false,
      largeText: json['large_text'] as bool? ?? false,
      reduceMotion: json['reduce_motion'] as bool? ?? false,
      screenReader: json['screen_reader'] as bool? ?? false,
      fontSize: (json['font_size'] as num?)?.toDouble() ?? 1.0,
      tapAlternativeForDrag: json['tap_alternative_for_drag'] as bool? ?? false,
      colorIndependentFeedback: json['color_independent_feedback'] as bool? ?? true,
      subtitlesEnabled: json['subtitles_enabled'] as bool? ?? false,
      extendedResponseTime: json['extended_response_time'] as bool? ?? false,
    );
  }

  /// Default preferences.
  static const MiAccessibilityPrefs defaults = MiAccessibilityPrefs();

  @override
  List<Object?> get props => [
        highContrast,
        largeText,
        reduceMotion,
        screenReader,
        fontSize,
        tapAlternativeForDrag,
        colorIndependentFeedback,
        subtitlesEnabled,
        extendedResponseTime,
      ];
}
