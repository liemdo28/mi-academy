import 'package:mi_game_core/mi_game_core.dart';

/// Session logic for Math Race – a timed quiz where the child picks the
/// correct answer from multiple-choice options. Speed bonuses reward fast
/// answers. Each level is JSON-driven with vi/en localization.
class MathRaceSession {
  MathRaceSession({
    required MiLevel level,
    this.childProfileId = 'offline-child',
  }) : _level = level {
    _resetForLevel(level);
  }

  final MiLevel _level;
  final String childProfileId;

  // ---- state ----
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _attemptsUsed = 0;
  int _hintsUsed = 0;
  int _correctInRow = 0;
  int _totalCorrect = 0;
  int _totalQuestions = 0;
  bool _completed = false;
  String? _feedback;
  String? _lastAnswer;

  // ---- parsed data ----
  late final List<_MathRaceQuestion> _questions;

  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  int get attemptsUsed => _attemptsUsed;
  int get hintsUsed => _hintsUsed;
  int get correctInRow => _correctInRow;
  int get totalCorrect => _totalCorrect;
  int get totalQuestions => _totalQuestions;
  bool get completed => _completed;
  String? get feedback => _feedback;
  String? get lastAnswer => _lastAnswer;

  List<_MathRaceQuestion> get questions =>
      List.unmodifiable(_questions);

  _MathRaceQuestion? get currentQuestion =>
      _currentQuestionIndex < _questions.length
          ? _questions[_currentQuestionIndex]
          : null;

  String get levelId => _level.id;

  void _resetForLevel(MiLevel level) {
    final content = level.contentForLocale('vi');
    final dynamic raw = content['questions'];
    if (raw is List) {
      _questions = raw
          .map((e) => _MathRaceQuestion.fromJson(Map<dynamic, dynamic>.from(e as Map)))
          .toList();
    } else {
      _questions = [];
    }
    _totalQuestions = _questions.length;
    _currentQuestionIndex = 0;
    _score = 0;
    _attemptsUsed = 0;
    _hintsUsed = 0;
    _correctInRow = 0;
    _totalCorrect = 0;
    _completed = false;
    _feedback = null;
    _lastAnswer = null;
  }

  /// Returns the question text for the current locale.
  String? questionText(String locale) {
    final q = currentQuestion;
    if (q == null) return null;
    final content = _level.contentForLocale(locale);
    final questions = content['questions'] as List?;
    if (questions == null || _currentQuestionIndex >= questions.length) return null;
    final qMap = questions[_currentQuestionIndex] as Map;
    return qMap['question'] as String?;
  }

  /// Child picks an option index.
  void choose(int optionIndex) {
    final q = currentQuestion;
    if (q == null || _completed) return;

    _attemptsUsed++;
    final selected = q.options[optionIndex];
    _lastAnswer = selected.text;

    if (selected.correct) {
      _totalCorrect++;
      _correctInRow++;
      // Speed bonus: more correct-in-row = higher bonus
      final bonus = _correctInRow >= 3 ? 2 : 1;
      _score += 10 * bonus;
      _feedback = _correctInRow >= 3 ? 'great_streak' : 'correct';
      _advance();
    } else {
      _correctInRow = 0;
      _attemptsUsed++; // penalty attempt
      _feedback = 'try_again';
    }
  }

  void showHint() {
    _hintsUsed++;
    final q = currentQuestion;
    if (q == null) return;
    // Highlight one incorrect option to eliminate it.
    _feedback = 'hint_eliminate';
  }

  void _advance() {
    _currentQuestionIndex++;
    if (_currentQuestionIndex >= _questions.length) {
      _completed = true;
    }
  }

  /// Snapshot for save/restore.
  MiGameSnapshot saveSnapshot() {
    return MiGameSnapshot(
      gameId: 'math_race',
      levelId: _level.id,
      state: {
        'currentQuestionIndex': _currentQuestionIndex,
        'score': _score,
        'attemptsUsed': _attemptsUsed,
        'hintsUsed': _hintsUsed,
        'correctInRow': _correctInRow,
        'totalCorrect': _totalCorrect,
        'completed': _completed,
      },
      score: _score,
      attemptsUsed: _attemptsUsed,
      hintsUsed: _hintsUsed,
    );
  }

  void restoreSnapshot(MiGameSnapshot snapshot) {
    final s = snapshot.state;
    _currentQuestionIndex = s['currentQuestionIndex'] as int? ?? 0;
    _score = s['score'] as int? ?? 0;
    _attemptsUsed = s['attemptsUsed'] as int? ?? 0;
    _hintsUsed = s['hintsUsed'] as int? ?? 0;
    _correctInRow = s['correctInRow'] as int? ?? 0;
    _totalCorrect = s['totalCorrect'] as int? ?? 0;
    _completed = s['completed'] as bool? ?? false;
  }
}

class _MathRaceQuestion {
  _MathRaceQuestion({
    required this.question,
    required this.options,
  });

  final String question;
  final List<_MathRaceOption> options;

  factory _MathRaceQuestion.fromJson(Map<dynamic, dynamic> json) {
    return _MathRaceQuestion(
      question: json['question'] as String? ?? '',
      options: (json['options'] as List?)
              ?.map((e) => _MathRaceOption.fromJson(Map<dynamic, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );
  }
}

class _MathRaceOption {
  const _MathRaceOption({
    required this.text,
    required this.correct,
  });

  final String text;
  final bool correct;

  factory _MathRaceOption.fromJson(Map<dynamic, dynamic> json) {
    return _MathRaceOption(
      text: json['text'] as String? ?? '',
      correct: json['correct'] as bool? ?? false,
    );
  }
}
