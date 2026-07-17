# Model Readiness Baseline — MI Academy

> **Audit date:** 2026-07-17
> **Owner:** Adaptive Learning AI & Analytics Lead

---

## 1. Readiness overview

This document establishes baseline readiness criteria for all models and rules
in the adaptive learning system. A model/rule can only reach "production" status
when all readiness gates pass.

---

## 2. Rule-based model readiness

### 2.1 Mastery-rule-v1

| Criterion | Status | Notes |
|-----------|--------|-------|
| Input schema defined | ✅ | skillMastery + gameResult |
| Output schema defined | ✅ | SkillMasteryState |
| Rule logic documented | ✅ | accuracy + independence + difficulty + retention |
| Configuration externalized | ✅ | weights in config JSON |
| Maximum single-attempt delta enforced | ✅ | +0.08 / -0.04 |
| Fallback defined | ✅ | return current score if invalid input |
| Unit tests exist | ❌ | Needed |
| Property-based tests exist | ❌ | Needed |
| Evaluation scenarios exist | ❌ | Needed |
| Offline compatible | ✅ | Pure computation |
| Privacy reviewed | ✅ | No PII required |

**Readiness: NOT READY** — unit tests and evaluation scenarios required.

### 2.2 Recommendation-rule-v1

| Criterion | Status | Notes |
|-----------|--------|-------|
| Prerequisite enforcement | ❌ | Not implemented |
| Reason codes defined | ❌ | Basic only |
| Session length compliance | ❌ | Not implemented |
| Offline fallback | ❌ | Not implemented |
| Parent time limit respected | ❌ | Not implemented |
| Subject diversity | ❌ | Not implemented |
| Unit tests exist | ❌ | Needed |
| Scenario tests exist | ❌ | Needed |

**Readiness: NOT READY** — major gaps.

---

## 3. Evaluation required before production

### 3.1 Mastery evaluation

| Test | Method | Pass criteria |
|------|--------|---------------|
| Stability | Repeated identical input → same output | Variance < 0.001 |
| Sensitivity | Correct → mastery increases | delta > 0 |
| Sensitivity | Incorrect → mastery decreases | delta < 0 |
| Hint penalty | High hints → lower mastery | penalty applied |
| Single outlier | One bad result → mastery doesn't collapse | drop < 0.05 |
| No single-attempt overshoot | One correct → mastery increases ≤ 0.08 | enforced by rule |
| Confidence calibration | More evidence → higher confidence | correlation exists |

### 3.2 Recommendation evaluation

| Test | Method | Pass criteria |
|------|--------|---------------|
| Prerequisite compliance | 100% recommendations satisfy prerequisites | no violations |
| Difficulty match | Recommended level within 1 tier of optimal | ≥ 90% |
| Subject diversity | No single subject > 60% of session | enforced |
| Session length | Total ≤ parent time limit | 100% compliant |
| Offline availability | 100% recommendations have offline content | enforced |
| Safety compliance | No prohibited content recommended | 0 violations |
| Fallback rate | < 5% of sessions need fallback | measured |

### 3.3 Struggle detection evaluation

| Test | Method | Pass criteria |
|------|--------|---------------|
| False positive rate | Signal when child not struggling | < 10% |
| False negative rate | Miss actual struggling | < 15% |
| Response suitability | Hint/suggestion is age-appropriate | ≥ 90% |
| No harmful labels | Output doesn't label child negatively | 0 violations |

---

## 4. Shadow mode requirements

Before promoting any model to production:

1. Run shadow mode for ≥ 7 days
2. Collect ≥ 100 recommendation comparisons
3. No P0/P1 safety incidents
4. Fallback rate < 20%
5. Dev 3 educational safety review passed
6. Dev 1 integration test passed
7. Rollback plan documented

---

## 5. Model registry status

| Model | Version | Status | Ready for production |
|-------|---------|--------|---------------------|
| mastery-rule | v1 | experimental | ❌ No tests |
| recommendation-rule | v1 | experimental | ❌ Incomplete |
| difficulty-rule | v1 | experimental | ❌ Incomplete |
| spaced-repetition-rule | v1 | experimental | ❌ Not built |
| struggle-detection-rule | v1 | experimental | ❌ Not built |

---

## 6. Next actions

1. Create unit tests for mastery-rule-v1 (blocking)
2. Create evaluation scenarios for all rules
3. Implement prerequisite enforcement in recommendation-rule
4. Implement offline fallback decision tree
5. Integrate with Dev 1 sync system
6. Shadow-mode evaluation campaign
7. Dev 3 educational safety review
