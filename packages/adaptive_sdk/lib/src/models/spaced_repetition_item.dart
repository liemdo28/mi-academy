import 'dart:math';
import 'package:json_annotation/json_annotation.dart';

part 'spaced_repetition_item.g.dart';

/// A spaced repetition scheduling item using a simplified SM-2 algorithm.
///
/// Tracks review state, calculates next review time, and adjusts
/// intervals based on recall quality.
@JsonSerializable(explicitToJson: true)
class SpacedRepetitionItem {
  final String itemId;
  final String childProfileId;
  final String skillId;
  final String contentId; // lesson or level being reviewed
  final double easeFactor; // default 2.5, range 1.3-3.0
  final int interval; // days until next review
  final int repetitions; // consecutive successful reviews
  final DateTime nextReviewAt;
  final DateTime lastReviewAt;
  final double lastQuality; // 0.0-1.0 recall quality
  final String status; // new, learning, review, mastered, suspended
  final String schemaVersion;

  static const String currentSchemaVersion = '1.0.0';
  static const validStatuses = [
    'new',
    'learning',
    'review',
    'mastered',
    'suspended',
  ];
  static const defaultEaseFactor = 2.5;

  SpacedRepetitionItem({
    required this.itemId,
    required this.childProfileId,
    required this.skillId,
    required this.contentId,
    this.easeFactor = defaultEaseFactor,
    this.interval = 0,
    this.repetitions = 0,
    DateTime? nextReviewAt,
    DateTime? lastReviewAt,
    this.lastQuality = 0.0,
    this.status = 'new',
    this.schemaVersion = currentSchemaVersion,
  }) : nextReviewAt = nextReviewAt ?? DateTime.now(),
       lastReviewAt = lastReviewAt ?? DateTime.now();

  factory SpacedRepetitionItem.fromJson(Map<String, dynamic> json) =>
      _$SpacedRepetitionItemFromJson(json);
  Map<String, dynamic> toJson() => _$SpacedRepetitionItemToJson(this);

  /// Whether this item is due for review now.
  bool get isDue => DateTime.now().isAfter(nextReviewAt);

  /// Whether this item is overdue by more than 1 day.
  bool get isOverdue => DateTime.now().difference(nextReviewAt).inDays > 1;

  /// Days until next review. Negative means overdue.
  int get daysUntilReview => DateTime.now().difference(nextReviewAt).inDays;

  /// Whether the item has been mastered (5+ successful repetitions).
  bool get isMastered => repetitions >= 5;

  /// Process a review result and compute updated scheduling parameters.
  ///
  /// [quality]: 0.0-1.0 — how well the child recalled the material.
  /// Returns a new [SpacedRepetitionItem] with updated scheduling.
  SpacedRepetitionItem processReview(double quality) {
    if (quality < 0 || quality > 1) return this;

    int newInterval;
    int newRepetitions;
    double newEaseFactor = easeFactor;

    if (quality >= 0.6) {
      // Successful recall
      newRepetitions = repetitions + 1;
      if (repetitions == 0) {
        newInterval = 1; // first successful: 1 day
      } else if (repetitions == 1) {
        newInterval = 3; // second: 3 days
      } else {
        newInterval = (interval * easeFactor).round();
      }
      // Adjust ease factor
      newEaseFactor =
          easeFactor +
          (0.1 - (5 - quality * 5) * (0.08 + (5 - quality * 5) * 0.02));
      newEaseFactor = newEaseFactor.clamp(1.3, 3.0);
    } else {
      // Failed recall — reset
      newRepetitions = 0;
      newInterval = 1;
      newEaseFactor = (easeFactor - 0.2).clamp(1.3, 3.0);
    }

    String newStatus;
    if (newRepetitions >= 5) {
      newStatus = 'mastered';
    } else if (newRepetitions >= 2) {
      newStatus = 'review';
    } else if (newRepetitions >= 1) {
      newStatus = 'learning';
    } else {
      newStatus = 'learning';
    }

    return SpacedRepetitionItem(
      itemId: itemId,
      childProfileId: childProfileId,
      skillId: skillId,
      contentId: contentId,
      easeFactor: newEaseFactor,
      interval: newInterval,
      repetitions: newRepetitions,
      nextReviewAt: DateTime.now().add(Duration(days: newInterval)),
      lastReviewAt: DateTime.now(),
      lastQuality: quality,
      status: newStatus,
    );
  }

  /// Create a new item ready for first review.
  factory SpacedRepetitionItem.createNew({
    required String childProfileId,
    required String skillId,
    required String contentId,
  }) {
    return SpacedRepetitionItem(
      childProfileId: childProfileId,
      skillId: skillId,
      contentId: contentId,
      status: 'new',
    );
  }

  List<String> validate() {
    final errors = <String>[];
    if (itemId.isEmpty) errors.add('itemId required');
    if (!validStatuses.contains(status)) {
      errors.add('Invalid status: $status');
    }
    if (easeFactor < 1.3 || easeFactor > 3.0) {
      errors.add('easeFactor must be 1.3-3.0');
    }
    return errors;
  }
}
