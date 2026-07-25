import 'package:mi_game_core/mi_game_core.dart';

import '../game_locale_text.dart';

enum FreeCreativityStatus {
  composing,
  needsScene,
  needsCharacter,
  needsFeeling,
  needsStory,
  complete,
}

class FreeCreativitySession {
  FreeCreativitySession({
    required MiLevel level,
    this.childProfileId = 'offline-child',
    this.locale = 'vi',
  }) : _level = level {
    _resetForLevel(level);
  }

  MiLevel _level;
  final String childProfileId;
  final String locale;
  late List<String> _storyCards;
  late List<String> _labels;
  String? _scene;
  String? _character;
  String? _feeling;
  String _storyText = '';
  int _hintsUsed = 0;
  FreeCreativityStatus _status = FreeCreativityStatus.composing;
  String? _feedback;

  MiLevel get level => _level;
  Map<String, dynamic> get content => _level.contentForLocale(locale);
  List<String> get storyCards => List.unmodifiable(_storyCards);
  List<String> get labels => List.unmodifiable(_labels);
  String? get scene => _scene;
  String? get character => _character;
  String? get feeling => _feeling;
  String get storyText => _storyText;
  int get hintsUsed => _hintsUsed;
  FreeCreativityStatus get status => _status;
  String? get feedback => _feedback;
  GameLocaleText get _text => GameLocaleText(locale);

  bool get canComplete =>
      _scene != null &&
      _character != null &&
      _feeling != null &&
      _storyText.trim().isNotEmpty;

  void loadLevel(MiLevel level) {
    _level = level;
    _resetForLevel(level);
  }

  void selectScene(String value) {
    _scene = value;
    _clearPrompt();
  }

  void selectCharacter(String value) {
    _character = value;
    _clearPrompt();
  }

  void selectFeeling(String value) {
    _feeling = value;
    _clearPrompt();
  }

  void updateStoryText(String value) {
    _storyText = value;
    _clearPrompt();
  }

  void clearStoryText() {
    _storyText = '';
    _clearPrompt();
  }

  bool complete() {
    _status = _validateParticipation();
    _feedback = _messageFor(_status);
    return _status == FreeCreativityStatus.complete;
  }

  void showHint() {
    final hints = _level.hints;
    if (hints.isEmpty) {
      _feedback = _text.creativityStoryHint;
      return;
    }
    final hintIndex =
        _hintsUsed >= hints.length ? hints.length - 1 : _hintsUsed;
    _feedback = _text.hintFrom(hints[hintIndex], hintIndex);
    _hintsUsed = (_hintsUsed + 1).clamp(0, hints.length);
  }

  MiGameSnapshot saveSnapshot({DateTime? now}) {
    return MiGameSnapshot(
      gameId: _level.gameId,
      levelId: _level.id,
      childProfileId: childProfileId,
      state: {
        'scene': _scene,
        'character': _character,
        'feeling': _feeling,
        'storyText': _storyText,
        'feedback': _feedback,
        'status': _status.name,
      },
      createdAt: now ?? DateTime.now().toUtc(),
      score: 100,
      attemptsUsed: 1,
      hintsUsed: _hintsUsed,
      itemsCompleted: [_scene, _character, _feeling, _storyText.trim()]
          .where((value) => value != null && value.toString().isNotEmpty)
          .length,
      totalItems: 4,
      metadata: const {
        'snapshotKind': 'free_creativity_session',
        'completionModel': 'participation',
      },
    );
  }

  void restoreSnapshot(MiGameSnapshot snapshot) {
    if (snapshot.gameId != _level.gameId || snapshot.levelId != _level.id) {
      throw ArgumentError(
        'Snapshot does not belong to this Free Creativity level.',
      );
    }
    final state = snapshot.state;
    _scene = state['scene'] as String?;
    _character = state['character'] as String?;
    _feeling = state['feeling'] as String?;
    _storyText = state['storyText'] as String? ?? '';
    _feedback = state['feedback'] as String?;
    _status = FreeCreativityStatus.values.firstWhere(
      (status) => status.name == state['status'],
      orElse: () => FreeCreativityStatus.composing,
    );
    _hintsUsed = snapshot.hintsUsed;
  }

  FreeCreativityStatus _validateParticipation() {
    if (_scene == null) return FreeCreativityStatus.needsScene;
    if (_character == null) return FreeCreativityStatus.needsCharacter;
    if (_feeling == null) return FreeCreativityStatus.needsFeeling;
    if (_storyText.trim().isEmpty) return FreeCreativityStatus.needsStory;
    return FreeCreativityStatus.complete;
  }

  String _messageFor(FreeCreativityStatus status) {
    return switch (status) {
      FreeCreativityStatus.complete => _text.creativityDone,
      FreeCreativityStatus.needsScene => _text.creativityNeedsScene,
      FreeCreativityStatus.needsCharacter => _text.creativityNeedsCharacter,
      FreeCreativityStatus.needsFeeling => _text.creativityNeedsFeeling,
      FreeCreativityStatus.needsStory => _text.creativityNeedsStory,
      FreeCreativityStatus.composing => _text.creativitySupportiveFeedback,
    };
  }

  void _clearPrompt() {
    _status = FreeCreativityStatus.composing;
    _feedback = null;
  }

  void _resetForLevel(MiLevel level) {
    final deepData = _asMap(level.contentForLocale(locale)['deepData']);
    _storyCards = _asStringList(deepData['storyCards']);
    if (_storyCards.isEmpty) {
      _storyCards =
          (level.contentForLocale(locale)['options'] as List? ?? const [])
              .whereType<Map>()
              .map((option) => option['text'].toString())
              .toList(growable: false);
    }
    _labels = _asStringList(deepData['storyLabels']);
    _scene = null;
    _character = null;
    _feeling = null;
    _storyText = '';
    _hintsUsed = 0;
    _status = FreeCreativityStatus.composing;
    _feedback = _text.creativitySupportiveFeedback;
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static List<String> _asStringList(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }
}
