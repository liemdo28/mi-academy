import 'package:flutter/material.dart';

import 'sequence_content.dart';
import 'sequence_controller.dart';

/// Renders one Sequence Engine level end-to-end: instruction, reorder (via
/// [ReorderableListView] for drag, plus move-left/move-right buttons as an
/// accessibility fallback) or missing-item (choice list per blank) mode,
/// hint, pause/exit, completion with stars, and a recoverable error screen
/// for malformed content.
class SequenceScreen extends StatefulWidget {
  const SequenceScreen({
    super.key,
    required this.rawContent,
    required this.onExit,
    this.onComplete,
    this.onSaveProgress,
    this.initialState,
    this.onSaveState,
    this.locale = 'vi',
    this.reducedMotion = false,
    this.soundEnabled = true,
  });

  final Map<String, dynamic> rawContent;
  final VoidCallback onExit;
  final void Function(SequenceCompletionResult)? onComplete;
  final void Function(int attempts)? onSaveProgress;
  final Map<String, dynamic>? initialState;
  final void Function(Map<String, dynamic> state)? onSaveState;
  final String locale;
  final bool reducedMotion;
  final bool soundEnabled;

  @override
  State<SequenceScreen> createState() => _SequenceScreenState();
}

class SequenceCompletionResult {
  const SequenceCompletionResult({
    required this.contentId,
    required this.attempts,
    required this.starsEarned,
  });

  final String contentId;
  final int attempts;
  final int starsEarned;
}

class _SequenceScreenState extends State<SequenceScreen> {
  SequenceController? _controller;
  String? _loadError;
  bool _completionReported = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    try {
      final content = SequenceContent.fromJson(widget.rawContent);
      final controller = SequenceController(
        content: content,
        reducedMotion: widget.reducedMotion,
        soundEnabled: widget.soundEnabled,
      );
      final initialState = widget.initialState;
      if (initialState != null) {
        controller.restoreState(initialState);
      }
      controller.addListener(_onControllerChanged);
      _controller = controller;
      _loadError = null;
    } catch (e) {
      _loadError = e is SequenceContentException
          ? e.message
          : _text('Không thể tải nội dung trò chơi.',
              'Unable to load game content.');
    }
  }

  void _onControllerChanged() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.isComplete && !_completionReported) {
      _completionReported = true;
      widget.onComplete?.call(
        SequenceCompletionResult(
          contentId: controller.content.contentId,
          attempts: controller.attempts,
          starsEarned: controller.starsEarned,
        ),
      );
    }
    widget.onSaveProgress?.call(controller.attempts);
    widget.onSaveState?.call(controller.exportState());
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
                  '${_text('Nội dung không khả dụng.', 'Content unavailable.')}\n$error',
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
          tooltip: _text('Thoát', 'Exit'),
        ),
        title: Text(content.instruction),
        actions: [
          IconButton(
            icon: Icon(controller.isPaused ? Icons.play_arrow : Icons.pause),
            tooltip: controller.isPaused
                ? _text('Tiếp tục', 'Resume')
                : _text('Tạm dừng', 'Pause'),
            onPressed: () =>
                controller.isPaused ? controller.resume() : controller.pause(),
          ),
          if (content.hint != null)
            IconButton(
              icon: const Icon(Icons.lightbulb_outline),
              tooltip: _text('Gợi ý', 'Hint'),
              onPressed: controller.requestHint,
            ),
        ],
      ),
      body: SafeArea(
        child: controller.isPaused
            ? _PausedOverlay(
                onResume: controller.resume,
                resumeLabel: _text('Tiếp tục', 'Resume'),
              )
            : controller.isComplete
                ? _CompletionView(
                    stars: controller.starsEarned,
                    attempts: controller.attempts,
                    onExit: widget.onExit,
                    exitLabel: _text('Thoát', 'Exit'),
                    retryLabel: _text('Chơi lại', 'Play again'),
                    completionLabel: _text('Hoàn thành', 'Complete'),
                    attemptsLabel: _text('lượt thử', 'attempts'),
                    starsLabel: _text('trên 3 sao', 'out of 3 stars'),
                    onRetry: () {
                      _completionReported = false;
                      controller.retry();
                    },
                  )
                : Column(
                    children: [
                      if (controller.showHint && content.hint != null)
                        _HintBanner(
                          text: content.hint!,
                          onDismiss: controller.dismissHint,
                        ),
                      if (controller.lastSubmissionCorrect == false)
                        _FeedbackBanner(
                          message: _text(
                            'Chưa đúng thứ tự, thử lại nhé!',
                            'Not in the right order. Try again!',
                          ),
                        ),
                      Expanded(
                        child: content.mode == SequenceMode.reorder
                            ? _ReorderBody(
                                controller: controller,
                                moveLabel: _text('Di chuyển', 'Move'),
                                moveLeftLabel:
                                    _text('Di chuyển sang trái', 'Move left'),
                                moveRightLabel:
                                    _text('Di chuyển sang phải', 'Move right'),
                              )
                            : _MissingItemBody(
                                controller: controller,
                                chooseLabel: _text('Chọn', 'Choose'),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: content.mode == SequenceMode.reorder
                              ? controller.submitReorder
                              : controller.submitMissingItems,
                          child: Text(_text('Kiểm tra', 'Check')),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  String _text(String vi, String en) => widget.locale == 'en' ? en : vi;
}

class _ReorderBody extends StatelessWidget {
  const _ReorderBody({
    required this.controller,
    required this.moveLabel,
    required this.moveLeftLabel,
    required this.moveRightLabel,
  });
  final SequenceController controller;
  final String moveLabel;
  final String moveLeftLabel;
  final String moveRightLabel;

  @override
  Widget build(BuildContext context) {
    final items = controller.arrangement;
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;
        controller.moveItem(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          key: ValueKey(item.id),
          child: ListTile(
            title: Text(item.content, style: const TextStyle(fontSize: 20)),
            trailing: Semantics(
              label: '$moveLabel ${item.content}',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: moveLeftLabel,
                    onPressed: index > 0
                        ? () => controller.moveItem(index, index - 1)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: moveRightLabel,
                    onPressed: index < items.length - 1
                        ? () => controller.moveItem(index, index + 1)
                        : null,
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MissingItemBody extends StatelessWidget {
  const _MissingItemBody({required this.controller, required this.chooseLabel});
  final SequenceController controller;
  final String chooseLabel;

  @override
  Widget build(BuildContext context) {
    final content = controller.content;
    final allChoices = [
      for (final index in content.missingIndices) content.correctOrder[index],
      ...content.choices,
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < content.correctOrder.length; i++)
                if (content.missingIndices.contains(i))
                  _BlankSlot(
                    selectedContent: _contentFor(
                      controller.missingSelections[i],
                      allChoices,
                    ),
                  )
                else
                  Chip(label: Text(content.correctOrder[i].content)),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final choice in allChoices)
                Semantics(
                  button: true,
                  label: '$chooseLabel ${choice.content}',
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => controller.selectForMissingIndex(
                        content.missingIndices.first,
                        choice.id,
                      ),
                      child: Text(choice.content),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String? _contentFor(String? itemId, List<SequenceItem> pool) {
    if (itemId == null) return null;
    for (final item in pool) {
      if (item.id == itemId) return item.content;
    }
    return null;
  }
}

class _BlankSlot extends StatelessWidget {
  const _BlankSlot({required this.selectedContent});
  final String? selectedContent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(selectedContent ?? '?'),
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
  const _FeedbackBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        width: double.infinity,
        color: Colors.orange.withValues(alpha: 0.15),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _PausedOverlay extends StatelessWidget {
  const _PausedOverlay({required this.onResume, required this.resumeLabel});
  final VoidCallback onResume;
  final String resumeLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: onResume,
        icon: const Icon(Icons.play_arrow),
        label: Text(resumeLabel),
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
    required this.exitLabel,
    required this.retryLabel,
    required this.completionLabel,
    required this.attemptsLabel,
    required this.starsLabel,
  });

  final int stars;
  final int attempts;
  final VoidCallback onExit;
  final VoidCallback onRetry;
  final String exitLabel;
  final String retryLabel;
  final String completionLabel;
  final String attemptsLabel;
  final String starsLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: '$stars $starsLabel',
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
          Text('$completionLabel: $attempts $attemptsLabel'),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: onExit, child: Text(exitLabel)),
            ],
          ),
        ],
      ),
    );
  }
}
