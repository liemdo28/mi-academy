const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const levelsDir = path.join(root, 'apps', 'mobile', 'assets', 'levels');

const deepGames = [
  'story_comprehension',
  'logic_maze',
  'kids_sudoku',
  'reasoning_detective',
  'free_creativity',
];

const readingSeeds = [
  { viName: 'Lan', enName: 'Lan', itemVi: 'trang sách', itemEn: 'pages', placeVi: 'góc đọc sách', placeEn: 'reading corner' },
  { viName: 'Minh', enName: 'Minh', itemVi: 'bút chì', itemEn: 'pencils', placeVi: 'lớp học', placeEn: 'classroom' },
  { viName: 'An', enName: 'An', itemVi: 'khối gỗ', itemEn: 'blocks', placeVi: 'bàn học', placeEn: 'study table' },
  { viName: 'Mai', enName: 'Mai', itemVi: 'bông hoa giấy', itemEn: 'paper flowers', placeVi: 'góc thủ công', placeEn: 'craft corner' },
  { viName: 'Bình', enName: 'Binh', itemVi: 'thẻ chữ', itemEn: 'letter cards', placeVi: 'thư viện nhỏ', placeEn: 'mini library' },
  { viName: 'Hà', enName: 'Ha', itemVi: 'ngôi sao thưởng', itemEn: 'reward stars', placeVi: 'bảng tiến bộ', placeEn: 'progress board' },
  { viName: 'Nam', enName: 'Nam', itemVi: 'viên bi xanh', itemEn: 'blue marbles', placeVi: 'hộp đồ chơi', placeEn: 'toy box' },
  { viName: 'Linh', enName: 'Linh', itemVi: 'mảnh ghép', itemEn: 'puzzle pieces', placeVi: 'thảm chơi', placeEn: 'play mat' },
  { viName: 'Phúc', enName: 'Phuc', itemVi: 'lá cây', itemEn: 'leaves', placeVi: 'vườn nhỏ', placeEn: 'small garden' },
  { viName: 'Vy', enName: 'Vy', itemVi: 'nhãn dán', itemEn: 'stickers', placeVi: 'sổ sáng tạo', placeEn: 'creative notebook' },
];

const detectiveSeeds = [
  { vi: ['A đứng trước B.', 'C đứng sau B.', 'Người đầu tiên không có ai đứng trước.'], en: ['A stands before B.', 'C stands after B.', 'The first person has no one before them.'], answer: 'A', wrong: ['B', 'C'] },
  { vi: ['B cầm thẻ xanh.', 'A không cầm thẻ xanh.', 'C cầm thẻ còn lại.'], en: ['B holds the green card.', 'A does not hold the green card.', 'C holds the remaining card.'], answer: 'B', wrong: ['A', 'C'] },
  { vi: ['C về đích sau A.', 'B về đích sau C.', 'Người thắng về trước tất cả.'], en: ['C finishes after A.', 'B finishes after C.', 'The winner finishes before everyone.'], answer: 'A', wrong: ['B', 'C'] },
  { vi: ['A chọn hình tròn.', 'B không chọn hình vuông.', 'C chọn hình còn lại.'], en: ['A chooses the circle.', 'B does not choose the square.', 'C chooses the remaining shape.'], answer: 'A', wrong: ['B', 'C'] },
  { vi: ['B cao hơn A.', 'C thấp hơn A.', 'Người cao nhất đứng đầu hàng.'], en: ['B is taller than A.', 'C is shorter than A.', 'The tallest child stands first.'], answer: 'B', wrong: ['A', 'C'] },
  { vi: ['C đọc xong trước B.', 'A đọc xong sau B.', 'Người đọc xong trước nhất được chọn.'], en: ['C finishes reading before B.', 'A finishes after B.', 'Choose the first reader to finish.'], answer: 'C', wrong: ['A', 'B'] },
  { vi: ['A có 2 sao.', 'B có nhiều hơn A 1 sao.', 'C có ít hơn A 1 sao.'], en: ['A has 2 stars.', 'B has 1 more star than A.', 'C has 1 fewer star than A.'], answer: 'B', wrong: ['A', 'C'] },
  { vi: ['B đứng giữa A và C.', 'A đứng bên trái B.', 'Ai đứng bên phải B?'], en: ['B stands between A and C.', 'A stands to the left of B.', 'Who stands to the right of B?'], answer: 'C', wrong: ['A', 'B'] },
  { vi: ['C không phải màu đỏ.', 'A là màu đỏ.', 'B là màu còn lại.'], en: ['C is not red.', 'A is red.', 'B is the remaining color.'], answer: 'A', wrong: ['B', 'C'] },
  { vi: ['A đi 1 bước.', 'B đi 3 bước.', 'C đi 2 bước.', 'Ai đi xa nhất?'], en: ['A moves 1 step.', 'B moves 3 steps.', 'C moves 2 steps.', 'Who moves the farthest?'], answer: 'B', wrong: ['A', 'C'] },
];

const creativeSeeds = [
  { viFeeling: 'tò mò', enFeeling: 'curious', viCards: ['Một cánh cửa nhỏ', 'tiếng gõ nhẹ', 'một câu hỏi mới'], enCards: ['A tiny door', 'a gentle knock', 'a new question'], correctVi: 'một câu hỏi mới', correctEn: 'a new question' },
  { viFeeling: 'vui', enFeeling: 'happy', viCards: ['sân chơi sáng nắng', 'bạn mới mỉm cười', 'một lời cảm ơn'], enCards: ['a sunny playground', 'a new friend smiles', 'a thank-you note'], correctVi: 'bạn mới mỉm cười', correctEn: 'a new friend smiles' },
  { viFeeling: 'can đảm', enFeeling: 'brave', viCards: ['cây cầu nhỏ', 'MI hít thở sâu', 'bước đầu tiên'], enCards: ['a small bridge', 'MI takes a deep breath', 'the first step'], correctVi: 'bước đầu tiên', correctEn: 'the first step' },
  { viFeeling: 'tốt bụng', enFeeling: 'kind', viCards: ['hộp bút rơi', 'một bàn tay giúp đỡ', 'lời chia sẻ'], enCards: ['a fallen pencil box', 'a helping hand', 'a shared word'], correctVi: 'một bàn tay giúp đỡ', correctEn: 'a helping hand' },
  { viFeeling: 'bất ngờ', enFeeling: 'surprised', viCards: ['chiếc hộp kín', 'ánh sáng vàng', 'một món quà nhỏ'], enCards: ['a closed box', 'golden light', 'a small gift'], correctVi: 'một món quà nhỏ', correctEn: 'a small gift' },
  { viFeeling: 'bình tĩnh', enFeeling: 'calm', viCards: ['góc đọc yên tĩnh', 'ba hơi thở chậm', 'một trang sách mới'], enCards: ['a quiet reading nook', 'three slow breaths', 'a new page'], correctVi: 'ba hơi thở chậm', correctEn: 'three slow breaths' },
  { viFeeling: 'kiên trì', enFeeling: 'persistent', viCards: ['bài toán khó', 'thử lại từng bước', 'dấu kiểm xanh'], enCards: ['a hard problem', 'trying step by step', 'a green check'], correctVi: 'thử lại từng bước', correctEn: 'trying step by step' },
  { viFeeling: 'hào hứng', enFeeling: 'excited', viCards: ['bản đồ kho báu', 'vạch xuất phát', 'tiếng reo cổ vũ'], enCards: ['a treasure map', 'the starting line', 'cheering voices'], correctVi: 'tiếng reo cổ vũ', correctEn: 'cheering voices' },
  { viFeeling: 'quan tâm', enFeeling: 'caring', viCards: ['bạn buồn', 'một lời hỏi han', 'chiếc ghế trống'], enCards: ['a sad friend', 'a caring question', 'an empty chair'], correctVi: 'một lời hỏi han', correctEn: 'a caring question' },
  { viFeeling: 'sáng tạo', enFeeling: 'creative', viCards: ['mảnh giấy trắng', 'ba màu sáp', 'một ý tưởng lạ'], enCards: ['a blank page', 'three crayons', 'a surprising idea'], correctVi: 'một ý tưởng lạ', correctEn: 'a surprising idea' },
];

function readGame(gameId) {
  return JSON.parse(fs.readFileSync(path.join(levelsDir, `${gameId}.json`), 'utf8'));
}

function writeGame(gameId, data) {
  fs.writeFileSync(path.join(levelsDir, `${gameId}.json`), `${JSON.stringify(data, null, 2)}\n`, 'utf8');
}

function rotate(values, amount) {
  return values.map((_, index) => values[(index + amount) % values.length]);
}

function option(id, text, correct = false) {
  return { id, text: String(text), correct };
}

function setChoice(content, prompt, correct, wrongs, offset) {
  const options = rotate([
    option('a', correct, true),
    option('b', wrongs[0], false),
    option('c', wrongs[1], false),
  ], offset % 3);
  content.prompt = prompt;
  content.options = options.map((item, index) => ({ ...item, id: String.fromCharCode(97 + index) }));
}

function addLocalized(level, builder) {
  for (const locale of ['vi', 'en']) {
    const content = level.localizedContent[locale];
    content.deepData = builder(locale, content, level);
  }
}

function enrichStoryComprehension(level) {
  const seed = readingSeeds[(level.levelNumber - 1) % readingSeeds.length];
  const count = 3 + ((level.levelNumber + level.difficulty) % 6);
  const wrongs = [Math.max(1, count - 1), count + 1];
  setChoice(
    level.localizedContent.vi,
    `${seed.viName} ở ${seed.placeVi} và đếm được ${count} ${seed.itemVi}. ${seed.viName} đếm được bao nhiêu ${seed.itemVi}?`,
    count,
    wrongs,
    level.levelNumber,
  );
  setChoice(
    level.localizedContent.en,
    `${seed.enName} is in the ${seed.placeEn} and counts ${count} ${seed.itemEn}. How many ${seed.itemEn} did ${seed.enName} count?`,
    count,
    wrongs,
    level.levelNumber,
  );
  level.metadata.deepData = {
    scene: 'reading',
    passageKind: 'fact_lookup',
    answer: count,
  };
  addLocalized(level, (locale) => ({
    passage: locale === 'en'
      ? `${seed.enName} visited the ${seed.placeEn}. ${seed.enName} carefully counted ${count} ${seed.itemEn} before sharing the answer with MI.`
      : `${seed.viName} ghé ${seed.placeVi}. ${seed.viName} cẩn thận đếm ${count} ${seed.itemVi} rồi chia sẻ đáp án với MI.`,
    steps: locale === 'en'
      ? ['Read the passage', 'Find the counted item', 'Choose the number']
      : ['Đọc đoạn ngắn', 'Tìm vật được đếm', 'Chọn con số'],
  }));
}

function enrichLogicMaze(level) {
  const size = level.difficulty >= 4 ? 5 : 4;
  const startIndex = (size - 1) * size;
  const goalIndex = size - 1;
  const routeKinds = [
    ['up', 'up', 'right', 'right', 'right', 'up'],
    ['right', 'up', 'right', 'up', 'right', 'up'],
    ['up', 'right', 'up', 'right', 'up', 'right'],
    ['right', 'right', 'up', 'up', 'right', 'up'],
    ['up', 'up', 'up', 'right', 'right', 'right'],
  ];
  const moves = routeKinds[(level.levelNumber - 1) % routeKinds.length];
  let row = size - 1;
  let col = 0;
  const path = [startIndex];
  for (const move of moves) {
    if (move === 'up' && row > 0) row -= 1;
    if (move === 'right' && col < size - 1) col += 1;
    path.push(row * size + col);
  }
  while (row > 0) path.push((--row) * size + col);
  while (col < size - 1) path.push(row * size + ++col);
  const safePath = [...new Set(path)];
  const obstacles = [];
  for (let i = 0; i < size * size; i += 1) {
    if (!safePath.includes(i) && obstacles.length < level.difficulty + 1) {
      if ((i + level.levelNumber) % 3 === 0) obstacles.push(i);
    }
  }
  const answer = safePath.length - 1;
  setChoice(
    level.localizedContent.vi,
    `MI cần đi theo đường an toàn qua ${answer} bước để tới sao. Chọn số bước đúng.`,
    `${answer} bước`,
    [`${answer + 1} bước`, `${Math.max(1, answer - 1)} bước`],
    level.levelNumber,
  );
  setChoice(
    level.localizedContent.en,
    `MI needs the safe path with ${answer} moves to reach the star. Choose the correct number of moves.`,
    `${answer} moves`,
    [`${answer + 1} moves`, `${Math.max(1, answer - 1)} moves`],
    level.levelNumber,
  );
  level.metadata.deepData = {
    scene: 'maze',
    gridSize: size,
    startIndex,
    goalIndex,
    path: safePath,
    obstacles,
    commands: moves,
  };
  addLocalized(level, (locale) => ({
    steps: locale === 'en'
      ? ['Find MI', 'Avoid blocked squares', 'Reach the star']
      : ['Tìm MI', 'Tránh ô chặn', 'Tới ngôi sao'],
    pathSummary: locale === 'en' ? `${answer} safe moves` : `${answer} bước an toàn`,
  }));
}

function enrichKidsSudoku(level) {
  const symbols = level.difficulty >= 4 ? ['A', 'B', 'C', 'D'] : ['A', 'B', 'C'];
  const size = symbols.length;
  const solved = {};
  for (let row = 0; row < size; row += 1) {
    for (let col = 0; col < size; col += 1) {
      solved[row * size + col] = symbols[(row + col + level.levelNumber) % size];
    }
  }
  const blankIndex = (level.levelNumber * 2 + level.difficulty) % (size * size);
  const answer = solved[blankIndex];
  const givens = { ...solved };
  delete givens[blankIndex];
  const wrongs = symbols.filter((symbol) => symbol !== answer).slice(0, 2);
  setChoice(
    level.localizedContent.vi,
    `Ô trống cần ký hiệu không lặp trong hàng và cột. Chọn ${answer}.`,
    answer,
    wrongs,
    level.levelNumber,
  );
  setChoice(
    level.localizedContent.en,
    `The blank needs the symbol that does not repeat in its row and column. Choose ${answer}.`,
    answer,
    wrongs,
    level.levelNumber,
  );
  level.metadata.deepData = {
    scene: 'sudoku',
    gridSize: size,
    symbols,
    blankIndex,
    givens,
    answer,
  };
  addLocalized(level, (locale) => ({
    steps: locale === 'en'
      ? ['Check the row', 'Check the column', `Try ${answer}`]
      : ['Xem hàng', 'Xem cột', `Thử ${answer}`],
  }));
}

function enrichReasoningDetective(level) {
  const seed = detectiveSeeds[(level.levelNumber - 1) % detectiveSeeds.length];
  const clueCount = Math.min(seed.en.length, level.difficulty >= 4 ? 4 : 3);
  setChoice(
    level.localizedContent.vi,
    `Đọc các manh mối và chọn đáp án đúng: ${seed.vi.slice(0, clueCount).join(' ')}`,
    seed.answer,
    seed.wrong,
    level.levelNumber,
  );
  setChoice(
    level.localizedContent.en,
    `Read the clues and choose the correct answer: ${seed.en.slice(0, clueCount).join(' ')}`,
    seed.answer,
    seed.wrong,
    level.levelNumber,
  );
  level.metadata.deepData = {
    scene: 'detective',
    clueCount,
    answer: seed.answer,
  };
  addLocalized(level, (locale) => ({
    clues: locale === 'en' ? seed.en.slice(0, clueCount) : seed.vi.slice(0, clueCount),
  }));
}

function enrichFreeCreativity(level) {
  const seed = creativeSeeds[(level.levelNumber - 1) % creativeSeeds.length];
  setChoice(
    level.localizedContent.vi,
    `Chọn chi tiết giúp câu chuyện có cảm xúc ${seed.viFeeling}.`,
    seed.correctVi,
    seed.viCards.filter((card) => card !== seed.correctVi).slice(0, 2),
    level.levelNumber,
  );
  setChoice(
    level.localizedContent.en,
    `Choose the detail that makes the story feel ${seed.enFeeling}.`,
    seed.correctEn,
    seed.enCards.filter((card) => card !== seed.correctEn).slice(0, 2),
    level.levelNumber,
  );
  level.metadata.deepData = {
    scene: 'creative',
    cardCount: 3,
    targetFeeling: seed.enFeeling,
  };
  addLocalized(level, (locale) => ({
    storyLabels: locale === 'en'
      ? ['Setting', 'Feeling', 'Detail']
      : ['Bối cảnh', 'Cảm xúc', 'Chi tiết'],
    storyCards: locale === 'en' ? seed.enCards : seed.viCards,
  }));
}

const enrichers = {
  logic_maze: enrichLogicMaze,
  kids_sudoku: enrichKidsSudoku,
  reasoning_detective: enrichReasoningDetective,
  free_creativity: enrichFreeCreativity,
  story_comprehension: enrichStoryComprehension,
};

for (const gameId of deepGames) {
  const data = readGame(gameId);
  for (const level of data.levels) {
    level.metadata = level.metadata || {};
    enrichers[gameId](level);
  }
  writeGame(gameId, data);
  console.log(`Curated ${gameId}: ${data.levels.length} levels`);
}
