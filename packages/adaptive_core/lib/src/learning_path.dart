import 'package:equatable/equatable.dart';
import 'package:mastery_core/mastery_core.dart';
import 'student_state.dart';

/// A node in a learning path graph.
class LearningPathNode extends Equatable {
  const LearningPathNode({
    required this.skillId,
    required this.displayName,
    this.prerequisiteSkillIds = const [],
    this.estimatedMinutes = 5,
    this.difficulty = 1,
    this.subjectCode,
  });

  final String skillId;
  final String displayName;
  final List<String> prerequisiteSkillIds;
  final int estimatedMinutes;
  final int difficulty;
  final String? subjectCode;

  @override
  List<Object?> get props => [
    skillId,
    displayName,
    prerequisiteSkillIds,
    estimatedMinutes,
    difficulty,
    subjectCode,
  ];
}

/// A generated learning path with ordered nodes.
class LearningPath extends Equatable {
  const LearningPath({
    required this.childId,
    required this.nodes,
    required this.focusSkillIds,
    required this.totalEstimatedMinutes,
    required this.reasonCodes,
    this.engineVersion = 'learning-path-v1',
  });

  final String childId;
  final List<LearningPathNode> nodes;
  final List<String> focusSkillIds;
  final int totalEstimatedMinutes;
  final List<String> reasonCodes;
  final String engineVersion;

  @override
  List<Object?> get props => [
    childId,
    nodes,
    focusSkillIds,
    totalEstimatedMinutes,
    reasonCodes,
    engineVersion,
  ];
}

/// Learning path generator.
///
/// Per blueprint §9: Generates an ordered sequence of learning activities
/// based on current student state. Respects prerequisites, spacing,
/// and difficulty progression.
class LearningPathGenerator {
  const LearningPathGenerator({
    this.maxPathLength = 10,
    this.maxPathMinutes = 25,
  });

  final int maxPathLength;
  final int maxPathMinutes;

  /// Generate a learning path for a student.
  LearningPath generate({
    required StudentState student,
    required List<LearningPathNode> availableNodes,
    String? focusSubject,
  }) {
    final reasonCodes = <String>[];
    var totalMinutes = 0;
    final pathNodes = <LearningPathNode>[];
    final focusSkills = <String>[];
    final seenSkills = <String>{};

    // 1. Add review-due skills first
    final reviewDue = student.reviewDueSkills;
    for (final mastery in reviewDue) {
      final node = availableNodes
          .where((n) => n.skillId == mastery.skillId)
          .firstOrNull;
      if (node != null &&
          seenSkills.add(node.skillId) &&
          totalMinutes + node.estimatedMinutes <= maxPathMinutes &&
          pathNodes.length < maxPathLength) {
        pathNodes.add(node);
        focusSkills.add(node.skillId);
        totalMinutes += node.estimatedMinutes;
        reasonCodes.add('REVIEW_DUE:${node.skillId}');
      }
    }

    // 2. Add skills in developing/not-started by prerequisite order
    final candidates = availableNodes.where((n) {
      if (seenSkills.contains(n.skillId)) return false;
      if (focusSubject != null && n.subjectCode != focusSubject) return false;
      // Must have prerequisites met
      for (final prereq in n.prerequisiteSkillIds) {
        final prereqMastery = student.masteries[prereq];
        if (prereqMastery == null ||
            prereqMastery.status == MasteryStatus.notStarted) {
          return false;
        }
      }
      return true;
    }).toList();

    // Sort by mastery score ascending (lowest mastery = highest priority)
    candidates.sort((a, b) {
      final mAScore = student.masteries[a.skillId]?.masteryScore ?? 0.0;
      final mBScore = student.masteries[b.skillId]?.masteryScore ?? 0.0;
      return mAScore.compareTo(mBScore);
    });

    for (final node in candidates) {
      if (totalMinutes + node.estimatedMinutes > maxPathMinutes) break;
      if (pathNodes.length >= maxPathLength) break;
      pathNodes.add(node);
      focusSkills.add(node.skillId);
      totalMinutes += node.estimatedMinutes;

      final mastery = student.masteries[node.skillId];
      if (mastery == null) {
        reasonCodes.add('NEW_SKILL:${node.skillId}');
      } else if (mastery.status == MasteryStatus.developing) {
        reasonCodes.add('DEVELOPING:${node.skillId}');
      } else if (mastery.status == MasteryStatus.introduced) {
        reasonCodes.add('INTRODUCED:${node.skillId}');
      } else {
        reasonCodes.add('PRACTICE:${node.skillId}');
      }
    }

    return LearningPath(
      childId: student.childId,
      nodes: pathNodes,
      focusSkillIds: focusSkills,
      totalEstimatedMinutes: totalMinutes,
      reasonCodes: reasonCodes,
    );
  }
}
