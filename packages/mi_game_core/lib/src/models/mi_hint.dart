import 'package:equatable/equatable.dart';

/// A hint provided to the child when they request help.
///
/// Hints are progressive: level 1 is a gentle nudge,
/// level 4+ is near-solution (but never auto-completes).
class MiHint extends Equatable {
  const MiHint({
    required this.hintNumber,
    required this.content,
    this.mediaRef,
    this.highlightTarget,
    this.action,
  });

  /// Ordinal hint number (1 = first gentle hint).
  final int hintNumber;

  /// Localized hint text.
  final String content;

  /// Optional audio/image reference for the hint.
  final String? mediaRef;

  /// Optional UI element to highlight (e.g., "card:3", "slot:first").
  final String? highlightTarget;

  /// Optional action to perform (e.g., "place_letter:A").
  final Map<String, dynamic>? action;

  @override
  List<Object?> get props =>
      [hintNumber, content, mediaRef, highlightTarget, action];
}
