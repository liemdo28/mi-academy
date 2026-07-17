/// Motion configuration honoring reduced-motion preferences.
class MotionConfig {
  const MotionConfig({required this.reducedMotion});

  final bool reducedMotion;

  /// Standard card flip duration.
  Duration get cardFlip =>
      reducedMotion ? Duration.zero : const Duration(milliseconds: 300);

  /// Card mismatch "flip back" delay (time to observe before hiding).
  Duration get observeDelay =>
      reducedMotion ? const Duration(milliseconds: 400) : const Duration(seconds: 1);

  /// Celebration animation duration.
  Duration get celebration =>
      reducedMotion ? Duration.zero : const Duration(milliseconds: 1200);

  /// Feedback bubble display duration.
  Duration get feedbackDisplay => const Duration(milliseconds: 1800);
}
