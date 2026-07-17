# Spaced Repetition Report — MI Academy

> **Date:** 2026-07-17
> **Owner:** Adaptive Learning AI & Analytics Lead
> **Package:** `packages/spaced_repetition`

---

## 1. Scope

Configurable spaced repetition scheduler. Computes review intervals based on mastery
status, adjusts intervals based on retention evidence, and generates parent-facing hints
in neutral language.

---

## 2. Default Intervals

| Status | Interval |
|--------|----------|
| not_started | 1 day |
| introduced | 2 days |
| developing | 3 days |
| proficient | 7 days |
| mastered | 21 days |
| review_due | 1 day |

---

## 3. Key Features

- **Retention adjustment:** Interval extends when child retains knowledge (score ≥ 0.7)
- **Forgetting curve:** Interval shortens when child has a retention gap > 7 days
- **Difficulty adjustment:** Suggests reducing difficulty after retention failure
- **Parent hints:** Neutral language only ("Có thể cần luyện thêm" not "Con đã quên")

---

## 4. Neutral Language Rules

❌ Prohibited: "con đã quên", "con học chậm", "con không nhớ"
✅ Allowed: "có thể cần ôn tập", "thử hoạt động trực quan", "đã lâu không luyện"

---

## 5. Offline Compatibility

✅ Fully offline — pure computation.

---

## 6. Next Actions

- [ ] Validate intervals with curriculum team
- [ ] Parent hint localization for all supported languages
- [ ] Integration with mastery engine for retention tracking
