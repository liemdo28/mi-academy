import 'dart:convert';
import 'package:mastery_core/mastery_core.dart';

/// Synthetic evaluation scenario loader.
class ScenarioLoader {
  ScenarioLoader({required this.rawJson});
  final String rawJson;

  List<EvaluationScenario> load() {
    final data = json.decode(rawJson) as Map<String, dynamic>;
    final list = data['scenarios'] as List;
    return list.map((s) =>
      EvaluationScenario.fromJson(s as Map<String, dynamic>)).toList();
  }
}

class EvaluationScenario {
  const EvaluationScenario({
    required this.id,
    required this.description,
    required this.tags,
    required this.input,
    required this.expectedOutput,
  });

  final String id;
  final String description;
  final List<String> tags;
  final ScenarioInput input;
  final ExpectedOutput expectedOutput;

  factory EvaluationScenario.fromJson(Map<String, dynamic> json) {
    return EvaluationScenario(
      id: json['id'] as String,
      description: json['description'] as String,
      tags: (json['tags'] as List).cast<String>(),
      input: ScenarioInput.fromJson(json['input'] as Map<String, dynamic>),
      expectedOutput: ExpectedOutput.fromJson(
          json['expectedOutput'] as Map<String, dynamic>),
    );
  }
}

class ScenarioInput {
  const ScenarioInput({
    required this.childId,
    required this.skillId,
    this.attempt,
  });

  final String childId;
  final String skillId;
  final Map<String, dynamic>? attempt;

  factory ScenarioInput.fromJson(Map<String, dynamic> json) {
    return ScenarioInput(
      childId: json['childId'] as String,
      skillId: json['skillId'] as String,
      attempt: json['attempt'] as Map<String, dynamic>?,
    );
  }
}

class ExpectedOutput {
  const ExpectedOutput({
    this.masteryScoreGt,
    this.masteryScoreLt,
    this.deltaMax,
    this.hintPenalty,
    this.difficultyBonus,
  });

  final double? masteryScoreGt;
  final double? masteryScoreLt;
  final double? deltaMax;
  final bool? hintPenalty;
  final bool? difficultyBonus;

  factory ExpectedOutput.fromJson(Map<String, dynamic> json) {
    return ExpectedOutput(
      masteryScoreGt: (json['masteryScoreGreaterThan'] as num?)?.toDouble(),
      masteryScoreLt: (json['masteryScoreLessThan'] as num?)?.toDouble(),
      deltaMax: (json['deltaLessThanOrEqual'] as num?)?.toDouble(),
      hintPenalty: json['hintPenaltyApplied'] as bool?,
      difficultyBonus: json['difficultyBonusApplied'] as bool?,
    );
  }

  bool validate(MasteryResult result) {
    if (masteryScoreGt != null &&
        result.updatedState.masteryScore <= masteryScoreGt!) return false;
    if (deltaMax != null && result.delta > deltaMax!) return false;
    if (hintPenalty == true &&
        !result.reasonCodes.contains('HINT_PENALTY_APPLIED')) return false;
    if (difficultyBonus == true &&
        !result.reasonCodes.contains('HIGH_DIFFICULTY')) return false;
    return true;
  }
}
