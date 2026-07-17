import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'analytics_event.g.dart';

/// Core analytics event tracked across the MI Academy platform.
///
/// Every user interaction (game play, content view, assessment) produces
/// an [AnalyticsEvent] that flows through the analytics pipeline.
@JsonSerializable(explicitToJson: true)
class AnalyticsEvent {
  final String eventId;
  final String eventType;
  final String childProfileId;
  final String sessionId;
  final String? parentId;
  final Map<String, dynamic> properties;
  final Map<String, dynamic>? context;
  final DateTime timestamp;
  final String? source;
  final String schemaVersion;

  static const String currentSchemaVersion = '1.0.0';
  static const _uuid = Uuid();

  /// Valid event types recognized by the analytics pipeline.
  static const validEventTypes = [
    'game_started',
    'game_completed',
    'game_abandoned',
    'lesson_viewed',
    'lesson_completed',
    'assessment_started',
    'assessment_completed',
    'skill_mastered',
    'difficulty_changed',
    'content_searched',
    'session_started',
    'session_ended',
    'achievement_unlocked',
    'streak_updated',
    'parent_dashboard_viewed',
  ];

  AnalyticsEvent({
    String? eventId,
    required this.eventType,
    required this.childProfileId,
    required this.sessionId,
    this.parentId,
    this.properties = const {},
    this.context,
    DateTime? timestamp,
    this.source,
    this.schemaVersion = currentSchemaVersion,
  })  : eventId = eventId ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsEventFromJson(json);
  Map<String, dynamic> toJson() => _$AnalyticsEventToJson(this);

  /// Validates the event before submission.
  ///
  /// Returns a list of validation errors. Empty list means valid.
  List<String> validate() {
    final errors = <String>[];
    if (eventId.isEmpty) errors.add('eventId must not be empty');
    if (!validEventTypes.contains(eventType)) {
      errors.add('Invalid eventType: $eventType. Must be one of: ${validEventTypes.join(', ')}');
    }
    if (childProfileId.isEmpty) errors.add('childProfileId must not be empty');
    if (sessionId.isEmpty) errors.add('sessionId must not be empty');
    if (schemaVersion.isEmpty) errors.add('schemaVersion must not be empty');

    // Check forbidden fields (PII)
    final allKeys = {...properties.keys, ...(context?.keys ?? {})};
    const forbidden = {'password', 'token', 'secret', 'ssn', 'credit_card', 'email'};
    for (final key in allKeys) {
      if (forbidden.contains(key.toLowerCase())) {
        errors.add('Forbidden field in event properties: $key');
      }
    }
    return errors;
  }

  /// Creates a child event linked to this parent event.
  AnalyticsEvent createChild({
    required String eventType,
    Map<String, dynamic> properties = const {},
  }) {
    return AnalyticsEvent(
      eventType: eventType,
      childProfileId: childProfileId,
      sessionId: sessionId,
      parentId: eventId,
      properties: properties,
      source: source,
      context: context,
    );
  }

  /// Whether this event is a terminal/completion event.
  bool get isTerminal =>
      eventType.endsWith('_completed') || eventType == 'session_ended';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsEvent &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId;

  @override
  int get hashCode => eventId.hashCode;
}
