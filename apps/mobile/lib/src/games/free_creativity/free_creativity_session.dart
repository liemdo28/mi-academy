import 'package:mi_game_core/mi_game_core.dart';

import '../game_locale_text.dart';
import 'creative_artifact_store.dart';

enum CreativeFeedbackState {
  composing,
  needsScene,
  needsCharacter,
  needsFeeling,
  needsStory,
  shared,
}

class CreativeChoice {
  const CreativeChoice({
    required this.id,
    required this.label,
    this.assetRef,
  });

  final String id;
  final String label;
  final String? assetRef;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        if (assetRef != null) 'assetRef': assetRef,
      };
}

class CreativeCompletion {
  const CreativeCompletion({required this.artifact});

  final CreativeArtifact artifact;
}

class FreeCreativitySession {
  FreeCreativitySession({
    required MiLevel level,
    required this.childProfileId,
    this.locale = 'vi',
  }) : _level = level {
    _resetForLevel(level);
  }

  MiLevel _level;
  final String childProfileId;
  final String locale;
  late List<CreativeChoice> _scenes;
  late List<CreativeChoice> _characters;
  late List<CreativeChoice> _feelings;
  late List<CreativeChoice> _storyStarters;
  late List<String> _labels;
  late int _minimumStoryLength;
  late int _maximumStoryLength;
  String? _sceneId;
  String? _characterId;
  String? _feelingId;
  String? _storyStarterId;
  String _storyText = '';
  int _hintsUsed = 0;
  CreativeFeedbackState _feedbackState = CreativeFeedbackState.composing;
  String? _feedback;
  CreativeArtifact? _artifact;

  MiLevel get level => _level;
  Map<String, dynamic> get content => _level.contentForLocale(locale);
  List<CreativeChoice> get scenes => List.unmodifiable(_scenes);
  List<CreativeChoice> get characters => List.unmodifiable(_characters);
  List<CreativeChoice> get feelings => List.unmodifiable(_feelings);
  List<CreativeChoice> get storyStarters => List.unmodifiable(_storyStarters);
  List<String> get labels => List.unmodifiable(_labels);
  int get minimumStoryLength => _minimumStoryLength;
  int get maximumStoryLength => _maximumStoryLength;
  String? get sceneId => _sceneId;
  String? get characterId => _characterId;
  String? get feelingId => _feelingId;
  String? get storyStarterId => _storyStarterId;
  String? get scene => _labelFor(_scenes, _sceneId);
  String? get character => _labelFor(_characters, _characterId);
  String? get feeling => _labelFor(_feelings, _feelingId);
  String get storyText => _storyText;
  int get hintsUsed => _hintsUsed;
  CreativeFeedbackState get feedbackState => _feedbackState;
  CreativeFeedbackState get status => _feedbackState;
  String? get feedback => _feedback;
  CreativeArtifact? get artifact => _artifact;
  GameLocaleText get _text => GameLocaleText(locale);

  bool get canComplete =>
      _sceneId != null &&
      _characterId != null &&
      _feelingId != null &&
      _normalizedStoryText.length >= _minimumStoryLength;

  void loadLevel(MiLevel level) {
    _level = level;
    _resetForLevel(level);
  }

  void selectScene(String value) {
    _sceneId = _resolveChoiceId(_scenes, value);
    _storyStarterId ??= _storyStarters.isEmpty ? null : _storyStarters.first.id;
    _clearPrompt();
  }

  void selectCharacter(String value) {
    _characterId = _resolveChoiceId(_characters, value);
    _clearPrompt();
  }

  void selectFeeling(String value) {
    _feelingId = _resolveChoiceId(_feelings, value);
    _clearPrompt();
  }

  void updateStoryText(String value) {
    final trimmedRight = value.replaceFirst(RegExp(r'\s+$'), '');
    _storyText = trimmedRight.length <= _maximumStoryLength
        ? trimmedRight
        : String.fromCharCodes(trimmedRight.runes.take(_maximumStoryLength));
    _clearPrompt();
  }

  void clearStoryText() {
    _storyText = '';
    _clearPrompt();
  }

  CreativeCompletion? complete({DateTime? now}) {
    _feedbackState = _validateParticipation();
    _feedback = _messageFor(_feedbackState);
    if (_feedbackState != CreativeFeedbackState.shared) return null;

    final timestamp = (now ?? DateTime.now()).toUtc();
    final normalizedStory = _normalizedStoryText;
    final existing = _artifact;
    final artifactId = existing?.artifactId ??
        'creative-$childProfileId-${_level.id}-${timestamp.microsecondsSinceEpoch}';
    _artifact = CreativeArtifact(
      artifactId: artifactId,
      childProfileId: childProfileId,
      gameId: _level.gameId,
      levelId: _level.id,
      sceneId: _sceneId!,
      sceneLabel: scene!,
      characterId: _characterId!,
      characterLabel: character!,
      feelingId: _feelingId!,
      feelingLabel: feeling!,
      storyText: normalizedStory,
      locale: locale,
      createdAt: existing?.createdAt ?? timestamp,
      updatedAt: timestamp,
      contentVersion: _level.contentVersion,
      storyStarterId: _storyStarterId,
      assetReferences: _assetReferences,
      revision: existing == null ? 1 : existing.revision + 1,
    );
    return CreativeCompletion(artifact: _artifact!);
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
        'sceneId': _sceneId,
        'characterId': _characterId,
        'feelingId': _feelingId,
        'storyStarterId': _storyStarterId,
        'storyText': _storyText,
        'feedback': _feedback,
        'feedbackState': _feedbackState.name,
        if (_artifact != null) 'artifactId': _artifact!.artifactId,
        'contentVersion': _level.contentVersion,
      },
      createdAt: now ?? DateTime.now().toUtc(),
      score: 0,
      attemptsUsed: 1,
      hintsUsed: _hintsUsed,
      itemsCompleted: [_sceneId, _characterId, _feelingId, _normalizedStoryText]
          .where((value) => value != null && value.toString().isNotEmpty)
          .length,
      totalItems: 4,
      metadata: const {
        'snapshotKind': 'free_creativity_session',
        'engine': 'creative_story_lab',
        'completionModel': 'participation',
        'assessmentModel': 'ungraded',
      },
    );
  }

  void restoreSnapshot(MiGameSnapshot snapshot) {
    if (!snapshot.canRestoreFor(
      childProfileId: childProfileId,
      gameId: _level.gameId,
      levelId: _level.id,
    )) {
      throw ArgumentError(
        'Snapshot does not belong to this Free Creativity session.',
      );
    }
    final state = snapshot.state;
    final restoredVersion = _asNullableInt(state['contentVersion']);
    if (restoredVersion != null && restoredVersion > _level.contentVersion) {
      throw ArgumentError('Snapshot was created with a newer content version.');
    }

    _sceneId = _restoreChoiceId(_scenes, state['sceneId'], state['scene']);
    _characterId =
        _restoreChoiceId(_characters, state['characterId'], state['character']);
    _feelingId =
        _restoreChoiceId(_feelings, state['feelingId'], state['feeling']);
    _storyStarterId =
        _restoreChoiceId(_storyStarters, state['storyStarterId'], null);
    _storyText = String.fromCharCodes(
      (state['storyText']?.toString() ?? '').runes.take(_maximumStoryLength),
    );
    _feedback =
        state['feedback'] is String ? state['feedback'] as String : null;
    _feedbackState = CreativeFeedbackState.values.firstWhere(
      (stateValue) =>
          stateValue.name ==
          (state['feedbackState'] ?? state['status'] ?? '').toString(),
      orElse: () => CreativeFeedbackState.composing,
    );
    if (_feedbackState == CreativeFeedbackState.shared) {
      _feedbackState = CreativeFeedbackState.composing;
    }
    _hintsUsed = snapshot.hintsUsed.clamp(0, _level.hints.length);
  }

  CreativeFeedbackState _validateParticipation() {
    if (_sceneId == null) return CreativeFeedbackState.needsScene;
    if (_characterId == null) return CreativeFeedbackState.needsCharacter;
    if (_feelingId == null) return CreativeFeedbackState.needsFeeling;
    if (_normalizedStoryText.length < _minimumStoryLength) {
      return CreativeFeedbackState.needsStory;
    }
    return CreativeFeedbackState.shared;
  }

  String _messageFor(CreativeFeedbackState state) {
    return switch (state) {
      CreativeFeedbackState.shared => _text.creativityDone,
      CreativeFeedbackState.needsScene => _text.creativityNeedsScene,
      CreativeFeedbackState.needsCharacter => _text.creativityNeedsCharacter,
      CreativeFeedbackState.needsFeeling => _text.creativityNeedsFeeling,
      CreativeFeedbackState.needsStory => _text.creativityNeedsStory,
      CreativeFeedbackState.composing => _text.creativitySupportiveFeedback,
    };
  }

  void _clearPrompt() {
    _feedbackState = CreativeFeedbackState.composing;
    _feedback = null;
  }

  void _resetForLevel(MiLevel level) {
    final localized = level.contentForLocale(locale);
    final localizedDeepData = _asMap(localized['deepData']);
    final metadataDeepData = _asMap(level.metadata['deepData']);
    final deepData = {...metadataDeepData, ...localizedDeepData};
    _scenes = _parseChoices(deepData['scenes']);
    if (_scenes.isEmpty) {
      _scenes = _parseLegacyCards(localizedDeepData['storyCards'], localized);
    }
    _characters = _parseChoices(deepData['characters']);
    if (_characters.isEmpty) {
      _characters = _text.creativityCharacters
          .asMap()
          .entries
          .map((entry) => CreativeChoice(
                id: 'character-${entry.key + 1}',
                label: entry.value,
              ))
          .toList(growable: false);
    }
    _feelings = _parseChoices(deepData['feelings']);
    if (_feelings.isEmpty) {
      _feelings = _text.creativityFeelings
          .asMap()
          .entries
          .map((entry) => CreativeChoice(
                id: 'feeling-${entry.key + 1}',
                label: entry.value,
              ))
          .toList(growable: false);
    }
    _storyStarters = _parseChoices(deepData['storyStarters']);
    _labels = _asStringList(deepData['storyLabels']);
    _minimumStoryLength = _asPositiveInt(deepData['minimumStoryLength'], 1);
    _maximumStoryLength = _asPositiveInt(deepData['maximumStoryLength'], 500);
    if (_minimumStoryLength > _maximumStoryLength) {
      _minimumStoryLength = _maximumStoryLength;
    }
    _sceneId = null;
    _characterId = null;
    _feelingId = null;
    _storyStarterId = _storyStarters.isEmpty ? null : _storyStarters.first.id;
    _storyText = '';
    _hintsUsed = 0;
    _feedbackState = CreativeFeedbackState.composing;
    _feedback = _text.creativitySupportiveFeedback;
    _artifact = null;
  }

  String get _normalizedStoryText => _storyText.trim();

  List<String> get _assetReferences {
    return [
      _choiceFor(_scenes, _sceneId)?.assetRef,
      _choiceFor(_characters, _characterId)?.assetRef,
      _choiceFor(_feelings, _feelingId)?.assetRef,
    ].whereType<String>().toList(growable: false);
  }

  static String? _labelFor(List<CreativeChoice> choices, String? id) =>
      _choiceFor(choices, id)?.label;

  static CreativeChoice? _choiceFor(List<CreativeChoice> choices, String? id) {
    if (id == null) return null;
    for (final choice in choices) {
      if (choice.id == id) return choice;
    }
    return null;
  }

  static String? _resolveChoiceId(List<CreativeChoice> choices, String value) {
    for (final choice in choices) {
      if (choice.id == value || choice.label == value) return choice.id;
    }
    return null;
  }

  static String? _restoreChoiceId(
    List<CreativeChoice> choices,
    Object? id,
    Object? legacyLabel,
  ) {
    if (id != null) {
      final resolved = _resolveChoiceId(choices, id.toString());
      if (resolved != null) return resolved;
    }
    if (legacyLabel != null) {
      return _resolveChoiceId(choices, legacyLabel.toString());
    }
    return null;
  }

  static List<CreativeChoice> _parseChoices(Object? value) {
    if (value is! List) return const [];
    final choices = <CreativeChoice>[];
    for (var i = 0; i < value.length; i++) {
      final item = value[i];
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final label = (map['label'] ?? map['text'])?.toString().trim();
        if (label == null || label.isEmpty) continue;
        choices.add(CreativeChoice(
          id: (map['id'] as String?)?.trim().isNotEmpty == true
              ? map['id'].toString()
              : 'choice-${i + 1}',
          label: label,
          assetRef: map['assetRef'] as String?,
        ));
      } else {
        final label = item.toString().trim();
        if (label.isEmpty) continue;
        choices.add(CreativeChoice(id: 'choice-${i + 1}', label: label));
      }
    }
    return choices;
  }

  static List<CreativeChoice> _parseLegacyCards(
    Object? storyCards,
    Map<String, dynamic> localized,
  ) {
    final cards = _asStringList(storyCards);
    if (cards.isNotEmpty) {
      return cards
          .asMap()
          .entries
          .map((entry) => CreativeChoice(
                id: 'scene-${entry.key + 1}',
                label: entry.value,
              ))
          .toList(growable: false);
    }
    final options = localized['options'];
    if (options is! List) return const [];
    return options.whereType<Map>().toList().asMap().entries.map((entry) {
      final option = entry.value;
      return CreativeChoice(
        id: (option['id'] as String?)?.trim().isNotEmpty == true
            ? option['id'].toString()
            : 'scene-${entry.key + 1}',
        label: option['text'].toString(),
      );
    }).toList(growable: false);
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static List<String> _asStringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static int _asPositiveInt(Object? value, int fallback) {
    final number = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (number == null || number < 1) return fallback;
    return number;
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) return null;
    return value is int ? value : int.tryParse(value.toString());
  }
}
