import 'package:mastery_core/mastery_core.dart';

/// Checks if prerequisites for content are satisfied.
///
/// Per blueprint §8: Never recommend content when prerequisites are unmet.
class PrerequisiteChecker {
  const PrerequisiteChecker();

  /// Returns true if all prerequisites for a content item are met
  /// based on the child's current mastery states.
  bool canAccess({
    required List<String> requiredPrerequisites,
    required Map<String, MasteryState> childMasteries,
    double minimumMasteryThreshold = 0.15,
  }) {
    if (requiredPrerequisites.isEmpty) return true;

    for (final prereq in requiredPrerequisites) {
      final mastery = childMasteries[prereq];
      // No evidence of prerequisite → cannot access
      if (mastery == null) return false;
      // Mastery below minimum threshold → cannot access
      if (mastery.masteryScore < minimumMasteryThreshold) return false;
    }
    return true;
  }

  /// Returns the list of unmet prerequisites.
  List<String> getUnmetPrerequisites({
    required List<String> requiredPrerequisites,
    required Map<String, MasteryState> childMasteries,
    double minimumMasteryThreshold = 0.15,
  }) {
    final unmet = <String>[];
    for (final prereq in requiredPrerequisites) {
      final mastery = childMasteries[prereq];
      if (mastery == null || mastery.masteryScore < minimumMasteryThreshold) {
        unmet.add(prereq);
      }
    }
    return unmet;
  }

  /// Returns the mastery level of the weakest prerequisite.
  double getWeakestPrerequisiteMastery({
    required List<String> requiredPrerequisites,
    required Map<String, MasteryState> childMasteries,
  }) {
    if (requiredPrerequisites.isEmpty) return 1.0;

    double weakest = 1.0;
    for (final prereq in requiredPrerequisites) {
      final mastery = childMasteries[prereq];
      if (mastery != null) {
        if (mastery.masteryScore < weakest) {
          weakest = mastery.masteryScore;
        }
      }
    }
    return weakest;
  }
}
