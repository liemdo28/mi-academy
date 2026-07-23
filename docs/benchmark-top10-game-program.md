# MI Academy — Benchmark Top 10 Game Implementation Program

> **Status:** Active program — Milestone 0 complete, Milestones 1+ in progress
> **Date:** 2026-07-21
> **Owner:** Principal Educational Game Designer / Engineering Lead

---

## Phase 1 — Benchmark Selection Matrix

From the Deep Research Top 30 report, 10 products were selected using the
weighted model: 25% educational value, 20% age compatibility (5–12), 15%
reusable-engine potential, 15% bilingual applicability, 10% gameplay quality,
10% differentiation, 5% feasibility.

| # | Benchmark product | Domain | MI Academy game derived | Weighted score |
|---|---|---|---|---|
| 1 | Teach Your Monster to Read | Vietnamese literacy | **Hành Trang Âm Vần** (Sound & Word Adventure) | 91 |
| 2 | Khan Academy Kids + Lingokids | English literacy | **Phonics Quest** (English Phonics Quest) | 89 |
| 3 | DragonBox + Boddle + Prodigy | Mathematics | **Vương Quốc Số** (Number Kingdom) | 90 |
| 4 | DragonBox Geometry + Thinkrolls | Spatial reasoning | **Xưởng Hình Không** (Shape & Space Workshop) | 84 |
| 5 | LogicLike + Thinkrolls | Logic & deduction | **Phòng Thí Nghiệm Thám Tử** (Young Detective Logic Lab) | 85 |
| 6 | codeSpark + GCompris | Coding & sequencing | **Trung Tâm Robot** (Robot Mission Control) | 86 |
| 7 | PBS Kids + Khan Academy Kids | Science & discovery | **Phòng Thí Nghiệm Khoa Học** (Science Discovery Lab) | 82 |
| 8 | Toca Boca + Sago Mini | Creativity | **Thế Giới Sáng Tạo** (Creative World Builder) | 80 |
| 9 | Khan Academy Kids SEL + PBS Kids | Social-emotional | **Câu Chuyện Bạn Bè** (Emotion & Friendship Stories) | 78 |
| 10 | Sago Mini + LogicLike cognitive | Memory & executive function | **Hành Trình Trí Nhớ** (Memory Expedition) | 83 |

### Selection rationale per benchmark

#### 1. Teach Your Monster to Read → Hành Trang Âm Vần
- **Reason:** Strongest evidence that structured phonics progression retains
  children. 3-act journey model maps to MI Academy tier progression.
- **Principle extracted:** Linear literacy journey with mini-games placed at
  pedagogically deliberate moments; every interaction reinforces one phonics
  objective.
- **Weakness to avoid:** English-centric phonics — cannot transliterate to
  Vietnamese. MI Academy's version models Vietnamese orthography (dấu thanh,
  syllables, onset-rime) natively, not as English-phonics translation.
- **Existing engine:** Sound Match (listen→choose) + Word Builder (assemble) +
  Alphabet Explorer (recognition) + Missing Letter.
- **Missing:** Vietnamese-specific phonics-rule engine that understands
  Vietnamese syllable structure (consonant + vowel + tone).

#### 2. Khan Academy Kids + Lingokids → Phonics Quest
- **Reason:** Curriculum-breadth platforms that demonstrate retention through
  variety. Lingokids' content-cadence model is directly relevant.
- **Principle extracted:** Mixed-activity lessons (hear→identify→blend→build→
  read) create contextual application, not isolated drill.
- **Weakness to avoid:** Over-reliance on video content that requires streaming.
  MI Academy is offline-first.
- **Existing engine:** Sound Match + Word Builder + Choice Engine.
- **Missing:** English-specific phonics-rule engine (CVC, blends, digraphs,
  sight words).

#### 3. DragonBox + Boddle + Prodigy → Vương Quốc Số
- **Reason:** DragonBox proves abstract math can be taught through manipulation
  without symbols first. Prodigy proves quest-economy retains older children.
  Boddle proves adaptive reporting.
- **Principle extracted:** Start with visual quantity manipulation, progress to
  abstract symbols. Quest framing (unlock zones, collect rewards) provides
  purpose without manipulation.
- **Weakness to avoid:** Prodigy's battle mechanic can overshadow learning.
  MI Academy keeps the quest but makes math the primary interaction, not a
  gate between battles.
- **Existing engine:** Choice Engine (Math Race/Supermarket).
- **Missing:** Manipulative-quantity engine (drag-to-count, visual addition),
  fraction-bar engine.

#### 4. DragonBox Geometry + Thinkrolls → Xưởng Hình Không
- **Reason:** Spatial reasoning is underserved in the current catalog (no
  geometry game exists). Thinkrolls proves physics-based spatial puzzles work
  for ages 5–10.
- **Principle extracted:** Rotate, fit, construct, compare — hands-on spatial
  manipulation teaches geometry better than identification.
- **Existing engine:** Placement Engine (rotation-aware placement exists).
- **Missing:** Tangram/puzzle-placement engine, measurement engine.

#### 5. LogicLike + Thinkrolls → Phòng Thí Nghiệm Thám Tử
- **Reason:** LogicLike's 6,200+ puzzle library proves demand for deep logic
  content. Currently no deduction game exists.
- **Principle extracted:** Logic grids with clue interpretation force genuine
  reasoning, not guessing.
- **Weakness to avoid:** Cosmetic quizzes. Every puzzle must require
  observable-constraint reasoning.
- **Existing engine:** None — Logic Grid Engine must be built.
- **Missing:** Logic Grid Engine (clue interpretation, constraint elimination,
  grid-based deduction).

#### 6. codeSpark + GCompris → Trung Tâm Robot
- **Reason:** Robot Commands exists but only supports straight-line moves.
  codeSpark's word-free onboarding and loop/condition concepts must be added.
- **Principle extracted:** Command blocks → grid navigation → obstacles →
  loops → conditions → debugging. Progressive abstraction.
- **Existing engine:** Robot Commands (mi_blocks package).
- **Missing:** Loop blocks, condition blocks, function blocks, debug mode,
  collectible/obstacle variety in content.

#### 7. PBS Kids + Khan Academy Kids → Phòng Thí Nghiệm Khoa Học
- **Reason:** Science is in the skill taxonomy but has zero games. PBS Kids
  shows that observe→predict→test→explain loops teach science process skills.
- **Principle extracted:** Simulation components, not trivia screens.
- **Existing engine:** None — Simulation Engine must be built.
- **Missing:** Simulation Engine (state-based cause-effect models for
  plants/weather/materials/forces).

#### 8. Toca Boca + Sago Mini → Thế Giới Sáng Tạo
- **Reason:** Open-ended creativity is in the skill taxonomy but has zero
  games. Toca Boca's no-fail-state model is essential for creative confidence.
- **Principle extracted:** Place objects with meaningful relationships, create
  stories, save locally. No scoring of creativity.
- **Existing engine:** Placement Engine (could be extended for scene-building).
- **Missing:** Creative construction mode (scene-builder with object
  relationships, no win/lose state).

#### 9. Khan Academy Kids SEL + PBS Kids → Câu Chuyện Bạn Bè
- **Reason:** Social-emotional learning has no games. Interactive stories with
  branching choices teach empathy and decision-making.
- **Principle extracted:** Perspective taking, branching choices, consequence
  explanation. No moralizing or shame.
- **Existing engine:** None — Story/Branching-Choice Engine must be built.
- **Missing:** Story Engine (branching narrative, choice nodes, consequence
  tracking, reflection prompts).

#### 10. Sago Mini + LogicLike cognitive → Hành Trình Trí Nhớ
- **Reason:** Memory Cards exists (10 levels) but needs expansion and the
  Memory Engine needs generalization. Executive function (cognitive
  flexibility, working memory) is critical for ages 5–12.
- **Principle extracted:** Remember→reproduce, match-changing-rules, recall
  sequences, switch sorting conditions, increasing distractors.
- **Existing engine:** Memory Cards Game (single-game, needs generalization).
- **Missing:** Generalized Memory Engine (working memory, auditory memory,
  cognitive flexibility variants).

---

## Phase 2 — The 10 Original MI Academy Games

### Game 1: Hành Trang Âm Vần — Vietnamese Sound & Word Adventure

| Field | Value |
|---|---|
| **Game ID** | `vi_sound_word` |
| **Vietnamese title** | Hành Trang Âm Vần |
| **English title** | Sound & Word Adventure |
| **Age band** | junior (5–6), explorer (7–8) |
| **Domain** | Vietnamese literacy |
| **Engine** | Choice + Matching + Word Builder (existing) |
| **Skill IDs** | `letters.vi_phonics`, `letters.vi_tones`, `letters.vi_syllables`, `letters.word_building` |

**Educational outcomes:**
- Recognize all Vietnamese letters including ă, â, đ, ê, ô, ơ, ư
- Identify dấu thanh (sắc, huyền, hỏi, ngã, nặng)
- Discriminate initial and final sounds in Vietnamese syllables
- Assemble syllables from onset + rime + tone
- Build complete Vietnamese words

**Core loop:** Listen → identify sound → select matching letter/tone →
assemble syllable → complete word → celebrate with MI mascot.

**Content tiers:**
1. **Tier 1 (ages 5–6):** Letter recognition, initial sounds, tone matching
2. **Tier 2 (ages 6–7):** Syllable assembly, word construction
3. **Tier 3 (ages 7–8):** Listening discrimination, word families

**Minimum activities:** 30 levels across 3 tiers (10 per tier), bilingual
with Vietnamese-native content modeled correctly.

---

### Game 2: Phonics Quest — English Phonics Quest

| Field | Value |
|---|---|
| **Game ID** | `en_phonics_quest` |
| **Vietnamese title** | Hành Trình Phonics |
| **English title** | Phonics Quest |
| **Age band** | junior (5–6), explorer (7–8) |
| **Domain** | English literacy |
| **Engine** | Choice + Matching + Word Builder |
| **Skill IDs** | `letters.en_phonics`, `letters.en_cvc`, `letters.en_blends`, `letters.en_sight_words` |

**Educational outcomes:**
- Recognize English letter sounds (not letter names)
- Blend CVC words (consonant-vowel-consonant)
- Identify blends and digraphs
- Read sight words
- Apply phonics in short contextual challenges

**Content tiers:**
1. **Tier 1:** Letter sounds, initial sounds, simple CVC
2. **Tier 2:** Blends, digraphs, sight words
3. **Tier 3:** Short sentences, contextual application

---

### Game 3: Vương Quốc Số — Number Kingdom

| Field | Value |
|---|---|
| **Game ID** | `number_kingdom` |
| **Vietnamese title** | Vương Quốc Số |
| **English title** | Number Kingdom |
| **Age band** | junior, explorer, master |
| **Domain** | Mathematics |
| **Engine** | Choice + Placement (manipulative quantities) |
| **Skill IDs** | `math.counting`, `math.numberSense`, `math.addition`, `math.subtraction`, `math.comparison` |

**Educational outcomes:**
- Develop number sense through visual quantity manipulation
- Master counting, addition, subtraction
- Compare numbers and quantities
- Discover mathematical relationships through manipulation

**Core loop:** See quantity → manipulate → solve → discover → unlock next zone.

---

### Game 4: Xưởng Hình Không — Shape & Space Workshop

| Field | Value |
|---|---|
| **Game ID** | `shape_space` |
| **Vietnamese title** | Xưởng Hình Không |
| **English title** | Shape & Space Workshop |
| **Age band** | explorer, master |
| **Domain** | Spatial reasoning / geometry |
| **Engine** | Placement (rotation-aware) |
| **Skill IDs** | `math.geometry`, `logic.spatial`, `math.measurement` |

**Educational outcomes:**
- Identify and classify 2D and 3D shapes
- Understand symmetry and rotation
- Solve spatial puzzles (tangrams)
- Compare and construct shapes

---

### Game 5: Phòng Thí Nghiệm Thám Tử — Young Detective Logic Lab

| Field | Value |
|---|---|
| **Game ID** | `detective_logic` |
| **Vietnamese title** | Phòng Thí Nghiệm Thám Tử |
| **English title** | Young Detective Logic Lab |
| **Age band** | explorer, master |
| **Domain** | Logic & reasoning |
| **Engine** | Logic Grid (NEW) |
| **Skill IDs** | `logic.deduction`, `logic.classification`, `logic.pattern` |

---

### Game 6: Trung Tâm Robot — Robot Mission Control

| Field | Value |
|---|---|
| **Game ID** | `robot_mission` |
| **Vietnamese title** | Trung Tâm Robot |
| **English title** | Robot Mission Control |
| **Age band** | explorer, master |
| **Domain** | Coding & sequencing |
| **Engine** | Robot Commands (extended) |
| **Skill IDs** | `logic.algorithm`, `logic.sequence`, `logic.debugging` |

---

### Game 7: Phòng Thí Nghiệm Khoa Học — Science Discovery Lab

| Field | Value |
|---|---|
| **Game ID** | `science_lab` |
| **Vietnamese title** | Phòng Thí Nghiệm Khoa Học |
| **English title** | Science Discovery Lab |
| **Age band** | explorer, master |
| **Domain** | Science & discovery |
| **Engine** | Simulation (NEW) |
| **Skill IDs** | `science.observation`, `science.prediction`, `science.classification` |

---

### Game 8: Thế Giới Sáng Tạo — Creative World Builder

| Field | Value |
|---|---|
| **Game ID** | `creative_world` |
| **Vietnamese title** | Thế Giới Sáng Tạo |
| **English title** | Creative World Builder |
| **Age band** | junior, explorer, master |
| **Domain** | Creativity |
| **Engine** | Creative Construction (NEW, extends Placement) |
| **Skill IDs** | `creativity.visual`, `creativity.storytelling` |

---

### Game 9: Câu Chuyện Bạn Bè — Emotion & Friendship Stories

| Field | Value |
|---|---|
| **Game ID** | `emotion_stories` |
| **Vietnamese title** | Câu Chuyện Bạn Bè |
| **English title** | Emotion & Friendship Stories |
| **Age band** | junior, explorer, master |
| **Domain** | Social-emotional learning |
| **Engine** | Story/Branching (NEW) |
| **Skill IDs** | `sel.emotion_recognition`, `sel.empathy`, `sel.decision_making` |

---

### Game 10: Hành Trình Trí Nhớ — Memory Expedition

| Field | Value |
|---|---|
| **Game ID** | `memory_expedition` |
| **Vietnamese title** | Hành Trình Trí Nhớ |
| **English title** | Memory Expedition |
| **Age band** | junior, explorer, master |
| **Domain** | Memory & executive function |
| **Engine** | Memory (generalized from Memory Cards) |
| **Skill IDs** | `logic.memory`, `logic.working_memory`, `logic.attention` |

---

## Phase 3 — Engine Reuse Map

### Engines that EXIST (extend, don't duplicate)

| Engine | Package | Used by (existing) | Used by (new) |
|---|---|---|---|
| Choice | `apps/mobile/.../choice/` | Math Race, Math Supermarket, Alphabet, Missing Letter | Phonics Quest, Number Kingdom (partial) |
| Word Builder | `apps/mobile/.../word_builder/` | Word Builder | VI Sound & Word, Phonics Quest |
| Sound Match | `apps/mobile/.../sound_match/` | Sound Match | VI Sound & Word, Phonics Quest |
| Memory Cards | `apps/mobile/.../memory_cards/` | Memory Cards | Memory Expedition |
| Robot Commands | `apps/mobile/.../robot_commands/` + `mi_blocks` | Robot Commands | Robot Mission Control |
| Matching | `packages/mi_game_engines/.../matching/` | (test examples) | VI Sound & Word, Phonics Quest, Number Kingdom |
| Sequence | `packages/mi_game_engines/.../sequence/` | (test examples) | Number Kingdom, Detective Logic |
| Placement | `packages/mi_game_engines/.../placement/` | (test examples) | Shape & Space, Creative World |

### Engines that MUST BE BUILT

| Engine | Package location | Used by |
|---|---|---|
| Logic Grid | `packages/mi_game_engines/lib/src/logic_grid/` | Detective Logic Lab |
| Simulation | `packages/mi_game_engines/lib/src/simulation/` | Science Discovery Lab |
| Story/Branching | `packages/mi_game_engines/lib/src/story/` | Emotion & Friendship Stories |
| Generalized Memory | `packages/mi_game_engines/lib/src/memory/` | Memory Expedition |

### Engine design principles

1. **Rendering separate from rules** — each engine has `*_content.dart`
   (typed model), `*_controller.dart` (pure logic, no Flutter/storage deps),
   `*_screen.dart` (renderer).
2. **Content separate from engine** — content is JSON data conforming to
   `schemas/level.schema.json`; engine logic is reusable across content packs.
3. **Deterministic testing** — controllers are plain `ChangeNotifier`s with
   injectable clocks and deterministic shuffles.
4. **Normalized results** — every engine produces a result with `engineId`,
   `contentId`, `attempts`, `score`, `stars`, `duration`, `completed`.
5. **No storage coupling** — engines never write to Hive/backend/analytics;
   the host decides what to persist.
6. **Accessibility built-in** — every tappable element has Semantics labels,
   reduced-motion support, and tap-based alternatives to gestures.

---

## Implementation Milestone Schedule

| Milestone | Scope | Status |
|---|---|---|
| M0 | Audit, selection, architecture map | ✅ Complete |
| M1 | Shared schemas, curriculum adapters, new engine contracts | In progress |
| M2 | VI Sound & Word + Phonics Quest (literacy engines) | Pending |
| M3 | Number Kingdom + Shape & Space (math/spatial) | Pending |
| M4 | Detective Logic + Robot Mission (logic/coding) | Pending |
| M5 | Science Lab + Creative World (simulation/construction) | Pending |
| M6 | Emotion Stories + Memory Expedition (SEL/exec) | Pending |
| M7 | Cross-game mastery, rewards, garden integration | Pending |
| M8 | Full QA, performance, accessibility, release | Pending |

After each milestone: `flutter analyze`, `flutter test`, content validation,
Graphify update, logical commit.