import 'package:json_annotation/json_annotation.dart';

part 'level.g.dart';

/// A game level within a lesson.
/// Contract: mi.content.level / v1
@JsonSerializable(explicitToJson: true)
class Level {
  final String id;
  final String lessonId;
  final String gameId;
  final String title;
  final String difficulty;
  final int orderIndex;
  final Map<String, dynamic> config;
  final List<String> prerequisiteLevelIds;
  final int requiredAccuracy;
  final String status;

  const Level({
    required this.id,
    required this.lessonId,
    required this.gameId,
    required this.title,
    required this.difficulty,
    required this.orderIndex,
    this.config = const {},
    this.prerequisiteLevelIds = const [],
    this.requiredAccuracy = 70,
    this.status = 'draft',
  });

  factory Level.fromJson(Map<String, dynamic> json) =>
      _$LevelFromJson(json);

  Map<String, dynamic> toJson() => _$LevelToJson(this);

  static const List<String> validDifficulties = ['easy', 'medium', 'hard', 'adaptive'];

  List<String> validate() {
    final errors = <String>[];
    if (id.isEmpty) errors.add('id is required');
    if (lessonId.isEmpty) errors.add('lessonId is required');
    if (!validDifficulties.contains(difficulty)) {
      errors.add('difficulty must be one of: ${validDifficulties.join(', ')}');
    }
    if (requiredAccuracy < 0 || requiredAccuracy > 100) {
      errors.add('requiredAccuracy must be between 0 and 100');
    }
    return errors;
  }

  Level copyWith({
    String? id, String? lessonId, String? gameId, String? title,
    String? difficulty, int? orderIndex, Map<String, dynamic>? config,
    List<String>? prerequisiteLevelIds, int? requiredAccuracy, String? status,
  }) {
    return Level(
      id: id ?? this.id, lessonId: lessonId ?? this.lessonId,
      gameId: gameId ?? this.gameId, title: title ?? this.title,
      difficulty: difficulty ?? this.difficulty,
      orderIndex: orderIndex ?? this.orderIndex,
      config: config ?? this.config,
      prerequisiteLevelIds: prerequisiteLevelIds ?? this.prerequisiteLevelIds,
      requiredAccuracy: requiredAccuracy ?? this.requiredAccuracy,
      status: status ?? this.status,
    );
  }
}
