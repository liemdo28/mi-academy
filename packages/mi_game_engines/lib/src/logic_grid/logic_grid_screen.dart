// Logic Grid Engine — screen renderer for deduction puzzles.
//
// Renders clues, a grid of category pairs, and mark controls (yes/no/empty).
// Children tap cells to cycle marks and solve the puzzle through deduction.

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'logic_grid_content.dart';
import 'logic_grid_controller.dart';

class LogicGridScreen extends StatefulWidget {
  const LogicGridScreen({
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
  final void Function(LogicGridCompletionResult)? onComplete;
  final void Function(int attempts, int correctMarks)? onSaveProgress;
  final bool reducedMotion;
  final bool soundEnabled;

  @override
  State<LogicGridScreen> createState() => _LogicGridScreenState();
}

class LogicGridCompletionResult {
  const LogicGridCompletionResult({
    required this.contentId,
    required this.attempts,
    required this.starsEarned,
  });

  final String contentId;
  final int attempts;
  final int starsEarned;
}

class _LogicGridScreenState extends State<LogicGridScreen> {
  LogicGridController? _controller;
  String? _loadError;
  bool _completionReported = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    try {
      final content = LogicGridContent.fromJson(widget.rawContent);
      final controller = LogicGridController(
        content: content,
        reducedMotion: widget.reducedMotion,
        soundEnabled: widget.soundEnabled,
      );
      controller.addListener(_onControllerChanged);
      _controller = controller;
      _loadError = null;
    } catch (e) {
      _loadError = e is LogicGridContentException
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
        LogicGridCompletionResult(
          contentId: controller.content.contentId,
          attempts: controller.attempts,
          starsEarned: controller.starsEarned,
        ),
      );
    }
    widget.onSaveProgress?.call(controller.attempts, controller.correctMarks);
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
                : _PuzzleView(
                    controller: controller,
                    content: content,
                    reducedMotion: widget.reducedMotion,
                  ),
      ),
    );
  }
}

class _PuzzleView extends StatelessWidget {
  const _PuzzleView({
    required this.controller,
    required this.content,
    required this.reducedMotion,
  });

  final LogicGridController controller;
  final LogicGridContent content;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 48 : 16,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              _CluesCard(content: content),
              const SizedBox(height: 16),
              _GridSection(controller: controller, content: content),
            ],
          ),
        );
      },
    );
  }
}

class _CluesCard extends StatelessWidget {
  const _CluesCard({required this.content});
  final LogicGridContent content;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manh mối',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final clue in content.clues) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      clue.isPositive ? Icons.check_circle_outline : Icons.block,
                      size: 20,
                      color: clue.isPositive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(clue.text)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GridSection extends StatelessWidget {
  const _GridSection({required this.controller, required this.content});
  final LogicGridController controller;
  final LogicGridContent content;

  @override
  Widget build(BuildContext context) {
    // For simplicity with 2-3 categories, render pairwise grids.
    // Category 0 is the "row header", paired against each other category.
    final rowCategory = content.categories.first;
    final colCategories = content.categories.skip(1).toList();

    // Collect row values from the solution.
    final rowValues = <String>{};
    for (final p in content.solution) {
      if (p.categoryA == rowCategory) {
        rowValues.add(p.valueA);
      } else if (p.categoryB == rowCategory) {
        rowValues.add(p.valueB);
      }
    }
    final rows = rowValues.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final colCat in colCategories) ...[
          Text(
            '$rowCategory × $colCat',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _PairwiseGrid(
            controller: controller,
            rowCategory: rowCategory,
            rows: rows,
            colCategory: colCat,
            content: content,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _PairwiseGrid extends StatelessWidget {
  const _PairwiseGrid({
    required this.controller,
    required this.rowCategory,
    required this.rows,
    required this.colCategory,
    required this.content,
  });

  final LogicGridController controller;
  final String rowCategory;
  final List<String> rows;
  final String colCategory;
  final LogicGridContent content;

  @override
  Widget build(BuildContext context) {
    // Collect column values from the solution.
    final colValues = <String>{};
    for (final p in content.solution) {
      if (p.categoryA == colCategory) {
        colValues.add(p.valueA);
      } else if (p.categoryB == colCategory) {
        colValues.add(p.valueB);
      }
    }
    final cols = colValues.toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // Header row
            Row(
              children: [
                const SizedBox(width: 80),
                for (final col in cols)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Semantics(
                        header: true,
                        label: '$colCategory: $col',
                        child: Text(
                          col,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            for (final row in rows)
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Semantics(
                      header: true,
                      label: '$rowCategory: $row',
                      child: Text(
                        row,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  for (final col in cols)
                    Expanded(
                      child: _GridCell(
                        controller: controller,
                        pairing: LogicGridPairing(
                          categoryA: rowCategory,
                          valueA: row,
                          categoryB: colCategory,
                          valueB: col,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({required this.controller, required this.pairing});
  final LogicGridController controller;
  final LogicGridPairing pairing;

  @override
  Widget build(BuildContext context) {
    final mark = controller.markFor(pairing);
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Semantics(
        button: true,
        label:
            '${pairing.valueA} và ${pairing.valueB}: ${_markLabel(mark)}',
        child: InkWell(
          onTap: () => controller.toggleMark(pairing),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration:
                controller.reducedMotion ? Duration.zero : _kAnimDuration,
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              color: _markColor(mark),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Icon(
                _markIcon(mark),
                size: 24,
                color: mark == LogicGridMark.empty ? Colors.grey : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _markColor(LogicGridMark mark) {
    return switch (mark) {
      LogicGridMark.yes => Colors.green.withValues(alpha: 0.3),
      LogicGridMark.no => Colors.red.withValues(alpha: 0.2),
      LogicGridMark.empty => Colors.transparent,
    };
  }

  IconData _markIcon(LogicGridMark mark) {
    return switch (mark) {
      LogicGridMark.yes => Icons.check,
      LogicGridMark.no => Icons.close,
      LogicGridMark.empty => Icons.radio_button_unchecked,
    };
  }

  String _markLabel(LogicGridMark mark) {
    return switch (mark) {
      LogicGridMark.yes => 'đúng',
      LogicGridMark.no => 'sai',
      LogicGridMark.empty => 'chưa chọn',
    };
  }
}

const Duration _kAnimDuration = Duration(milliseconds: 150);

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
      label: isCorrect ? 'Chính xác!' : 'Chưa đúng, suy nghĩ thêm nhé!',
      child: Container(
        width: double.infinity,
        color: isCorrect
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.orange.withValues(alpha: 0.15),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          isCorrect ? 'Chính xác!' : 'Chưa đúng, suy nghĩ thêm nhé!',
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
          Text('Giải xong sau $attempts lượt thử!'),
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