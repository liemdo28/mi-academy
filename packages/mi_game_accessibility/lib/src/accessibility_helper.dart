import 'package:mi_game_core/mi_game_core.dart';

/// Helper that turns [AccessibilityPreferences] into concrete UI decisions.
class AccessibilityHelper {
  const AccessibilityHelper(this.prefs);

  final AccessibilityPreferences prefs;

  /// Clamped text scale factor (never below 1.0, never above 2.0).
  double get textScaleFactor => prefs.textScaleFactor.clamp(1.0, 2.0);

  /// Whether animations should be disabled/reduced.
  bool get reduceMotion => prefs.reducedMotion;

  /// Whether the game should offer tap-to-place instead of drag.
  bool get useTapAlternative => prefs.tapAlternativeForDrag;

  /// Whether feedback must not rely on color alone.
  bool get needsColorIndependentFeedback => prefs.colorIndependentFeedback;

  /// Whether subtitles should be shown for audio.
  bool get showSubtitles => prefs.subtitlesEnabled;

  /// Whether the screen reader is active.
  bool get screenReaderActive => prefs.screenReaderEnabled;

  /// Animation duration adjusted for reduced-motion.
  ///
  /// Returns [Duration.zero] when reduced motion is active.
  Duration animationDuration(Duration normal) {
    return reduceMotion ? Duration.zero : normal;
  }

  /// Response timeout adjusted for extended response time.
  ///
  /// Multiplies the base timeout by 2 when extended time is requested.
  Duration responseTimeout(Duration base) {
    return prefs.extendedResponseTime ? base * 2 : base;
  }

  /// Minimum touch target size — larger when needed.
  double get minTouchTarget => screenReaderActive ? 56.0 : 48.0;
}
