// Simulation Engine — typed content for science discovery activities.
//
// A simulation presents a state-based model where the child observes a scene,
// predicts an outcome, applies an action (manipulates a variable), and sees
// the result. The engine enforces cause-effect consistency: each action maps
// deterministically to a state transition, and the child must match the
// predicted outcome to the actual outcome to demonstrate understanding.

import 'package:equatable/equatable.dart';

/// A variable the child can manipulate in the simulation.
class SimVariable extends Equatable {
  const SimVariable({
    required this.id,
    required this.label,
    required this.values,
  });

  factory SimVariable.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'];
    if (rawValues is! List || rawValues.isEmpty) {
      throw SimulationContentException(
        'Variable "${json['id']}" must have at least one value',
      );
    }
    return SimVariable(
      id: json['id'] as String,
      label: json['label'] as String,
      values: rawValues.map((e) => e.toString()).toList(growable: false),
    );
  }

  final String id;
  final String label;
  final List<String> values;

  @override
  List<Object?> get props => [id, label, values];
}

/// One outcome the simulation can produce, with the conditions that trigger it.
class SimOutcome extends Equatable {
  const SimOutcome({
    required this.id,
    required this.label,
    required this.description,
    required this.conditions,
  });

  factory SimOutcome.fromJson(Map<String, dynamic> json) {
    final rawConditions = json['conditions'];
    if (rawConditions is! Map || rawConditions.isEmpty) {
      throw SimulationContentException(
        'Outcome "${json['id']}" must have at least one condition',
      );
    }
    return SimOutcome(
      id: json['id'] as String,
      label: json['label'] as String,
      description: json['description'] as String,
      conditions: Map<String, String>.from(rawConditions),
    );
  }

  final String id;
  final String label;
  final String description;

  /// Map of variableId -> required value for this outcome to trigger.
  final Map<String, String> conditions;

  /// Returns true if all conditions match the given current state.
  bool matches(Map<String, String> state) {
    for (final entry in conditions.entries) {
      if (state[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [id, label, description, conditions];
}

/// A prediction option the child can choose before running the simulation.
class SimPredictionChoice extends Equatable {
  const SimPredictionChoice({
    required this.id,
    required this.label,
    required this.isCorrect,
  });

  factory SimPredictionChoice.fromJson(Map<String, dynamic> json) {
    return SimPredictionChoice(
      id: json['id'] as String,
      label: json['label'] as String,
      isCorrect: json['isCorrect'] as bool,
    );
  }

  final String id;
  final String label;
  final bool isCorrect;

  @override
  List<Object?> get props => [id, label, isCorrect];
}

/// A step in the observe-predict-test-explain cycle.
enum SimPhase { observe, predict, test, explain, complete }

/// Typed content for one simulation activity.
class SimulationContent extends Equatable {
  const SimulationContent({
    required this.contentId,
    required this.gameId,
    required this.locale,
    required this.ageBand,
    required this.difficulty,
    required this.instruction,
    required this.observeDescription,
    required this.variables,
    required this.outcomes,
    required this.predictionChoices,
    required this.explanation,
    this.hint,
    this.estimatedSeconds = 90,
  });

  final String contentId;
  final String gameId;
  final String locale;
  final String ageBand;
  final int difficulty;
  final String instruction;
  final String? hint;
  final int estimatedSeconds;

  /// What the child sees at the start (the "observation" prompt).
  final String observeDescription;

  final List<SimVariable> variables;
  final List<SimOutcome> outcomes;
  final List<SimPredictionChoice> predictionChoices;

  /// The correct explanation shown after testing.
  final String explanation;

  factory SimulationContent.fromJson(Map<String, dynamic> json) {
    final required = [
      'contentId',
      'gameId',
      'locale',
      'ageBand',
      'difficulty',
      'instruction',
      'observeDescription',
      'variables',
      'outcomes',
      'predictionChoices',
      'explanation',
    ];
    final missing = <String>[];
    for (final field in required) {
      if (!json.containsKey(field)) missing.add(field);
    }
    if (missing.isNotEmpty) {
      throw SimulationContentException('Missing required field(s): $missing');
    }

    final difficulty = json['difficulty'];
    if (difficulty is! int || difficulty < 1 || difficulty > 5) {
      throw SimulationContentException(
        'difficulty must be an integer 1-5, got $difficulty',
      );
    }

    final rawVars = json['variables'];
    if (rawVars is! List || rawVars.isEmpty) {
      throw SimulationContentException('variables must be a non-empty list');
    }
    final variables = rawVars
        .map((e) => SimVariable.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    final rawOutcomes = json['outcomes'];
    if (rawOutcomes is! List || rawOutcomes.isEmpty) {
      throw SimulationContentException('outcomes must be a non-empty list');
    }
    final outcomeIds = <String>{};
    final outcomes = <SimOutcome>[];
    for (final raw in rawOutcomes) {
      final outcome = SimOutcome.fromJson(raw as Map<String, dynamic>);
      if (!outcomeIds.add(outcome.id)) {
        throw SimulationContentException(
          'Duplicate outcome id: ${outcome.id}',
        );
      }
      outcomes.add(outcome);
    }

    final rawChoices = json['predictionChoices'];
    if (rawChoices is! List || rawChoices.length < 2) {
      throw SimulationContentException(
        'predictionChoices must have at least 2 options',
      );
    }
    final choiceIds = <String>{};
    final choices = <SimPredictionChoice>[];
    var hasCorrect = false;
    for (final raw in rawChoices) {
      final choice = SimPredictionChoice.fromJson(raw as Map<String, dynamic>);
      if (!choiceIds.add(choice.id)) {
        throw SimulationContentException(
          'Duplicate prediction choice id: ${choice.id}',
        );
      }
      if (choice.isCorrect) hasCorrect = true;
      choices.add(choice);
    }
    if (!hasCorrect) {
      throw SimulationContentException(
        'At least one prediction choice must be correct',
      );
    }

    return SimulationContent(
      contentId: json['contentId'] as String,
      gameId: json['gameId'] as String,
      locale: json['locale'] as String,
      ageBand: json['ageBand'] as String,
      difficulty: difficulty,
      instruction: json['instruction'] as String,
      hint: json['hint'] as String?,
      observeDescription: json['observeDescription'] as String,
      variables: variables,
      outcomes: outcomes,
      predictionChoices: choices,
      explanation: json['explanation'] as String,
      estimatedSeconds: json['estimatedSeconds'] as int? ?? 90,
    );
  }

  @override
  List<Object?> get props => [
        contentId,
        gameId,
        locale,
        ageBand,
        difficulty,
        instruction,
        hint,
        observeDescription,
        variables,
        outcomes,
        predictionChoices,
        explanation,
        estimatedSeconds,
      ];
}

class SimulationContentException implements Exception {
  SimulationContentException(this.message);
  final String message;

  @override
  String toString() => 'SimulationContentException: $message';
}
