# Recommendation Engine Report — MI Academy

> **Date:** 2026-07-17
> **Owner:** Adaptive Learning AI & Analytics Lead
> **Package:** `packages/recommendation_core`

---

## 1. Scope

Deterministic offline-first recommendation engine with prerequisite enforcement,
reason codes for every decision, session planning, and fallback logic.

---

## 2. Architecture

**Core Engine (`recommendation_engine.dart`):**
- Filters content by: published status, offline availability, time limit, quality warnings
- Scores each candidate: prerequisite → mastery → difficulty → review due → exploration
- Builds `Recommendation` objects with full reason codes

**Prerequisite Checker (`prerequisite_checker.dart`):**
- `canAccess()` — returns false if any prerequisite has mastery < 0.15
- `getUnmetPrerequisites()` — lists missing prerequisites
- `getWeakestPrerequisiteMastery()` — identifies weakest link

**Session Planner (`session_planner.dart`):**
- Warmup (2 min) → Review (3-5 min) → Main learning (5 min) → Practice game (3 min) → Creative (optional)
- Respects `remainingMinutes` cap from parent settings
- Subject rotation enforced

---

## 3. Safety Guarantees

| Guarantee | Implementation |
|-----------|----------------|
| Reason codes on every recommendation | `reasonCodes[]` always non-empty |
| Engine version on every recommendation | `engineVersion` always present |
| Prerequisite enforcement | Unmet prereqs → score -1.0 (excluded) |
| Offline availability filtering | `offlineDownloaded` field checked |
| Parent time limit | `estimatedMinutes <= remainingMinutes` |
| Quality warning blocking | `qualityWarnings.isNotEmpty` → excluded |
| Published-only content | `isPublished == true` required |

---

## 4. Fallback Behavior

When no content passes all filters:
- `usedFallback: true` with `fallbackReason: 'NO_AVAILABLE_CONTENT'`
- Falls back to most recently practiced skill as review
- Child can always continue learning (no blocking)

---

## 5. Output Schema

```dart
Recommendation {
  recommendationId: String
  childProfileId: String
  type: RecommendationType (nextLesson/review/game/difficultyChange/warmup/creativeActivity)
  targetId: String
  priority: RecommendationPriority (unlock/weak/review/newContent/enrichment)
  score: double (0.0-1.0)
  confidence: double (0.0-1.0)
  reasonCodes: List<String>
  engineVersion: "recommendation-rule-v1"
  offlineAvailable: bool
}
```

---

## 6. Versions

| Version | Status |
|---------|--------|
| recommendation-rule-v1 | experimental |
| session-planner-v1 | experimental |

---

## 7. Integration Points

- **Dev 1:** Receives `RecommendationResult` → stores in DB → syncs to mobile
- **Dev 2:** Receives recommended `difficulty` and `levelId` → sets game difficulty
- **Dev 3:** Receives `qualityWarning` content → review queue

---

## 8. Next Actions

- [ ] Prerequisite graph data from `skill_taxonomy.json`
- [ ] Content → skillId mapping from Dev 3
- [ ] Unit tests for recommendation scenarios
- [ ] Session planner tests
- [ ] Dev 1 integration
