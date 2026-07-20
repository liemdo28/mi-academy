import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';
import 'package:localization/localization.dart';

import 'memory_cards_game.dart';

/// Memory Cards game screen — implements the complete vertical slice.
class MemoryCardsScreen extends StatefulWidget {
  const MemoryCardsScreen({
    super.key,
    required this.game,
    required this.level,
    required this.onComplete,
    this.onExit,
    this.childProfileId = 'local-child',
    this.initialSnapshot,
    this.onSaveSnapshot,
    this.reduceMotion = false,
    this.locale = 'vi',
  });

  final MemoryCardsGame game;
  final MiLevel level;
  final void Function(MiCompletionResult) onComplete;
  final VoidCallback? onExit;

  /// Real child id when launched from the production route; defaults to
  /// the prior hardcoded placeholder for the debug game picker, which
  /// doesn't have a real backend child.
  final String childProfileId;

  /// From the parent's accessibility settings (see
  /// ParentSettingsSnapshot.reduceMotion) -- shortens the card-flip
  /// animation to near-instant for children sensitive to motion, instead
  /// of always animating at a fixed duration regardless of preference.
  final bool reduceMotion;

  /// From the parent's language setting (see ParentSettingsSnapshot.language)
  /// -- was previously hardcoded to 'vi' regardless of this setting.
  final String locale;

  /// See WordBuilderScreen.initialSnapshot.
  final MiGameSnapshot? initialSnapshot;

  /// See WordBuilderScreen.onSaveSnapshot.
  final void Function(MiGameSnapshot)? onSaveSnapshot;

  @override
  State<MemoryCardsScreen> createState() => _MemoryCardsScreenState();
}

class _MemoryCardsScreenState extends State<MemoryCardsScreen>
    with WidgetsBindingObserver {
  bool _isPaused = false;
  String? _feedbackMessage;
  bool _showFeedback = false;
  bool _showHint = false;
  String _currentHint = '';
  bool _showTutorial = true;
  Timer? _feedbackTimer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initGame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveSnapshotNow();
    }
  }

  void _saveSnapshotNow() {
    if (_completed) return;
    final onSave = widget.onSaveSnapshot;
    if (onSave == null) return;
    // Best-effort, fire-and-forget: this fires from a lifecycle callback
    // (and potentially dispose()), neither of which can await.
    widget.game.saveSnapshot().then(onSave).catchError((_) {});
  }

  Future<void> _initGame() async {
    await widget.game.initialize(
      context: MiGameContext(
        childProfileId: widget.childProfileId,
        language: widget.locale,
        ageGroup: '5-7',
        accessibility: AccessibilityPreferences(
          reducedMotion: widget.reduceMotion,
        ),
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
    final snapshot = widget.initialSnapshot;
    if (snapshot != null) {
      await widget.game.restoreSnapshot(snapshot);
    }
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
    _saveSnapshotNow();
    WidgetsBinding.instance.removeObserver(this);
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
      _completed = true;
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
    final content = widget.level.contentForLocale(widget.locale);
    final prompt = content['prompt'] as String? ?? MiMobileStrings.m201;

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
                      reduceMotion: widget.reduceMotion,
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
                    isCorrect:
                        _feedbackMessage!.contains(MiMobileStrings.m202) ||
                            _feedbackMessage!.contains(MiMobileStrings.m177),
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
                message: MiMobileStrings.m203 +
                    MiMobileStrings.m204 +
                    MiMobileStrings.m205,
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
    this.reduceMotion = false,
  });

  final List<MemoryCard> cards;
  final int cols;
  final void Function(int) onTap;
  final bool isProcessing;
  final bool reduceMotion;

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
              reduceMotion: reduceMotion,
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
    this.reduceMotion = false,
  });

  final MemoryCard card;
  final int index;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final bool reduceMotion;

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
      label: _isFaceUp
          ? MiMobileStrings.text('m206', {'p0': card.content})
          : MiMobileStrings.text('m250', {'p0': index + 1}),
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
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
