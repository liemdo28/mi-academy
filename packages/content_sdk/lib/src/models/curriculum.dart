import 'package:json_annotation/json_annotation.dart';
import 'lesson.dart';

part 'curriculum.g.dart';

/// A curriculum for an age group and subject.
/// Contract: mi.content.curriculum / v1
@JsonSerializable(explicitToJson: true)
class Curriculum {
  final String id;
  final String title;
  final String ageGroup;
  final String language;
  final List<String> subjectIds;
  final List<Lesson> lessons;
  final String version;
  final String status;
  final DateTime? effectiveDate;

  const Curriculum({
    required this.id,
    required this.title,
    required this.ageGroup,
    required this.language,
    this.subjectIds = const [],
    this.lessons = const [],
    this.version = '1.0.0',
    this.status = 'draft',
    this.effectiveDate,
  });

  factory Curriculum.fromJson(Map<String, dynamic> json) =>
      _$CurriculumFromJson(json);

  Map<String, dynamic> toJson() => _$CurriculumToJson(this);

  /// Total number of lessons in the curriculum.
  int get lessonCount => lessons.length;

  /// Get published lessons only.
  List<Lesson> get publishedLessons =>
      lessons.where((l) => l.status == 'published').toList();

  /// Get lessons for a specific subject.
  List<Lesson> lessonsForSubject(String subject) =>
      lessons.where((l) => l.subject == subject).toList();

  List<String> validate() {
    final errors = <String>[];
    if (id.isEmpty) errors.add('id is required');
    if (title.isEmpty) errors.add('title is required');
    for (var i = 0; i < lessons.length; i++) {
      errors.addAll(
        lessons[i].validate().map((e) => 'lessons[$i].$e'),
      );
    }
    return errors;
  }

  Curriculum copyWith({
    String? id, String? title, String? ageGroup, String? language,
    List<String>? subjectIds, List<Lesson>? lessons, String? version,
    String? status, DateTime? effectiveDate,
  }) {
    return Curriculum(
      id: id ?? this.id, title: title ?? this.title,
      ageGroup: ageGroup ?? this.ageGroup, language: language ?? this.language,
      subjectIds: subjectIds ?? this.subjectIds, lessons: lessons ?? this.lessons,
      version: version ?? this.version, status: status ?? this.status,
      effectiveDate: effectiveDate ?? this.effectiveDate,
    );
  }
}
