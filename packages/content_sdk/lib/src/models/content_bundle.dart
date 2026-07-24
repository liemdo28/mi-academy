import 'package:json_annotation/json_annotation.dart';
import 'lesson.dart';
import 'question.dart';
import 'level.dart';
import 'skill.dart';

part 'content_bundle.g.dart';

/// Content bundle — a packaged set of content for a skill/skill area.
/// Contract ID: mi.content.bundle, schemaVersion: 1
@JsonSerializable()
class ContentBundle {
  static const int schemaVersion = 1;

  final String id;
  final String title;
  final String description;
  final String ageGroup;
  final String language;
  final String version;
  final List<Lesson> lessons;
  final List<Question> questions;
  final List<Level> levels;
  final List<Skill> skills;

  const ContentBundle({
    required this.id,
    required this.title,
    this.description = '',
    this.ageGroup = 'junior',
    this.language = 'vi',
    this.version = '1.0.0',
    this.lessons = const [],
    this.questions = const [],
    this.levels = const [],
    this.skills = const [],
  });

  factory ContentBundle.fromJson(Map<String, dynamic> json) =>
      _$ContentBundleFromJson(json);

  Map<String, dynamic> toJson() => _$ContentBundleToJson(this);

  /// Validate all content in the bundle.
  List<String> validate() {
    final errors = <String>[];
    if (id.isEmpty) errors.add('id is required');
    for (final lesson in lessons) {
      errors.addAll(lesson.validate().map((e) => 'Lesson ${lesson.id}: $e'));
    }
    for (final question in questions) {
      errors.addAll(
        question.validate().map((e) => 'Question ${question.id}: $e'),
      );
    }
    for (final level in levels) {
      errors.addAll(level.validate().map((e) => 'Level ${level.id}: $e'));
    }
    for (final skill in skills) {
      errors.addAll(skill.validate().map((e) => 'Skill ${skill.id}: $e'));
    }
    return errors;
  }

  /// Get total content counts.
  Map<String, int> get stats => {
    'lessons': lessons.length,
    'questions': questions.length,
    'levels': levels.length,
    'skills': skills.length,
  };
}
