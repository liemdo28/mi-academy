import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:mi_game_audio/mi_game_audio.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

import '../game_locale_text.dart';
import '../level_skill_ids.dart';
import '../snapshot_lifecycle_mixin.dart';
import 'free_creativity_session.dart';

class FreeCreativityScreen extends StatefulWidget {
  const FreeCreativityScreen({
    super.key,
    required this.level,
    required this.allLevels,
    this.onExit,
    this.onComplete,
    this.initialSnapshot,
    this.onSaveSnapshot,
    this.locale = 'vi',
  });

  final MiLevel level;
  final List<MiLevel> allLevels;
  final VoidCallback? onExit;
  final void Function(MiCompletionResult)? onComplete;
  final MiGameSnapshot? initialSnapshot;
  final void Function(MiGameSnapshot)? onSaveSnapshot;
  final String locale;

  @override
  State<FreeCreativityScreen> createState() => _FreeCreativityScreenState();
}

class _FreeCreativityScreenState extends State<FreeCreativityScreen>
    with WidgetsBindingObserver, SnapshotLifecycleMixin<FreeCreativityScreen> {
  late FreeCreativitySession _session;
  late Stopwatch _stopwatch;
  late TextEditingController _storyController;
  late final MiAudioService _audio = MiAudioService();
  bool _completed = false;

  @override
  void Function(MiGameSnapshot)? get onSaveSnapshot => widget.onSaveSnapshot;

  @override
  MiGameSnapshot? captureSnapshot() {
    if (_completed) return null;
    return _session.saveSnapshot();
  }

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _loadLevel(widget.level, snapshot: widget.initialSnapshot);
  }

  @override
  void dispose() {
    disposeSnapshotLifecycle();
    _storyController.dispose();
    unawaited(_audio.dispose());
    _stopwatch.stop();
    super.dispose();
  }

  void _loadLevel(MiLevel level, {MiGameSnapshot? snapshot}) {
    _session = FreeCreativitySession(level: level, locale: widget.locale);
    if (snapshot != null) _session.restoreSnapshot(snapshot);
    _storyController = TextEditingController(text: _session.storyText);
    setState(() {
      _completed = false;
      _stopwatch
        ..reset()
        ..start();
    });
  }

  MiLevel get _level => _session.level;
  Map<String, dynamic> get _content => _session.content;

  void _selectScene(String value) {
    setState(() => _session.selectScene(value));
  }

  void _selectCharacter(String value) {
    setState(() => _session.selectCharacter(value));
  }

  void _selectFeeling(String value) {
    setState(() => _session.selectFeeling(value));
  }

  void _updateStoryText(String value) {
    setState(() => _session.updateStoryText(value));
  }

  void _clearStoryText() {
    _storyController.clear();
    setState(() => _session.clearStoryText());
  }

  void _completeStory() {
    final complete = _session.complete();
    unawaited(_playEffect(complete ? 'correct' : 'try_again'));
    setState(() {});
    if (complete) _showCompletion();
  }

  void _showHint() {
    setState(() => _session.showHint());
    unawaited(_playEffect('try_again'));
  }

  Future<void> _playEffect(String assetKey) async {
    try {
      await _audio.playEffect('audio/$assetKey.wav');
    } catch (_) {
      // Audio feedback should never interrupt gameplay.
    }
  }

  void _showCompletion() {
    final text = GameLocaleText(widget.locale);
    final completion = text.completion;
    _completed = true;
    _stopwatch.stop();
    widget.onComplete?.call(MiCompletionResult(
      gameId: _level.gameId,
      levelId: _level.id,
      childProfileId: _session.childProfileId,
      completedAt: DateTime.now(),
      score: 100,
      maxScore: 100,
      attemptsUsed: 1,
      hintsUsed: _session.hintsUsed,
      duration: _stopwatch.elapsed,
      perfectRun: _session.hintsUsed == 0,
      newSkillsAcquired: skillIdsFor(
        _level,
        fallback: const ['creative.storytelling'],
      ),
      metadata: {
        'stars': 3,
        'engine': 'creative_story_lab',
        'completionModel': 'participation',
        'scene': _session.scene,
        'character': _session.character,
        'feeling': _session.feeling,
      },
    ));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompletionOverlay(
        starsEarned: 3,
        maxStars: 3,
        message: text.creativityComplete,
        score: 100,
        scoreLabel: completion.scoreLabel,
        nextLabel: completion.nextLabel,
        replayLabel: completion.replayLabel,
        exitLabel: completion.exitLabel,
        mascotSemanticLabel: completion.mascotSemanticLabel,
        earnedStarSemanticLabel: completion.earnedStarSemanticLabel,
        unearnedStarSemanticLabel: completion.unearnedStarSemanticLabel,
        onNext: _goNext,
        onReplay: () {
          Navigator.of(context).pop();
          _storyController.dispose();
          _loadLevel(_level);
        },
        onExit: () {
          Navigator.of(context).pop();
          widget.onExit?.call();
        },
      ),
    );
  }

  void _goNext() {
    Navigator.of(context).pop();
    final nextIndex =
        widget.allLevels.indexWhere((level) => level.id == _level.id) + 1;
    if (nextIndex > 0 && nextIndex < widget.allLevels.length) {
      _storyController.dispose();
      _loadLevel(widget.allLevels[nextIndex]);
    } else {
      widget.onExit?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = GameLocaleText(widget.locale);
    final prompt = _content['prompt'] as String? ?? text.creativityStoryHint;

    return Scaffold(
      backgroundColor: GameTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
              title: text.creativityTitle,
              score: _level.levelNumber,
              onExit: widget.onExit,
            ),
            ProgressDots(
              total: widget.allLevels.length,
              completed: _level.levelNumber - 1,
              color: MiColors.primary,
            ),
            Expanded(
              child: ListView(
                padding: GameTheme.screenPadding,
                children: [
                  _CreativeIntroCard(prompt: prompt, text: text),
                  const SizedBox(height: 16),
                  _ChoiceSection(
                    title: text.creativityScene,
                    icon: Icons.landscape_rounded,
                    options: _session.storyCards,
                    selected: _session.scene,
                    onSelected: _selectScene,
                  ),
                  const SizedBox(height: 16),
                  _ChoiceSection(
                    title: text.creativityCharacter,
                    icon: Icons.person_rounded,
                    options: text.creativityCharacters,
                    selected: _session.character,
                    onSelected: _selectCharacter,
                  ),
                  const SizedBox(height: 16),
                  _ChoiceSection(
                    title: text.creativityFeeling,
                    icon: Icons.favorite_rounded,
                    options: text.creativityFeelings,
                    selected: _session.feeling,
                    onSelected: _selectFeeling,
                  ),
                  const SizedBox(height: 16),
                  _StoryComposer(
                    controller: _storyController,
                    onChanged: _updateStoryText,
                    onClear: _clearStoryText,
                    text: text,
                  ),
                  if (_session.feedback != null) ...[
                    const SizedBox(height: 16),
                    FeedbackBubble(
                      isCorrect:
                          _session.status == FreeCreativityStatus.complete,
                      message: _session.feedback!,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  HintButton(
                    onPressed: _showHint,
                    hintsAvailable: _level.hints.length,
                    hintsRemaining: (_level.hints.length - _session.hintsUsed)
                        .clamp(0, _level.hints.length),
                    availableSemanticLabel: text.hintAvailable,
                    emptySemanticLabel: text.hintEmpty,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _completeStory,
                      icon: const Icon(Icons.auto_stories_rounded),
                      label: Text(text.creativityCompleteAction),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MiColors.primary,
                        foregroundColor: Colors.white,
                        padding: GameTheme.buttonPadding,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreativeIntroCard extends StatelessWidget {
  const _CreativeIntroCard({required this.prompt, required this.text});

  final String prompt;
  final GameLocaleText text;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const MiBrandIconView(
              icon: MiBrandIcon.writing,
              color: MiColors.primary,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text.creativityLab, style: GameTheme.headingMedium),
                  const SizedBox(height: 6),
                  Text(prompt, style: GameTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceSection extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.icon,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final IconData icon;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: MiColors.primary),
            const SizedBox(width: 8),
            Text(title, style: GameTheme.headingMedium),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              _CreativeChip(
                text: option,
                selected: selected == option,
                onPressed: () => onSelected(option),
              ),
          ],
        ),
      ],
    );
  }
}

class _CreativeChip extends StatelessWidget {
  const _CreativeChip({
    required this.text,
    required this.selected,
    required this.onPressed,
  });

  final String text;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor:
            selected ? MiColors.primary.withValues(alpha: 0.14) : Colors.white,
        foregroundColor: selected ? MiColors.primary : MiColors.navy,
        side: BorderSide(
          color: selected
              ? MiColors.primary
              : MiColors.navy.withValues(alpha: 0.2),
          width: selected ? 2 : 1,
        ),
        minimumSize: const Size(56, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      child: Text(text),
    );
  }
}

class _StoryComposer extends StatelessWidget {
  const _StoryComposer({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.text,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final GameLocaleText text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text.creativityStory, style: GameTheme.headingMedium),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('free-creativity-story-field'),
          controller: controller,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: text.creativityStoryFieldHint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.backspace_rounded),
          label: Text(text.creativityErase),
          style: OutlinedButton.styleFrom(
            foregroundColor: MiColors.primary,
            minimumSize: const Size(80, 48),
          ),
        ),
      ],
    );
  }
}
