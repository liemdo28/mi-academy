import 'package:json_annotation/json_annotation.dart';

part 'learning_event.g.dart';

/// Learning event — a single tracked event during a child's session.
/// Contract ID: mi.analytics.event, schemaVersion: 1
@JsonSerializable()
class LearningEvent {
  static const int schemaVersion = 1;

  final String eventId;
  final String childProfileId;
  final String
  eventType; // game_start, game_complete, lesson_view, question_answer
  final String? gameId;
  final String? lessonId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> context;

  const LearningEvent({
    required this.eventId,
    required this.childProfileId,
    required this.eventType,
    this.gameId,
    this.lessonId,
    required this.timestamp,
    this.payload = const {},
    this.context = const {},
  });

  factory LearningEvent.fromJson(Map<String, dynamic> json) =>
      _$LearningEventFromJson(json);

  Map<String, dynamic> toJson() => _$LearningEventToJson(this);

  static const validEventTypes = [
    'game_start',
    'game_complete',
    'game_pause',
    'game_resume',
    'lesson_start',
    'lesson_complete',
    'question_answer',
    'hint_used',
    'skill_unlocked',
    'level_completed',
    'daily_summary',
  ];

  List<String> validate() {
    final errors = <String>[];
    if (eventId.isEmpty) errors.add('eventId is required');
    if (childProfileId.isEmpty) errors.add('childProfileId is required');
    if (!validEventTypes.contains(eventType)) {
      errors.add('Invalid eventType: $eventType');
    }
    return errors;
  }
}
