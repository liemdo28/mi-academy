import 'package:flutter/material.dart';
import 'package:mi_game_ui/mi_game_ui.dart';
import 'math_race_session.dart';

/// Math Race screen – shows the current question, 4 answer buttons,
/// score bar, streak counter, and feedback overlay.
class MathRaceScreen extends StatefulWidget {
  const MathRaceScreen({
    super.key,
    required this.session,
    required this.locale,
    this.onComplete,
  });

  final MathRaceSession session;
  final String locale;
  final VoidCallback? onComplete;

  @override
  State<MathRaceScreen> createState() => _MathRaceScreenState();
}

class _MathRaceScreenState extends State<MathRaceScreen> {
  MathRaceSession get _session => widget.session;

  @override
  void initState() {
    super.initState();
    // Listen for completion.
    _session.saveSnapshot(); // prime
  }

  @override
  Widget build(BuildContext context) {
    if (_session.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onComplete?.call();
      });
    }

    return GameScaffold(
      title: 'Math Race',
      score: _session.score,
      onHint: _handleHint,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStreakBar(),
            const SizedBox(height: 16),
            _buildQuestionCard(),
            const SizedBox(height: 24),
            _buildOptions(),
            const SizedBox(height: 16),
            _buildFeedback(),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBar() {
    final streak = _session.correctInRow;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.local_fire_department,
            color: streak >= 3 ? Colors.orange : Colors.grey, size: 20),
        const SizedBox(width: 4),
        Text(
          'Streak: $streak',
          style: TextStyle(
            fontSize: 14,
            fontWeight: streak >= 3 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard() {
    final text = _session.questionText(widget.locale);
    return QuestionCard(
      text: text ?? '...',
      questionNumber: _session.currentQuestionIndex + 1,
      totalQuestions: _session.totalQuestions,
    );
  }

  Widget _buildOptions() {
    final q = _session.currentQuestion;
    if (q == null) return const SizedBox.shrink();

    return Expanded(
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: List.generate(q.options.length, (index) {
          return AnswerButton(
            text: q.options[index].text,
            onTap: () => _handleChoose(index),
          );
        }),
      ),
    );
  }

  Widget _buildFeedback() {
    final fb = _session.feedback;
    if (fb == null) return const SizedBox.shrink();

    IconData icon;
    Color color;
    String message;

    switch (fb) {
      case 'correct':
        icon = Icons.check_circle;
        color = Colors.green;
        message = 'Correct!';
      case 'great_streak':
        icon = Icons.star;
        color = Colors.amber;
        message = 'Great streak!';
      case 'try_again':
        icon = Icons.refresh;
        color = Colors.orange;
        message = 'Try again!';
      case 'hint_eliminate':
        icon = Icons.lightbulb;
        color = Colors.blue;
        message = 'One wrong answer removed!';
      default:
        return const SizedBox.shrink();
    }

    return AnimatedFeedback(
      icon: icon,
      color: color,
      message: message,
    );
  }

  void _handleChoose(int index) {
    setState(() {
      _session.choose(index);
    });
  }

  void _handleHint() {
    setState(() {
      _session.showHint();
    });
  }
}
