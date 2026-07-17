# Adaptive System Audit — MI Academy

> **Audit date:** 2026-07-17
> **Owner:** Adaptive Learning AI & Analytics Lead
> **Status:** Wave 0 Baseline

---

## 1. Audit scope

This audit covers all systems, schemas, and code relevant to adaptive learning,
skill mastery, recommendation, analytics, and AI safety.

---

## 2. Existing schema inventory

### 2.1 Database schema (`docs/database-schema.md`)

| Table | Adaptive relevance | Notes |
|-------|-------------------|-------|
| `skill_progress` | ✅ Core | Has `skill_code`, `level`, `accuracy_pct`, `attempts`, `last_practiced` |
| `game_session` | ✅ Core | Has `correct_count`, `wrong_count`, `hint_used`, `stars_earned` |
| `attempt` | ✅ Core | Has `is_correct`, `time_spent_ms`, `attempt_no` |
| `lesson_completion` | ⚠️ Partial | Stars-based only; no skill evidence mapping |
| `usage_time` | ⚠️ Analytics | Daily bucket; session count only |
| `child` | ⚠️ Context | Has `age_group`; needed for recommendation |
| `game_level` | ✅ Context | Has `difficulty 1-5`; needed for calibration |
| `parent` | ⚠️ Settings | Has `daily_time_limit`; needed for session planning |

**Gap:** `skill_progress` uses coarse `skill_level` enum (`beginner/developing/proficient`).
Missing: confidence, evidence count, mastery score, next review date, model version.

### 2.2 Skill taxonomy (`content/skills/skill_taxonomy.json`)

- ✅ Structured with `skillId`, `name`, `ageGroup`, `difficultyMin/Max`, `prerequisites`, `evidenceRules`
- ✅ 5 subjects: letters, math, logic, science, creative
- ✅ Evidence rules: `minimumAttempts`, `minimumAccuracy`, `maximumHintRatio`
- ✅ Prerequisite chain documented
- ⚠️ No `levelId` → `skillId` mapping (needed for game result → skill evidence)
- ⚠️ No `gameId` → `skillId` mapping

### 2.3 Curriculum (`content/curriculum/age_*.json`)

- ✅ Age-grouped skill lists
- ✅ `dailyTimeMinutes`, `lessonsPerDay` bounds
- ⚠️ No skill → lesson mapping
- ⚠️ No skill → game mapping

### 2.4 Shared models (`packages/shared_models/lib/shared_models.dart`)

| Model | Adaptive relevance | Notes |
|-------|-------------------|-------|
| `ChildProfile` | ✅ Context | Has `ageGroup`, `preferredLanguage` |
| `LessonProgress` | ⚠️ Partial | Has `masteryScore` (0-1) but no confidence, evidenceCount |
| `MiGameResult` | ✅ Core | Has `correctCount`, `incorrectCount`, `hintCount`, `durationSeconds`, `skillEvidence` |
| `MiGameLaunchRequest` | ✅ Context | Has `ageGroup`, `language`, accessibility |

**Gap:** `LessonProgress` is lesson-based, not skill-based. `skillEvidence` in `MiGameResult`
is a `Map<String, dynamic>` — needs schema definition.

### 2.5 Progress packages

#### `packages/progress_core/` (Python — backend)

- `skill_mastery.dart`: Simple entity with `masteryScore`, `currentDifficulty`, `correctStreak`, `totalAttempts`, `totalCorrect`, `lastPlayedAt`, `reviewDueAt`
- `mastery_service.dart`: Weighted update (accuracy 60%, completion 20%, hints 20%); hintPenalty up to 20%
- `adaptive_engine.dart`: Difficulty adjustment (3+ attempts + 85% → +1 difficulty; 2+ attempts + 50% → -1); lesson recommendation (weak skills, due reviews, new content)

**Status:** Basic foundation exists. Gaps: no confidence, no reason codes, no prerequisite enforcement,
no session planning, no offline fallback, no AI safety.

#### `packages/mi_game_progress/` (Dart — Flutter client)

- `skill_mastery.dart`: Entity with `skillId`, `childId`, `mastery`, `totalAttempts`, `correctAttempts`, `totalHintsUsed`, `lastAttemptedAt`, `lastSpacedRecallAt`; `isMastered` (≥0.8); `needsRecall` (>2 days)
- `mastery_calculator.dart`: `calculate(attempts, difficulty)` — accuracy, hintPenalty, difficultyBonus; `recommendDifficulty(mastery)` — 5 tiers
- `attempt_record.dart`: Entity — `childId`, `gameId`, `levelId`, `correct`, `attemptedAt`, `duration`, `hintsUsed`
- `progress_tracker.dart`: Aggregates attempts and skills; Hive persistence; `getMastery`, `recommendDifficulty`, `masteredSkills`, `skillsNeedingRecall`

**Status:** Better structure than Python version. Gaps: no confidence, no status (not_started/introduced/developing/proficient/mastered/review_due),
no reason codes, no prerequisite enforcement, no session planner, no struggle detection, no offline fallback with server sync.

---

## 3. Analytics event audit

### 3.1 Currently tracked events

From database:
- `session_started` → `game_session` row with `started_at`
- `session_completed` → `game_session` row with `finished=true`
- `attempt_submitted` → `attempt` rows
- `level_abandoned` → implicit (session started but not finished)

### 3.2 Missing events (per blueprint §16)

| Missing event | Why needed |
|---------------|-------------|
| `session_completed` (with metadata) | Session planning feedback |
| `hint_requested` | Struggle detection, hint effectiveness |
| `snapshot_saved` | Save/resume analytics |
| `snapshot_restored` | Resume analytics |
| `recommendation_served` | Recommendation quality tracking |
| `recommendation_accepted` | Recommendation acceptance tracking |
| `content_error` | Level quality detection |
| `technical_error` | System health |

### 3.3 Prohibited data audit

✅ No PII in `MiGameResult`, `MiGameLaunchRequest`
✅ No GPS, contact, advertising ID in schema
