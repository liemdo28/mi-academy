// Story Engine — typed content for branching-narrative activities.
//
// A story is a graph of nodes. Each node presents text and optionally an image
// or audio prompt. Choice nodes present 2+ options that lead to other nodes.
// Ending nodes conclude the story with a reflection prompt. The engine tracks
// the path taken, choices made, and which endings were reached.

import 'package:equatable/equatable.dart';

/// One node in the story graph.
class StoryNode extends Equatable {
  const StoryNode({
    required this.id,
    required this.text,
    required this.type,
    this.choices = const [],
    this.reflectionPrompt,
    this.endingTone,
  });

  factory StoryNode.fromJson(Map<String, dynamic> json) {
    final type = StoryNodeType.values.byName(json['type'] as String);
    final choices = <StoryChoice>[];
    if (type == StoryNodeType.choice) {
      final rawChoices = json['choices'];
      if (rawChoices is! List || rawChoices.length < 2) {
        throw StoryContentException(
          'Choice node "${json['id']}" must have at least 2 choices',
        );
      }
      for (final raw in rawChoices) {
        choices.add(StoryChoice.fromJson(raw as Map<String, dynamic>));
      }
    }
    return StoryNode(
      id: json['id'] as String,
      text: json['text'] as String,
      type: type,
      choices: List.unmodifiable(choices),
      reflectionPrompt: json['reflectionPrompt'] as String?,
      endingTone: json['endingTone'] as String?,
    );
  }

  final String id;
  final String text;
  final StoryNodeType type;
  final List<StoryChoice> choices;
  final String? reflectionPrompt;
  final String? endingTone;

  @override
  List<Object?> get props =>
      [id, text, type, choices, reflectionPrompt, endingTone];
}

enum StoryNodeType { narrative, choice, ending }

class StoryChoice extends Equatable {
  const StoryChoice({
    required this.id,
    required this.label,
    required this.targetNodeId,
  });

  factory StoryChoice.fromJson(Map<String, dynamic> json) {
    return StoryChoice(
      id: json['id'] as String,
      label: json['label'] as String,
      targetNodeId: json['targetNodeId'] as String,
    );
  }

  final String id;
  final String label;
  final String targetNodeId;

  @override
  List<Object?> get props => [id, label, targetNodeId];
}

class StoryContent extends Equatable {
  StoryContent({
    required this.contentId,
    required this.gameId,
    required this.locale,
    required this.ageBand,
    required this.difficulty,
    required this.title,
    required this.nodes,
    required this.startNodeId,
    this.hint,
    this.estimatedSeconds = 120,
  });

  final String contentId;
  final String gameId;
  final String locale;
  final String ageBand;
  final int difficulty;
  final String title;
  final String? hint;
  final int estimatedSeconds;

  final List<StoryNode> nodes;
  final String startNodeId;

  /// Map for fast node lookup by ID.
  late final Map<String, StoryNode> nodeMap = {
    for (final n in nodes) n.id: n,
  };

  factory StoryContent.fromJson(Map<String, dynamic> json) {
    final required = [
      'contentId',
      'gameId',
      'locale',
      'ageBand',
      'difficulty',
      'title',
      'nodes',
      'startNodeId',
    ];
    final missing = <String>[];
    for (final field in required) {
      if (!json.containsKey(field)) missing.add(field);
    }
    if (missing.isNotEmpty) {
      throw StoryContentException('Missing required field(s): $missing');
    }

    final difficulty = json['difficulty'];
    if (difficulty is! int || difficulty < 1 || difficulty > 5) {
      throw StoryContentException(
        'difficulty must be an integer 1-5, got $difficulty',
      );
    }

    final rawNodes = json['nodes'];
    if (rawNodes is! List || rawNodes.isEmpty) {
      throw StoryContentException('nodes must be a non-empty list');
    }
    final nodeIds = <String>{};
    final nodes = <StoryNode>[];
    for (final raw in rawNodes) {
      final node = StoryNode.fromJson(raw as Map<String, dynamic>);
      if (!nodeIds.add(node.id)) {
        throw StoryContentException('Duplicate node id: ${node.id}');
      }
      nodes.add(node);
    }

    final startNodeId = json['startNodeId'] as String;
    if (!nodeIds.contains(startNodeId)) {
      throw StoryContentException(
        'startNodeId "$startNodeId" not found in nodes',
      );
    }

    // Validate choice targets exist.
    for (final node in nodes) {
      for (final choice in node.choices) {
        if (!nodeIds.contains(choice.targetNodeId)) {
          throw StoryContentException(
            'Choice "${choice.id}" targets missing node "${choice.targetNodeId}"',
          );
        }
      }
    }

    return StoryContent(
      contentId: json['contentId'] as String,
      gameId: json['gameId'] as String,
      locale: json['locale'] as String,
      ageBand: json['ageBand'] as String,
      difficulty: difficulty,
      title: json['title'] as String,
      hint: json['hint'] as String?,
      nodes: List.unmodifiable(nodes),
      startNodeId: startNodeId,
      estimatedSeconds: json['estimatedSeconds'] as int? ?? 120,
    );
  }

  @override
  List<Object?> get props => [
        contentId,
        gameId,
        locale,
        ageBand,
        difficulty,
        title,
        hint,
        nodes,
        startNodeId,
        estimatedSeconds,
      ];
}

class StoryContentException implements Exception {
  StoryContentException(this.message);
  final String message;

  @override
  String toString() => 'StoryContentException: $message';
}
