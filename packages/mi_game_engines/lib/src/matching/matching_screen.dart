import 'package:flutter/material.dart';

import 'matching_content.dart';
import 'matching_controller.dart';

/// Renders one Matching Engine level end-to-end: instruction, two shuffled
/// columns (tap left item, then its right partner), hint, pause/exit,
/// completion with stars, and a recoverable error state for malformed
/// content. No dependency on any specific child-profile repository or
/// persistence mechanism -- [onComplete]/[onSaveProgress] are plain
/// callbacks the host screen owns.
class MatchingScreen extends StatefulWidget {
  const MatchingScreen({
    super.key,
    required this.rawContent,
    required this.onExit,
    this.onComplete,
    this.onSaveProgress,
    this.reducedMotion = false,
    this.soundEnabled = true,
  });

  /// Unvalidated JSON -- validated internally via
  /// [MatchingContent.fromJson] so a malformed level shows a recoverable
  /// error instead of throwing during [build].
  final Map<String, dynamic> rawContent;
  final VoidCallback onExit;
  final void Function(MatchingCompletionResult)? onComplete;
  final void Function(int attempts, int matchedPairs)? onSaveProgress;
  final bool reducedMotion;
  final bool soundEnabled;

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class MatchingCompletionResult {
  const MatchingCompletionResult({
    required this.contentId,
    required this.attempts,
    required this.starsEarned,
  });

  final String contentId;
  final int attempts;
  final int starsEarned;
}

class _MatchingScreenState extends State<MatchingScreen> {
  MatchingController? _controller;
  String? _loadError;
  List<MatchingItem> _leftOrder = const [];
  List<MatchingItem> _rightOrder = const [];
  bool _completionReported = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    try {
      final content = MatchingContent.fromJson(widget.rawContent);
      final controller = MatchingController(
        content: content,
        reducedMotion: widget.reducedMotion,
        soundEnabled: widget.soundEnabled,
      );
      controller.addListener(_onControllerChanged);
      _controller = controller;
      _loadError = null;
      // Shuffle deterministically per content id so the same level always
      // presents the same shuffle within a session, but different pairs
      // still look shuffled relative to authoring order.
      final seed = content.contentId.hashCode;
      _leftOrder = List.of(content.pairs.map((p) => p.left))
        ..shuffleSeeded(_SeededRandom(seed));
      _rightOrder = List.of(content.pairs.map((p) => p.right))
        ..shuffleSeeded(_SeededRandom(seed + 1));
    } catch (e) {
      _loadError = e is MatchingContentException
          ? e.message
          : 'Không thể tải nội dung trò chơi.';
    }
  }

  void _onControllerChanged() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.isComplete && !_completionReported) {
      _completionReported = true;
      widget.onComplete?.call(
        MatchingCompletionResult(
          contentId: controller.content.contentId,
          attempts: controller.attempts,
          starsEarned: controller.starsEarned,
        ),
      );
    }
    widget.onSaveProgress?.call(
      controller.attempts,
      controller.matchedPairCount,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = _loadError;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onExit,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'Nội dung không khả dụng.\n$error',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final controller = _controller!;
    final content = controller.content;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onExit,
          tooltip: 'Thoát',
        ),
        title: Text(content.instruction),
        actions: [
          IconButton(
            icon: Icon(controller.isPaused ? Icons.play_arrow : Icons.pause),
            tooltip: controller.isPaused ? 'Tiếp tục' : 'Tạm dừng',
            onPressed: () =>
                controller.isPaused ? controller.resume() : controller.pause(),
          ),
          if (content.hint != null)
            IconButton(
              icon: const Icon(Icons.lightbulb_outline),
              tooltip: 'Gợi ý',
              onPressed: controller.requestHint,
            ),
        ],
      ),
      body: SafeArea(
        child: controller.isPaused
            ? _PausedOverlay(onResume: controller.resume)
            : controller.isComplete
                ? _CompletionView(
                    stars: controller.starsEarned,
                    attempts: controller.attempts,
                    onExit: widget.onExit,
                    onRetry: () {
                      _completionReported = false;
                      controller.retry();
                    },
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 600; // tablet
                      return Column(
                        children: [
                          if (controller.showHint && content.hint != null)
                            _HintBanner(
                              text: content.hint!,
                              onDismiss: controller.dismissHint,
                            ),
                          if (controller.lastFeedback != null)
                            _FeedbackBanner(
                              isCorrect: controller.lastFeedbackWasCorrect,
                            ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isWide ? 48 : 16,
                                vertical: 16,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _MatchColumn(
                                      items: _leftOrder,
                                      selectedId: controller.selectedLeftId,
                                      isMatched: controller.isLeftMatched,
                                      onTap: controller.selectLeft,
                                      reducedMotion: widget.reducedMotion,
                                      semanticPrefix: 'Mục bên trái',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _MatchColumn(
                                      items: _rightOrder,
                                      selectedId: controller.selectedRightId,
                                      isMatched: controller.isRightMatched,
                                      onTap: controller.selectRight,
                                      reducedMotion: widget.reducedMotion,
                                      semanticPrefix: 'Mục bên phải',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }
}

class _MatchColumn extends StatelessWidget {
  const _MatchColumn({
    required this.items,
    required this.selectedId,
    required this.isMatched,
    required this.onTap,
    required this.reducedMotion,
    required this.semanticPrefix,
  });

  final List<MatchingItem> items;
  final String? selectedId;
  final bool Function(String id) isMatched;
  final void Function(String id) onTap;
  final bool reducedMotion;
  final String semanticPrefix;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Semantics(
              button: true,
              selected: selectedId == item.id,
              label: '$semanticPrefix: ${item.content}'
                  '${isMatched(item.id) ? ", đã ghép đúng" : ""}',
              child: AnimatedContainer(
                duration: reducedMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 150),
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                decoration: BoxDecoration(
                  color: isMatched(item.id)
                      ? Colors.green.withValues(alpha: 0.2)
                      : selectedId == item.id
                          ? Colors.blue.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedId == item.id ? Colors.blue : Colors.grey,
                  ),
                ),
                child: InkWell(
                  onTap: isMatched(item.id) ? null : () => onTap(item.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: Text(
                      item.content,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HintBanner extends StatelessWidget {
  const _HintBanner({required this.text, required this.onDismiss});
  final String text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.amber.withValues(alpha: 0.2),
      child: ListTile(
        leading: const Icon(Icons.lightbulb),
        title: Text(text),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onDismiss,
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.isCorrect});
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: isCorrect ? 'Ghép đúng!' : 'Chưa khớp, thử lại nhé!',
      child: Container(
        width: double.infinity,
        color: isCorrect
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.orange.withValues(alpha: 0.15),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          isCorrect ? 'Ghép đúng!' : 'Chưa khớp, thử lại nhé!',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _PausedOverlay extends StatelessWidget {
  const _PausedOverlay({required this.onResume});
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: onResume,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Tiếp tục'),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({
    required this.stars,
    required this.attempts,
    required this.onExit,
    required this.onRetry,
  });

  final int stars;
  final int attempts;
  final VoidCallback onExit;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: '$stars trên 3 sao',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Icon(
                  i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Hoàn thành sau $attempts lượt thử!'),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(onPressed: onRetry, child: const Text('Chơi lại')),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: onExit, child: const Text('Thoát')),
            ],
          ),
        ],
      ),
    );
  }
}

/// Minimal deterministic PRNG (linear congruential) so shuffles are
/// reproducible per content id without depending on `dart:math`'s
/// `Random(seed)` behavior differing across Dart versions/platforms --
/// deterministic tests need bit-for-bit reproducibility across CI/local.
class _SeededRandom {
  _SeededRandom(int seed) : _state = seed & 0x7fffffff;
  int _state;

  int nextInt(int max) {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state % max;
  }
}

extension on List<MatchingItem> {
  void shuffleSeeded(_SeededRandom random) {
    for (var i = length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final tmp = this[i];
      this[i] = this[j];
      this[j] = tmp;
    }
  }
}
