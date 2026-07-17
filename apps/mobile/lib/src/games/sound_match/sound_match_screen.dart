import 'package:flutter/material.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

import 'sound_match_session.dart';

class SoundMatchScreen extends StatefulWidget {
  const SoundMatchScreen({
    super.key,
    required this.level,
    required this.allLevels,
    this.onExit,
  });

  final MiLevel level;
  final List<MiLevel> allLevels;
  final VoidCallback? onExit;

  @override
  State<SoundMatchScreen> createState() => _SoundMatchScreenState();
}

class _SoundMatchScreenState extends State<SoundMatchScreen> {
  late SoundMatchSession _session;
  late Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _loadLevel(widget.level);
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  void _loadLevel(MiLevel level) {
    setState(() {
      _session = SoundMatchSession(level: level);
      _stopwatch
        ..reset()
        ..start();
    });
  }

  MiLevel get _level => _session.level;
  Map<String, dynamic> get _content => _session.content;

  void _playPrompt() {
    setState(() {
      _session.playPrompt();
    });
  }

  void _choose(String option) {
    final correct = _session.choose(option);
    if (correct) {
      _showCompletion();
    } else {
      setState(() {});
    }
  }

  void _showHint() {
    setState(() {
      _session.showHint();
    });
  }

  void _showCompletion() {
    _stopwatch.stop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompletionOverlay(
        starsEarned: _session.stars,
        maxStars: 3,
        message: 'Con đã nghe và chọn đúng!',
        score: _session.score,
        onNext: _goNext,
        onReplay: () {
          Navigator.of(context).pop();
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
      _loadLevel(widget.allLevels[nextIndex]);
    } else {
      widget.onExit?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prompt = _content['prompt'] as String? ?? 'Nghe và chọn đáp án đúng!';
    final transcript = _content['audioTranscript'] as String? ?? '';
    final audioKey = _content['audioKey'] as String? ?? '';

    return Scaffold(
      backgroundColor: GameTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
              title: 'Nghe âm tìm chữ',
              score: _level.levelNumber,
              onExit: widget.onExit,
            ),
            ProgressDots(
              total: widget.allLevels.length,
              completed: _level.levelNumber - 1,
            ),
            Expanded(
              child: ListView(
                padding: GameTheme.screenPadding,
                children: [
                  _SoundPromptCard(
                    prompt: prompt,
                    audioKey: audioKey,
                    transcript: transcript,
                    showTranscript: _session.showTranscript,
                    onPlay: _playPrompt,
                  ),
                  const SizedBox(height: 24),
                  ..._session.options.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OptionButton(
                        label: option,
                        onPressed: () => _choose(option),
                      ),
                    ),
                  ),
                  if (_session.feedback != null) ...[
                    const SizedBox(height: 8),
                    FeedbackBubble(
                      isCorrect: _session.feedback!.contains('đúng'),
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
                    hintsRemaining: _level.hints.length - _session.hintsUsed < 0
                        ? 0
                        : _level.hints.length - _session.hintsUsed,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _playPrompt,
                      icon: const Icon(Icons.volume_up_rounded),
                      label: const Text('Nghe lại'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GameTheme.primary,
                        padding: GameTheme.buttonPadding,
                        textStyle: GameTheme.buttonLabel,
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

class _SoundPromptCard extends StatelessWidget {
  const _SoundPromptCard({
    required this.prompt,
    required this.audioKey,
    required this.transcript,
    required this.showTranscript,
    required this.onPlay,
  });

  final String prompt;
  final String audioKey;
  final String transcript;
  final bool showTranscript;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(prompt, style: GameTheme.headingMedium),
            const SizedBox(height: 16),
            SizedBox(
              width: 96,
              height: 96,
              child: ElevatedButton(
                onPressed: onPlay,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: GameTheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Icon(Icons.volume_up_rounded, size: 44),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Âm thanh: $audioKey',
              style: GameTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (showTranscript) ...[
              const SizedBox(height: 12),
              Text(
                transcript,
                style: GameTheme.headingLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: GameTheme.textPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameTheme.buttonRadius),
            side: const BorderSide(color: GameTheme.primary),
          ),
        ),
        child: Text(label, style: GameTheme.headingMedium),
      ),
    );
  }
}
