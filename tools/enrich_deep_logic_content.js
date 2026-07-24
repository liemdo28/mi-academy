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

function readGame(gameId) {
  return JSON.parse(
    fs.readFileSync(path.join(levelsDir, `${gameId}.json`), 'utf8'),
  );
}

function writeGame(gameId, data) {
  fs.writeFileSync(
    path.join(levelsDir, `${gameId}.json`),
    `${JSON.stringify(data, null, 2)}\n`,
    'utf8',
  );
}

function correctText(content) {
  const correct = content.options.find((option) => option.correct);
  return correct ? String(correct.text) : '';
}

function addLocalized(level, builder) {
  for (const locale of ['vi', 'en']) {
    const content = level.localizedContent[locale];
    content.deepData = builder(locale, content, level);
  }
}

function enrichLogicMaze(level) {
  const size = level.difficulty >= 4 ? 5 : 4;
  const startIndex = (size - 1) * size;
  const goalIndex = size - 1;
  const path = [];
  let row = size - 1;
  let col = 0;
  path.push(row * size + col);
  while ((row > 0 || col < size - 1) && path.length < size + level.difficulty + 2) {
    if ((path.length + level.levelNumber) % 2 === 0 && col < size - 1) {
      col += 1;
    } else if (row > 0) {
      row -= 1;
    } else {
      col += 1;
    }
    path.push(row * size + col);
  }
  if (!path.includes(goalIndex)) path.push(goalIndex);
  const obstacles = [];
  for (let i = 0; i < size * size; i += 1) {
    if (!path.includes(i) && (i + level.levelNumber) % 5 === 0) {
      obstacles.push(i);
    }
  }
  level.metadata.deepData = {
    scene: 'maze',
    gridSize: size,
    startIndex,
    goalIndex,
    path,
    obstacles: obstacles.slice(0, level.difficulty),
    commands: ['forward', 'turn-right', 'forward'],
  };
  addLocalized(level, (locale) => ({
    steps: locale === 'en'
      ? ['Find MI', 'Avoid blocks', 'Reach the star']
      : ['Tìm MI', 'Tránh ô chặn', 'Tới ngôi sao'],
    pathSummary: locale === 'en'
      ? `${path.length - 1} safe moves`
      : `${path.length - 1} bước an toàn`,
  }));
}

function enrichKidsSudoku(level) {
  const symbols = level.difficulty >= 4 ? ['A', 'B', 'C', 'D'] : ['A', 'B', 'C'];
  const size = symbols.length;
  const blankIndex = level.levelNumber % (size * size);
  const givens = {};
  for (let i = 0; i < size * size; i += 1) {
    if (i === blankIndex) continue;
    givens[i] = symbols[(i + Math.floor(i / size) + level.levelNumber) % symbols.length];
  }
  level.metadata.deepData = {
    scene: 'sudoku',
    gridSize: size,
    symbols,
    blankIndex,
    givens,
  };
  addLocalized(level, (locale, content) => ({
    steps: locale === 'en'
      ? ['Check the row', 'Check the column', `Try ${correctText(content)}`]
      : ['Xem hàng', 'Xem cột', `Thử ${correctText(content)}`],
  }));
}

function enrichReasoningDetective(level) {
  level.metadata.deepData = {
    scene: 'detective',
    clueCount: level.difficulty >= 4 ? 4 : 3,
  };
  addLocalized(level, (locale) => ({
    clues: locale === 'en'
      ? [
          'A stands before B.',
          'B stands before C.',
          'The first person has no one before them.',
          'Follow the order from left to right.',
        ].slice(0, level.metadata.deepData.clueCount)
      : [
          'A đứng trước B.',
          'B đứng trước C.',
          'Người đầu tiên không có ai đứng trước.',
          'Suy luận theo thứ tự từ trái sang phải.',
        ].slice(0, level.metadata.deepData.clueCount),
  }));
}

function enrichFreeCreativity(level) {
  level.metadata.deepData = {
    scene: 'creative',
    cardCount: 3,
  };
  addLocalized(level, (locale, content) => {
    const answer = correctText(content);
    return {
      storyLabels: locale === 'en'
        ? ['Setting', 'Feeling', 'Detail']
        : ['Bối cảnh', 'Cảm xúc', 'Chi tiết'],
      storyCards: locale === 'en'
        ? ['A small classroom', answer, 'A helpful choice']
        : ['Một lớp học nhỏ', answer, 'Một lựa chọn tốt bụng'],
    };
  });
}

function enrichStoryComprehension(level) {
  level.metadata.deepData = {
    scene: 'reading',
    passageKind: 'fact_lookup',
  };
  addLocalized(level, (locale, content) => {
    const answer = correctText(content);
    return {
      passage: locale === 'en'
        ? `Story note: read the sentence, keep the number ${answer} in mind, then choose the matching answer.`
        : `Ghi chú truyện: đọc câu chuyện, nhớ số ${answer}, rồi chọn đáp án khớp.`,
      steps: locale === 'en'
        ? ['Read the note', 'Find the number', 'Choose the match']
        : ['Đọc ghi chú', 'Tìm con số', 'Chọn đáp án khớp'],
    };
  });
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
  console.log(`Enriched ${gameId}: ${data.levels.length} levels`);
}
