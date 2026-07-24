import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:mi_game_core/mi_game_core.dart';

import 'choice_game_session.dart';

class ChoiceVisualBoard extends StatelessWidget {
  const ChoiceVisualBoard({
    super.key,
    required this.level,
    required this.content,
    required this.options,
    required this.color,
    required this.locale,
  });

  final MiLevel level;
  final Map<String, dynamic> content;
  final List<ChoiceGameOption> options;
  final Color color;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final builder = _builderFor(level.gameId);
    if (builder == null) return const SizedBox.shrink();

    final title = _titleFor(level.gameId);
    final child = builder(context);
    return Semantics(
      label: title,
      child: Container(
        key: ValueKey('choice-visual-board-${level.gameId}'),
        padding: const EdgeInsets.all(MiTokens.space4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MiTokens.radiusLg),
          border: Border.all(color: color.withValues(alpha: 0.18), width: 2),
          boxShadow: MiShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MiCharacterHead(size: 36, semanticLabel: title),
                const SizedBox(width: MiTokens.space3),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MiTokens.space4),
            child,
          ],
        ),
      ),
    );
  }

  Widget Function(BuildContext)? _builderFor(String gameId) {
    switch (gameId) {
      case 'clock_time':
        return (_) => _ClockBoard(
              color: color,
              hour: _correctHour(),
              locale: locale,
            );
      case 'object_counting':
      case 'number_quantity_match':
        return (_) => _CountingBoard(
              color: color,
              count: _correctNumber(),
              locale: locale,
            );
      case 'math_race':
      case 'math_supermarket':
      case 'multiplication_adventure':
      case 'treasure_division':
        return (_) => _MathBoard(
              color: color,
              numbers: _numbersFromPrompt().take(4).toList(),
              answer: _correctText(),
            );
      case 'greater_less':
        return (_) =>
            _CompareBoard(color: color, numbers: _numbersFromPrompt());
      case 'number_sequence':
      case 'pattern_finder':
      case 'sentence_order':
        return (_) => _SequenceBoard(
              color: color,
              prompt: _prompt,
              answer: _correctText(),
              locale: locale,
            );
      case 'visual_fractions':
        return (_) => _FractionBoard(
              color: color,
              text: _correctText(),
              locale: locale,
            );
      case 'shape_builder':
      case 'odd_one_out':
      case 'shadow_match':
        return (_) => _ShapeBoard(
              color: color,
              answer: _correctText(),
              locale: locale,
            );
      case 'alphabet_explorer':
      case 'missing_letter':
      case 'picture_word_match':
      case 'rhyme_picker':
      case 'speed_spelling':
        return (_) => _LetterBoard(color: color, answer: _correctText());
    }
    return null;
  }

  String _titleFor(String gameId) {
    final en = locale == 'en';
    switch (gameId) {
      case 'clock_time':
        return en ? 'Look at the clock' : 'Nhìn đồng hồ';
      case 'object_counting':
      case 'number_quantity_match':
        return en ? 'Count with MI' : 'Cùng MI đếm';
      case 'greater_less':
        return en ? 'Compare the numbers' : 'So sánh hai số';
      case 'number_sequence':
      case 'pattern_finder':
      case 'sentence_order':
        return en ? 'Find the pattern' : 'Tìm quy luật';
      case 'visual_fractions':
        return en ? 'See equal parts' : 'Nhìn phần bằng nhau';
      case 'shape_builder':
      case 'odd_one_out':
      case 'shadow_match':
        return en ? 'Look at the shapes' : 'Nhìn các hình';
      case 'alphabet_explorer':
      case 'missing_letter':
      case 'picture_word_match':
      case 'rhyme_picker':
      case 'speed_spelling':
        return en ? 'Read the clue' : 'Đọc gợi ý';
      default:
        return en ? 'Puzzle board' : 'Bảng trò chơi';
    }
  }

  String get _prompt => content['prompt'] as String? ?? '';

  String _correctText() {
    for (final option in options) {
      if (option.correct) return option.text;
    }
    return '';
  }

  int _correctNumber() {
    final match = RegExp(r'\d+').firstMatch(_correctText());
    return int.tryParse(match?.group(0) ?? '') ??
        level.levelNumber.clamp(1, 10).toInt();
  }

  int _correctHour() {
    final match = RegExp(r'(\d{1,2})\s*:').firstMatch(_correctText());
    final hour = int.tryParse(match?.group(1) ?? '') ?? _correctNumber();
    return hour == 0 ? 12 : ((hour - 1) % 12) + 1;
  }

  List<int> _numbersFromPrompt() {
    return RegExp(r'\d+')
        .allMatches(_prompt)
        .map((match) => int.tryParse(match.group(0) ?? ''))
        .whereType<int>()
        .toList(growable: false);
  }
}

class _CountingBoard extends StatelessWidget {
  const _CountingBoard({
    required this.color,
    required this.count,
    required this.locale,
  });

  final Color color;
  final int count;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final safeCount = count.clamp(1, 20);
    final rows = (safeCount / 5).ceil();
    return Column(
      children: [
        for (var row = 0; row < rows; row += 1)
          Padding(
            padding: const EdgeInsets.only(bottom: MiTokens.space2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var col = 0; col < 5; col += 1)
                  if (row * 5 + col < safeCount)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MiTokens.space1,
                      ),
                      child: _SoftShape(index: row * 5 + col, color: color),
                    )
                  else
                    const SizedBox(width: 50),
              ],
            ),
          ),
        _MiniLabel(
          text: locale == 'en' ? 'Counted: $safeCount' : 'Đã đếm: $safeCount',
          color: color,
        ),
      ],
    );
  }
}

class _MathBoard extends StatelessWidget {
  const _MathBoard({
    required this.color,
    required this.numbers,
    required this.answer,
  });

  final Color color;
  final List<int> numbers;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final values = numbers.isEmpty ? [1, 2] : numbers;
    return Row(
      children: [
        for (var i = 0; i < values.length; i += 1) ...[
          Expanded(
            child: _NumberTile(number: values[i], color: color),
          ),
          if (i < values.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MiTokens.space1),
              child: Text('+', style: Theme.of(context).textTheme.titleLarge),
            ),
        ],
        const SizedBox(width: MiTokens.space2),
        Expanded(
          child: _AnswerTile(answer: answer, color: color),
        ),
      ],
    );
  }
}

class _CompareBoard extends StatelessWidget {
  const _CompareBoard({required this.color, required this.numbers});

  final Color color;
  final List<int> numbers;

  @override
  Widget build(BuildContext context) {
    final left = numbers.isNotEmpty ? numbers[0] : 3;
    final right = numbers.length > 1 ? numbers[1] : 5;
    return Row(
      children: [
        Expanded(child: _NumberTile(number: left, color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MiTokens.space3),
          child: Icon(
            left == right
                ? Icons.drag_handle_rounded
                : left > right
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
            size: 48,
            color: color,
          ),
        ),
        Expanded(child: _NumberTile(number: right, color: color)),
      ],
    );
  }
}

class _SequenceBoard extends StatelessWidget {
  const _SequenceBoard({
    required this.color,
    required this.prompt,
    required this.answer,
    required this.locale,
  });

  final Color color;
  final String prompt;
  final String answer;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final parts = RegExp(r'[^\s,.;:!?]+|\?')
        .allMatches(prompt)
        .map((match) => match.group(0)!)
        .where((part) => part.length <= 8)
        .take(5)
        .toList();
    final chips = parts.isEmpty ? ['A', 'B', '?'] : parts;
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: MiTokens.space2,
          runSpacing: MiTokens.space2,
          children: [
            for (final chip in chips)
              _TokenChip(
                text: chip == '?' ? '?' : chip,
                color: chip == '?' ? color : MiColors.discovery,
                outlined: chip != '?',
              ),
          ],
        ),
        const SizedBox(height: MiTokens.space3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MiniLabel(
              text: locale == 'en' ? 'Best fit' : 'Điền vào chỗ trống',
              color: color,
            ),
            const SizedBox(width: MiTokens.space2),
            Flexible(child: _AnswerTile(answer: answer, color: color)),
          ],
        ),
      ],
    );
  }
}

class _FractionBoard extends StatelessWidget {
  const _FractionBoard({
    required this.color,
    required this.text,
    required this.locale,
  });

  final Color color;
  final String text;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final match = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(text);
    final numerator = int.tryParse(match?.group(1) ?? '') ?? 1;
    final denominator = int.tryParse(match?.group(2) ?? '') ?? 2;
    final parts = denominator.clamp(2, 8);
    final filled = numerator.clamp(1, parts);
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < parts; i += 1)
              Expanded(
                child: Container(
                  height: 72,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i < filled ? color : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(MiTokens.radiusMd),
                    border: Border.all(color: color.withValues(alpha: 0.22)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: MiTokens.space3),
        _MiniLabel(
          text: locale == 'en'
              ? '$filled of $parts equal parts'
              : '$filled trong $parts phần bằng nhau',
          color: color,
        ),
      ],
    );
  }
}

class _ShapeBoard extends StatelessWidget {
  const _ShapeBoard({
    required this.color,
    required this.answer,
    required this.locale,
  });

  final Color color;
  final String answer;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ShapeGlyph(shape: _ShapeKind.circle, color: color),
            const _ShapeGlyph(
                shape: _ShapeKind.square, color: MiColors.discovery),
            const _ShapeGlyph(
                shape: _ShapeKind.triangle, color: MiColors.accent),
          ],
        ),
        const SizedBox(height: MiTokens.space3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MiniLabel(
              text: locale == 'en' ? 'Match' : 'Chọn hình',
              color: color,
            ),
            const SizedBox(width: MiTokens.space2),
            Flexible(child: _AnswerTile(answer: answer, color: color)),
          ],
        ),
      ],
    );
  }
}

class _LetterBoard extends StatelessWidget {
  const _LetterBoard({required this.color, required this.answer});

  final Color color;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final letters = answer.isEmpty
        ? ['M', 'I']
        : answer.characters.take(5).map((char) => char.toUpperCase()).toList();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: MiTokens.space2,
      runSpacing: MiTokens.space2,
      children: [
        for (final letter in letters) _TokenChip(text: letter, color: color),
      ],
    );
  }
}

class _ClockBoard extends StatelessWidget {
  const _ClockBoard({
    required this.color,
    required this.hour,
    required this.locale,
  });

  final Color color;
  final int hour;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 148,
          height: 148,
          child: CustomPaint(
            painter: _ClockPainter(color: color, hour: hour),
          ),
        ),
        const SizedBox(height: MiTokens.space3),
        _MiniLabel(
          text: locale == 'en' ? '$hour o’clock' : '$hour giờ đúng',
          color: color,
        ),
      ],
    );
  }
}

class _ClockPainter extends CustomPainter {
  const _ClockPainter({required this.color, required this.hour});

  final Color color;
  final int hour;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final face = Paint()..color = Colors.white;
    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius - 4, face);
    canvas.drawCircle(center, radius - 4, border);

    final tick = Paint()
      ..color = MiColors.navy
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i += 1) {
      final angle = (math.pi * 2 * i / 12) - math.pi / 2;
      final outer =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 16);
      final inner =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 26);
      canvas.drawLine(inner, outer, tick);
    }

    final hourAngle = (math.pi * 2 * (hour % 12) / 12) - math.pi / 2;
    final hand = Paint()
      ..color = MiColors.navy
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      center +
          Offset(math.cos(hourAngle), math.sin(hourAngle)) * (radius * 0.45),
      hand,
    );
    canvas.drawLine(
      center,
      center + const Offset(0, -1) * (radius * 0.62),
      Paint()
        ..color = color
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 7, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.hour != hour;
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({required this.number, required this.color});

  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(MiTokens.radiusLg),
      ),
      child: Text(
        '$number',
        style:
            Theme.of(context).textTheme.headlineLarge?.copyWith(color: color),
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({required this.answer, required this.color});

  final String answer;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72, minWidth: 72),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: MiTokens.space3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(MiTokens.radiusLg),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          answer.isEmpty ? '?' : answer,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: MiTokens.touchTargetParent),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: MiTokens.space4,
        vertical: MiTokens.space2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(MiTokens.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
        textAlign: TextAlign.center,
      ),
    );
  }
}

enum _ShapeKind { circle, square, triangle }

class _ShapeGlyph extends StatelessWidget {
  const _ShapeGlyph({
    required this.shape,
    required this.color,
  });

  final _ShapeKind shape;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _ShapeGlyphPainter(shape: shape, color: color),
      ),
    );
  }
}

class _ShapeGlyphPainter extends CustomPainter {
  const _ShapeGlyphPainter({required this.shape, required this.color});

  final _ShapeKind shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final outline = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round;
    final rect = Offset.zero & size;
    switch (shape) {
      case _ShapeKind.circle:
        canvas.drawCircle(rect.center, size.shortestSide * 0.38, paint);
        canvas.drawCircle(rect.center, size.shortestSide * 0.38, outline);
      case _ShapeKind.square:
        final rrect = RRect.fromRectAndRadius(
          rect.deflate(10),
          const Radius.circular(MiTokens.radiusMd),
        );
        canvas.drawRRect(rrect, paint);
        canvas.drawRRect(rrect, outline);
      case _ShapeKind.triangle:
        final path = Path()
          ..moveTo(size.width / 2, 8)
          ..lineTo(size.width - 8, size.height - 8)
          ..lineTo(8, size.height - 8)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, outline);
    }
  }

  @override
  bool shouldRepaint(covariant _ShapeGlyphPainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.color != color;
  }
}

class _TokenChip extends StatelessWidget {
  const _TokenChip({
    required this.text,
    required this.color,
    this.outlined = false,
  });

  final String text;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: MiTokens.space4),
      decoration: BoxDecoration(
        color: outlined ? Colors.white : color,
        borderRadius: BorderRadius.circular(MiTokens.radiusLg),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: outlined ? color : Colors.white,
            ),
      ),
    );
  }
}

class _SoftShape extends StatelessWidget {
  const _SoftShape({
    required this.index,
    required this.color,
  });

  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final radius = index.isEven ? MiTokens.radiusFull : MiTokens.radiusMd;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: index % 3 == 0 ? 1 : 0.75),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: MiShadows.soft,
      ),
    );
  }
}
