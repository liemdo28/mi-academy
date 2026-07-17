# MI Academy — Dev 3 Content, QA & Release Report

> **Report date:** 2026-07-17
> **Author:** Dev 3 — Content, QA & Release Lead
> **Status:** ✅ Complete

---

## 1. Deliverables Summary

### Skill Taxonomy
- **File:** `content/skills/skill_taxonomy.json` (23,566 bytes)
- **5 subjects:** letters, math, logic, science, creative
- **62 skills** across 3 age groups (junior, explorer, master)
- IDs follow PRD spec: `subject.skill_name` (e.g., `math.addition_within_10`)

### Curriculum Maps
- **Files:** `content/curriculum/age_5_7.json`, `age_8_10.json`, `age_11_12.json`
- Each maps skills → recommended games → suggested progression

### English Vocabulary
- **File:** `content/en/words.json` (8,099 bytes)
- 88 English words across 13 categories (animals, fruits, family, colors, numbers, school, nature, feelings, opposites, toys, food, transport, house)

### MVP Game Level Content

| Game | File | Levels | vi | en | Validator |
|------|------|--------|----|----|-----------|
| Memory Cards | `apps/mobile/assets/levels/memory_cards.json` | 10 | ✅ | ✅ | ✅ PASS |
| Word Builder | `apps/mobile/assets/levels/word_builder.json` | 10 | ✅ | ✅ | ✅ PASS |
| Sound Match | `apps/mobile/assets/levels/sound_match.json` | 10 | ✅ | ✅ | ✅ PASS |
| Math Race | `apps/mobile/assets/levels/math_race.json` | 10 | ✅ | ✅ | ✅ PASS |
| Math Supermarket | `apps/mobile/assets/levels/math_supermarket.json` | 10 | ✅ | ✅ | ✅ PASS |
| Robot Commands | `apps/mobile/assets/levels/robot_commands.json` | 10 | ✅ | ✅ | ✅ PASS |
| **Total** | | **60** | | | **ALL PASS** |

### Content Validation
- **Tool:** `tools/content_validator/validate_content.py`
- Validates: skill taxonomy references, difficulty ranges, localization completeness,
  card pairs, answer choices, option uniqueness, robot grid paths
- **Result:** `ALL CONTENT VALID` ✅

### Level Solver
- **Tool:** `tools/level_validator/solve_levels.py`
- Solves: Memory Cards (pair matching), Math Race (calculation), Robot Commands (pathfinding)

---

## 2. Level Design Philosophy

### Difficulty Progression
- **Levels 1-2 (difficulty 1):** Junior — letter/number recognition, basic matching
- **Levels 3-4 (difficulty 2):** Junior — initial sounds, addition/subtraction within 10
- **Levels 5-6 (difficulty 3):** Explorer — multiplication tables, loops, rhyming
- **Levels 7-8 (difficulty 4):** Explorer — division, mixed operations, conditions
- **Levels 9-10 (difficulty 5):** Master — fractions, word problems, algorithms

### Localization (vi/en)
All levels are fully bilingual with proper Vietnamese diacritics and culturally appropriate content.

### Accessibility
Each level includes `metadata.ageGroup` and `metadata.skillIds` for curriculum alignment.

---

## 3. What Remains (Post-MVP)

| Item | Priority | Status |
|------|----------|--------|
| Audio assets for Sound Match | P1 | Pending — needs audio recordings |
| Image assets for Math Supermarket | P1 | Pending — product images |
| Robot Commands robot/grid sprites | P1 | Pending — 2D sprites |
| Level solver edge cases | P2 | Pending |
| 20 additional levels per game | P2 | Pending |

---

## 4. Validation Results

```
$ python tools/content_validator/validate_content.py apps/mobile/assets/levels/
[OK] Skill taxonomy: 62 skills registered
[OK] Curriculum: age_5_7.json present
[OK] Curriculum: age_8_10.json present
[OK] Curriculum: age_11_12.json present
ALL CONTENT VALID ✅
```

---

## 5. Key Files

| File | Description |
|------|-------------|
| `content/skills/skill_taxonomy.json` | Master skill definitions (62 skills) |
| `content/curriculum/age_*.json` | Curriculum maps per age group |
| `content/vi/words.json` | Vietnamese vocabulary (88 words) |
| `content/en/words.json` | English vocabulary (88 words) |
| `apps/mobile/assets/levels/*.json` | All game level content (60 levels total) |
| `tools/content_validator/validate_content.py` | Content validation script |
| `tools/level_validator/solve_levels.py` | Level solver/simulation script |
| `schemas/level.schema.json` | Game level JSON schema |
