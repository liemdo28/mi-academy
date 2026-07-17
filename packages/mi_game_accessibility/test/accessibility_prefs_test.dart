import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_accessibility/mi_game_accessibility.dart';

void main() {
  group('MiAccessibilityPrefs', () {
    test('defaults are child-safe and conservative', () {
      const prefs = MiAccessibilityPrefs.defaults;

      expect(prefs.highContrast, isFalse);
      expect(prefs.largeText, isFalse);
      expect(prefs.reduceMotion, isFalse);
      expect(prefs.screenReader, isFalse);
      expect(prefs.subtitlesEnabled, isFalse);
      expect(prefs.tapAlternativeForDrag, isFalse);
      expect(prefs.colorIndependentFeedback, isTrue);
      expect(prefs.extendedResponseTime, isFalse);
      expect(prefs.textScaleFactor, 1.0);
      expect(prefs.minTouchTarget, 48.0);
    });

    test('clamps text scale between 1.0 and 2.0', () {
      expect(const MiAccessibilityPrefs(fontSize: 0.5).textScaleFactor, 1.0);
      expect(const MiAccessibilityPrefs(fontSize: 1.5).textScaleFactor, 1.5);
      expect(const MiAccessibilityPrefs(fontSize: 3.0).textScaleFactor, 2.0);
    });

    test('screen reader increases minimum touch target', () {
      expect(const MiAccessibilityPrefs(screenReader: false).minTouchTarget, 48.0);
      expect(const MiAccessibilityPrefs(screenReader: true).minTouchTarget, 56.0);
    });

    test('reduced motion removes animation duration', () {
      const normal = Duration(milliseconds: 300);

      expect(const MiAccessibilityPrefs(reduceMotion: false).animationDuration(normal), normal);
      expect(const MiAccessibilityPrefs(reduceMotion: true).animationDuration(normal), Duration.zero);
    });

    test('extended response time doubles timeout', () {
      const base = Duration(seconds: 10);

      expect(const MiAccessibilityPrefs(extendedResponseTime: false).responseTimeout(base), base);
      expect(const MiAccessibilityPrefs(extendedResponseTime: true).responseTimeout(base), const Duration(seconds: 20));
    });

    test('JSON roundtrip preserves fields', () {
      const prefs = MiAccessibilityPrefs(
        highContrast: true,
        largeText: true,
        reduceMotion: true,
        screenReader: true,
        fontSize: 1.5,
        tapAlternativeForDrag: true,
        colorIndependentFeedback: false,
        subtitlesEnabled: true,
        extendedResponseTime: true,
      );

      final restored = MiAccessibilityPrefs.fromJson(prefs.toJson());

      expect(restored, prefs);
    });

    test('copyWith changes selected fields only', () {
      final copy = MiAccessibilityPrefs.defaults.copyWith(
        reduceMotion: true,
        fontSize: 1.4,
      );

      expect(copy.reduceMotion, isTrue);
      expect(copy.fontSize, 1.4);
      expect(copy.highContrast, isFalse);
    });
  });

  group('MotionConfig', () {
    test('reduced motion disables motion-heavy durations', () {
      const config = MotionConfig(reducedMotion: true);

      expect(config.cardFlip, Duration.zero);
      expect(config.celebration, Duration.zero);
      expect(config.observeDelay, const Duration(milliseconds: 400));
    });
  });

  group('SemanticLabels', () {
    test('returns Vietnamese labels', () {
      final labels = SemanticLabels('vi');

      expect(labels.pauseButton, 'Nút tạm dừng');
      expect(labels.progress(1, 3), 'Đã hoàn thành 1 trên 3');
    });

    test('returns English labels', () {
      final labels = SemanticLabels('en');

      expect(labels.pauseButton, 'Pause button');
      expect(labels.progress(1, 3), 'Completed 1 of 3');
    });
  });
}
