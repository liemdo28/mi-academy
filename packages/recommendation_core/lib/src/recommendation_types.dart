import 'package:equatable/equatable.dart';

/// Types of recommendations.
enum RecommendationType {
  nextLesson,
  review,
  game,
  difficultyChange,
  warmup,
  creativeActivity,
}

/// Priority tier for recommendations.
enum RecommendationPriority {
  /// Critical — prerequisite skill just mastered, unlock path is open
  unlock(1),

  /// High — weak skill needs immediate practice
  weak(2),

  /// Medium — spaced repetition due
  review(3),

  /// Normal — new content introduction
  newContent(4),

  /// Low — enrichment or creative
  enrichment(5);

  const RecommendationPriority(this.value);
  final int value;
}

/// A single recommendation for a child.
class Recommendation extends Equatable {
  const Recommendation({
    required this.recommendationId,
    required this.childProfileId,
    required this.type,
    required this.targetId,
    required this.priority,
    required this.score,
    required this.confidence,
    required this.reasonCodes,
    required this.engineVersion,
    this.subjectCode,
    this.gameId,
    this.levelId,
    this.skillId,
    this.estimatedMinutes,
    this.offlineAvailable = true,
    this.fallbackRecommendationId,
  });

  final String recommendationId;
  final String childProfileId;
  final RecommendationType type;
  final String targetId;
  final RecommendationPriority priority;
  final double score;
  final double confidence;
  final List<String> reasonCodes;
  final String engineVersion;
  final String? subjectCode;
  final String? gameId;
  final String? levelId;
  final String? skillId;
  final int? estimatedMinutes;
  final bool offlineAvailable;
  final String? fallbackRecommendationId;

  @override
  List<Object?> get props => [
    recommendationId,
    childProfileId,
    type,
    targetId,
    priority,
    score,
    confidence,
    reasonCodes,
    engineVersion,
    subjectCode,
    gameId,
    levelId,
    skillId,
    estimatedMinutes,
    offlineAvailable,
    fallbackRecommendationId,
  ];

  Map<String, dynamic> toJson() => {
    'recommendationId': recommendationId,
    'childProfileId': childProfileId,
    'type': type.name,
    'targetId': targetId,
    'priority': priority.value,
    'score': score,
    'confidence': confidence,
    'reasonCodes': reasonCodes,
    'engineVersion': engineVersion,
    if (subjectCode != null) 'subjectCode': subjectCode,
    if (gameId != null) 'gameId': gameId,
    if (levelId != null) 'levelId': levelId,
    if (skillId != null) 'skillId': skillId,
    if (estimatedMinutes != null) 'estimatedMinutes': estimatedMinutes,
    'offlineAvailable': offlineAvailable,
    if (fallbackRecommendationId != null)
      'fallbackRecommendationId': fallbackRecommendationId,
  };
}

/// Complete recommendation result with engine metadata.
class RecommendationResult extends Equatable {
  const RecommendationResult({
    required this.recommendations,
    required this.engineVersion,
    required this.offlineMode,
    this.usedFallback = false,
    this.fallbackReason,
    this.totalEstimatedMinutes = 0,
  });

  final List<Recommendation> recommendations;
  final String engineVersion;
  final bool offlineMode;
  final bool usedFallback;
  final String? fallbackReason;
  final int totalEstimatedMinutes;

  @override
  List<Object?> get props => [
    recommendations,
    engineVersion,
    offlineMode,
    usedFallback,
    fallbackReason,
    totalEstimatedMinutes,
  ];
}

/// Available content item for recommendation.
class ContentItem extends Equatable {
  const ContentItem({
    required this.id,
    required this.type,
    required this.subjectCode,
    required this.ageGroup,
    required this.difficulty,
    this.gameId,
    this.levelIndex,
    this.skillIds = const [],
    this.estimatedMinutes = 5,
    this.isPublished = true,
    this.offlineDownloaded = false,
    this.qualityWarnings = const [],
    this.prerequisiteSkillIds = const [],
  });

  final String id;
  final ContentType type;
  final String subjectCode;
  final String ageGroup;
  final int difficulty;
  final String? gameId;
  final int? levelIndex;
  final List<String> skillIds;
  final int estimatedMinutes;
  final bool isPublished;
  final bool offlineDownloaded;
  final List<String> qualityWarnings;
  final List<String> prerequisiteSkillIds;

  @override
  List<Object?> get props => [
    id,
    type,
    subjectCode,
    ageGroup,
    difficulty,
    gameId,
    levelIndex,
    skillIds,
    estimatedMinutes,
    isPublished,
    offlineDownloaded,
    qualityWarnings,
    prerequisiteSkillIds,
  ];
}

enum ContentType { lesson, game, level }

/// Reason codes for recommendation decisions.
class ReasonCodes {
  ReasonCodes._();

  // Prerequisite related
  static const prerequisiteMastered = 'PREREQUISITE_MASTERED';
  static const prerequisiteUnmet = 'PREREQUISITE_UNMET';
  static const allPrerequisitesMet = 'ALL_PREREQUISITES_MET';

  // Mastery related
  static const lowMastery = 'LOW_MASTERY';
  static const developingSkill = 'DEVELOPING_SKILL';
  static const masteredSkill = 'MASTERED_SKILL';
  static const noEvidence = 'NO_EVIDENCE';

  // Spaced repetition related
  static const reviewDue = 'REVIEW_DUE';
  static const reviewNotYet = 'REVIEW_NOT_YET';
  static const retentionConfirm = 'RETENTION_CONFIRM';

  // Difficulty related
  static const difficultyMatch = 'DIFFICULTY_MATCH';
  static const difficultyHigh = 'DIFFICULTY_HIGH';
  static const difficultyLow = 'DIFFICULTY_LOW';
  static const difficultyIncrease = 'DIFFICULTY_INCREASE';
  static const difficultyDecrease = 'DIFFICULTY_DECREASE';

  // Session related
  static const subjectRotation = 'SUBJECT_ROTATION';
  static const sessionLengthOk = 'SESSION_LENGTH_OK';
  static const sessionLengthExceeded = 'SESSION_LENGTH_EXCEEDED';
  static const warmupNeeded = 'WARMUP_NEEDED';

  // Content availability
  static const offlineAvailable = 'OFFLINE_AVAILABLE';
  static const published = 'PUBLISHED';
  static const qualityWarning = 'QUALITY_WARNING';

  // Age appropriateness
  static const ageGroupMatch = 'AGE_GROUP_MATCH';
}
