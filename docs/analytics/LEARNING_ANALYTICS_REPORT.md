# Learning Analytics Report — MI Academy

> **Date:** 2026-07-17
> **Owner:** Adaptive Learning AI & Analytics Lead
> **Package:** `packages/learning_analytics`

---

## 1. Scope

Learning analytics package providing struggle detection, parent insight generation,
level health analysis, and error pattern taxonomy.

---

## 2. Components

### 2.1 StruggleDetector

Detects 5 struggle signals from session evidence:
| Signal | Severity | Trigger | Suggested Action |
|--------|----------|---------|----------------|
| repeatedError | Moderate | 3+ wrong same difficulty | Show example |
| hintFlood | Mild | 4+ hints in ≤3 attempts | Gentle hint |
| longPause | Mild | Avg pause > 20s | Encouragement |
| levelRetry | Moderate | Retry same level ≥2 | Split task |
| randomTapping | High | All wrong <3s apart | Suggest break |

### 2.2 ParentInsightGenerator

Generates weekly parent insights with neutral language:
- Practice summary
- Review reminders
- Mastery achievements
- Subject balance notes

**Language:** Vietnamese and English supported.

### 2.3 LevelHealth

Detects content quality anomalies:
- Completion rate deviation
- Abnormal hint rates
- High abandon rates
- Anomalous duration

Status: `healthy` / `needsAttention` / `reviewRequired` / `qualityWarning`

### 2.4 ErrorTaxonomy

Taxonomy for categorizing educational errors:
- Math: OFF_BY_ONE, OPERATION_CONFUSION, PLACE_VALUE_ERROR, etc.
- Language: INITIAL_SOUND_CONFUSION, VOWEL_CONFUSION, LETTER_ORDER_ERROR, etc.
- Logic: TURN_DIRECTION_ERROR, SEQUENCE_ORDER_ERROR, MISSING_LOOP, etc.

---

## 3. Neutral Language Policy

All parent-facing output uses neutral language.

| ❌ Never say | ✅ Say instead |
|-------------|--------------|
| "Con đã quên" | "Có thể cần ôn tập" |
| "Con học chậm" | "Có thể cần luyện thêm" |
| "Con thất bại" | "Thử hoạt động khác" |
| "Dưới trung bình" | "Cần luyện thêm kỹ năng này" |
| "Chậm hơn trẻ khác" | Never compare children |

---

## 4. Next Actions

- [ ] Validate parent insight templates with content team
- [ ] Localize insights for all supported languages
- [ ] Integrate struggle detector with game engine
- [ ] Set level health thresholds from baseline data
