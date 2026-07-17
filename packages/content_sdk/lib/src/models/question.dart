import 'package:json_annotation/json_annotation.dart';

part 'question.g.dart';

/// Question model — assessment item within a lesson.
/// Contract ID: mi.content.question, schemaVersion: 1
@JsonSerializable()
class Question {
  static const int schemaVersion = 1;

  final String id;
  final String lessonId;
  final String type; // multiple_choice, true_false, fill_blank, matching
  final String text;
  final String? imageUrl;
  final String? audioUrl;
  final List<QuestionOption> options;
  final String correctAnswerId;
  final int difficulty;
  final String skillTag;

  const Question({
    required this.id,
    required this.lessonId,
    required this.type,
    required this.text,
    this.imageUrl,
    this.audioUrl,
    this.options = const [],
    this.correctAnswerId = '',
    this.difficulty = 1,
    this.skillTag = '',
  });

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionToJson(this);

  List<String> validate() {
    final errors = <String>[];
    if (id.isEmpty) errors.add('id is required');
    if (text.isEmpty) errors.add('text is required');
    if (correctAnswerId.isEmpty) errors.add('correctAnswerId is required');
    if (difficulty < 1 || difficulty > 5) {
      errors.add('difficulty must be 1-5');
    }
    return errors;
  }
}

@JsonSerializable()
class QuestionOption {
  final String id;
  final String text;
  final String? imageUrl;

  const QuestionOption({
    required this.id,
    required this.text,
    this.imageUrl,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) =>
      _$QuestionOptionFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionOptionToJson(this);
}
