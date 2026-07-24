import 'package:json_annotation/json_annotation.dart';

part 'personalization_profile.g.dart';

/// Personalization profile capturing a child's learning preferences
/// and behavioral patterns for adaptive content delivery.
@JsonSerializable(explicitToJson: true)
class PersonalizationProfile {
  final String childProfileId;
  final String ageGroup; // junior, mid, senior
  final Map<String, double> subjectAffinity; // subject -> affinity score 0-1
  final String preferredDifficulty; // easy, medium, hard, adaptive
  final int preferredSessionLengthMinutes;
  final String preferredLearningStyle; // visual, auditory, kinesthetic, reading
  final Map<String, dynamic>? behavioralPatterns;
  final DateTime updatedAt;
  final String schemaVersion;

  static const String currentSchemaVersion = '1.0.0';
  static const validAgeGroups = ['junior', 'mid', 'senior'];
  static const validDifficulties = ['easy', 'medium', 'hard', 'adaptive'];
  static const validLearningStyles = [
    'visual',
    'auditory',
    'kinesthetic',
    'reading',
  ];

  PersonalizationProfile({
    required this.childProfileId,
    required this.ageGroup,
    this.subjectAffinity = const {},
    this.preferredDifficulty = 'adaptive',
    this.preferredSessionLengthMinutes = 15,
    this.preferredLearningStyle = 'visual',
    this.behavioralPatterns,
    DateTime? updatedAt,
    this.schemaVersion = currentSchemaVersion,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory PersonalizationProfile.fromJson(Map<String, dynamic> json) =>
      _$PersonalizationProfileFromJson(json);
  Map<String, dynamic> toJson() => _$PersonalizationProfileToJson(this);

  /// Top 3 subjects by affinity score.
  List<MapEntry<String, double>> get topSubjects {
    final sorted = subjectAffinity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).toList();
  }

  /// Weakest subject (lowest affinity).
  String? get weakestSubject {
    if (subjectAffinity.isEmpty) return null;
    final sorted = subjectAffinity.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted.first.key;
  }

  /// Recommended session length based on age group and past behavior.
  int get recommendedSessionLength {
    switch (ageGroup) {
      case 'junior':
        return 10;
      case 'mid':
        return 15;
      case 'senior':
        return 20;
      default:
        return 15;
    }
  }

  /// Whether the profile has enough data to make recommendations.
  bool get hasSufficientData => subjectAffinity.isNotEmpty;

  /// Merge incoming behavioral signals into the profile.
  PersonalizationProfile mergeSignals({
    Map<String, double>? subjectScores,
    int? sessionLength,
    String? learningStyle,
  }) {
    final newAffinity = Map<String, double>.from(subjectAffinity);
    if (subjectScores != null) {
      for (final entry in subjectScores.entries) {
        final existing = newAffinity[entry.key] ?? 0.5;
        newAffinity[entry.key] = (existing * 0.7 + entry.value * 0.3).clamp(
          0.0,
          1.0,
        );
      }
    }

    return PersonalizationProfile(
      childProfileId: childProfileId,
      ageGroup: ageGroup,
      subjectAffinity: newAffinity,
      preferredDifficulty: preferredDifficulty,
      preferredSessionLengthMinutes:
          sessionLength ?? preferredSessionLengthMinutes,
      preferredLearningStyle: learningStyle ?? preferredLearningStyle,
      behavioralPatterns: behavioralPatterns,
      updatedAt: DateTime.now(),
    );
  }

  List<String> validate() {
    final errors = <String>[];
    if (childProfileId.isEmpty) errors.add('childProfileId required');
    if (!validAgeGroups.contains(ageGroup)) {
      errors.add('Invalid ageGroup: $ageGroup');
    }
    if (!validDifficulties.contains(preferredDifficulty)) {
      errors.add('Invalid preferredDifficulty');
    }
    if (!validLearningStyles.contains(preferredLearningStyle)) {
      errors.add('Invalid preferredLearningStyle');
    }
    return errors;
  }
}
