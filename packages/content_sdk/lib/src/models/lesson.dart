import 'package:json_annotation/json_annotation.dart';

part 'lesson.g.dart';

/// A lesson in the curriculum.
/// Contract: mi.content.lesson / v1
@JsonSerializable(explicitToJson: true)
class Lesson {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String ageGroup;
  final int orderIndex;
  final List<String> skillIds;
  final List<String> levelIds;
  final Duration estimatedDuration;
  final String status;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.ageGroup,
    required this.orderIndex,
    this.skillIds = const [],
    this.levelIds = const [],
    this.estimatedDuration = Duration.zero,
    this.status = 'draft',
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) =>
      _$LessonFromJson(json);

  Map<String, dynamic> toJson() => _$LessonToJson(this);

  static const List<String> validSubjects = [
    'mathematics', 'language', 'science', 'social_studies', 'arts'
  ];
  static const List<String> validStatuses = ['draft', 'review', 'published', 'archived'];

  List<String> validate() {
    final errors = <String>[];
    if (id.isEmpty) errors.add('id is required');
    if (title.isEmpty) errors.add('title is required');
    if (!validSubjects.contains(subject)) {
      errors.add('subject must be one of: ${validSubjects.join(', ')}');
    }
    if (!validStatuses.contains(status)) {
      errors.add('status must be one of: ${validStatuses.join(', ')}');
    }
    if (orderIndex < 0) errors.add('orderIndex must be non-negative');
    return errors;
  }

  Lesson copyWith({
    String? id, String? title, String? description, String? subject,
    String? ageGroup, int? orderIndex, List<String>? skillIds,
    List<String>? levelIds, Duration? estimatedDuration, String? status,
    DateTime? publishedAt, DateTime? createdAt, DateTime? updatedAt,
  }) {
    return Lesson(
      id: id ?? this.id, title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject, ageGroup: ageGroup ?? this.ageGroup,
      orderIndex: orderIndex ?? this.orderIndex,
      skillIds: skillIds ?? this.skillIds, levelIds: levelIds ?? this.levelIds,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      status: status ?? this.status, publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
