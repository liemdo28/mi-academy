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
    this.text,
    this.initialSnapshot,
    this.onComplete,
    this.onNext,
    this.onRestart,
    this.onSnapshotChanged,
    this.onSaveProgress,
    this.reducedMotion = false,
    this.soundEnabled = true,
    this.locale = 'vi',
  });

  final Map<String, dynamic> rawContent;
  final VoidCallback onExit;
  final SequenceScreenText? text;
  final SequenceSnapshot? initialSnapshot;
  final void Function(SequenceCompletionResult)? onComplete;
  final VoidCallback? onNext;
  final VoidCallback? onRestart;
  final void Function(SequenceSnapshot)? onSnapshotChanged;
  final void Function(int attempts)? onSaveProgress;
  final bool reducedMotion;
  final bool soundEnabled;
  final String locale;

  @override
  State<SequenceScreen> createState() => _SequenceScreenState();
}

class SequenceCompletionResult {
  const SequenceCompletionResult({
    required this.contentId,
    required this.attempts,
    required this.hintsUsed,
    required this.starsEarned,
    required this.completedItemCount,
    required this.totalItemCount,
    required this.snapshot,
  });

  final String contentId;
  final int attempts;
  final int hintsUsed;
  final int starsEarned;
  final int completedItemCount;
  final int totalItemCount;
  final SequenceSnapshot snapshot;
}

class _SequenceScreenState extends State<SequenceScreen> {
  SequenceController? _controller;
  String? _loadError;
  bool _completionReported = false;
  Map<String, dynamic>? _lastSavedSnapshot;

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
        initialSnapshot: widget.initialSnapshot,
        reducedMotion: widget.reducedMotion,
        soundEnabled: widget.soundEnabled,
      );
      controller.addListener(_onControllerChanged);
      _controller = controller;
      _loadError = null;
    } catch (e) {
      _loadError = 'invalid_sequence_content';
    }
  }

  void _onControllerChanged() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.isComplete && !_completionReported) {
      _completionReported = true;
      final snapshot = controller.snapshot();
      widget.onComplete?.call(
        SequenceCompletionResult(
          contentId: controller.content.contentId,
          attempts: controller.attempts,
          hintsUsed: controller.hintsUsed,
          starsEarned: controller.starsEarned,
          completedItemCount: controller.completedItemCount,
          totalItemCount: controller.totalItemCount,
          snapshot: snapshot,
        ),
      );
    }
    _saveSnapshotIfChanged(controller);
    widget.onSaveProgress?.call(controller.attempts);
    setState(() {});
  }

  void _saveSnapshotIfChanged(SequenceController controller) {
    if (controller.isComplete) return;
    final snapshot = controller.snapshot();
    final payload = snapshot.toJson();
    if (_lastSavedSnapshot.toString() == payload.toString()) return;
    _lastSavedSnapshot = payload;
    widget.onSnapshotChanged?.call(snapshot);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text ?? SequenceScreenText.forLocale(widget.locale);
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
                Text(text.contentUnavailable, textAlign: TextAlign.center),
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
          tooltip: text.exit,
        ),
        title: Text(content.instruction),
        actions: [
          IconButton(
            icon: Icon(controller.isPaused ? Icons.play_arrow : Icons.pause),
            tooltip: controller.isPaused ? text.resume : text.pause,
            onPressed: () =>
                controller.isPaused ? controller.resume() : controller.pause(),
          ),
          if (content.hint != null)
            IconButton(
              icon: const Icon(Icons.lightbulb_outline),
              tooltip: text.hint,
              onPressed: controller.requestHint,
            ),
        ],
      ),
      body: SafeArea(
        child: controller.isPaused
            ? _PausedOverlay(onResume: controller.resume, label: text.resume)
            : controller.isComplete
                ? _CompletionView(
                    text: text,
                    stars: controller.starsEarned,
                    attempts: controller.attempts,
                    onExit: widget.onExit,
                    onRetry: () {
                      _completionReported = false;
                      controller.retry();
                      widget.onRestart?.call();
                    },
                    onNext: widget.onNext,
                  )
                : Column(
                    children: [
                      if (controller.showHint && content.hint != null)
                        _HintBanner(
                          text: content.hint!,
                          onDismiss: controller.dismissHint,
                        ),
                      if (controller.lastSubmissionCorrect == false)
                        _FeedbackBanner(message: text.tryAgain),
                      Expanded(
                        child: content.mode == SequenceMode.reorder
                            ? _ReorderBody(
                                controller: controller,
                                text: text,
                              )
                            : _MissingItemBody(
                                controller: controller,
                                text: text,
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: content.mode == SequenceMode.reorder
                              ? controller.submitReorder
                              : controller.submitMissingItems,
                          child: Text(text.check),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _ReorderBody extends StatelessWidget {
  const _ReorderBody({required this.controller, required this.text});
  final SequenceController controller;
  final SequenceScreenText text;

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
              label: text.moveItem(item.content),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: text.moveLeft,
                    onPressed: index > 0
                        ? () => controller.moveItem(index, index - 1)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: text.moveRight,
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
  const _MissingItemBody({required this.controller, required this.text});
  final SequenceController controller;
  final SequenceScreenText text;

  @override
  Widget build(BuildContext context) {
    final content = controller.content;
    final allChoices = [
      for (final index in content.missingIndices) content.correctOrder[index],
      ...content.choices,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < content.correctOrder.length; i++)
                if (content.missingIndices.contains(i))
                  _BlankSlot(
                    index: i,
                    selected: controller.selectedMissingIndex == i,
                    selectedContent: _contentFor(
                      controller.missingSelections[i],
                      allChoices,
                    ),
                    label: text.blankSlot(i),
                    onTap: () => controller.selectMissingIndex(i),
                  )
                else
                  Chip(label: Text(content.correctOrder[i].content)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final choice in allChoices)
                Semantics(
                  button: true,
                  label: text.choose(choice.content),
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final target = controller.selectedMissingIndex ??
                            content.missingIndices.first;
                        controller.selectForMissingIndex(target, choice.id);
                      },
                      child: Text(choice.content),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
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
  const _BlankSlot({
    required this.index,
    required this.selected,
    required this.selectedContent,
    required this.label,
    required this.onTap,
  });
  final int index;
  final bool selected;
  final String? selectedContent;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 56, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(selectedContent ?? '?'),
        ),
      ),
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
  const _PausedOverlay({required this.onResume, required this.label});
  final VoidCallback onResume;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: onResume,
        icon: const Icon(Icons.play_arrow),
        label: Text(label),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({
    required this.text,
    required this.stars,
    required this.attempts,
    required this.onExit,
    required this.onRetry,
    required this.onNext,
  });

  final SequenceScreenText text;
  final int stars;
  final int attempts;
  final VoidCallback onExit;
  final VoidCallback onRetry;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: text.stars(stars),
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
          Text(text.completed(attempts)),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(onPressed: onRetry, child: Text(text.replay)),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onNext ?? onExit,
                child: Text(onNext == null ? text.exit : text.next),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SequenceScreenText {
  const SequenceScreenText({
    required this.check,
    required this.exit,
    required this.next,
    required this.pause,
    required this.resume,
    required this.hint,
    required this.replay,
    required this.contentUnavailable,
    required this.moveLeft,
    required this.moveRight,
    required this.tryAgain,
    required this.choose,
    required this.moveItem,
    required this.blankSlot,
    required this.stars,
    required this.completed,
  });

  factory SequenceScreenText.forLocale(String locale) {
    final isEnglish = locale == 'en';
    return SequenceScreenText(
      check: isEnglish ? 'Check' : 'Kiểm tra',
      exit: isEnglish ? 'Exit' : 'Thoát',
      next: isEnglish ? 'Next' : 'Tiếp theo',
      pause: isEnglish ? 'Pause' : 'Tạm dừng',
      resume: isEnglish ? 'Resume' : 'Tiếp tục',
      hint: isEnglish ? 'Hint' : 'Gợi ý',
      replay: isEnglish ? 'Play again' : 'Chơi lại',
      contentUnavailable:
          isEnglish ? 'Content is unavailable.' : 'Nội dung không khả dụng.',
      moveLeft: isEnglish ? 'Move left' : 'Di chuyển sang trái',
      moveRight: isEnglish ? 'Move right' : 'Di chuyển sang phải',
      tryAgain: isEnglish
          ? 'Not quite in order. Try again!'
          : 'Chưa đúng thứ tự, thử lại nhé!',
      choose: (content) => isEnglish ? 'Choose $content' : 'Chọn $content',
      moveItem: (content) => isEnglish ? 'Move $content' : 'Di chuyển $content',
      blankSlot: (index) => isEnglish
          ? 'Blank ${index + 1}, tap to fill'
          : 'Ô trống ${index + 1}, chạm để điền',
      stars: (count) => isEnglish ? '$count of 3 stars' : '$count trên 3 sao',
      completed: (attempts) => isEnglish
          ? 'Completed in $attempts attempt${attempts == 1 ? '' : 's'}!'
          : 'Hoàn thành sau $attempts lượt thử!',
    );
  }

  final String check;
  final String exit;
  final String next;
  final String pause;
  final String resume;
  final String hint;
  final String replay;
  final String contentUnavailable;
  final String moveLeft;
  final String moveRight;
  final String tryAgain;
  final String Function(String content) choose;
  final String Function(String content) moveItem;
  final String Function(int index) blankSlot;
  final String Function(int count) stars;
  final String Function(int attempts) completed;
}
