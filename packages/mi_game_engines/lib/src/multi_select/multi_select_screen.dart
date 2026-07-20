import 'package:flutter/material.dart';

import 'multi_select_content.dart';
import 'multi_select_controller.dart';

/// Every production-facing string [MultiSelectScreen] needs, supplied by
/// the host so this engine never contains hardcoded Vietnamese or
/// English UI text itself -- same convention as PlacementLocalization.
/// Sample/example content (tests, docs) may construct one of these with
/// explicit Vietnamese or English values.
class MultiSelectLocalization {
  const MultiSelectLocalization({
    required this.exitLabel,
    required this.pauseLabel,
    required this.resumeLabel,
    required this.submitLabel,
    required this.checkAnswersLabel,
    required this.clearLabel,
    required this.retryLabel,
    required this.completionLabel,
    required this.authorHintLabel,
    required this.hintLabel,
    required this.revealCorrectLabel,
    required this.revealAnswersLabel,
    required this.eliminateIncorrectLabel,
    required this.noMoreHintsLabel,
    required this.malformedContentMessage,
    required this.incorrectMessage,
    required this.correctMessage,
    required this.partiallyCorrectMessage,
    required this.tryAgainMessage,
    required this.minimumSelectionRequiredMessage,
    required this.maximumSelectionReachedMessage,
    required this.selectionCountMessage,
    required this.optionAnnouncement,
    required this.optionSelectedAnnouncement,
    required this.optionDeselectedAnnouncement,
    required this.correctOptionAnnouncement,
    required this.incorrectOptionAnnouncement,
  });

  final String exitLabel;
  final String pauseLabel;
  final String resumeLabel;
  final String submitLabel;
  final String checkAnswersLabel;
  final String clearLabel;
  final String retryLabel;
  final String completionLabel;
  final String authorHintLabel;
  final String hintLabel;
  final String revealCorrectLabel;
  final String revealAnswersLabel;
  final String eliminateIncorrectLabel;
  final String noMoreHintsLabel;
  final String malformedContentMessage;
  final String incorrectMessage;
  final String correctMessage;
  final String partiallyCorrectMessage;
  final String tryAgainMessage;
  final String minimumSelectionRequiredMessage;
  final String maximumSelectionReachedMessage;

  /// e.g. "Select between 2 and 3 answers" -- built from the configured
  /// min/max so the child knows how many to pick.
  final String Function(int min, int max) selectionCountMessage;

  /// Semantics announcement for one option, given its label and whether
  /// it is currently selected.
  final String Function(String label, bool selected) optionAnnouncement;
  final String Function(String label) optionSelectedAnnouncement;
  final String Function(String label) optionDeselectedAnnouncement;
  final String Function(String label) correctOptionAnnouncement;
  final String Function(String label) incorrectOptionAnnouncement;
}

/// Renders one Multi-select Engine level end-to-end: instruction,
/// option grid (text/image/mixed), explicit or automatic submit, three
/// distinct hint actions, pause/exit, completion with stars, and a
/// recoverable error screen for malformed content -- the fourth and
/// final Milestone 1 WS5 shared engine, alongside MatchingScreen,
/// SequenceScreen, and PlacementScreen.
class MultiSelectScreen extends StatefulWidget {
  const MultiSelectScreen({
    super.key,
    required this.rawContent,
    required this.localization,
    required this.onExit,
    this.onComplete,
    this.onSaveProgress,
    this.initialState,
    this.onSaveState,
    this.reducedMotion = false,
    this.soundEnabled = true,
  });

  final Map<String, dynamic> rawContent;
  final MultiSelectLocalization localization;
  final VoidCallback onExit;
  final void Function(MultiSelectResult)? onComplete;
  final void Function(int attempts)? onSaveProgress;
  final Map<String, dynamic>? initialState;
  final void Function(Map<String, dynamic> state)? onSaveState;
  final bool reducedMotion;
  final bool soundEnabled;

  @override
  State<MultiSelectScreen> createState() => _MultiSelectScreenState();
}

class _MultiSelectScreenState extends State<MultiSelectScreen> {
  MultiSelectController? _controller;
  String? _loadError;
  bool _completionReported = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    try {
      final content = MultiSelectContent.fromJson(widget.rawContent);
      final controller = MultiSelectController(
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
    final config = content.configuration;

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
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: loc.revealCorrectLabel,
            onPressed: controller.revealCorrectOption,
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: loc.eliminateIncorrectLabel,
            onPressed: controller.eliminateIncorrectOption,
          ),
        ],
      ),
      body: SafeArea(
        child: controller.isPaused
            ? _PausedOverlay(
                resumeLabel: loc.resumeLabel,
                onResume: controller.resume,
              )
            : controller.isComplete
                ? _CompletionView(
                    localization: loc,
                    stars: controller.starsEarned,
                    onExit: widget.onExit,
                    onRetry: () {
                      _completionReported = false;
                      controller.retry();
                    },
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (config.showSelectionCount)
                              Text(
                                loc.selectionCountMessage(
                                  config.minimumSelections,
                                  config.maximumSelections,
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            const SizedBox(height: 8),
                            Text(
                              content.prompt,
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      if (controller.showAuthorHint && content.hint != null)
                        _HintBanner(
                          text: content.hint!,
                          onDismiss: controller.dismissAuthorHint,
                        ),
                      if (controller.validationFeedback !=
                          MultiSelectFeedbackCode.none)
                        _FeedbackBanner(
                          message: _feedbackMessage(
                            controller.validationFeedback,
                            loc,
                          ),
                        ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final option in controller.orderedOptions)
                                _OptionTile(
                                  option: option,
                                  controller: controller,
                                  localization: loc,
                                  reducedMotion: widget.reducedMotion,
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (config.submitMode ==
                          MultiSelectSubmitMode.explicitSubmit)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton(
                                onPressed: controller.clear,
                                child: Text(loc.clearLabel),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: controller.submit,
                                child: Text(loc.checkAnswersLabel),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  String _feedbackMessage(
    MultiSelectFeedbackCode code,
    MultiSelectLocalization loc,
  ) =>
      switch (code) {
        MultiSelectFeedbackCode.minimumSelectionRequired =>
          loc.minimumSelectionRequiredMessage,
        MultiSelectFeedbackCode.maximumSelectionReached =>
          loc.maximumSelectionReachedMessage,
        MultiSelectFeedbackCode.deselectDisabled => loc.tryAgainMessage,
        MultiSelectFeedbackCode.incorrect => loc.incorrectMessage,
        MultiSelectFeedbackCode.correct => loc.correctMessage,
        MultiSelectFeedbackCode.noMoreHints => loc.noMoreHintsLabel,
        MultiSelectFeedbackCode.none => '',
      };
}

const double _kMinTouchSize = 48;

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.controller,
    required this.localization,
    required this.reducedMotion,
  });

  final MultiSelectOption option;
  final MultiSelectController controller;
  final MultiSelectLocalization localization;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final selected = controller.isSelected(option.id);
    final eliminated = controller.isEliminated(option.id);
    final revealed = controller.revealedCorrectIds.contains(option.id);

    return Semantics(
      label: localization.optionAnnouncement(option.accessibleLabel, selected),
      button: true,
      enabled: !eliminated,
      selected: selected,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: _kMinTouchSize,
          minHeight: _kMinTouchSize,
        ),
        child: FilterChip(
          avatar: option.assetId != null
              ? const Icon(Icons.image_outlined, size: 18)
              : null,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(option.displayText)),
              if (selected) const SizedBox(width: 6),
              if (selected) const Icon(Icons.check, size: 16),
            ],
          ),
          selected: selected,
          onSelected:
              eliminated ? null : (_) => controller.toggleOption(option.id),
          showCheckmark: true,
          side: revealed
              ? const BorderSide(color: Colors.green, width: 2)
              : eliminated
                  ? BorderSide(color: Colors.grey.shade400)
                  : null,
          backgroundColor:
              eliminated ? Colors.grey.withValues(alpha: 0.15) : null,
          disabledColor: Colors.grey.withValues(alpha: 0.15),
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
        trailing: IconButton(
          key: const Key('multi-select-hint-dismiss'),
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
    required this.onExit,
    required this.onRetry,
  });

  final MultiSelectLocalization localization;
  final int stars;
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
                (i) => Icon(
                  i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(localization.completionLabel),
          const SizedBox(height: 20),
          if (stars == 0) Text(localization.tryAgainMessage),
          if (stars == 0) const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: onRetry,
                child: Text(localization.retryLabel),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onExit,
                child: Text(localization.exitLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
