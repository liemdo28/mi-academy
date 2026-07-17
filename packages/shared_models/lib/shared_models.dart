/// Cross-app data models for MI Academy.
///
/// These models are shared between:
/// - apps/mobile (child + parent UI)
/// - apps/admin (content management)
/// - packages/learning_core
/// - packages/progress_core
library shared_models;

// ─── Auth ────────────────────────────────────────────────────────────────────

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });
}

// ─── Parent ───────────────────────────────────────────────────────────────────

class ParentProfile {
  final String id;
  final String displayName;
  final String language;
  final String timezone;
  final bool hasPin;
  const ParentProfile({
    required this.id,
    required this.displayName,
    required this.language,
    required this.timezone,
    required this.hasPin,
  });
}

// ─── Child ────────────────────────────────────────────────────────────────────

enum AgeGroup { junior, explorer, master }

extension AgeGroupExtension on AgeGroup {
  String get value {
    switch (this) {
      case AgeGroup.junior:
        return 'junior';
      case AgeGroup.explorer:
        return 'explorer';
      case AgeGroup.master:
        return 'master';
    }
  }

  static AgeGroup fromString(String value) {
    switch (value) {
      case 'junior':
        return AgeGroup.junior;
      case 'explorer':
        return AgeGroup.explorer;
      case 'master':
        return AgeGroup.master;
      default:
        return AgeGroup.junior;
    }
  }
}

class ChildProfile {
  final String id;
  final String parentId;
  final String nickname;
  final int? birthYear;
  final AgeGroup ageGroup;
  final String? gradeLevel;
  final String avatarId;
  final String preferredLanguage;
  final int? dailyTimeLimitMinutes;
  final DateTime createdAt;

  const ChildProfile({
    required this.id,
    required this.parentId,
    required this.nickname,
    this.birthYear,
    required this.ageGroup,
    this.gradeLevel,
    required this.avatarId,
    required this.preferredLanguage,
    this.dailyTimeLimitMinutes,
    required this.createdAt,
  });

  ChildProfile copyWith({
    String? nickname,
    String? avatarId,
    String? preferredLanguage,
    int? dailyTimeLimitMinutes,
  }) {
    return ChildProfile(
      id: id,
      parentId: parentId,
      nickname: nickname ?? this.nickname,
      birthYear: birthYear,
      ageGroup: ageGroup,
      gradeLevel: gradeLevel,
      avatarId: avatarId ?? this.avatarId,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      dailyTimeLimitMinutes: dailyTimeLimitMinutes ?? this.dailyTimeLimitMinutes,
      createdAt: createdAt,
    );
  }
}

// ─── Subject ──────────────────────────────────────────────────────────────────

class Subject {
  final String id;
  final String name;
  final String code;
  final String? icon;
  final int orderIndex;

  const Subject({
    required this.id,
    required this.name,
    required this.code,
    this.icon,
    required this.orderIndex,
  });
}

// ─── Lesson ───────────────────────────────────────────────────────────────────

class Lesson {
  final String id;
  final String subjectId;
  final String title;
  final String? description;
  final AgeGroup ageGroup;
  final int difficulty; // 1-5
  final String language;
  final int estimatedMinutes;
  final Map<String, dynamic>? contentJson;
  final bool isActive;

  const Lesson({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    required this.ageGroup,
    required this.difficulty,
    required this.language,
    required this.estimatedMinutes,
    this.contentJson,
    required this.isActive,
  });
}

// ─── Progress ─────────────────────────────────────────────────────────────────

enum LessonStatus { notStarted, learning, completed, needsPractice, mastered }

extension LessonStatusExtension on LessonStatus {
  String get value {
    switch (this) {
      case LessonStatus.notStarted:
        return 'not_started';
      case LessonStatus.learning:
        return 'learning';
      case LessonStatus.completed:
        return 'completed';
      case LessonStatus.needsPractice:
        return 'needs_practice';
      case LessonStatus.mastered:
        return 'mastered';
    }
  }

  static LessonStatus fromString(String value) {
    switch (value) {
      case 'not_started':
        return LessonStatus.notStarted;
      case 'learning':
        return LessonStatus.learning;
      case 'completed':
        return LessonStatus.completed;
      case 'needs_practice':
        return LessonStatus.needsPractice;
      case 'mastered':
        return LessonStatus.mastered;
      default:
        return LessonStatus.notStarted;
    }
  }
}

class LessonProgress {
  final String id;
  final String lessonId;
  final LessonStatus status;
  final double masteryScore; // 0.0-1.0
  final int totalAttempts;
  final DateTime? lastPlayedAt;

  const LessonProgress({
    required this.id,
    required this.lessonId,
    required this.status,
    required this.masteryScore,
    required this.totalAttempts,
    this.lastPlayedAt,
  });
}

// ─── Rewards ─────────────────────────────────────────────────────────────────

enum RewardType { star, badge, sticker, avatarItem }

class Reward {
  final String id;
  final RewardType type;
  final String name;
  final String? description;
  final String? assetUrl;

  const Reward({
    required this.id,
    required this.type,
    required this.name,
    this.description,
    this.assetUrl,
  });
}

class ChildReward {
  final String id;
  final String rewardId;
  final Reward reward;
  final DateTime unlockedAt;

  const ChildReward({
    required this.id,
    required this.rewardId,
    required this.reward,
    required this.unlockedAt,
  });
}

// ─── Usage ───────────────────────────────────────────────────────────────────

class DailySession {
  final String id;
  final String childId;
  final DateTime sessionDate;
  final int durationSeconds;
  final int lessonsCompleted;
  final int gamesCompleted;

  const DailySession({
    required this.id,
    required this.childId,
    required this.sessionDate,
    required this.durationSeconds,
    required this.lessonsCompleted,
    required this.gamesCompleted,
  });
}

// ─── App Settings ─────────────────────────────────────────────────────────────

class AccessibilitySettings {
  final bool highContrast;
  final bool largeText;
  final bool reduceMotion;
  final bool screenReader;
  final double fontSize;

  const AccessibilitySettings({
    this.highContrast = false,
    this.largeText = false,
    this.reduceMotion = false,
    this.screenReader = false,
    this.fontSize = 1.0,
  });
}

class AudioSettings {
  final double musicVolume; // 0.0-1.0
  final double sfxVolume; // 0.0-1.0
  final bool speechEnabled;

  const AudioSettings({
    this.musicVolume = 0.8,
    this.sfxVolume = 1.0,
    this.speechEnabled = true,
  });
}

// ─── Game Contracts ─────────────────────────────────────────────────────────
// These contracts define the interface between the platform and games (Dev 2).
// They must be serializable, versioned, and contain NO sensitive data.

/// Version for all game contracts. Increment when breaking changes occur.
const int kGameContractVersion = 1;

/// Preferences passed to a game when launching.
/// Only non-sensitive, child-appropriate settings.
class AccessibilityPreferences {
  final bool highContrast;
  final bool largeText;
  final bool reduceMotion;
  final bool screenReader;
  final double fontSize;

  const AccessibilityPreferences({
    this.highContrast = false,
    this.largeText = false,
    this.reduceMotion = false,
    this.screenReader = false,
    this.fontSize = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'highContrast': highContrast,
    'largeText': largeText,
    'reduceMotion': reduceMotion,
    'screenReader': screenReader,
    'fontSize': fontSize,
  };

  factory AccessibilityPreferences.fromJson(Map<String, dynamic> json) =>
      AccessibilityPreferences(
        highContrast: json['highContrast'] as bool? ?? false,
        largeText: json['largeText'] as bool? ?? false,
        reduceMotion: json['reduceMotion'] as bool? ?? false,
        screenReader: json['screenReader'] as bool? ?? false,
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 1.0,
      );
}

class AudioPreferences {
  final double musicVolume; // 0.0-1.0
  final double sfxVolume; // 0.0-1.0
  final bool speechEnabled;

  const AudioPreferences({
    this.musicVolume = 0.8,
    this.sfxVolume = 1.0,
    this.speechEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'musicVolume': musicVolume,
    'sfxVolume': sfxVolume,
    'speechEnabled': speechEnabled,
  };

  factory AudioPreferences.fromJson(Map<String, dynamic> json) =>
      AudioPreferences(
        musicVolume: (json['musicVolume'] as num?)?.toDouble() ?? 0.8,
        sfxVolume: (json['sfxVolume'] as num?)?.toDouble() ?? 1.0,
        speechEnabled: json['speechEnabled'] as bool? ?? true,
      );
}

/// Request sent from the platform to a game when launching.
/// NEVER contains: access tokens, parent passwords, parent emails, PII.
class MiGameLaunchRequest {
  final int schemaVersion;
  final String childProfileId;
  final String gameId;
  final String levelId;
  final String language;
  final String ageGroup;
  final AccessibilityPreferences accessibility;
  final AudioPreferences audioPreferences;
  final Map<String, dynamic> levelContent;
  final Map<String, dynamic>? restoredState;

  const MiGameLaunchRequest({
    this.schemaVersion = kGameContractVersion,
    required this.childProfileId,
    required this.gameId,
    required this.levelId,
    required this.language,
    required this.ageGroup,
    required this.accessibility,
    required this.audioPreferences,
    required this.levelContent,
    this.restoredState,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'childProfileId': childProfileId,
    'gameId': gameId,
    'levelId': levelId,
    'language': language,
    'ageGroup': ageGroup,
    'accessibility': accessibility.toJson(),
    'audioPreferences': audioPreferences.toJson(),
    'levelContent': levelContent,
    if (restoredState != null) 'restoredState': restoredState,
  };

  factory MiGameLaunchRequest.fromJson(Map<String, dynamic> json) =>
      MiGameLaunchRequest(
        schemaVersion: json['schemaVersion'] as int? ?? kGameContractVersion,
        childProfileId: json['childProfileId'] as String,
        gameId: json['gameId'] as String,
        levelId: json['levelId'] as String,
        language: json['language'] as String,
        ageGroup: json['ageGroup'] as String,
        accessibility: AccessibilityPreferences.fromJson(
          json['accessibility'] as Map<String, dynamic>? ?? {},
        ),
        audioPreferences: AudioPreferences.fromJson(
          json['audioPreferences'] as Map<String, dynamic>? ?? {},
        ),
        levelContent: json['levelContent'] as Map<String, dynamic>,
        restoredState: json['restoredState'] as Map<String, dynamic>?,
      );
}

/// Result sent from a game back to the platform after completion.
/// NEVER contains: access tokens, parent passwords, parent emails, PII.
class MiGameResult {
  final int schemaVersion;
  final String attemptId;
  final String childProfileId;
  final String gameId;
  final String levelId;
  final DateTime startedAt;
  final DateTime completedAt;
  final int attemptCount;
  final int correctCount;
  final int incorrectCount;
  final int hintCount;
  final int durationSeconds;
  final bool completed;
  final double masteryEvidence; // 0.0-1.0
  final Map<String, dynamic> skillEvidence;
  final Map<String, dynamic> metadata;

  const MiGameResult({
    this.schemaVersion = kGameContractVersion,
    required this.attemptId,
    required this.childProfileId,
    required this.gameId,
    required this.levelId,
    required this.startedAt,
    required this.completedAt,
    required this.attemptCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.hintCount,
    required this.durationSeconds,
    required this.completed,
    required this.masteryEvidence,
    required this.skillEvidence,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'attemptId': attemptId,
    'childProfileId': childProfileId,
    'gameId': gameId,
    'levelId': levelId,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'completedAt': completedAt.toUtc().toIso8601String(),
    'attemptCount': attemptCount,
    'correctCount': correctCount,
    'incorrectCount': incorrectCount,
    'hintCount': hintCount,
    'durationSeconds': durationSeconds,
    'completed': completed,
    'masteryEvidence': masteryEvidence,
    'skillEvidence': skillEvidence,
    'metadata': metadata,
  };

  factory MiGameResult.fromJson(Map<String, dynamic> json) =>
      MiGameResult(
        schemaVersion: json['schemaVersion'] as int? ?? kGameContractVersion,
        attemptId: json['attemptId'] as String,
        childProfileId: json['childProfileId'] as String,
        gameId: json['gameId'] as String,
        levelId: json['levelId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: DateTime.parse(json['completedAt'] as String),
        attemptCount: json['attemptCount'] as int,
        correctCount: json['correctCount'] as int,
        incorrectCount: json['incorrectCount'] as int,
        hintCount: json['hintCount'] as int,
        durationSeconds: json['durationSeconds'] as int,
        completed: json['completed'] as bool,
        masteryEvidence: (json['masteryEvidence'] as num).toDouble(),
        skillEvidence: json['skillEvidence'] as Map<String, dynamic>,
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      );
}

/// Snapshot of in-progress game state for save/resume.
/// NEVER contains: access tokens, parent passwords, parent emails, PII.
class MiGameSnapshot {
  final int schemaVersion;
  final String gameId;
  final String levelId;
  final String childProfileId;
  final DateTime savedAt;
  final Map<String, dynamic> state;

  const MiGameSnapshot({
    this.schemaVersion = kGameContractVersion,
    required this.gameId,
    required this.levelId,
    required this.childProfileId,
    required this.savedAt,
    required this.state,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'gameId': gameId,
    'levelId': levelId,
    'childProfileId': childProfileId,
    'savedAt': savedAt.toUtc().toIso8601String(),
    'state': state,
  };

  factory MiGameSnapshot.fromJson(Map<String, dynamic> json) =>
      MiGameSnapshot(
        schemaVersion: json['schemaVersion'] as int? ?? kGameContractVersion,
        gameId: json['gameId'] as String,
        levelId: json['levelId'] as String,
        childProfileId: json['childProfileId'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
        state: json['state'] as Map<String, dynamic>,
      );
}
