import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

import 'memory_cards_game.dart';

/// Memory Cards game screen — implements the complete vertical slice.
class MemoryCardsScreen extends StatefulWidget {
  const MemoryCardsScreen({
    super.key,
    required this.game,
    required this.level,
    required this.onComplete,
    this.onExit,
  });

  final MemoryCardsGame game;
  final MiLevel level;
  final void Function(MiCompletionResult) onComplete;
  final VoidCallback? onExit;

  @override
  State<MemoryCardsScreen> createState() => _MemoryCardsScreenState();
}

class _MemoryCardsScreenState extends State<MemoryCardsScreen> {
  bool _isPaused = false;
  String? _feedbackMessage;
  bool _showFeedback = false;
  bool _showHint = false;
  String _currentHint = '';
  bool _showTutorial = true;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    await widget.game.initialize(
      context: MiGameContext(
        childProfileId: 'local-child',
        language: 'vi',
        ageGroup: '5-7',
        accessibility: const AccessibilityPreferences(),
        audio: const AudioPreferences(),
        services: MiGameServices(
          saveSnapshot: _noopSave,
          loadSnapshot: _noopLoad,
          logEvent: _noopLog,
          playAudio: _noopAudio,
          stopAudio: _noopStop,
        ),
      ),
    );
    await widget.game.loadLevel(level: widget.level);
    await widget.game.start();
    if (mounted) setState(() {});
  }

  Future<void> _noopSave(String k, Map<String, dynamic> d) async {}
  Future<Map<String, dynamic>?> _noopLoad(String k) async => null;
  Future<void> _noopLog(String e, Map<String, dynamic> d) async {}
  Future<void> _noopAudio(String r, {double? volume}) async {}
  Future<void> _noopStop() async {}

  void _showFeedbackMessage(String msg) {
    setState(() {
      _feedbackMessage = msg;
      _showFeedback = true;
    });
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showFeedback = false);
    });
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    widget.game.dispose();
    super.dispose();
  }

  Future<void> _onCardTap(int index) async {
    if (widget.game.currentState != GameState.playing) return;

    final result = await widget.game.handleAction(
      MiGameAction(type: 'tap', targetId: index.toString()),
    );

    if (mounted) setState(() {});

    if (result.feedback != null) {
      _showFeedbackMessage(result.feedback!);
    }

    if (result.isLevelComplete) {
      final completion = await widget.game.complete();
      widget.onComplete(completion);
    }
  }

  Future<void> _requestHint() async {
    final hint = await widget.game.requestHint();
    setState(() {
      _currentHint = hint.content;
      _showHint = true;
    });
  }

  void _dismissHint() {
    setState(() => _showHint = false);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    const locale = 'vi';
    final content = widget.level.contentForLocale(locale);
    final prompt = content['prompt'] as String? ?? 'Tìm cặp giống nhau!';

    return Scaffold(
      backgroundColor: GameTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                GameHeader(
                  title: 'Memory Cards',
                  score: game.matchedPairs,
                  onPause: () => setState(() => _isPaused = true),
                  onExit: widget.onExit,
                ),

                // Progress dots
                ProgressDots(
                  total: game.totalPairs,
                  completed: game.matchedPairs,
                ),

                const SizedBox(height: 8),

                // Prompt
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    prompt,
                    style: GameTheme.headingMedium,
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 16),

                // Card grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _CardGrid(
                      cards: game.cards,
                      cols: game.gridCols,
                      onTap: _onCardTap,
                      isProcessing: game.isProcessing,
                    ),
                  ),
                ),

                // Hint button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: HintButton(
                    onPressed: _requestHint,
                    hintsAvailable: widget.level.hints.length,
                    hintsRemaining: widget.level.hints.length,
                  ),
                ),
              ],
            ),

            // Feedback bubble
            if (_showFeedback && _feedbackMessage != null)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: FeedbackBubble(
                    isCorrect: _feedbackMessage!.contains('đúng') ||
                        _feedbackMessage!.contains('Hoàn thành'),
                    message: _feedbackMessage!,
                  ),
                ),
              ),

            // Hint bubble
            if (_showHint)
              Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: HintBubble(
                  hintText: _currentHint,
                  onDismiss: _dismissHint,
                ),
              ),

            // Pause overlay
            if (_isPaused)
              PauseOverlay(
                onResume: () => setState(() => _isPaused = false),
                onRestart: () async {
                  setState(() => _isPaused = false);
                  await _initGame();
                },
                onExit: widget.onExit ?? () {},
              ),

            // Tutorial overlay
            if (_showTutorial)
              TutorialOverlay(
                title: 'Memory Cards',
                message: 'Chạm vào thẻ để lật lên.\n'
                    'Tìm hai thẻ có hình giống nhau.\n'
                    'Ghép tất cả cặp để thắng!',
                onContinue: () => setState(() => _showTutorial = false),
                imageHint: Icons.style_rounded,
                pageNumber: 1,
                totalPages: 1,
              ),
          ],
        ),
      ),
    );
  }
}

/// The card grid widget.
class _CardGrid extends StatelessWidget {
  const _CardGrid({
    required this.cards,
    required this.cols,
    required this.onTap,
    required this.isProcessing,
  });

  final List<MemoryCard> cards;
  final int cols;
  final void Function(int) onTap;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - (cols - 1) * 8) / cols;
        final cardHeight = cardWidth;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(cards.length, (i) {
            final card = cards[i];
            return _MemoryCardWidget(
              card: card,
              index: i,
              width: cardWidth,
              height: cardHeight,
              onTap: isProcessing ? null : () => onTap(i),
            );
          }),
        );
      },
    );
  }
}

/// Individual card widget with flip animation.
class _MemoryCardWidget extends StatelessWidget {
  const _MemoryCardWidget({
    required this.card,
    required this.index,
    required this.width,
    required this.height,
    this.onTap,
  });

  final MemoryCard card;
  final int index;
  final double width;
  final double height;
  final VoidCallback? onTap;

  bool get _isFaceUp =>
      card.state == CardState.faceUp ||
      card.state == CardState.matched ||
      card.state == CardState.mismatched;

  Color get _cardColor {
    switch (card.state) {
      case CardState.matched:
        return GameTheme.success.withValues(alpha: 0.2);
      case CardState.mismatched:
        return GameTheme.warning.withValues(alpha: 0.2);
      default:
        return GameTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _isFaceUp ? 'Thẻ ${card.content}' : 'Thẻ úp, vị trí ${index + 1}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: _isFaceUp ? _cardColor : GameTheme.primary,
            borderRadius: BorderRadius.circular(GameTheme.cardRadius),
            boxShadow: GameTheme.cardShadow,
          ),
          child: Center(
            child: _isFaceUp
                ? _FaceUpContent(card: card)
                : const Icon(
                    Icons.question_mark_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
          ),
        ),
      ),
    );
  }
}

class _FaceUpContent extends StatelessWidget {
  const _FaceUpContent({required this.card});

  final MemoryCard card;

  @override
  Widget build(BuildContext context) {
    final fontSize = card.type == 'image' ? 48.0 : 28.0;
    return Text(
      card.content,
      style: TextStyle(fontSize: fontSize),
      textAlign: TextAlign.center,
    );
  }
}
