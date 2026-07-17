/// Standardized semantic labels for screen readers (Vietnamese + English).
///
/// Games use these so screen-reader output is consistent and localized.
class SemanticLabels {
  SemanticLabels(this.locale);

  final String locale;

  bool get _isVi => locale.startsWith('vi');

  String _t(String vi, String en) => _isVi ? vi : en;

  // --- Cards ---

  String faceDownCard(int position) =>
      _t('Thẻ úp, vị trí $position', 'Face-down card, position $position');

  String faceUpCard(String content, int position) => _t(
        'Thẻ mở, $content, vị trí $position',
        'Face-up card, $content, position $position',
      );

  String matchedCard(String content) =>
      _t('Thẻ đã ghép, $content', 'Matched card, $content');

  // --- General ---

  String get correct => _t('Đúng rồi!', 'Correct!');
  String get tryAgain => _t('Thử lại nhé!', 'Try again!');
  String get levelComplete => _t('Hoàn thành!', 'Level complete!');

  String hint(int number) => _t('Gợi ý số $number', 'Hint number $number');

  String get pauseButton => _t('Nút tạm dừng', 'Pause button');
  String get audioButton => _t('Nút âm thanh', 'Audio button');
  String get hintButton => _t('Nút gợi ý', 'Hint button');
  String get exitButton => _t('Nút thoát', 'Exit button');

  String progress(int done, int total) =>
      _t('Đã hoàn thành $done trên $total', 'Completed $done of $total');
}
