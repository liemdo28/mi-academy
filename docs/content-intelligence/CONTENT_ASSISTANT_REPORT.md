# Content Intelligence Report — MI Academy

> **Date:** 2026-07-17
> **Owner:** Adaptive Learning AI & Analytics Lead
> **Package:** `packages/content_intelligence` (draft only)

---

## 1. Scope

Content intelligence supports Dev 3 in authoring content. It is a **draft-only tool**
for adult administrators — never for children.

---

## 2. Capabilities (Draft Only)

### 2.1 What AI CAN help with

| Task | Description |
|------|-------------|
| Question variants | Generate alternative questions for same skill |
| Distractor generation | Create plausible wrong answers |
| Explanation drafts | First-pass explanations for review |
| Hint ladders | Suggest hint escalation levels |
| Translation assistance | Draft translations for review |
| Skill tagging | Suggest skill tags for content |
| QA test generation | Generate test cases for content |
| Duplicate detection | Flag similar existing content |

### 2.2 What AI CANNOT do

```
❌ Auto-publish content
❌ Validate educational correctness without rules
❌ Approve content
❌ Send content directly to children
❌ Replace Dev 3 judgment
```

---

## 3. Pipeline

```
Dev 3 request
→ Apply content constraints (skillId, ageGroup, difficulty)
→ Generate draft
→ Structural validation
→ Answer validation (deterministic)
→ Age/appropriateness check
→ Language quality check
→ Duplicate check
→ Draft generated → DRAFT_GENERATED
→ Dev 3 reviews
→ Dev 3 approves or rejects
→ Only Dev 3 transitions to HUMAN_APPROVED
→ Only Dev 3 can publish
```

---

## 4. Validation Layers

| Layer | Method | Who |
|-------|--------|-----|
| Math answer | Recalculate with code | System |
| Word building | Verify grapheme | System |
| Robot commands | Run solver | System |
| Language appropriateness | Rule-based + human | System + Dev 3 |
| Age group fit | Constraint check | System |
| Duplication | Content fingerprint | System |
| Educational correctness | Human review | Dev 3 |

---

## 5. Safety Gates

- All drafts require Dev 3 approval before any child can access
- No draft can transition to `PUBLISHED` without Dev 3 action
- Content lifecycle state machine enforced at code level

---

## 6. Status

**DRAFT — NOT YET IMPLEMENTED.** Requires Dev 3 workflow definition.
Tier 3 generative AI capabilities are disabled until §27 safety controls are implemented.
