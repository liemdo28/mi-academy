# AI Safety Review — MI Academy

> **Date:** 2026-07-17
> **Owner:** Adaptive Learning AI & Analytics Lead
> **Package:** `packages/ai_safety`

---

## 1. Overview

AI Safety package implements mandatory safety controls per blueprint §27.
Covers model registry, output validation, audit logging, and content lifecycle.

---

## 2. Safety Controls Status

| Control | Implemented | Location |
|---------|-------------|----------|
| Input schema validation | ✅ | SafetyValidator |
| Output schema validation | ✅ | SafetyValidator |
| Prompt versioning | ✅ | ContentDraft.promptVersion |
| Prompt injection protection | ⚠️ | Basic patterns only |
| Prohibited topic filter | ✅ | SafetyValidator |
| Child-facing output block | ✅ | ContentDraft.childFacing |
| Human review gate | ✅ | ContentLifecycle |
| Rate limit | ❌ | Needed |
| Cost limit | ❌ | Needed |
| Timeout | ❌ | Needed |
| Retry limit | ❌ | Needed |
| Offline fallback | ✅ | RecommendationEngine fallback |
| Audit log | ✅ | AuditLogger |
| Model version tracking | ✅ | ModelRegistry |

---

## 3. Model Registry

All adaptive models/rules are registered with status tracking:

| Model | Version | Status |
|-------|---------|--------|
| mastery-rule | v1 | experimental |
| recommendation-rule | v1 | experimental |
| session-planner | v1 | experimental |
| spaced-repetition-rule | v1 | experimental |
| struggle-detection-rule | v1 | experimental |
| difficulty-rule | v1 | experimental |

Status lifecycle: `experimental` → `shadow` → `canary` → `production` → `deprecated`

---

## 4. Audit Requirements

Every adaptive decision is logged with:
- Timestamp
- Model version
- Anonymous child profile key
- Input hash (not raw data)
- Output hash (not raw data)
- Reason codes
- Action type

---

## 5. Content Lifecycle

```
DRAFT_GENERATED
  ↓ (validation passes)
READY_FOR_REVIEW
  ↓ (Dev 3 approves)
HUMAN_APPROVED
  ↓ (Dev 3 publishes)
PUBLISHED
```

Invalid transitions are blocked at code level.

---

## 6. Required Actions Before Tier 3

1. Implement rate limiting on content assistant endpoints
2. Implement timeout and retry limits
3. Implement cost monitoring
4. Conduct prompt injection red-team review
5. Complete Dev 3 human review workflow
6. Pass security review
