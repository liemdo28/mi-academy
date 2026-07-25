// Simulation Engine — screen renderer for observe-predict-test-explain.
//
// Guides the child through the science process cycle with clear phase
// indicators, variable controls, prediction cards, and result display.

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'simulation_content.dart';
import 'simulation_controller.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({
    super.key,
    required this.rawContent,
    required this.onExit,
    this.onComplete,
    this.reducedMotion = false,
    this.soundEnabled = true,
  });

  final Map<String, dynamic> rawContent;
  final VoidCallback onExit;
  final void Function(SimulationCompletionResult)? onComplete;
  final bool reducedMotion;
  final bool soundEnabled;

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class SimulationCompletionResult {
  const SimulationCompletionResult({
    required this.contentId,
    required this.starsEarned,
    required this.predictionCorrect,
  });

  final String contentId;
  final int starsEarned;
  final bool predictionCorrect;
}

class _SimulationScreenState extends State<SimulationScreen> {
  SimulationController? _controller;
  String? _loadError;
  bool _completionReported = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    try {
      final content = SimulationContent.fromJson(widget.rawContent);
      final controller = SimulationController(
        content: content,
        reducedMotion: widget.reducedMotion,
        soundEnabled: widget.soundEnabled,
      );
      controller.addListener(_onControllerChanged);
      _controller = controller;
    } catch (e) {
      _loadError = e is SimulationContentException
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
        SimulationCompletionResult(
          contentId: controller.content.contentId,
          starsEarned: controller.starsEarned,
          predictionCorrect: controller.predictionCorrect,
        ),
      );
    }
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
            ? _CenteredButton(
                label: 'Tiếp tục',
                icon: Icons.play_arrow,
                onTap: controller.resume,
              )
            : controller.isComplete
                ? _CompletionView(
                    stars: controller.starsEarned,
                    predictionCorrect: controller.predictionCorrect,
                    onExit: widget.onExit,
                    onRetry: () {
                      _completionReported = false;
                      controller.retry();
                    },
                  )
                : _PhaseView(controller: controller, content: content),
      ),
    );
  }
}

class _PhaseView extends StatelessWidget {
  const _PhaseView({required this.controller, required this.content});
  final SimulationController controller;
  final SimulationContent content;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PhaseIndicator(phase: controller.phase),
          const SizedBox(height: 16),
          if (controller.showHint && content.hint != null)
            _HintBanner(text: content.hint!, onDismiss: controller.dismissHint),
          switch (controller.phase) {
            SimPhase.observe => _ObserveView(controller: controller),
            SimPhase.predict => _PredictView(controller: controller),
            SimPhase.test => _TestView(controller: controller),
            SimPhase.explain => _ExplainView(controller: controller),
            SimPhase.complete => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }
}

class _PhaseIndicator extends StatelessWidget {
  const _PhaseIndicator({required this.phase});
  final SimPhase phase;

  @override
  Widget build(BuildContext context) {
    final stepNum = switch (phase) {
      SimPhase.observe => 1,
      SimPhase.predict => 2,
      SimPhase.test => 3,
      SimPhase.explain => 4,
      SimPhase.complete => 4,
    };
    return Semantics(
      header: true,
      child: Row(
        children: List.generate(4, (i) {
          final active = i < stepNum;
          final current = i == stepNum - 1;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 6,
              decoration: BoxDecoration(
                color: current
                    ? Theme.of(context).colorScheme.primary
                    : active
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5)
                        : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ObserveView extends StatelessWidget {
  const _ObserveView({required this.controller});
  final SimulationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hãy quan sát:',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(controller.content.observeDescription),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.startPrediction,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Tiếp tục'),
          ),
        ),
      ],
    );
  }
}

class _PredictView extends StatelessWidget {
  const _PredictView({required this.controller});
  final SimulationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Điều gì sẽ xảy ra?',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final choice in controller.content.predictionChoices) ...[
          Card(
            color: controller.selectedPredictionId == choice.id
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Text(choice.label),
              trailing: controller.selectedPredictionId == choice.id
                  ? const Icon(Icons.check_circle)
                  : null,
              onTap: () => controller.selectPrediction(choice.id),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: controller.selectedPredictionId != null
                ? controller.confirmPrediction
                : null,
            icon: const Icon(Icons.science),
            label: const Text('Thử nghiệm'),
          ),
        ),
      ],
    );
  }
}

class _TestView extends StatelessWidget {
  const _TestView({required this.controller});
  final SimulationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thay đổi và quan sát:',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final variable in controller.content.variables) ...[
          Text(variable.label),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              for (final value in variable.values)
                ChoiceChip(
                  label: Text(value),
                  selected: controller.state[variable.id] == value,
                  onSelected: (_) => controller.setVariable(variable.id, value),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: controller.runSimulation,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Xem kết quả'),
          ),
        ),
      ],
    );
  }
}

class _ExplainView extends StatelessWidget {
  const _ExplainView({required this.controller});
  final SimulationController controller;

  @override
  Widget build(BuildContext context) {
    final result = controller.lastRunResult;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result != null) ...[
          Card(
            color: result.predictionWasCorrect
                ? Colors.green.withValues(alpha: 0.15)
                : Colors.orange.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    result.predictionWasCorrect
                        ? Icons.check_circle
                        : Icons.lightbulb,
                    size: 32,
                    color: result.predictionWasCorrect
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.predictionWasCorrect
                          ? 'Dự đoán đúng!'
                          : 'Kết quả khác với dự đoán.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Giải thích:',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(controller.content.explanation),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.finishExplanation,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Hoàn thành'),
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

class _CenteredButton extends StatelessWidget {
  const _CenteredButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({
    required this.stars,
    required this.predictionCorrect,
    required this.onExit,
    required this.onRetry,
  });

  final int stars;
  final bool predictionCorrect;
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
          Text(predictionCorrect ? 'Tuyệt vời!' : 'Cố gắng lên!'),
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
