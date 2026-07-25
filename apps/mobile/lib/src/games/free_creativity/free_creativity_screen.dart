import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:mi_game_audio/mi_game_audio.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

import '../game_locale_text.dart';
import '../level_skill_ids.dart';
import '../snapshot_lifecycle_mixin.dart';
import 'creative_artifact_store.dart';
import 'free_creativity_session.dart';

class FreeCreativityScreen extends StatefulWidget {
  const FreeCreativityScreen({
    super.key,
    required this.level,
    required this.allLevels,
    required this.childProfileId,
    this.onExit,
    this.onComplete,
    this.initialSnapshot,
    this.onSaveSnapshot,
    this.artifactStore,
    this.playAudioIntent,
    this.reduceMotion = false,
    this.locale = 'vi',
  });

  final MiLevel level;
  final List<MiLevel> allLevels;
  final String childProfileId;
  final VoidCallback? onExit;
  final void Function(MiCompletionResult)? onComplete;
  final MiGameSnapshot? initialSnapshot;
  final void Function(MiGameSnapshot)? onSaveSnapshot;
  final CreativeArtifactStore? artifactStore;
  final Future<void> Function(MiAudioIntent intent)? playAudioIntent;
  final bool reduceMotion;
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
    _session = FreeCreativitySession(
      level: level,
      childProfileId: widget.childProfileId,
      locale: widget.locale,
    );
    if (snapshot != null) {
      try {
        _session.restoreSnapshot(snapshot);
      } catch (_) {}
    }
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
    unawaited(_playIntent(MiAudioIntent.selectionSoft));
  }

  void _selectCharacter(String value) {
    setState(() => _session.selectCharacter(value));
    unawaited(_playIntent(MiAudioIntent.selectionSoft));
  }

  void _selectFeeling(String value) {
    setState(() => _session.selectFeeling(value));
    unawaited(_playIntent(MiAudioIntent.selectionSoft));
  }

  void _updateStoryText(String value) {
    setState(() => _session.updateStoryText(value));
  }

  void _clearStoryText() {
    _storyController.clear();
    setState(() => _session.clearStoryText());
  }

  Future<void> _completeStory() async {
    if (_completed) return;
    final completion = _session.complete();
    unawaited(_playIntent(completion == null
        ? MiAudioIntent.gentleAttention
        : MiAudioIntent.creativeComplete));
    setState(() {});
    if (completion == null) return;
    _completed = true;
    await widget.artifactStore?.save(completion.artifact);
    _showCompletion(completion.artifact);
  }

  void _showHint() {
    setState(() => _session.showHint());
    unawaited(_playIntent(MiAudioIntent.creativePrompt));
  }

  Future<void> _playIntent(MiAudioIntent intent) async {
    try {
      final play = widget.playAudioIntent;
      if (play != null) {
        await play(intent);
      } else {
        await _audio.playIntent(intent);
      }
    } catch (_) {
      // Audio feedback should never interrupt gameplay.
    }
  }

  void _showCompletion(CreativeArtifact artifact) {
    final text = GameLocaleText(widget.locale);
    _stopwatch.stop();
    widget.onComplete?.call(MiCompletionResult(
      gameId: _level.gameId,
      levelId: _level.id,
      childProfileId: _session.childProfileId,
      completedAt: DateTime.now(),
      score: 1,
      maxScore: 1,
      attemptsUsed: 1,
      hintsUsed: _session.hintsUsed,
      duration: _stopwatch.elapsed,
      perfectRun: false,
      newSkillsAcquired: skillIdsFor(
        _level,
        fallback: const ['creative.storytelling'],
      ),
      metadata: {
        'engine': 'creative_story_lab',
        'completionModel': 'participation',
        'assessmentModel': 'ungraded',
        'isMasteryScore': false,
        'isQualityScore': false,
        'artifactId': artifact.artifactId,
        'contentVersion': _level.contentVersion,
        'sceneId': artifact.sceneId,
        'characterId': artifact.characterId,
        'feelingId': artifact.feelingId,
      },
    ));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreativeCompletionDialog(
        message: text.creativityComplete,
        nextLabel: text.completion.nextLabel,
        replayLabel: text.completion.replayLabel,
        exitLabel: text.completion.exitLabel,
        reduceMotion: widget.reduceMotion,
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
                    options: _session.scenes,
                    selected: _session.sceneId,
                    onSelected: _selectScene,
                  ),
                  const SizedBox(height: 16),
                  _ChoiceSection(
                    title: text.creativityCharacter,
                    icon: Icons.person_rounded,
                    options: _session.characters,
                    selected: _session.characterId,
                    onSelected: _selectCharacter,
                  ),
                  const SizedBox(height: 16),
                  _ChoiceSection(
                    title: text.creativityFeeling,
                    icon: Icons.favorite_rounded,
                    options: _session.feelings,
                    selected: _session.feelingId,
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
                    _CreativeFeedbackPanel(
                      message: _session.feedback!,
                      reduceMotion: widget.reduceMotion,
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
  final List<CreativeChoice> options;
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
                text: option.label,
                selected: selected == option.id,
                onPressed: () => onSelected(option.id),
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
    return Semantics(
      selected: selected,
      button: true,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? MiColors.primary.withValues(alpha: 0.14)
              : Colors.white,
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
      ),
    );
  }
}

class _CreativeFeedbackPanel extends StatelessWidget {
  const _CreativeFeedbackPanel({
    required this.message,
    required this.reduceMotion,
  });

  final String message;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      key: ValueKey(message),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MiColors.discovery.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
        border: Border.all(color: MiColors.discovery.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const MiBrandIconView(
            icon: MiBrandIcon.writing,
            color: MiColors.discovery,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: GameTheme.bodyMedium),
          ),
        ],
      ),
    );

    return AnimatedSwitcher(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
      child: content,
    );
  }
}

class _CreativeCompletionDialog extends StatelessWidget {
  const _CreativeCompletionDialog({
    required this.message,
    required this.nextLabel,
    required this.replayLabel,
    required this.exitLabel,
    required this.reduceMotion,
    required this.onNext,
    required this.onReplay,
    required this.onExit,
  });

  final String message;
  final String nextLabel;
  final String replayLabel;
  final String exitLabel;
  final bool reduceMotion;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedScale(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          scale: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiMascotReaction(
                emotion: MiMascotEmotion.celebration,
                size: 96,
                semanticLabel: 'MI celebrates the story',
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GameTheme.headingMedium,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MiColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(nextLabel),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onReplay,
                style: OutlinedButton.styleFrom(
                  foregroundColor: MiColors.primary,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(replayLabel),
              ),
              TextButton(
                onPressed: onExit,
                child: Text(exitLabel),
              ),
            ],
          ),
        ),
      ),
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
