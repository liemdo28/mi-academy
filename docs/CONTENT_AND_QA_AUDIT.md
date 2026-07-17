# MI Academy — Content & QA Audit

> **Audit date:** 2026-07-17
> **Auditor:** Dev 3 — Content, QA & Release Lead
> **Status:** Complete

---

## 1. Repository state

### Existing content assets

| Path | Status | Notes |
|------|--------|-------|
| `content/vi/words.json` | ✅ | 88 Vietnamese vocab entries (animals, fruits, family, colors, numbers, school, nature) |
| `content/schemas/lesson.schema.json` | ✅ | JSON Schema draft-07 for lessons; `age_group` uses `junior/explorer/master` |
| `content/schemas/question.schema.json` | ✅ | JSON Schema draft-07 for questions; supports `multiple_choice/text/image/audio` |
| `content/manifests/manifest_vi.json` | ✅ | 3 sample lesson stubs |
| `apps/mobile/assets/levels/memory_cards.json` | ✅ | 10 Memory Cards levels (vi+en), created in Foundation Sprint |
| `schemas/level.schema.json` | ✅ | Game-level schema (draft 2020-12), Foundation Sprint |

### Missing content assets

| Asset | Status | Priority |
|-------|--------|----------|
| `content/en/words.json` | ✅ Created by Dev 3 | P0 |
| `content/curriculum/age_*.json` | ✅ Created by Dev 3 | P0 |
| `content/skills/skill_taxonomy.json` | ✅ Created by Dev 3 | P0 |
| `memory_cards.json` | ✅ 10 levels, vi+en, Foundation Sprint | - |
| `word_builder.json` | ✅ 10 levels, vi+en | - |
| `sound_match.json` | ✅ 10 levels, vi+en | - |
| `math_race.json` | ✅ 10 levels, vi+en | - |
| `math_supermarket.json` | ✅ 10 levels, vi+en | - |
| `robot_commands.json` | ✅ 10 levels, vi+en (validated) | - |
| Sound Match audio files | ⏳ Audio assets pending | P1 |
| Math Supermarket product images | ⏳ Image assets pending | P1 |
| Robot Commands robot/grid sprites | ⏳ Image assets pending | P1 |

### Existing documentation (Dev 1/Dev 2 generated)

| Doc | Relevance to Dev 3 |
|-----|---------------------|
| `CURRENT_ARCHITECTURE.md` | High — platform contract reference |
| `GAME_PLATFORM_GAP_ANALYSIS.md` | High — content gap alignment |
| `FOUNDATION_SPRINT_REPORT.md` | High — what's already built |
| `LICENSE_DECISIONS.md` | High — license policy |
| `OPEN_SOURCE_AUDIT.md` | High — dependency allowlist |
| `THIRD_PARTY_NOTICES.md` | Medium — needs content/asset notices added |
| `GAME_OPEN_SOURCE_INVENTORY.md` | Medium — game-specific OSS |

### Existing test infrastructure

| Path | Status |
|------|--------|
| `packages/mi_game_core/test/` | ✅ 22 unit tests |
| `tests/test_game_core.py` | ✅ Python backend tests |
| `packages/*/test/` | Mostly empty — needs content tests |

### Existing schemas alignment

The `lesson.schema.json` uses `age_group: junior/explorer/master` which aligns
with the PRD's naming. The `level.schema.json` from the Foundation Sprint uses
numeric `difficulty` (1-5) which also aligns. No conflict detected — schemas
can coexist (lesson = pedagogical unit, level = game data unit).

---

## 2. Gap analysis summary

| Category | Ready? | Gap |
|----------|--------|-----|
| Skill taxonomy | ❌ | No skill IDs defined anywhere |
| Curriculum map | ❌ | Only 3 stub lessons in manifest |
| Content schemas | ⚠️ | Lesson + question exist; game-level, skill, audio, asset schemas missing |
| MVP content | ⚠️ | Memory Cards 10 levels done; other 5 games have no content |
| Content validator | ❌ | None exists |
| Level solver | ❌ | None exists |
| Open-source inventory | ⚠️ | `OPEN_SOURCE_AUDIT.md` covers deps but not referenced code/algorithms |
| Asset manifest | ⚠️ | `ASSET_LICENSE_MANIFEST.json` exists but empty/placeholder |
| QA test plan | ❌ | No master test plan |
| CI validation | ❌ | No content validation in CI |
| Child-safety checklist | ❌ | None |
| Release scorecard | ❌ | None |

---

## 3. Immediate blockers

1. **Skill taxonomy** — All content and progress tracking depends on stable skill IDs.
   Must be created before any game-specific content.
2. **Content schemas** — Word Builder, Sound Match, Math Race, Math Supermarket,
   and Robot Commands have no level schema defined.
3. **Content validator** — No automated way to prevent invalid content from merging.

---

## 4. Recommended action plan

See the full task list in the execution plan below. Priority order:
1. Skill taxonomy → 2. Curriculum map → 3. Content schemas → 4. MVP content →
5. Validators → 6. Level solvers → 7. OSS inventory → 8. QA plan → 9. Child safety →
10. Release scorecard
