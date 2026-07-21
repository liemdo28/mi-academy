import 'package:design_system/design_system.dart';
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
    this.reducedMotion = false,
    this.soundEnabled = true,
  });

  final Map<String, dynamic> rawContent;
  final VoidCallback onExit;
  final void Function(SequenceCompletionResult)? onComplete;
  final void Function(int attempts)? onSaveProgress;
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
      controller.addListener(_onControllerChanged);
      _controller = controller;
      _loadError = null;
    } catch (e) {
      _loadError = e is SequenceContentException
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
        SequenceCompletionResult(
          contentId: controller.content.contentId,
          attempts: controller.attempts,
          starsEarned: controller.starsEarned,
        ),
      );
    }
    widget.onSaveProgress?.call(controller.attempts);
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
              icon: const Icon(Icons.close), onPressed: widget.onExit),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text('Nội dung không khả dụng.\n$error',
                    textAlign: TextAlign.center),
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
                : Column(
                    children: [
                      if (controller.showHint && content.hint != null)
                        _HintBanner(
                          text: content.hint!,
                          onDismiss: controller.dismissHint,
                        ),
                      if (controller.lastSubmissionCorrect == false)
                        const _FeedbackBanner(isCorrect: false),
                      Expanded(
                        child: content.mode == SequenceMode.reorder
                            ? _ReorderBody(controller: controller)
                            : _MissingItemBody(controller: controller),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: content.mode == SequenceMode.reorder
                              ? controller.submitReorder
                              : controller.submitMissingItems,
                          child: const Text('Kiểm tra'),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _ReorderBody extends StatelessWidget {
  const _ReorderBody({required this.controller});
  final SequenceController controller;

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
              label: 'Di chuyển ${item.content}',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Di chuyển sang trái',
                    onPressed: index > 0
                        ? () => controller.moveItem(index, index - 1)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: 'Di chuyển sang phải',
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
  const _MissingItemBody({required this.controller});
  final SequenceController controller;

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
                  label: 'Chọn ${choice.content}',
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
        trailing:
            IconButton(icon: const Icon(Icons.close), onPressed: onDismiss),
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
      label: 'Chưa đúng thứ tự, thử lại nhé!',
      child: Container(
        width: double.infinity,
        color: Colors.orange.withValues(alpha: 0.15),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: const Text('Chưa đúng thứ tự, thử lại nhé!',
            textAlign: TextAlign.center),
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
                (i) => MiBrandIconView(
                  icon: MiBrandIcon.rewardStar,
                  color: Colors.amber,
                  size: 40,
                  enabled: i < stars,
                  decorative: true,
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
