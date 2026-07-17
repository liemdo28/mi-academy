import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

import 'word_builder_session.dart';

class WordBuilderScreen extends StatefulWidget {
  const WordBuilderScreen({
    super.key,
    required this.level,
    required this.allLevels,
    this.onExit,
  });

  final MiLevel level;
  final List<MiLevel> allLevels;
  final VoidCallback? onExit;

  @override
  State<WordBuilderScreen> createState() => _WordBuilderScreenState();
}

class _WordBuilderScreenState extends State<WordBuilderScreen> {
  late WordBuilderSession _session;
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
      _session = WordBuilderSession(level: level);
      _stopwatch
        ..reset()
        ..start();
    });
  }

  MiLevel get _level => _session.level;
  Map<String, dynamic> get _content => _session.content;

  void _placeLetter(int bankIndex) {
    final slotIndex = _session.placed.indexWhere((letter) => letter == null);
    if (slotIndex == -1) return;

    setState(() {
      _session.placeLetter(bankIndex);
    });
  }

  void _removeLetter(int slotIndex) {
    final letter = _session.placed[slotIndex];
    if (letter == null) return;

    setState(() {
      _session.removeLetter(slotIndex);
    });
  }

  void _checkAnswer() {
    final correct = _session.checkAnswer();
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
        message: 'Con đã ghép đúng từ!',
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
    final prompt = _content['prompt'] as String? ?? 'Ghép chữ thành từ!';
    final targetWord = _content['targetWord'] as String? ?? '';

    return Scaffold(
      backgroundColor: GameTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
              title: 'Ghép chữ tạo từ',
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
                  _MiPromptCard(prompt: prompt, targetWord: targetWord),
                  const SizedBox(height: 20),
                  _AnswerSlots(
                    placed: _session.placed,
                    onRemove: _removeLetter,
                  ),
                  const SizedBox(height: 24),
                  _LetterBank(
                    letters: _session.bank,
                    onPick: _placeLetter,
                  ),
                  const SizedBox(height: 20),
                  if (_session.feedback != null)
                    FeedbackBubble(
                      isCorrect: _session.feedback!.contains('đúng'),
                      message: _session.feedback!,
                    ),
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
                    child: ElevatedButton.icon(
                      onPressed: _checkAnswer,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Kiểm tra'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameTheme.primary,
                        foregroundColor: Colors.white,
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

class _MiPromptCard extends StatelessWidget {
  const _MiPromptCard({required this.prompt, required this.targetWord});

  final String prompt;
  final String targetWord;

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
            const MiCharacter(
              expression: MiExpression.hinting,
              size: 56,
              semanticLabel: 'MI',
            ),
            const SizedBox(height: 8),
            Text(prompt, style: GameTheme.headingMedium),
            const SizedBox(height: 8),
            Text(
              '${targetWord.length} ký tự',
              style: GameTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerSlots extends StatelessWidget {
  const _AnswerSlots({required this.placed, required this.onRemove});

  final List<String?> placed;
  final void Function(int slotIndex) onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(placed.length, (index) {
        final letter = placed[index];
        return SizedBox(
          width: 54,
          height: 58,
          child: OutlinedButton(
            onPressed: letter == null ? null : () => onRemove(index),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: GameTheme.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GameTheme.buttonRadius),
              ),
              backgroundColor: Colors.white,
            ),
            child: Text(
              letter == ' ' ? '␣' : letter ?? '',
              style: GameTheme.headingMedium,
            ),
          ),
        );
      }),
    );
  }
}

class _LetterBank extends StatelessWidget {
  const _LetterBank({required this.letters, required this.onPick});

  final List<String> letters;
  final void Function(int index) onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: List.generate(letters.length, (index) {
        final letter = letters[index];
        return SizedBox(
          width: 56,
          height: 56,
          child: ElevatedButton(
            onPressed: () => onPick(index),
            style: ElevatedButton.styleFrom(
              backgroundColor: GameTheme.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GameTheme.buttonRadius),
              ),
            ),
            child: Text(
              letter == ' ' ? '␣' : letter,
              style: GameTheme.headingMedium.copyWith(color: Colors.white),
            ),
          ),
        );
      }),
    );
  }
}
