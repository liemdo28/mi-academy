# Learning Data Gap Analysis — MI Academy

> **Audit date:** 2026-07-17
> **Owner:** Adaptive Learning AI & Analytics Lead

---

## 1. Data gap summary

| Gap | Severity | Description | Resolution |
|-----|----------|-------------|------------|
| No skill→level mapping | High | Cannot route game results to skill evidence | Content team creates `skill_game_mapping.json` |
| No confidence in mastery | High | Cannot distinguish sure vs. uncertain mastery | Add confidence field to SkillMastery |
| No mastery status enum | High | No distinction not_started/developing/proficient/mastered | Add SkillMasteryStatus to schema |
| No model version | Medium | Cannot track rule versions | Add `modelVersion` to all adaptive outputs |
| No reason codes | Medium | Cannot explain recommendations | Add `reasonCodes[]` to Recommendation |
| No prerequisite enforcement | High | May recommend inaccessible content | Add prerequisite check to RecommendationEngine |
| No offline fallback schema | High | No documented fallback behavior | Create `offline_fallback.dart` and docs |
| No event schema for analytics | High | Missing hint_requested, recommendation_served, etc. | Create `analytics_event.schema.json` |
| No level health schema | Medium | No standardized level quality report | Create LevelHealth schema |
| No parent insight schema | Medium | Inconsistent insight formats | Create ParentInsight schema |
| Coarse skill_progress table | Low | beginner/developing/proficient too coarse | Extend table with new columns |
| No error pattern taxonomy | Medium | Cannot categorize learning errors | Create ErrorPattern taxonomy |

---

## 2. Priority 1 gaps (MVP blocking)

### 2.1 Skill→Game mapping

**Problem:** `MiGameResult.skillEvidence` is untyped. The system cannot know which
skills a particular level is meant to exercise.

**Required data:**

```json
{
  "gameId": "word_builder",
  "levelIndex": 3,
  "skillIds": ["letters.word_building", "letters.initial_sound"],
  "difficulty": 2,
  "ageGroups": ["junior"]
}
```

**Action:** Dev 3 to create `content/skill_game_mapping.json` using `skill_taxonomy.json`
and game level data as source.

### 2.2 Mastery state schema upgrade

**Problem:** Current `SkillMastery` lacks confidence, status, and evidence count.

**Required fields:**

```dart
class SkillMasteryState {
  String childId;
  String skillId;
  double masteryScore;      // 0.0-1.0
  double confidence;       // 0.0-1.0, how certain we are
  int evidenceCount;       // number of independent attempts
  SkillMasteryStatus status; // not_started/developing/proficient/mastered/review_due
  DateTime? lastPracticedAt;
  DateTime? nextReviewAt;
  String modelVersion;     // "mastery-rule-v1"
}
```

### 2.3 Recommendation with reason codes

**Required fields per recommendation:**

```dart
class Recommendation {
  String recommendationId;
  String childProfileId;
  RecommendationType type; // next_lesson, review, game, difficulty_change
  String targetId;           // lessonId or gameId or null
  double score;              // 0.0-1.0
  double confidence;         // 0.0-1.0
  List<String> reasonCodes;  // e.g. ["PREREQUISITE_MASTERED", "DIFFICULTY_MATCH"]
  String engineVersion;      // "recommendation-rule-v1"
  String? fallback;          // what to use if this recommendation fails
}
```

---

## 3. Priority 2 gaps (Wave 1)

- Offline fallback decision tree documentation
- Analytics event schema
- Parent insight schema
- Level health report schema
- Error pattern taxonomy
- Session plan schema

---

## 4. Priority 3 gaps (Wave 2+)

- Statistical difficulty calibration (requires aggregate data)
- Churn/disengagement detection
- Content quality analysis
- Generative AI content drafts (requires Dev 3 workflow)

---

## 5. Offline-first capability gaps

| Capability | Current | Required | Action |
|-----------|---------|----------|--------|
| Local mastery update | Partial | Full rule-based mastery | Enhance `mi_game_progress` |
| Local review schedule | None | Spaced repetition scheduler | Create `spaced_repetition/` package |
| Local recommendation | None | Deterministic offline engine | Create `recommendation_core/` package |
| Local difficulty adjustment | Partial | Configurable rules | Enhance `adaptive_engine.dart` |
| Sync queue | Exists in DB | Sync-aware recommendation | Coordinate with Dev 1 |

---

## 6. Privacy gaps

- ❌ No data minimization audit for analytics events
- ❌ No retention policy documented
- ❌ No deletion propagation plan for adaptive data
- ❌ No pseudonymous key strategy documented

**Action:** Create `docs/ai-safety/PRIVACY_AND_BIAS_REVIEW.md` in Wave 0.

---

## 7. Evaluation dataset gaps

No synthetic evaluation datasets exist yet.

**Required datasets:**
- `data/evaluation/mastery_scenarios.json` — mastery stability, recovery, calibration
- `data/evaluation/recommendation_scenarios.json` — prerequisite compliance, safety
- `data/evaluation/difficulty_scenarios.json` — difficulty change accuracy
- `data/evaluation/struggle_scenarios.json` — false positive/negative rates
- `data/evaluation/content_generation_cases.json` — draft quality, validator pass rate
