# MI Academy — Curriculum Map

> **Version:** 1.0.0
> **Date:** 2026-07-17

---

## Overview

MI Academy covers 5 subjects across 3 age groups, each with a defined set
of skills. Game content maps to skills using stable skill IDs from the
skill taxonomy (`content/skills/skill_taxonomy.json`).

## Age groups

| Group | ID | Age | Label |
|-------|-----|-----|-------|
| Junior | `junior` | 5–7 | MI Junior |
| Explorer | `explorer` | 8–10 | MI Explorer |
| Master | `master` | 11–12 | MI Master |

## Subject areas

| Subject | ID | Skills (total) |
|---------|-----|----------------|
| Letters & Language | `letters` | 15 |
| Mathematics | `math` | 21 |
| Thinking & Logic | `logic` | 15 |
| Science & Life | `science` | 6 |
| Creativity & Arts | `creative` | 5 |
| **Total** | | **47** |

---

## Junior (5–7 years)

### Letters
- letters.recognition.uppercase
- letters.recognition.lowercase
- letters.case_matching
- letters.initial_sound
- letters.rhyming
- letters.word_building
- letters.simple_sentences
- letters.listening_comprehension

### Math
- math.number_recognition.1_20
- math.counting
- math.number_comparison
- math.addition.within_10
- math.addition.within_20
- math.subtraction.within_10
- math.subtraction.within_20
- math.shapes.basic
- math.time.basic
- math.currency.basic

### Logic
- logic.memory
- logic.matching
- logic.classification
- logic.odd_one_out
- logic.pattern.basic
- logic.navigation
- science.cause_effect
- science.observation

### Creative
- creative.color_recognition
- creative.shape_construction

---

## Explorer (8–10 years)

### Letters
- letters.spelling
- letters.vocabulary
- letters.reading_comprehension
- letters.synonyms_antonyms
- letters.sentence_completion

### Math
- math.addition.multi_digit
- math.subtraction.multi_digit
- math.multiplication.tables
- math.division.basic
- math.measurement
- math.fractions.visual

### Logic
- logic.pattern.recognition
- logic.maze
- logic.sequence.programming
- logic.loops

### Science
- science.symbol_recognition
- science.traffic
- science.environment

### Creative
- creative.tangram
- creative.bridge_building

---

## Master (11–12 years)

### Letters
- letters.advanced_comprehension
- letters.storytelling

### Math
- math.fractions.operations
- math.decimals
- math.percentage
- math.geometry
- math.word_problems

### Logic
- logic.conditions
- logic.algorithms
- logic.strategy
- logic.resource_optimization
- logic.spatial_reasoning

### Science
- science.simulation

### Creative
- creative.storytelling

---

## Game → Skill mapping

| Game | Primary skills | Age groups |
|------|---------------|------------|
| Memory Cards | logic.memory, logic.matching, letters.case_matching | All |
| Word Builder | letters.word_building, letters.initial_sound | Junior, Explorer |
| Sound Match | letters.initial_sound, letters.listening_comprehension | Junior, Explorer |
| Math Race | math.addition.*, math.subtraction.*, math.multiplication.* | All |
| Math Supermarket | math.currency.*, math.addition.*, math.word_problems | All |
| Robot Commands | logic.sequence.programming, logic.loops, logic.conditions | Explorer, Master |

---

## Mastery criteria

- Mastery threshold: 0.8 (80%)
- Minimum attempts per skill: varies by skill (4–12)
- Spaced recall interval: 2–3 days
- Factors: accuracy, attempts, hints used, spacing, difficulty level

See `content/skills/skill_taxonomy.json` for per-skill evidence rules.
