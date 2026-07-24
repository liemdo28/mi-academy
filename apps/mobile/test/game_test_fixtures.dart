import 'package:mi_game_core/mi_game_core.dart';

const wordBuilderLevel = MiLevel(
  id: 'wb-test',
  gameId: 'word_builder',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {
      'prompt': 'Ghép chữ thành từ!',
      'targetWord': 'mèo',
      'letters': ['m', 'è', 'o'],
      'distractors': ['a'],
    },
    'en': {
      'prompt': 'Build the word!',
      'targetWord': 'cat',
      'letters': ['c', 'a', 't'],
      'distractors': ['o'],
    },
  },
  hints: [
    {'text': 'Chữ đầu tiên là M'},
  ],
);

const soundMatchLevel = MiLevel(
  id: 'sm-test',
  gameId: 'sound_match',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {
      'prompt': 'Nghe âm và chọn chữ cái!',
      'correctAnswer': 'A',
      'options': ['A', 'B', 'C'],
      'audioKey': 'letter_a',
      'audioTranscript': 'A',
    },
    'en': {
      'prompt': 'Listen and choose the letter!',
      'correctAnswer': 'A',
      'options': ['A', 'B', 'C'],
      'audioKey': 'letter_a',
      'audioTranscript': 'A',
    },
  },
  hints: [
    {'text': 'Nghe lại âm thanh'},
  ],
);

const mathRaceLevel = MiLevel(
  id: 'mr-test',
  gameId: 'math_race',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {
      'prompt': '2 + 3 = ?',
      'options': [
        {'id': 'a', 'text': '4', 'correct': false},
        {'id': 'b', 'text': '5', 'correct': true},
      ],
    },
    'en': {
      'prompt': '2 + 3 = ?',
      'options': [
        {'id': 'a', 'text': '4', 'correct': false},
        {'id': 'b', 'text': '5', 'correct': true},
      ],
    },
  },
  hints: [
    {'text': 'Đếm thêm 3 từ số 2'},
  ],
);

const mathSupermarketLevel = MiLevel(
  id: 'ms-test',
  gameId: 'math_supermarket',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {
      'prompt': 'Quả táo 2 đồng, quả chuối 3 đồng. Tổng cộng bao nhiêu?',
      'options': [
        {'id': 'a', 'text': '4 đồng', 'correct': false},
        {'id': 'b', 'text': '5 đồng', 'correct': true},
      ],
    },
  },
  hints: [
    {'text': 'Cộng giá hai mặt hàng'},
  ],
);

const clockTimeLevel = MiLevel(
  id: 'ct-test',
  gameId: 'clock_time',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {
      'prompt': 'Kim giờ chỉ 3. Đồng hồ là mấy giờ?',
      'options': [
        {'id': 'a', 'text': '3:30', 'correct': false},
        {'id': 'b', 'text': '3:00', 'correct': true},
      ],
    },
    'en': {
      'prompt': 'The hour hand points to 3. What time is it?',
      'options': [
        {'id': 'a', 'text': '3:30', 'correct': false},
        {'id': 'b', 'text': '3:00', 'correct': true},
      ],
    },
  },
  hints: [
    {'text': 'Nhìn kim giờ'},
  ],
);

const objectCountingLevel = MiLevel(
  id: 'oc-test',
  gameId: 'object_counting',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {
      'prompt': 'Có bao nhiêu ngôi sao?',
      'options': [
        {'id': 'a', 'text': '4', 'correct': false},
        {'id': 'b', 'text': '6', 'correct': true},
      ],
    },
    'en': {
      'prompt': 'How many stars are there?',
      'options': [
        {'id': 'a', 'text': '4', 'correct': false},
        {'id': 'b', 'text': '6', 'correct': true},
      ],
    },
  },
  hints: [
    {'text': 'Đếm từng hình'},
  ],
);

const visualFractionsLevel = MiLevel(
  id: 'vf-test',
  gameId: 'visual_fractions',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {
      'prompt': 'Phần tô màu là phân số nào?',
      'options': [
        {'id': 'a', 'text': '1/4', 'correct': false},
        {'id': 'b', 'text': '3/4', 'correct': true},
      ],
    },
    'en': {
      'prompt': 'Which fraction is shaded?',
      'options': [
        {'id': 'a', 'text': '1/4', 'correct': false},
        {'id': 'b', 'text': '3/4', 'correct': true},
      ],
    },
  },
  hints: [
    {'text': 'Đếm phần được tô'},
  ],
);

const patternFinderLevel = MiLevel(
  id: 'pf-test',
  gameId: 'pattern_finder',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {
      'prompt': 'Dãy số 2, 4, 6, ?',
      'options': [
        {'id': 'a', 'text': '7', 'correct': false},
        {'id': 'b', 'text': '8', 'correct': true},
      ],
    },
    'en': {
      'prompt': 'Number pattern 2, 4, 6, ?',
      'options': [
        {'id': 'a', 'text': '7', 'correct': false},
        {'id': 'b', 'text': '8', 'correct': true},
      ],
    },
  },
  hints: [
    {'text': 'Mỗi bước tăng 2'},
  ],
);

const shapeBuilderLevel = MiLevel(
  id: 'sb-test',
  gameId: 'shape_builder',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {
      'prompt': 'Hình nào có ba cạnh?',
      'options': [
        {'id': 'a', 'text': 'Hình vuông', 'correct': false},
        {'id': 'b', 'text': 'Hình tam giác', 'correct': true},
      ],
    },
    'en': {
      'prompt': 'Which shape has three sides?',
      'options': [
        {'id': 'a', 'text': 'Square', 'correct': false},
        {'id': 'b', 'text': 'Triangle', 'correct': true},
      ],
    },
  },
  hints: [
    {'text': 'Đếm các cạnh'},
  ],
);

const memoryCardsLevel = MiLevel(
  id: 'mc-test',
  gameId: 'memory_cards',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {
      'prompt': 'Tìm cặp giống nhau!',
      'cards': [
        {'id': 'a1', 'pairId': 'a', 'content': 'A', 'type': 'text'},
        {'id': 'a2', 'pairId': 'a', 'content': 'A', 'type': 'text'},
        {'id': 'b1', 'pairId': 'b', 'content': 'B', 'type': 'text'},
        {'id': 'b2', 'pairId': 'b', 'content': 'B', 'type': 'text'},
      ],
    },
    'en': {
      'prompt': 'Find the matching pairs!',
      'cards': [
        {'id': 'a1', 'pairId': 'a', 'content': 'A', 'type': 'text'},
        {'id': 'a2', 'pairId': 'a', 'content': 'A', 'type': 'text'},
        {'id': 'b1', 'pairId': 'b', 'content': 'B', 'type': 'text'},
        {'id': 'b2', 'pairId': 'b', 'content': 'B', 'type': 'text'},
      ],
    },
  },
  hints: [
    {'text': 'Nhớ vị trí hai thẻ giống nhau'},
  ],
  metadata: {
    'gridCols': 2,
    'gridRows': 2,
    'initialRevealMs': 0,
  },
);

const robotCommandsLevel = MiLevel(
  id: 'rc-test',
  gameId: 'robot_commands',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {
      'prompt': 'Đưa MI tới ngôi sao bằng 2 bước tiến.',
      'availableCommands': ['MOVE_FORWARD'],
    },
  },
  hints: [
    {'text': 'Mỗi lệnh tiến đi một ô.'},
  ],
  metadata: {
    'grid': {'width': 3, 'height': 1},
    'start': {'x': 0, 'y': 0, 'facing': 'east'},
    'goal': {'x': 2, 'y': 0},
    'obstacles': [],
    'collectibles': [],
  },
);

const robotCommandsTurnLevel = MiLevel(
  id: 'rc-turn-test',
  gameId: 'robot_commands',
  levelNumber: 1,
  difficulty: 2,
  localizedContent: {
    'vi': {
      'prompt': 'Sắp xếp lệnh để MI đổi hướng.',
      'availableCommands': ['MOVE_FORWARD', 'TURN_RIGHT'],
    },
  },
  hints: [
    {'text': 'Con có thể đổi thứ tự lệnh.'},
  ],
  metadata: {
    'grid': {'width': 2, 'height': 2},
    'start': {'x': 0, 'y': 0, 'facing': 'east'},
    'goal': {'x': 1, 'y': 1},
    'obstacles': [],
    'collectibles': [],
  },
);
