import 'package:json_annotation/json_annotation.dart';

part 'skill.g.dart';

/// Skill model — a learnable competency area.
/// Contract ID: mi.content.skill, schemaVersion: 1
@JsonSerializable()
class Skill {
  static const int schemaVersion = 1;

  final String id;
  final String name;
  final String category; // math, language, science, logic, creativity
  final String description;
  final String ageGroup;
  final String language;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  const Skill({
    required this.id,
    required this.name,
    required this.category,
    this.description = '',
    this.ageGroup = 'junior',
    this.language = 'vi',
    this.tags = const [],
    this.metadata = const {},
  });

  factory Skill.fromJson(Map<String, dynamic> json) =>
      _$SkillFromJson(json);

  Map<String, dynamic> toJson() => _$SkillToJson(this);

  static const validCategories = [
    'math', 'language', 'science', 'logic', 'creativity'
  ];

  List<String> validate() {
    final errors = <String>[];
    if (id.isEmpty) errors.add('id is required');
    if (name.isEmpty) errors.add('name is required');
    if (!validCategories.contains(category)) {
      errors.add('category must be one of: ${validCategories.join(", ")}');
    }
    return errors;
  }
}
