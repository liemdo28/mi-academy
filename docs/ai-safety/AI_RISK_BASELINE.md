# AI Risk Baseline — MI Academy

> **Audit date:** 2026-07-17
> **Owner:** Adaptive Learning AI & Analytics Lead

---

## 1. Risk overview

This document identifies AI-related risks in the MI Academy adaptive learning system
and establishes mitigations. Risks are rated: **Critical / High / Medium / Low**.

---

## 2. AI decision risks

### 2.1 Child-facing recommendation without explanation

| Risk | Rating | Description |
|------|--------|-------------|
| Opaque difficulty changes | **Critical** | Child perceives unfairness when difficulty silently adjusts |
| Unexplained skip of content | **High** | Child confused about why a lesson was skipped |
| Irrelevant recommendations | **High** | Child disengaged by irrelevant content |

**Mitigation:**
- All recommendations include `reasonCodes[]` and `engineVersion`
- No difficulty decrease shown to child ("you went down a level")
- Fallback always available when recommendation engine fails

### 2.2 Labelling children

| Risk | Rating | Description |
|------|--------|-------------|
| Mastery score displayed as grade | **Critical** | Child sees "0.4 = bad student" |
| Struggle signal shown as failure | **Critical** | Messages like "you are struggling" create anxiety |
| Comparison between children | **High** | Ranking children by progress |

**Mitigation:**
- Mastery scores NEVER shown to children as numbers or letters
- Struggle signals trigger help, not labels
- Per blueprint §12: parent insights use neutral language only
- No cross-child comparison in any UI

### 2.3 Harmful content generation

| Risk | Rating | Description |
|------|--------|-------------|
| LLM generates incorrect educational content | **Critical** | Child learns wrong facts |
| LLM generates age-inappropriate content | **Critical** | Content not suitable for 5-12 year olds |
| LLM generates content with bias | **High** | Stereotypes, cultural bias in examples |

**Mitigation:**
- LLM output for content MUST go through: `DRAFT_GENERATED → VALIDATION_FAILED / READY_FOR_REVIEW → HUMAN_APPROVED → PUBLISHED`
- Deterministic validators for math, language, logic exercises
- Human review by Dev 3 REQUIRED before any content reaches children
- Prompt injection protection for admin content tools
- Prohibited topic filter for generation prompts

---

## 3. Safety controls checklist

| Control | Required | Implemented |
|---------|----------|-------------|
| Input schema validation | ✅ | ❌ |
| Output schema validation | ✅ | ❌ |
| Prompt versioning | ✅ | ❌ |
| Prompt injection protection | ✅ | ❌ |
| Prohibited topic filter | ✅ | ❌ |
| Child-facing output block | ✅ | ❌ |
| Human review gate | ✅ | ❌ |
| Rate limit | ✅ | ❌ |
| Cost limit | ✅ | ❌ |
| Timeout (max 10s) | ✅ | ❌ |
| Retry limit (max 1) | ✅ | ❌ |
| Offline fallback | ✅ | ❌ |
| Audit log | ✅ | ❌ |
| Model version tracking | ✅ | ❌ |

All controls must be implemented before Tier 3 (Generative AI) is enabled.

---

## 4. Data safety risks

### 4.1 Privacy violations

| Risk | Rating | Description |
|------|--------|-------------|
| Child UUID in AI service calls | **Critical** | Links learning data to identity |
| Parent email in model context | **Critical** | PII in AI pipeline |
| Child name in recommendations | **High** | PII in logs |

**Mitigation:**
- Use only `anonymousProfileKey` in all AI service calls
- Identity data never sent to model services
- Separate data planes: identity ↔ learning data ↔ AI service

### 4.2 Behavioral data misuse

| Risk | Rating | Description |
|------|--------|-------------|
| Session patterns used for profiling | **High** | Inferring learning disabilities |
| Timing data used to label speed | **Medium** | Inferring "slow learner" |
| Hint usage labeled as failure | **High** | Penalties for help-seeking |

**Mitigation:**
- Timing data normalized for accessibility mode
- Hint usage is evidence, not failure
- No inferring medical/psychological conditions

---

## 5. Prohibited AI uses

```
❌ Diagnosing learning disabilities
❌ Comparing children to each other
❌ Predicting IQ or cognitive ability
❌ Labelling children as "slow", "weak", "behind"
❌ Generating health or mental health advice
❌ Generating content with violence, explicit material
❌ Using child data for advertising
❌ Cross-app child tracking
❌ Selling or sharing child learning data
❌ Automated decisions with no human oversight for child-facing content
```

---

## 6. Risk monitoring

| Metric | Acceptable | Action |
|--------|-----------|--------|
| P0 safety incidents | 0 | Immediate escalation |
| P1 safety incidents | ≤ 1/month | Emergency review |
| PII leak events | 0 | Immediate data lockdown |
| Unvalidated content reaching children | 0 | Pause AI pipeline |
