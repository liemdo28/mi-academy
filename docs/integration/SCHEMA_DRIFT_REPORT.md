# MI Academy — Schema Drift Report

**Date:** 2026-07-17  
**Owner:** Dev 7  
**Status:** Wave 0 — Audit

---

## 1. Summary

Schema drift occurs when the same domain concept has different schemas in different parts of the system. Found **9 active drift points** that must be resolved before release.

---

## 2. Active Drift Points

### SD-01: Game Result Contract — CRITICAL
- **Source of Truth (intended):** `MiGameResult` (shared_models.dart:428-503)
- **Backend expectation:** `SaveGameResultRequest` (schemas/progress.py) — **EMPTY**
- **Actual API behavior:** Uses `GameCompleteRequest` + `GameAttemptRequest` which lack 10 of 17 fields
- **Impact:** Game results sent via API lose 60% of data (no masteryEvidence, skillEvidence, durationSeconds tracking)
- **Severity:** INT-P1

### SD-02: Game Launch Contract — HIGH
- **Source of Truth (intended):** `MiGameLaunchRequest` (shared_models.dart:369-424)
- **Backend endpoint:** `/api/v1/games/{game_id}/start` only accepts `child_id`
- **Impact:** Game gets no accessibility prefs, no level content, no language — all fall back to defaults
- **Severity:** INT-P1

### SD-03: Game Snapshot — HIGH
- **Source of Truth:** `MiGameSnapshot` (shared_models.dart:507-542)
- **Backend:** No API endpoints exist
- **Impact:** No game resume functionality possible across updates
- **Severity:** INT-P1

### SD-04: Accessibility Preferences — MEDIUM
- **Source of Truth:** `AccessibilityPreferences` (shared_models.dart:309-340) with 5 fields
- **Python schema:** Only `high_contrast` field (1 of 5)
- **Impact:** 4 accessibility settings silently ignored by backend
- **Severity:** INT-P2

### SD-05: Audio Preferences — MEDIUM
- **Source of Truth:** `AudioPreferences` (shared_models.dart:342-365)
- **Python schema:** Only field names different (snake_case)
- **Impact:** Low — naming adapter handles this
- **Severity:** INT-P3

### SD-06: Lesson Response — MEDIUM
- **Source of Truth:** `Lesson` (shared_models.dart:134-158) + lesson.schema.json
- **Python API:** `LessonResponse` only has `id` and `title`
- **Impact:** Mobile cannot know age_group, difficulty, skills from API response
- **Severity:** INT-P2

### SD-07: LessonStatus Enum — MEDIUM
- **Dart:** `notStarted`, `learning`, `completed`, `needsPractice`, `mastered`
- **Python:** `not_started`, `learning`, `completed`, `needs_practice`, `mastered`
- **Impact:** Status stored as string, comparison fails without adapter
- **Severity:** INT-P2

### SD-08: Skill Evidence — MEDIUM
- **Contract:** `MiGameResult.skillEvidence: Map<String, dynamic>` — untyped
- **Expected:** Typed skill evidence with schema
- **Impact:** Adaptive engine cannot reliably parse skill evidence
- **Severity:** INT-P1 (for adaptive integration)

### SD-09: DailyPlanItem — LOW
- **Python API:** Has `title`, `subject`, `type`, `is_required`
- **Dart:** No equivalent class exists
- **Impact:** Dashboard/UI must implement mapping manually
- **Severity:** INT-P3

---

## 3. Schema Completeness Matrix

| Schema | JSON Schema | OpenAPI | Dart Model | Python Pydantic | ORM | Adapter |
|--------|------------|---------|-----------|----------------|-----|---------|
| Lesson | ✅ | ❌ | ✅ partial | ✅ partial | ✅ | ❌ |
| Question | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Level | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| ChildProfile | ❌ | ❌ | ✅ | ✅ partial | ✅ | ❌ |
| ParentProfile | ❌ | ❌ | ✅ | ✅ partial | ✅ | ❌ |
| MiGameResult | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| MiGameLaunchRequest | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| MiGameSnapshot | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| AccessibilityPreferences | ❌ | ❌ | ✅ | ✅ partial | ❌ | ❌ |
| AudioPreferences | ❌ | ❌ | ✅ | ✅ partial | ❌ | ❌ |
| LessonProgress | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| DailySession | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| AuthTokens | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |
| Reward | ❌ | ❌ | ✅ | ✅ partial | ✅ | ❌ |
| SyncEvent | ❌ | ❌ | ❌ | ✅ partial | ✅ | ❌ |
| AnalyticsEvent | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| SkillEvidence | ❌ | ❌ | ❌ (Map) | ❌ | ❌ | ❌ |

---

## 4. Required Actions

| ID | Action | Owner | Priority |
|----|--------|-------|----------|
| SD-01 | Implement SaveGameResultRequest with full MiGameResult fields | Dev 1 + Dev 7 | P1 |
| SD-02 | Extend GameStartRequest to full MiGameLaunchRequest | Dev 1 + Dev 7 | P1 |
| SD-03 | Create snapshot API endpoints (save/load/clear) | Dev 1 | P1 |
| SD-04 | Extend AccessibilityPreferencesSchema to 5 fields | Dev 1 + Dev 7 | P2 |
| SD-06 | Extend LessonResponse to match lesson.schema.json | Dev 1 + Dev 7 | P2 |
| SD-07 | Add enum adapters in Dart ↔ Python bridge | Dev 7 | P2 |
| SD-08 | Define SkillEvidence JSON Schema | Dev 5 + Dev 7 | P1 |
| All | Generate OpenAPI spec from routes | Dev 7 | P0 |

---

## 5. Migration Path

**Phase 1 (Week 1):**  
- Generate OpenAPI spec
- Implement missing Pydantic models
- Add snapshot endpoints

**Phase 2 (Week 2):**  
- Generate Dart API client
- Create adapter layer
- Update all imports

**Phase 3 (Week 3):**  
- Integration tests
- Migration scripts for existing data
- Compatibility matrix
