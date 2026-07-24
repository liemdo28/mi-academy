// Simulation Engine — controller for observe-predict-test-explain cycle.
//
// Manages the simulation state machine: the child first observes the scene,
// then makes a prediction, then sets variable values and runs the simulation
// to see the actual outcome, and finally reads the explanation. The controller
// tracks prediction accuracy and supports hints, pause/resume, and retry.

import 'package:flutter/foundation.dart';

import 'simulation_content.dart';

/// Result of running the simulation (the "test" phase).
class SimRunResult {
  const SimRunResult({
    required this.outcome,
    required this.state,
    required this.predictionWasCorrect,
  });

  final SimOutcome? outcome;
  final Map<String, String> state;
  final bool predictionWasCorrect;
}

/// Drives one simulation activity through observe → predict → test → explain.
class SimulationController extends ChangeNotifier {
  static const String engineId = 'simulation';

  SimulationController({
    required SimulationContent content,
    this.reducedMotion = false,
    this.soundEnabled = true,
  }) : _content = content {
    _state = {for (final v in content.variables) v.id: v.values.first};
  }

  final SimulationContent _content;
  SimulationContent get content => _content;

  final bool reducedMotion;
  final bool soundEnabled;

  SimPhase _phase = SimPhase.observe;
  SimPhase get phase => _phase;

  Map<String, String> _state = {};
  Map<String, String> get state => Map.unmodifiable(_state);

  String? _selectedPredictionId;
  String? get selectedPredictionId => _selectedPredictionId;

  SimRunResult? _lastRunResult;
  SimRunResult? get lastRunResult => _lastRunResult;

  int _attempts = 0;
  int get attempts => _attempts;

  bool _predictionCorrect = false;
  bool get predictionCorrect => _predictionCorrect;

  bool _showHint = false;
  bool get showHint => _showHint;

  bool _paused = false;
  bool get isPaused => _paused;

  bool get isComplete => _phase == SimPhase.complete;

  /// Stars: 3 if prediction correct on first try, 2 if on second, 1 otherwise.
  int get starsEarned {
    if (!isComplete) return 0;
    if (_attempts <= 1 && _predictionCorrect) return 3;
    if (_attempts <= 2 && _predictionCorrect) return 2;
    return 1;
  }

  /// Advance from observe to predict phase.
  void startPrediction() {
    if (_phase != SimPhase.observe) return;
    _phase = SimPhase.predict;
    notifyListeners();
  }

  /// Select a prediction choice.
  void selectPrediction(String choiceId) {
    if (_phase != SimPhase.predict) return;
    _selectedPredictionId = choiceId;
    notifyListeners();
  }

  /// Confirm prediction and advance to test phase.
  void confirmPrediction() {
    if (_phase != SimPhase.predict || _selectedPredictionId == null) return;
    _phase = SimPhase.test;
    notifyListeners();
  }

  /// Change a variable value during the test phase.
  void setVariable(String variableId, String value) {
    if (_phase != SimPhase.test) return;
    _state[variableId] = value;
    notifyListeners();
  }

  /// Run the simulation: determine outcome and check prediction.
  SimRunResult runSimulation() {
    if (_phase != SimPhase.test) {
      return _lastRunResult ??
          SimRunResult(
            outcome: null,
            state: Map.of(_state),
            predictionWasCorrect: false,
          );
    }

    _attempts++;

    // Find the matching outcome.
    SimOutcome? matchedOutcome;
    for (final outcome in _content.outcomes) {
      if (outcome.matches(_state)) {
        matchedOutcome = outcome;
        break;
      }
    }

    // Check if prediction was correct.
    final selectedChoice = _content.predictionChoices
        .where((c) => c.id == _selectedPredictionId)
        .firstOrNull;
    final predictionWasCorrect = selectedChoice?.isCorrect ?? false;
    _predictionCorrect = predictionWasCorrect;

    _lastRunResult = SimRunResult(
      outcome: matchedOutcome,
      state: Map.of(_state),
      predictionWasCorrect: predictionWasCorrect,
    );

    _phase = SimPhase.explain;
    notifyListeners();

    return _lastRunResult!;
  }

  /// Advance from explain to complete.
  void finishExplanation() {
    if (_phase != SimPhase.explain) return;
    _phase = SimPhase.complete;
    notifyListeners();
  }

  void requestHint() {
    _showHint = true;
    notifyListeners();
  }

  void dismissHint() {
    _showHint = false;
    notifyListeners();
  }

  void pause() {
    _paused = true;
    notifyListeners();
  }

  void resume() {
    _paused = false;
    notifyListeners();
  }

  void retry() {
    _phase = SimPhase.observe;
    _state = {for (final v in _content.variables) v.id: v.values.first};
    _selectedPredictionId = null;
    _lastRunResult = null;
    _attempts = 0;
    _predictionCorrect = false;
    _showHint = false;
    _paused = false;
    notifyListeners();
  }

  void loadContent(SimulationContent content) {
    _state = {for (final v in content.variables) v.id: v.values.first};
    retry();
  }
}
