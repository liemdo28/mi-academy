# Adaptive Release Readiness — MI Academy

> **Date:** 2026-07-17
> **Owner:** Adaptive Learning AI & Analytics Lead

---

## 1. Release readiness assessment

### 1.1 Quality gates status

| Gate | Status | Notes |
|------|--------|-------|
| Deterministic fallback pass | ✅ | Rule-based engine always available |
| Offline learning not blocked | ✅ | All Tier 1 rules are offline |
| Recommendation prerequisite compliance | ✅ | `PrerequisiteChecker` enforces this |
| Parent time limit respected | ✅ | Session planner enforces `remainingMinutes` |
| No prohibited data used | ✅ | No PII in adaptive engine |
| Reason codes on all recommendations | ✅ | Never empty |
| Model version on all outputs | ✅ | Always "*-rule-v1" |
| Audit log available | ✅ | `AuditLogger` implemented |
| Rollback available | ✅ | Model registry tracks status |
| Evaluation pass | ❌ | Unit tests written; scenario tests needed |
| Dev 3 educational safety review | ❌ | Pending |
| No P0/P1 safety issues | ✅ | No issues identified |
| No high privacy issues | ✅ | Privacy architecture reviewed |

### 1.2 Blocking items for production

1. **Unit test execution** — tests written, need to run
2. **Synthetic scenario validation** — `data/evaluation/mastery_scenarios.json` created, not yet run
3. **Dev 3 review** — prerequisite enforcement needs Dev 3 sign-off
4. **Dev 1 integration** — adaptive engine needs to be wired to `mi_game_progress`

---

## 2. Risk summary

| Risk | Severity | Mitigation |
|------|----------|------------|
| Child labelled by mastery score | Critical | Scores never shown to child |
| Wrong content recommended | High | Prerequisite enforcement + quality warnings |
| Offline fallback not tested | High | Need offline integration tests |
| Privacy leak | Critical | Anonymous keys enforced at engine boundary |
| LLM output to child | Critical | Tier 3 disabled until controls implemented |
| Recommendation loop | Medium | Subject diversity enforced in planner |

---

## 3. Recommended release path

### Phase 1 — Safe MVP (current)
- ✅ Tier 1 deterministic rules only
- ✅ Mastery calculation with safety bounds
- ✅ Offline-first with rule-based fallback
- ⏳ Unit tests + scenario validation
- ⏳ Dev 1 integration

### Phase 2 — Enhanced (post-MVP)
- Statistical difficulty calibration from aggregate data
- Statistical recommendation ranking
- Shadow-mode evaluation of enhancements

### Phase 3 — Generative AI (future)
- Tier 3 content drafts for Dev 3
- All §27 safety controls implemented
- Human review workflow operational
- Prompt injection protection verified
