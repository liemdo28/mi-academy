class GameLocaleText {
  const GameLocaleText(this.locale);

  final String locale;

  bool get isEnglish => locale == 'en';

  String get score => isEnglish ? 'Score' : 'Điểm';
  String get next => isEnglish ? 'Continue' : 'Tiếp tục';
  String get replay => isEnglish ? 'Play again' : 'Chơi lại';
  String get home => isEnglish ? 'Home' : 'Trang chính';
  String get mascotCelebration =>
      isEnglish ? 'MI celebrates with you' : 'MI chúc mừng con';
  String get earnedStar => isEnglish ? 'Earned star' : 'Sao đã nhận';
  String get unearnedStar => isEnglish ? 'Unearned star' : 'Sao chưa nhận';
  String get hintAvailable => isEnglish ? 'Ask for a hint' : 'Xin gợi ý';
  String get hintEmpty => isEnglish ? 'No hints left' : 'Đã hết gợi ý';
  String fallbackHint(int index) => isEnglish
      ? 'Hint ${index + 1}: Look closely and try one step at a time.'
      : 'Gợi ý ${index + 1}: Mình quan sát kỹ rồi thử từng bước nhé.';

  String hintFrom(Map<dynamic, dynamic> hint, int index) {
    final localizedText = hint['localizedText'];
    if (localizedText is Map && localizedText[locale] is String) {
      return localizedText[locale] as String;
    }

    final directLocale = hint[locale];
    if (directLocale is String) return directLocale;

    final text = hint['text'];
    if (!isEnglish && text is String && text.isNotEmpty) return text;

    return fallbackHint(index);
  }

  String get wordBuilderTitle => isEnglish ? 'Word Builder' : 'Ghép chữ tạo từ';
  String get wordBuilderCheck => isEnglish ? 'Check' : 'Kiểm tra';
  String get wordBuilderComplete =>
      isEnglish ? 'You built the word!' : 'Con đã ghép đúng từ!';
  String get wordBuilderEmpty => isEnglish
      ? 'There is still an empty spot. Add more letters!'
      : 'Mình còn ô trống, thử ghép thêm nhé!';
  String get wordBuilderRetry => isEnglish
      ? 'Almost there, try changing a few letters!'
      : 'Gần đúng rồi, mình đổi lại vài chữ nhé!';
  String wordBuilderLength(int count) =>
      isEnglish ? '$count letters' : '$count ký tự';
  String emptySlot(int index) =>
      isEnglish ? 'Empty spot ${index + 1}' : 'Ô trống ${index + 1}';
  String filledLetter(String letter) => isEnglish
      ? 'Letter $letter, tap to remove'
      : 'Chữ $letter, chạm để bỏ ra';
  String get spaceSlot =>
      isEnglish ? 'Space, tap to remove' : 'Khoảng trắng, chạm để bỏ ra';
  String bankLetter(String letter) =>
      isEnglish ? 'Letter $letter' : 'Chữ $letter';
  String get bankSpace => isEnglish ? 'Space' : 'Khoảng trắng';

  String get soundMatchTitle => isEnglish ? 'Sound Match' : 'Nghe âm tìm chữ';
  String get soundMatchPrompt => isEnglish
      ? 'Listen and choose the right answer!'
      : 'Nghe và chọn đáp án đúng!';
  String get soundMatchReplay => isEnglish ? 'Listen again' : 'Nghe lại';
  String get soundMatchAudioPrefix => isEnglish ? 'Sound' : 'Âm thanh';
  String get soundMatchPlaying =>
      isEnglish ? 'MI is playing the sound.' : 'MI đang đọc âm thanh mẫu.';
  String get soundMatchRetry => isEnglish
      ? 'Not a match yet. Listen again and try another answer!'
      : 'Chưa khớp rồi, con nghe lại và thử đáp án khác nhé!';
  String get soundMatchComplete => isEnglish
      ? 'You listened and chose correctly!'
      : 'Con đã nghe và chọn đúng!';

  String get robotTitle => isEnglish ? 'Robot Commands' : 'Robot làm theo lệnh';
  String get robotPrompt =>
      isEnglish ? 'Build a program for MI.' : 'Lập chương trình cho MI nhé.';
  String get robotProgram => isEnglish ? 'Program' : 'Chương trình';
  String get robotRun => isEnglish ? 'Run' : 'Chạy lệnh';
  String get robotUndoTooltip =>
      isEnglish ? 'Remove last command' : 'Xóa lệnh cuối';
  String get robotResetTooltip => isEnglish ? 'Reset' : 'Làm lại';
  String get robotMoveBefore =>
      isEnglish ? 'Move command earlier' : 'Đưa lệnh lên trước';
  String get robotMoveAfter =>
      isEnglish ? 'Move command later' : 'Đưa lệnh ra sau';
  String get robotRemoveCommand =>
      isEnglish ? 'Remove this command' : 'Xóa lệnh này';
  String get robotComplete =>
      isEnglish ? 'You programmed MI!' : 'Con đã lập trình cho MI!';
  String get robotDone => isEnglish
      ? 'Robot MI completed the mission!'
      : 'Robot MI đã hoàn thành nhiệm vụ!';
  String get robotRetry => isEnglish
      ? 'Robot MI has not reached everything yet. Try changing the commands!'
      : 'Robot MI chưa tới đủ mục tiêu, mình thử đổi lệnh nhé!';
  String robotCommandLabel(String commandName) {
    if (isEnglish) return commandName;
    return commandName;
  }

  String get memoryTitle => isEnglish ? 'Memory Cards' : 'Ghi nhớ vị trí';
  String get memoryPrompt =>
      isEnglish ? 'Find the matching pairs!' : 'Tìm cặp giống nhau!';
  String get pauseTitle => isEnglish ? 'Paused' : 'Tạm dừng';
  String get pauseResume => isEnglish ? 'Resume' : 'Tiếp tục';
  String get pauseRestart => isEnglish ? 'Play again' : 'Chơi lại';
  String get pauseExit => isEnglish ? 'Exit' : 'Thoát';
  String get tutorialContinue => isEnglish ? 'Continue' : 'Tiếp tục';
  String get tutorialStart => isEnglish ? 'Start' : 'Bắt đầu';
  String get tutorialMascot =>
      isEnglish ? 'MI shows how to play' : 'MI hướng dẫn cách chơi';
  String get memoryTutorial => isEnglish
      ? 'Tap a card to flip it.\nFind two cards with the same picture.\nMatch every pair to win!'
      : 'Chạm vào thẻ để lật lên.\nTìm hai thẻ có hình giống nhau.\nGhép tất cả cặp để thắng!';
  String memoryFaceDown(int index) => isEnglish
      ? 'Face-down card, position ${index + 1}'
      : 'Thẻ úp, vị trí ${index + 1}';
  String memoryFaceUp(String content) =>
      isEnglish ? 'Card $content' : 'Thẻ $content';
  String get memoryMatched => isEnglish ? 'Matched!' : 'Ghép đúng!';
  String get memoryDone => isEnglish ? 'Complete!' : 'Hoàn thành!';
  String get memoryRetry =>
      isEnglish ? 'Not a match, try again!' : 'Không khớp, thử lại nhé!';
  String get memoryCongrats => isEnglish ? 'Great memory!' : 'Chúc mừng!';

  CompletionText get completion => CompletionText(
        scoreLabel: score,
        nextLabel: next,
        replayLabel: replay,
        exitLabel: home,
        mascotSemanticLabel: mascotCelebration,
        earnedStarSemanticLabel: earnedStar,
        unearnedStarSemanticLabel: unearnedStar,
      );
}

class CompletionText {
  const CompletionText({
    required this.scoreLabel,
    required this.nextLabel,
    required this.replayLabel,
    required this.exitLabel,
    required this.mascotSemanticLabel,
    required this.earnedStarSemanticLabel,
    required this.unearnedStarSemanticLabel,
  });

  final String scoreLabel;
  final String nextLabel;
  final String replayLabel;
  final String exitLabel;
  final String mascotSemanticLabel;
  final String earnedStarSemanticLabel;
  final String unearnedStarSemanticLabel;
}
