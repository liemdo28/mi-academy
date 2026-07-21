import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'placement_content.dart';
import 'placement_controller.dart';

/// Every production-facing string [PlacementScreen] needs, supplied by
/// the host so this engine never contains hardcoded Vietnamese or
/// English UI text itself. Sample/example content (tests, docs) may of
/// course construct one of these with explicit Vietnamese or English
/// values -- the constraint is on the engine's own source, not on
/// callers.
class PlacementLocalization {
  const PlacementLocalization({
    required this.exitLabel,
    required this.pauseLabel,
    required this.resumeLabel,
    required this.hintLabel,
    required this.retryLabel,
    required this.completionLabel,
    required this.invalidPlacementMessage,
    required this.malformedContentMessage,
    required this.selectedAnnouncement,
    required this.targetAnnouncement,
    required this.removeLabel,
  });

  final String exitLabel;
  final String pauseLabel;
  final String resumeLabel;
  final String hintLabel;
  final String retryLabel;
  final String completionLabel;
  final String invalidPlacementMessage;
  final String malformedContentMessage;
  final String removeLabel;

  /// Semantics announcement when an item becomes the tap-mode selection.
  final String Function(String itemLabel) selectedAnnouncement;

  /// Semantics label for a target, including its current occupancy.
  final String Function(String targetLabel, int occupied, int capacity)
      targetAnnouncement;
}

/// Renders one Drag-and-drop Placement Engine level end-to-end:
/// instruction, source item tray, target area, drag interaction, full
/// tap-accessibility interaction, hint, pause/exit, completion with
/// stars, and a recoverable error screen for malformed content -- the
/// third of the four Milestone 1 WS5 shared engines, alongside
/// MatchingScreen and SequenceScreen.
class PlacementScreen extends StatefulWidget {
  const PlacementScreen({
    super.key,
    required this.rawContent,
    required this.localization,
    required this.onExit,
    this.onComplete,
    this.onSaveProgress,
    this.reducedMotion = false,
    this.soundEnabled = true,
  });

  final Map<String, dynamic> rawContent;
  final PlacementLocalization localization;
  final VoidCallback onExit;
  final void Function(PlacementResult)? onComplete;
  final void Function(int attempts)? onSaveProgress;
  final bool reducedMotion;
  final bool soundEnabled;

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<PlacementScreen> {
  PlacementController? _controller;
  String? _loadError;
  bool _completionReported = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    try {
      final content = PlacementContent.fromJson(widget.rawContent);
      final controller = PlacementController(
        content: content,
        reducedMotion: widget.reducedMotion,
        soundEnabled: widget.soundEnabled,
      );
      controller.addListener(_onControllerChanged);
      _controller = controller;
      _loadError = null;
    } catch (e) {
      _loadError = widget.localization.malformedContentMessage;
    }
  }

  void _onControllerChanged() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.isComplete && !_completionReported) {
      _completionReported = true;
      widget.onComplete?.call(controller.result);
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
    final loc = widget.localization;
    final error = _loadError;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: loc.exitLabel,
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
                Text(error, textAlign: TextAlign.center),
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
          tooltip: loc.exitLabel,
          onPressed: widget.onExit,
        ),
        title: Text(content.instruction),
        actions: [
          IconButton(
            icon: Icon(controller.isPaused ? Icons.play_arrow : Icons.pause),
            tooltip: controller.isPaused ? loc.resumeLabel : loc.pauseLabel,
            onPressed: () =>
                controller.isPaused ? controller.resume() : controller.pause(),
          ),
          if (content.hint != null)
            IconButton(
              icon: const Icon(Icons.lightbulb_outline),
              tooltip: loc.hintLabel,
              onPressed: controller.requestHint,
            ),
        ],
      ),
      body: SafeArea(
        child: controller.isPaused
            ? _PausedOverlay(
                resumeLabel: loc.resumeLabel, onResume: controller.resume)
            : controller.isComplete
                ? _CompletionView(
                    localization: loc,
                    stars: controller.starsEarned,
                    score: controller.score,
                    onExit: widget.onExit,
                    onRetry: () {
                      _completionReported = false;
                      controller.restart();
                    },
                  )
                : Column(
                    children: [
                      if (controller.showHint && content.hint != null)
                        _HintBanner(
                            text: content.hint!,
                            onDismiss: controller.dismissHint),
                      if (controller.lastAttemptWasCorrect == false)
                        _FeedbackBanner(message: loc.invalidPlacementMessage),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 500;
                            final targetArea = _TargetArea(
                              controller: controller,
                              localization: loc,
                              reducedMotion: widget.reducedMotion,
                            );
                            final sourceArea = _SourceItemArea(
                              controller: controller,
                              localization: loc,
                            );
                            return isNarrow
                                ? Column(
                                    children: [
                                      Expanded(flex: 3, child: targetArea),
                                      const Divider(height: 1),
                                      Expanded(flex: 2, child: sourceArea),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(child: targetArea),
                                      const VerticalDivider(width: 1),
                                      Expanded(child: sourceArea),
                                    ],
                                  );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

const double _kMinTouchSize = 48;
const double _kPreferredTouchSize = 64;

class _TargetArea extends StatelessWidget {
  const _TargetArea({
    required this.controller,
    required this.localization,
    required this.reducedMotion,
  });

  final PlacementController controller;
  final PlacementLocalization localization;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          for (final target in controller.content.targets)
            _TargetSlot(
              target: target,
              controller: controller,
              localization: localization,
              reducedMotion: reducedMotion,
            ),
        ],
      ),
    );
  }
}

class _TargetSlot extends StatelessWidget {
  const _TargetSlot({
    required this.target,
    required this.controller,
    required this.localization,
    required this.reducedMotion,
  });

  final PlacementTarget target;
  final PlacementController controller;
  final PlacementLocalization localization;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final occupancy = controller.occupancyOf(target.id);
    final placed = controller.placedItemsFor(target.id);

    return DragTarget<String>(
      // Always accept the drop itself (rather than gating via
      // `canAccept`) -- an invalid drop must still register as an
      // attempt and produce feedback, not be silently swallowed by
      // Flutter's DragTarget refusing the drop. `canAccept` is used only
      // for the *visual* hover highlight below, via `candidateData`.
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) =>
          controller.placeItem(details.data, target.id),
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;
        final wouldAccept =
            hovering && controller.canAccept(candidateData.first!, target.id);
        final selected = controller.selectedItemId;
        final tapWouldAccept =
            selected != null && controller.canAccept(selected, target.id);
        final highlight = wouldAccept || tapWouldAccept;

        return Semantics(
          label: localization.targetAnnouncement(
            target.label,
            occupancy,
            target.capacity,
          ),
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () {
              final selectedId = controller.selectedItemId;
              if (selectedId != null) {
                controller.placeItem(selectedId, target.id);
              }
            },
            child: AnimatedContainer(
              duration: reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 150),
              constraints: const BoxConstraints(
                minWidth: _kPreferredTouchSize * 1.5,
                minHeight: _kPreferredTouchSize * 1.5,
              ),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: hovering && !wouldAccept
                      ? Colors.red
                      : highlight
                          ? Colors.green
                          : Colors.grey,
                  width: highlight || (hovering && !wouldAccept) ? 3 : 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                color: highlight
                    ? Colors.green.withValues(alpha: 0.12)
                    : hovering && !wouldAccept
                        ? Colors.red.withValues(alpha: 0.08)
                        : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(target.text ?? target.label,
                      textAlign: TextAlign.center),
                  Text('$occupancy/${target.capacity}',
                      style: const TextStyle(fontSize: 12)),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final item in placed)
                        _PlacedItemChip(
                          item: item,
                          controller: controller,
                          localization: localization,
                        ),
                    ],
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

class _PlacedItemChip extends StatelessWidget {
  const _PlacedItemChip({
    required this.item,
    required this.controller,
    required this.localization,
  });
  final PlacementItem item;
  final PlacementController controller;
  final PlacementLocalization localization;

  @override
  Widget build(BuildContext context) {
    final canRemove = controller.content.configuration.allowRemoveFromTarget;
    return Draggable<String>(
      data: item.id,
      feedback: Material(
        color: Colors.transparent,
        child: _ItemChip(item: item, minSize: _kMinTouchSize),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _ItemChip(item: item, minSize: _kMinTouchSize),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () => controller.selectItem(item.id),
            child: _ItemChip(
              item: item,
              minSize: _kMinTouchSize,
              selected: controller.selectedItemId == item.id,
            ),
          ),
          if (canRemove)
            Positioned(
              top: -8,
              right: -8,
              child: SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  tooltip: localization.removeLabel,
                  icon: const CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                  onPressed: () => controller.removeItem(item.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SourceItemArea extends StatelessWidget {
  const _SourceItemArea({required this.controller, required this.localization});
  final PlacementController controller;
  final PlacementLocalization localization;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          for (final item in controller.unplacedItems)
            Draggable<String>(
              data: item.id,
              feedback: Material(
                color: Colors.transparent,
                child: _ItemChip(item: item, minSize: _kPreferredTouchSize),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _ItemChip(item: item, minSize: _kPreferredTouchSize),
              ),
              child: Semantics(
                label: controller.selectedItemId == item.id
                    ? localization.selectedAnnouncement(item.label)
                    : item.label,
                button: true,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => controller.selectItem(item.id),
                  child: _ItemChip(
                    item: item,
                    minSize: _kPreferredTouchSize,
                    selected: controller.selectedItemId == item.id,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  const _ItemChip(
      {required this.item, required this.minSize, this.selected = false});
  final PlacementItem item;
  final double minSize;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: (item.rotationDegrees ?? 0) * 3.1415926535 / 180,
      child: Container(
        constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blue.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.15),
          border: Border.all(
              color: selected ? Colors.blue : Colors.grey.shade400,
              width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(item.text ?? item.label, textAlign: TextAlign.center),
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
        trailing: IconButton(
          key: const Key('placement-hint-dismiss'),
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
  const _PausedOverlay({required this.resumeLabel, required this.onResume});
  final String resumeLabel;
  final VoidCallback onResume;

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
    required this.localization,
    required this.stars,
    required this.score,
    required this.onExit,
    required this.onRetry,
  });

  final PlacementLocalization localization;
  final int stars;
  final int score;
  final VoidCallback onExit;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: '${localization.completionLabel}: $stars/3',
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
          Text(localization.completionLabel),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                  onPressed: onRetry, child: Text(localization.retryLabel)),
              const SizedBox(width: 12),
              ElevatedButton(
                  onPressed: onExit, child: Text(localization.exitLabel)),
            ],
          ),
        ],
      ),
    );
  }
}
