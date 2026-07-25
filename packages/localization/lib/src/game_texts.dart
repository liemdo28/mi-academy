/// Localized text used by game shells and registry metadata.
///
/// Keeping these maps in the localization package prevents production screen
/// code from carrying user-facing Vietnamese/English literals.
const miGameNames = {
  'alphabet_explorer': {'vi': 'Khám phá chữ cái', 'en': 'Alphabet Explorer'},
  'clock_time': {'vi': 'Đồng hồ và thời gian', 'en': 'Clock Time'},
  'free_creativity': {'vi': 'Sáng tạo tự do', 'en': 'Free Creativity'},
  'fun_measurement': {'vi': 'Đo lường vui nhộn', 'en': 'Fun Measurement'},
  'greater_less': {'vi': 'So sánh lớn và bé', 'en': 'Greater or Less'},
  'kids_sudoku': {'vi': 'Sudoku trẻ em', 'en': 'Kids Sudoku'},
  'logic_maze': {'vi': 'Mê cung logic', 'en': 'Logic Maze'},
  'math_race': {'vi': 'Đường đua cộng trừ', 'en': 'Math Race'},
  'math_supermarket': {'vi': 'Siêu thị toán học', 'en': 'Math Supermarket'},
  'memory_cards': {'vi': 'Ghi nhớ vị trí', 'en': 'Memory Cards'},
  'missing_letter': {'vi': 'Tìm chữ còn thiếu', 'en': 'Missing Letter'},
  'multiplication_adventure': {
    'vi': 'Bảng nhân phiêu lưu',
    'en': 'Multiplication Adventure',
  },
  'number_quantity_match': {
    'vi': 'Ghép số với số lượng',
    'en': 'Number Quantity Match',
  },
  'number_sequence': {'vi': 'Hoàn thành dãy số', 'en': 'Number Sequence'},
  'object_counting': {'vi': 'Đếm đồ vật', 'en': 'Object Counting'},
  'odd_one_out': {'vi': 'Tìm hình khác biệt', 'en': 'Odd One Out'},
  'pattern_finder': {'vi': 'Tìm quy luật', 'en': 'Pattern Finder'},
  'picture_word_match': {'vi': 'Nối từ với hình', 'en': 'Picture Word Match'},
  'reasoning_detective': {
    'vi': 'Thám tử suy luận',
    'en': 'Reasoning Detective',
  },
  'rhyme_picker': {'vi': 'Vần nào đúng?', 'en': 'Rhyme Picker'},
  'robot_commands': {'vi': 'Robot làm theo lệnh', 'en': 'Robot Commands'},
  'sentence_order': {'vi': 'Sắp xếp câu', 'en': 'Sentence Order'},
  'shadow_match': {'vi': 'Ghép bóng với vật', 'en': 'Shadow Match'},
  'shape_builder': {'vi': 'Hình học lắp ghép', 'en': 'Shape Builder'},
  'sound_match': {'vi': 'Nghe âm tìm chữ', 'en': 'Sound Match'},
  'speed_spelling': {'vi': 'Chính tả nhanh', 'en': 'Speed Spelling'},
  'story_comprehension': {
    'vi': 'Đọc hiểu truyện ngắn',
    'en': 'Story Comprehension',
  },
  'treasure_division': {'vi': 'Chia đều kho báu', 'en': 'Treasure Division'},
  'visual_fractions': {'vi': 'Phân số trực quan', 'en': 'Visual Fractions'},
  'word_builder': {'vi': 'Ghép chữ tạo từ', 'en': 'Word Builder'},
};

const miGameWorldLabels = {
  'alphabet_explorer': {
    'vi': 'MI cùng con khám phá chữ cái.',
    'en': 'MI explores letters with you.',
  },
  'clock_time': {
    'vi': 'MI cùng con xem đồng hồ.',
    'en': 'MI reads clocks with you.',
  },
  'free_creativity': {
    'vi': 'MI cùng con biến ý tưởng thành câu chuyện.',
    'en': 'MI helps turn ideas into a story.',
  },
  'fun_measurement': {
    'vi': 'MI cùng con so sánh đơn vị đo.',
    'en': 'MI compares length, weight, and units.',
  },
  'greater_less': {
    'vi': 'MI cùng con so sánh các số.',
    'en': 'MI compares numbers with you.',
  },
  'kids_sudoku': {
    'vi': 'MI cùng con giải ô lưới nhỏ.',
    'en': 'MI solves small grids with clues.',
  },
  'logic_maze': {
    'vi': 'MI cùng con tìm đường qua mê cung.',
    'en': 'MI plans a path through the maze.',
  },
  'math_race': {
    'vi': 'Xe MI tiến lên khi con chọn đúng.',
    'en': 'MI moves forward when you choose correctly.',
  },
  'math_supermarket': {
    'vi': 'Giỏ hàng MI giúp con luyện tính tiền.',
    'en': "MI's basket helps you practice money math.",
  },
  'missing_letter': {
    'vi': 'MI cùng con tìm chữ còn thiếu.',
    'en': 'MI looks for the missing letters with you.',
  },
  'multiplication_adventure': {
    'vi': 'MI cùng con phiêu lưu với bảng nhân.',
    'en': 'MI practices times tables on an adventure.',
  },
  'number_quantity_match': {
    'vi': 'MI cùng con ghép số với số lượng.',
    'en': 'MI connects numbers to quantities.',
  },
  'number_sequence': {
    'vi': 'MI cùng con tìm số tiếp theo.',
    'en': 'MI finds the next number in the pattern.',
  },
  'object_counting': {
    'vi': 'MI cùng con đếm từng đồ vật.',
    'en': 'MI counts objects one by one.',
  },
  'odd_one_out': {
    'vi': 'MI cùng con tìm hình khác nhóm.',
    'en': 'MI finds the item that does not belong.',
  },
  'pattern_finder': {
    'vi': 'MI cùng con tìm quy luật.',
    'en': 'MI spots the rule in the pattern.',
  },
  'picture_word_match': {
    'vi': 'MI cùng con nối từ với ý nghĩa.',
    'en': 'MI matches words with meaning.',
  },
  'reasoning_detective': {
    'vi': 'MI cùng con suy luận từng bước.',
    'en': 'MI follows clues step by step.',
  },
  'rhyme_picker': {
    'vi': 'MI cùng con nghe những từ cùng vần.',
    'en': 'MI listens for words that sound alike.',
  },
  'sentence_order': {
    'vi': 'MI cùng con ghép câu rõ nghĩa.',
    'en': 'MI builds clear sentences with you.',
  },
  'shadow_match': {
    'vi': 'MI cùng con ghép bóng với vật.',
    'en': 'MI matches each object to its shadow.',
  },
  'shape_builder': {
    'vi': 'MI cùng con nhận biết hình khối.',
    'en': 'MI names and builds shapes.',
  },
  'speed_spelling': {
    'vi': 'MI giúp con chọn cách viết đúng.',
    'en': 'MI helps you spot the correct spelling.',
  },
  'story_comprehension': {
    'vi': 'MI cùng con đọc hiểu truyện ngắn.',
    'en': 'MI reads short stories with you.',
  },
  'treasure_division': {
    'vi': 'MI cùng con chia đều kho báu.',
    'en': 'MI shares treasure equally.',
  },
  'visual_fractions': {
    'vi': 'MI cùng con nhìn phân số bằng hình.',
    'en': 'MI sees fractions as equal parts.',
  },
};

Map<String, String> miGameNameMap(String gameId) {
  return miGameNames[gameId] ?? {'vi': gameId, 'en': gameId};
}

String miGameName(String gameId, String locale) {
  final names = miGameNameMap(gameId);
  return names[locale] ?? names['en'] ?? gameId;
}

String miGameWorldLabel(String gameId, String locale) {
  final labels = miGameWorldLabels[gameId];
  return labels?[locale] ?? labels?['en'] ?? miGameName(gameId, locale);
}

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

  String get wordBuilderTitle => miGameName('word_builder', locale);
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

  String get soundMatchTitle => miGameName('sound_match', locale);
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

  String get robotTitle => miGameName('robot_commands', locale);
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
  String robotCommandLabel(String commandName) => commandName;

  String get mazeTitle => miGameName('logic_maze', locale);
  String get mazePlanner => isEnglish ? 'Path planner' : 'Bàn tìm đường';
  String get mazeProgram => isEnglish ? 'Path commands' : 'Lệnh di chuyển';
  String get mazeRun => isEnglish ? 'Run path' : 'Chạy đường đi';
  String get mazeUndoTooltip =>
      isEnglish ? 'Remove last move' : 'Xóa bước cuối';
  String get mazeResetTooltip => isEnglish ? 'Reset path' : 'Làm lại đường đi';
  String get mazeComplete =>
      isEnglish ? 'You guided MI to the star!' : 'Con đã dẫn MI tới ngôi sao!';
  String get mazeDone =>
      isEnglish ? 'MI reached the star safely!' : 'MI đã tới ngôi sao an toàn!';
  String get mazeHitWall => isEnglish
      ? 'That path bumps into a blocked square. Try another route!'
      : 'Đường này đụng ô bị chặn rồi. Mình thử hướng khác nhé!';
  String get mazeOutOfBounds => isEnglish
      ? 'That path leaves the maze. Keep MI inside the board!'
      : 'Đường này đi ra ngoài mê cung. Giữ MI trong bảng nhé!';
  String get mazeRetry => isEnglish
      ? 'MI has not reached the star yet. Add or change some moves!'
      : 'MI chưa tới ngôi sao. Con thêm hoặc đổi vài bước nhé!';
  String get mazeEmpty => isEnglish
      ? 'Add moves before running the path.'
      : 'Con thêm bước rồi hãy chạy đường đi nhé.';
  String get mazeStepUp => isEnglish ? 'Up' : 'Lên';
  String get mazeStepDown => isEnglish ? 'Down' : 'Xuống';
  String get mazeStepLeft => isEnglish ? 'Left' : 'Trái';
  String get mazeStepRight => isEnglish ? 'Right' : 'Phải';
  String mazeCommandLabel(String commandName) {
    switch (commandName) {
      case 'up':
        return mazeStepUp;
      case 'down':
        return mazeStepDown;
      case 'left':
        return mazeStepLeft;
      case 'right':
        return mazeStepRight;
      default:
        return commandName;
    }
  }

  String get memoryTitle => miGameName('memory_cards', locale);
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

class ChoiceBoardText {
  const ChoiceBoardText(this.locale);

  final String locale;

  bool get isEnglish => locale == 'en';

  String titleFor(String gameId) {
    switch (gameId) {
      case 'clock_time':
        return isEnglish ? 'Look at the clock' : 'Nhìn đồng hồ';
      case 'object_counting':
      case 'number_quantity_match':
        return isEnglish ? 'Count with MI' : 'Cùng MI đếm';
      case 'greater_less':
        return isEnglish ? 'Compare the numbers' : 'So sánh hai số';
      case 'multiplication_adventure':
        return isEnglish ? 'Groups of numbers' : 'Nhóm phép nhân';
      case 'treasure_division':
        return isEnglish ? 'Share equally' : 'Chia đều';
      case 'fun_measurement':
        return isEnglish ? 'Measure it' : 'Đo lường';
      case 'number_sequence':
      case 'pattern_finder':
        return isEnglish ? 'Find the pattern' : 'Tìm quy luật';
      case 'sentence_order':
        return isEnglish ? 'Build the sentence' : 'Ghép câu đúng';
      case 'visual_fractions':
        return isEnglish ? 'See equal parts' : 'Nhìn phần bằng nhau';
      case 'shape_builder':
        return isEnglish ? 'Look at the shapes' : 'Nhìn các hình';
      case 'odd_one_out':
        return isEnglish ? 'Which one is different?' : 'Tìm cái khác nhóm';
      case 'shadow_match':
        return isEnglish ? 'Match the shadow' : 'Ghép bóng';
      case 'alphabet_explorer':
      case 'missing_letter':
        return isEnglish ? 'Read the clue' : 'Đọc gợi ý';
      case 'picture_word_match':
        return isEnglish ? 'Match word and meaning' : 'Nối từ với nghĩa';
      case 'rhyme_picker':
        return isEnglish ? 'Listen for rhyme' : 'Nghe vần giống nhau';
      case 'speed_spelling':
        return isEnglish ? 'Choose the spelling' : 'Chọn chính tả';
      default:
        return isEnglish ? 'Puzzle board' : 'Bảng trò chơi';
    }
  }

  String counted(int count) => isEnglish ? 'Counted: $count' : 'Đã đếm: $count';

  String get workItOut => isEnglish ? 'Work it out' : 'Tính từng bước';

  String groupsOf(int left, int right) =>
      isEnglish ? '$left groups of $right' : '$left nhóm, mỗi nhóm $right';

  String shareInto(int groups) =>
      isEnglish ? 'Share into $groups groups' : 'Chia thành $groups nhóm';

  String get biggerNumber => isEnglish ? 'Bigger number' : 'Số lớn hơn';

  String measure(String amount) =>
      isEnglish ? 'Measure: $amount' : 'Số đo: $amount';

  String get bestFit => isEnglish ? 'Best fit' : 'Điền vào chỗ trống';

  String equalParts(int filled, int parts) => isEnglish
      ? '$filled of $parts equal parts'
      : '$filled trong $parts phần bằng nhau';

  String get matchShape => isEnglish ? 'Match' : 'Chọn hình';

  String get sameEndingSound => isEnglish ? 'Same ending sound' : 'Cùng âm vần';

  String get meaningMatch => isEnglish ? 'Meaning match' : 'Khớp với nghĩa';

  String readOrder(int count) =>
      isEnglish ? 'Read from 1 to $count' : 'Đọc từ 1 đến $count';

  String get matchingObject =>
      isEnglish ? 'Find the matching object' : 'Tìm vật khớp bóng';

  String get differentItem => isEnglish ? 'Different item' : 'Khác nhóm';

  String clockHour(int hour) => isEnglish ? "$hour o'clock" : '$hour giờ đúng';
}

class LearningJourneyText {
  const LearningJourneyText(this.locale);

  final String locale;

  bool get isEnglish => locale == 'en';

  String reason(String code) {
    final copy = _reasonCopy[code];
    return copy?[locale] ?? copy?['en'] ?? '';
  }

  String get difficulty => isEnglish ? 'Difficulty' : 'Độ khó';
  String get ageBand => isEnglish ? 'Age band' : 'Độ tuổi';
  String get estimatedTime =>
      isEnglish ? 'Estimated time' : 'Thời gian dự kiến';
  String get buildsOn => isEnglish ? 'Builds on' : 'Cần học trước';
  String minutes(int value) => isEnglish ? '$value min' : '$value phút';
  String get rewardPreview => isEnglish
      ? 'Earn stars and journey progress by completing this.'
      : 'Hoàn thành để nhận sao và tiến bộ trong hành trình học tập.';
  String get locked => isEnglish ? 'Locked' : 'Đã khoá';
  String get play => isEnglish ? 'Play' : 'Chơi ngay';

  String stateLabel(String stateName) {
    final copy = _stateLabels[stateName];
    return copy?[locale] ?? copy?['en'] ?? stateName;
  }
}

const _reasonCopy = {
  'NEW_SKILL_EASY_START': {
    'vi': 'Bài học dễ để con bắt đầu tự tin.',
    'en': 'An easy start to build confidence.',
  },
  'DIFFICULTY_MATCH': {
    'vi': 'Vừa đúng trình độ hiện tại của con.',
    'en': 'Matches your current skill level.',
  },
  'REVIEW_DUE': {
    'vi': 'Đã đến lúc ôn lại kỹ năng này.',
    'en': 'Time to review this skill.',
  },
  'PREREQUISITES_MET': {
    'vi': 'Con đã sẵn sàng học bài này.',
    'en': "You're ready for this lesson.",
  },
  'AVOID_IMMEDIATE_REPEAT': {
    'vi': 'Một bài mới để đổi không khí.',
    'en': 'A fresh lesson for variety.',
  },
};

const _stateLabels = {
  'locked': {'vi': 'Đã khoá', 'en': 'Locked'},
  'available': {'vi': 'Có thể học', 'en': 'Available'},
  'recommended': {'vi': 'Gợi ý cho con', 'en': 'Recommended'},
  'mastered': {'vi': 'Đã thành thạo', 'en': 'Mastered'},
  'review': {'vi': 'Cần ôn tập', 'en': 'Review'},
  'challenge': {'vi': 'Thử thách', 'en': 'Challenge'},
  'bonus': {'vi': 'Phần thưởng thêm', 'en': 'Bonus'},
};

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
