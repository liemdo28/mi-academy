class ChildProfile {
  final String id;
  final String nickname;
  final int? birthYear;
  final String ageGroup; // junior | explorer | master
  final String? gradeLevel;
  final String avatarId;
  final String preferredLanguage;
  final int? dailyTimeLimit;
  final DateTime createdAt;

  ChildProfile({
    required this.id,
    required this.nickname,
    this.birthYear,
    required this.ageGroup,
    this.gradeLevel,
    this.avatarId = 'avatar_01',
    this.preferredLanguage = 'vi',
    this.dailyTimeLimit,
    required this.createdAt,
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
        id: json['id'] as String,
        nickname: json['nickname'] as String,
        birthYear: json['birth_year'] as int?,
        ageGroup: json['age_group'] as String,
        gradeLevel: json['grade_level'] as String?,
        avatarId: json['avatar_id'] as String? ?? 'avatar_01',
        preferredLanguage: json['preferred_language'] as String? ?? 'vi',
        dailyTimeLimit: json['daily_time_limit'] as int?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'birth_year': birthYear,
        'age_group': ageGroup,
        'grade_level': gradeLevel,
        'avatar_id': avatarId,
        'preferred_language': preferredLanguage,
        'daily_time_limit': dailyTimeLimit,
        'created_at': createdAt.toIso8601String(),
      };
}
