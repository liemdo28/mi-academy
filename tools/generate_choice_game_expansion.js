const fs = require('fs');
const path = require('path');

const outDir = path.join(__dirname, '..', 'apps', 'mobile', 'assets', 'levels');

function option(id, text, correct) {
  return { id, text: String(text), correct };
}

function makeChoices(correct, distractors) {
  const values = [correct, ...distractors]
    .map((value) => String(value))
    .filter((value, index, all) => all.indexOf(value) === index);
  while (values.length < 3) values.push(String(Number(correct) + values.length + 1));
  return [
    option('a', values[0], values[0] === String(correct)),
    option('b', values[1], values[1] === String(correct)),
    option('c', values[2], values[2] === String(correct)),
  ];
}

function rotatedChoices(correct, distractors, levelNumber) {
  const choices = makeChoices(correct, distractors);
  const correctIndex = choices.findIndex((choice) => choice.correct);
  const targetIndex = levelNumber % 3;
  const tmp = choices[targetIndex].text;
  choices[targetIndex].text = choices[correctIndex].text;
  choices[targetIndex].correct = true;
  choices[correctIndex].text = tmp;
  choices[correctIndex].correct = correctIndex === targetIndex;
  return choices.map((choice, index) => ({
    id: ['a', 'b', 'c'][index],
    text: choice.text,
    correct: choice.correct,
  }));
}

const gameSpecs = [
  {
    id: 'picture_word_match',
    skillIds: ['letters.vocabulary'],
    age: 'junior',
    viName: 'Nối từ với hình',
    enName: 'Picture Word Match',
    prompt(n, d) {
      const vi = ['mèo', 'bút', 'sách', 'bóng', 'cá', 'hoa'];
      const en = ['cat', 'pen', 'book', 'ball', 'fish', 'flower'];
      const i = (n + d) % vi.length;
      return {
        vi: [`Từ nào khớp với gợi ý: ${vi[i]}?`, vi[i], [vi[(i + 1) % vi.length], vi[(i + 2) % vi.length]]],
        en: [`Which word matches the clue: ${en[i]}?`, en[i], [en[(i + 1) % en.length], en[(i + 2) % en.length]]],
      };
    },
  },
  {
    id: 'rhyme_picker',
    skillIds: ['letters.rhyming'],
    age: 'junior',
    viName: 'Vần nào đúng?',
    enName: 'Rhyme Picker',
    prompt(n) {
      const pairs = [
        ['cat', 'hat', ['sun', 'dog']],
        ['mèo', 'bèo', ['bút', 'cá']],
        ['sing', 'ring', ['book', 'tree']],
        ['hoa', 'loa', ['nhà', 'bàn']],
      ];
      const p = pairs[n % pairs.length];
      return {
        vi: [`Từ nào cùng vần với "${p[0]}"?`, p[1], p[2]],
        en: [`Which word rhymes with "${p[0]}"?`, p[1], p[2]],
      };
    },
  },
  {
    id: 'speed_spelling',
    skillIds: ['letters.spelling'],
    age: 'explorer',
    viName: 'Chính tả nhanh',
    enName: 'Speed Spelling',
    prompt(n, d) {
      const words = [['school', 'scohol', 'shool'], ['apple', 'appel', 'aple'], ['trường', 'tường', 'trưỡng'], ['quyển', 'quển', 'qyuển']];
      const w = words[(n + d) % words.length];
      return { vi: ['Chọn cách viết đúng.', w[0], [w[1], w[2]]], en: ['Choose the correct spelling.', w[0], [w[1], w[2]]] };
    },
  },
  {
    id: 'sentence_order',
    skillIds: ['letters.simple_sentences', 'letters.sentence_completion'],
    age: 'explorer',
    viName: 'Sắp xếp câu',
    enName: 'Sentence Order',
    prompt(n) {
      const vi = [['Con mèo ngủ.', ['Ngủ mèo con.', 'Mèo con. ngủ']], ['Bé đọc sách.', ['Sách đọc bé.', 'Đọc bé sách.']]];
      const en = [['The cat sleeps.', ['Sleeps cat the.', 'Cat the sleeps.']], ['Mia reads books.', ['Reads Mia books.', 'Books reads Mia.']]];
      const i = n % vi.length;
      return { vi: ['Câu nào đúng thứ tự?', vi[i][0], vi[i][1]], en: ['Which sentence is in the right order?', en[i][0], en[i][1]] };
    },
  },
  {
    id: 'story_comprehension',
    skillIds: ['letters.reading_comprehension'],
    age: 'explorer',
    viName: 'Đọc hiểu truyện ngắn',
    enName: 'Story Comprehension',
    prompt(n, d) {
      const count = d + 2;
      return {
        vi: [`Lan đọc ${count} trang rồi nghỉ. Lan đã đọc mấy trang?`, count, [count - 1, count + 1]],
        en: [`Lan reads ${count} pages, then rests. How many pages did Lan read?`, count, [count - 1, count + 1]],
      };
    },
  },
  {
    id: 'object_counting',
    skillIds: ['math.counting'],
    age: 'junior',
    viName: 'Đếm đồ vật',
    enName: 'Object Counting',
    prompt(n, d) {
      const answer = d * 2 + (n % 4);
      return { vi: [`Có ${answer} ngôi sao. Có mấy ngôi sao?`, answer, [answer - 1, answer + 1]], en: [`There are ${answer} stars. How many stars are there?`, answer, [answer - 1, answer + 1]] };
    },
  },
  {
    id: 'number_quantity_match',
    skillIds: ['math.number_recognition.1_20'],
    age: 'junior',
    viName: 'Ghép số với số lượng',
    enName: 'Number Quantity Match',
    prompt(n, d) {
      const answer = Math.min(20, d * 3 + (n % 5));
      return { vi: [`Nhóm có ${answer} chấm. Chọn số đúng.`, answer, [answer - 2, answer + 1]], en: [`The group has ${answer} dots. Choose the number.`, answer, [answer - 2, answer + 1]] };
    },
  },
  {
    id: 'greater_less',
    skillIds: ['math.number_comparison'],
    age: 'junior',
    viName: 'So sánh lớn và bé',
    enName: 'Greater or Less',
    prompt(n, d) {
      const a = d * 5 + n % 7;
      const b = a + d + 1;
      return { vi: [`Số nào lớn hơn: ${a} hay ${b}?`, b, [a, b - 1]], en: [`Which number is greater: ${a} or ${b}?`, b, [a, b - 1]] };
    },
  },
  {
    id: 'number_sequence',
    skillIds: ['math.number_recognition.1_20', 'logic.pattern.basic'],
    age: 'junior',
    viName: 'Hoàn thành dãy số',
    enName: 'Number Sequence',
    prompt(n, d) {
      const step = Math.min(5, d);
      const start = n % 8;
      const answer = start + step * 3;
      return { vi: [`${start}, ${start + step}, ${start + step * 2}, ?`, answer, [answer - step, answer + step]], en: [`${start}, ${start + step}, ${start + step * 2}, ?`, answer, [answer - step, answer + step]] };
    },
  },
  {
    id: 'multiplication_adventure',
    skillIds: ['math.multiplication.tables'],
    age: 'explorer',
    viName: 'Bảng nhân phiêu lưu',
    enName: 'Multiplication Adventure',
    prompt(n, d) {
      const a = Math.min(9, d + 1);
      const b = 2 + (n % 8);
      const answer = a * b;
      return { vi: [`${a} × ${b} = ?`, answer, [answer + a, answer - a]], en: [`${a} × ${b} = ?`, answer, [answer + a, answer - a]] };
    },
  },
  {
    id: 'treasure_division',
    skillIds: ['math.division.basic'],
    age: 'explorer',
    viName: 'Chia đều kho báu',
    enName: 'Treasure Division',
    prompt(n, d) {
      const divisor = d + 1;
      const answer = 2 + (n % 6);
      const total = divisor * answer;
      return { vi: [`Chia ${total} viên ngọc cho ${divisor} bạn. Mỗi bạn được mấy viên?`, answer, [answer - 1, answer + 1]], en: [`Share ${total} gems among ${divisor} friends. How many each?`, answer, [answer - 1, answer + 1]] };
    },
  },
  {
    id: 'clock_time',
    skillIds: ['math.time.basic'],
    age: 'explorer',
    viName: 'Đồng hồ và thời gian',
    enName: 'Clock Time',
    prompt(n, d) {
      const hour = 1 + ((n + d) % 12);
      return { vi: [`Kim giờ chỉ ${hour}. Đồng hồ là mấy giờ?`, `${hour}:00`, [`${hour}:30`, `${(hour % 12) + 1}:00`]], en: [`The hour hand points to ${hour}. What time is it?`, `${hour}:00`, [`${hour}:30`, `${(hour % 12) + 1}:00`]] };
    },
  },
  {
    id: 'fun_measurement',
    skillIds: ['math.measurement'],
    age: 'explorer',
    viName: 'Đo lường vui nhộn',
    enName: 'Fun Measurement',
    prompt(n, d) {
      const cm = d * 10 + n;
      return { vi: [`Sợi dây dài ${cm} cm. Đơn vị đang dùng là gì?`, 'cm', ['kg', 'lít']], en: [`The ribbon is ${cm} cm long. Which unit is used?`, 'cm', ['kg', 'liter']] };
    },
  },
  {
    id: 'shape_builder',
    skillIds: ['math.shapes.basic', 'creative.shape_construction'],
    age: 'junior',
    viName: 'Hình học lắp ghép',
    enName: 'Shape Builder',
    prompt(n) {
      const shapes = [['tam giác', 'triangle'], ['hình vuông', 'square'], ['hình tròn', 'circle']];
      const s = shapes[n % shapes.length];
      return { vi: [`Hình có tên nào?`, s[0], ['hình sao', 'hình chữ nhật']], en: [`What is this shape called?`, s[1], ['star', 'rectangle']] };
    },
  },
  {
    id: 'visual_fractions',
    skillIds: ['math.fractions.visual'],
    age: 'master',
    viName: 'Phân số trực quan',
    enName: 'Visual Fractions',
    prompt(n, d) {
      const denom = d + 2;
      return { vi: [`Tô 1 trong ${denom} phần bằng nhau là phân số nào?`, `1/${denom}`, [`${denom}/1`, `2/${denom}`]], en: [`Shading 1 of ${denom} equal parts is which fraction?`, `1/${denom}`, [`${denom}/1`, `2/${denom}`]] };
    },
  },
  {
    id: 'odd_one_out',
    skillIds: ['logic.odd_one_out', 'logic.classification'],
    age: 'junior',
    viName: 'Tìm hình khác biệt',
    enName: 'Odd One Out',
    prompt(n) {
      const sets = [['táo, lê, xe', 'xe', ['táo', 'lê']], ['red, blue, spoon', 'spoon', ['red', 'blue']]];
      const s = sets[n % sets.length];
      return { vi: [`Cái nào khác nhóm: ${s[0]}?`, s[1], s[2]], en: [`Which one does not belong: ${s[0]}?`, s[1], s[2]] };
    },
  },
  {
    id: 'shadow_match',
    skillIds: ['logic.matching', 'logic.spatial_reasoning'],
    age: 'junior',
    viName: 'Ghép bóng với vật',
    enName: 'Shadow Match',
    prompt(n) {
      const items = [['cốc', 'cup'], ['chìa khóa', 'key'], ['lá', 'leaf']];
      const i = n % items.length;
      return { vi: [`Bóng này thuộc về vật nào?`, items[i][0], ['quả bóng', 'bàn']], en: [`Which object matches this shadow?`, items[i][1], ['ball', 'table']] };
    },
  },
  {
    id: 'logic_maze',
    skillIds: ['logic.maze', 'logic.navigation'],
    age: 'explorer',
    viName: 'Mê cung logic',
    enName: 'Logic Maze',
    prompt(n, d) {
      const steps = d + 1 + (n % 2);
      return { vi: [`MI cần đi ${steps} bước tới sao. Chọn lệnh đúng.`, `${steps} bước`, [`${steps + 1} bước`, `${Math.max(1, steps - 1)} bước`]], en: [`MI needs ${steps} steps to the star. Choose the command.`, `${steps} steps`, [`${steps + 1} steps`, `${Math.max(1, steps - 1)} steps`]] };
    },
  },
  {
    id: 'pattern_finder',
    skillIds: ['logic.pattern.recognition'],
    age: 'explorer',
    viName: 'Tìm quy luật',
    enName: 'Pattern Finder',
    prompt(n, d) {
      const step = d;
      const a = n % 5;
      const answer = a + step * 3;
      return { vi: [`${a}, ${a + step}, ${a + step * 2}, ?`, answer, [answer + step, answer - 1]], en: [`${a}, ${a + step}, ${a + step * 2}, ?`, answer, [answer + step, answer - 1]] };
    },
  },
  {
    id: 'kids_sudoku',
    skillIds: ['logic.conditions', 'logic.spatial_reasoning'],
    age: 'master',
    viName: 'Sudoku trẻ em',
    enName: 'Kids Sudoku',
    prompt(n, d) {
      const answer = ['A', 'B', 'C', 'D'][(n + d) % 4];
      return { vi: [`Ô trống cần ký hiệu chưa xuất hiện trong hàng. Chọn ${answer}.`, answer, ['A', 'C'].filter((x) => x !== answer).concat(['D']).slice(0, 2)], en: [`The blank needs the symbol missing from the row. Choose ${answer}.`, answer, ['A', 'C'].filter((x) => x !== answer).concat(['D']).slice(0, 2)] };
    },
  },
  {
    id: 'reasoning_detective',
    skillIds: ['logic.strategy', 'logic.algorithms'],
    age: 'master',
    viName: 'Thám tử suy luận',
    enName: 'Reasoning Detective',
    prompt(n, d) {
      return { vi: [`Nếu A đứng trước B và B đứng trước C, ai đứng đầu?`, 'A', ['B', 'C']], en: [`If A is before B and B is before C, who is first?`, 'A', ['B', 'C']] };
    },
  },
  {
    id: 'free_creativity',
    skillIds: ['creative.storytelling', 'letters.storytelling'],
    age: 'master',
    viName: 'Sáng tạo tự do',
    enName: 'Free Creativity',
    prompt(n, d) {
      const mood = d % 2 === 0 ? ['vui', 'happy'] : ['tò mò', 'curious'];
      return { vi: [`Chọn chi tiết giúp câu chuyện có cảm xúc ${mood[0]}.`, 'nhân vật mỉm cười', ['trời tối đen', 'cửa khóa']], en: [`Choose the detail that makes the story feel ${mood[1]}.`, 'the character smiles', ['the sky is dark', 'the door is locked']] };
    },
  },
];

function makeLevels(spec) {
  const levels = [];
  for (let i = 1; i <= 30; i += 1) {
    const difficulty = Math.ceil(i / 6);
    const ageGroup = difficulty <= 2 ? 'junior' : difficulty <= 4 ? 'explorer' : 'master';
    const p = spec.prompt(i, difficulty);
    levels.push({
      id: `${spec.id.replaceAll('_', '-')}-lv${String(i).padStart(3, '0')}`,
      gameId: spec.id,
      levelNumber: i,
      difficulty,
      learningObjective: `${spec.enName} tier ${difficulty}`,
      localizedContent: {
        vi: {
          prompt: p.vi[0],
          options: rotatedChoices(p.vi[1], p.vi[2], i),
        },
        en: {
          prompt: p.en[0],
          options: rotatedChoices(p.en[1], p.en[2], i),
        },
      },
      hints: [
        { text: `Cấp ${difficulty}: đọc kỹ câu hỏi và loại đáp án sai.` },
        { text: `Tier ${difficulty}: read carefully and remove the wrong choices.` },
      ],
      metadata: {
        ageGroup: spec.age === 'junior' ? ageGroup : spec.age,
        skillIds: spec.skillIds,
        contentKind: 'choice_progression',
        progressionTier: difficulty,
        reviewState: 'technically_validated',
      },
      assetRefs: [],
      contentVersion: 1,
      estimatedSeconds: 45 + difficulty * 10,
      publicationState: 'published',
    });
  }
  return { gameId: spec.id, schemaVersion: '1.0.0', levels };
}

for (const spec of gameSpecs) {
  const file = path.join(outDir, `${spec.id}.json`);
  fs.writeFileSync(file, `${JSON.stringify(makeLevels(spec))}\n`, 'utf8');
}

function readPack(gameId) {
  const file = path.join(outDir, `${gameId}.json`);
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function writePack(pack) {
  const file = path.join(outDir, `${pack.gameId}.json`);
  fs.writeFileSync(file, `${JSON.stringify(pack, null, 2)}\n`, 'utf8');
}

function expandedWordBuilderLevels() {
  const words = [
    ['nhà', 'house', ['n', 'h', 'à'], ['h', 'o', 'u', 's', 'e']],
    ['sách', 'book', ['s', 'á', 'c', 'h'], ['b', 'o', 'o', 'k']],
    ['bút', 'pen', ['b', 'ú', 't'], ['p', 'e', 'n']],
    ['trăng', 'moon', ['t', 'r', 'ă', 'n', 'g'], ['m', 'o', 'o', 'n']],
    ['hoa', 'flower', ['h', 'o', 'a'], ['f', 'l', 'o', 'w', 'e', 'r']],
  ];
  const levels = [];
  for (let i = 11; i <= 30; i += 1) {
    const difficulty = Math.ceil(i / 6);
    const w = words[i % words.length];
    levels.push({
      id: `wb-gen-${String(i).padStart(3, '0')}`,
      gameId: 'word_builder',
      levelNumber: i,
      difficulty,
      learningObjective: `Build tier ${difficulty} vocabulary words`,
      localizedContent: {
        vi: {
          prompt: difficulty >= 4 ? 'Ghép từ dài hơn!' : 'Ghép chữ thành từ!',
          targetWord: w[0],
          imageKey: `mi-word-${i}`,
          letters: w[2],
          distractors: ['a', 'e', 'i', 'o'].slice(0, Math.min(4, difficulty)),
        },
        en: {
          prompt: difficulty >= 4 ? 'Build the longer word!' : 'Build the word!',
          targetWord: w[1],
          imageKey: `mi-word-${i}`,
          letters: w[3],
          distractors: ['a', 't', 's', 'r'].slice(0, Math.min(4, difficulty)),
        },
      },
      hints: [
        { text: 'Nhìn từng chữ rồi ghép theo thứ tự.' },
        { text: 'Look at each letter and build the word in order.' },
      ],
      metadata: {
        ageGroup: difficulty <= 2 ? 'junior' : difficulty <= 4 ? 'explorer' : 'master',
        skillIds: ['letters.word_building'],
        progressionTier: difficulty,
        reviewState: 'technically_validated',
      },
      assetRefs: [],
      contentVersion: 1,
      estimatedSeconds: 50 + difficulty * 10,
      publicationState: 'published',
    });
  }
  return levels;
}

function expandedSoundMatchLevels() {
  const sounds = [
    ['letter_a', 'A', ['A', 'E', 'O']],
    ['letter_b', 'B', ['B', 'D', 'P']],
    ['letter_m', 'M', ['M', 'N', 'W']],
    ['word_cat', 'cat', ['cat', 'cap', 'can']],
    ['word_library', 'library', ['library', 'school', 'market']],
  ];
  const levels = [];
  for (let i = 11; i <= 30; i += 1) {
    const difficulty = Math.ceil(i / 6);
    const s = sounds[i % sounds.length];
    levels.push({
      id: `sm-gen-${String(i).padStart(3, '0')}`,
      gameId: 'sound_match',
      levelNumber: i,
      difficulty,
      learningObjective: `Listen and identify tier ${difficulty} sounds`,
      localizedContent: {
        vi: {
          prompt: difficulty >= 3 ? 'Nghe và chọn từ đúng!' : 'Nghe và chọn âm đúng!',
          correctAnswer: s[1],
          options: s[2],
          audioKey: s[0],
          audioTranscript: s[1],
        },
        en: {
          prompt: difficulty >= 3 ? 'Listen and choose the word!' : 'Listen and choose the sound!',
          correctAnswer: s[1],
          options: s[2],
          audioKey: s[0],
          audioTranscript: s[1],
        },
      },
      hints: [
        { text: 'Nghe lại rồi so sánh âm đầu.' },
        { text: 'Listen again and compare the first sound.' },
      ],
      metadata: {
        ageGroup: difficulty <= 2 ? 'junior' : difficulty <= 4 ? 'explorer' : 'master',
        mode: difficulty >= 3 ? 'word_sound' : 'letter_sound',
        skillIds: [difficulty >= 3 ? 'letters.listening_comprehension' : 'letters.initial_sound'],
        progressionTier: difficulty,
        reviewState: 'technically_validated',
      },
      assetRefs: [],
      contentVersion: 1,
      estimatedSeconds: 45 + difficulty * 8,
      publicationState: 'published',
    });
  }
  return levels;
}

function expandedMemoryLevels() {
  const labels = ['red', 'blue', 'green', 'star', 'book', 'pen', 'moon', 'sun'];
  const levels = [];
  for (let i = 11; i <= 30; i += 1) {
    const difficulty = Math.ceil(i / 6);
    const pairCount = Math.min(8, 2 + difficulty);
    const cards = [];
    for (let p = 0; p < pairCount; p += 1) {
      const text = labels[(i + p) % labels.length];
      cards.push({ id: `c${p * 2 + 1}`, content: text, pairId: `p${p + 1}`, type: 'text' });
      cards.push({ id: `c${p * 2 + 2}`, content: text, pairId: `p${p + 1}`, type: 'text' });
    }
    levels.push({
      id: `mc-gen-${String(i).padStart(3, '0')}`,
      gameId: 'memory_cards',
      levelNumber: i,
      difficulty,
      learningObjective: `Remember ${pairCount} matching pairs`,
      localizedContent: {
        vi: { prompt: `Tìm ${pairCount} cặp thẻ giống nhau!`, cards },
        en: { prompt: `Find ${pairCount} matching pairs!`, cards },
      },
      hints: [
        { text: 'Nhớ vị trí của thẻ vừa lật.' },
        { text: 'Remember where each card was.' },
      ],
      metadata: {
        gridCols: pairCount <= 4 ? 4 : 4,
        gridRows: Math.ceil((pairCount * 2) / 4),
        initialRevealMs: Math.max(700, 1600 - difficulty * 150),
        ageGroup: difficulty <= 2 ? 'junior' : difficulty <= 4 ? 'explorer' : 'master',
        skillIds: ['logic.memory'],
        progressionTier: difficulty,
        reviewState: 'technically_validated',
      },
      assetRefs: [],
      contentVersion: 1,
      estimatedSeconds: 60 + difficulty * 12,
      publicationState: 'published',
    });
  }
  return levels;
}

function expandedRobotLevels() {
  const levels = [];
  for (let i = 11; i <= 30; i += 1) {
    const difficulty = Math.ceil(i / 6);
    const steps = Math.min(5, difficulty + 1);
    const useTurn = difficulty >= 3 && i % 2 === 0;
    const required = useTurn
      ? ['START', 'MOVE_FORWARD', 'TURN_RIGHT', ...Array.from({ length: steps }, () => 'MOVE_FORWARD')]
      : ['START', ...Array.from({ length: steps }, () => 'MOVE_FORWARD')];
    levels.push({
      id: `rc-gen-${String(i).padStart(3, '0')}`,
      gameId: 'robot_commands',
      levelNumber: i,
      difficulty,
      learningObjective: useTurn ? 'Sequence with a turn' : 'Longer forward sequence',
      localizedContent: {
        vi: {
          prompt: useTurn ? 'Đi tới, rẽ phải, rồi đi tới đích!' : `Đi ${steps} bước tới ngôi sao!`,
          availableCommands: useTurn ? ['MOVE_FORWARD', 'TURN_RIGHT'] : ['MOVE_FORWARD'],
          requiredCommands: required,
        },
        en: {
          prompt: useTurn ? 'Move, turn right, then reach the goal!' : `Move ${steps} steps to the star!`,
          availableCommands: useTurn ? ['MOVE_FORWARD', 'TURN_RIGHT'] : ['MOVE_FORWARD'],
          requiredCommands: required,
        },
      },
      hints: [
        { text: useTurn ? 'Cần rẽ đúng hướng trước khi đi tiếp.' : 'Đếm số lần dùng lệnh Tiến.' },
        { text: useTurn ? 'Turn before the final forward steps.' : 'Count how many Forward blocks you need.' },
      ],
      metadata: {
        grid: useTurn ? { width: 2, height: steps + 1 } : { width: steps + 1, height: 1 },
        start: { x: 0, y: 0, facing: 'east' },
        goal: useTurn ? { x: 1, y: steps } : { x: steps, y: 0 },
        ageGroup: difficulty <= 2 ? 'junior' : difficulty <= 4 ? 'explorer' : 'master',
        skillIds: [useTurn ? 'logic.sequence.programming' : 'logic.navigation'],
        progressionTier: difficulty,
        reviewState: 'technically_validated',
      },
      assetRefs: [],
      contentVersion: 1,
      estimatedSeconds: 60 + difficulty * 10,
      publicationState: 'published',
    });
  }
  return levels;
}

function expandExistingPack(gameId, generatedLevels) {
  const pack = readPack(gameId);
  const generatedIds = new Set(generatedLevels.map((level) => level.id));
  pack.levels = [
    ...pack.levels.filter((level) => !generatedIds.has(level.id)),
    ...generatedLevels,
  ].sort((a, b) => a.levelNumber - b.levelNumber);
  writePack(pack);
}

expandExistingPack('word_builder', expandedWordBuilderLevels());
expandExistingPack('sound_match', expandedSoundMatchLevels());
expandExistingPack('memory_cards', expandedMemoryLevels());
expandExistingPack('robot_commands', expandedRobotLevels());

const summary = gameSpecs.map((spec) => ({
  id: spec.id,
  vi: spec.viName,
  en: spec.enName,
  levels: 30,
}));
console.log(JSON.stringify(summary, null, 2));
