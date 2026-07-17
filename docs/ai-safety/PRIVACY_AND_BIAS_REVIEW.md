# Privacy and Bias Review — MI Academy

> **Date:** 2026-07-17
> **Owner:** Adaptive Learning AI & Analytics Lead

---

## 1. Privacy Architecture

### 1.1 Data separation

| Layer | Data | Access |
|-------|------|--------|
| Identity | Parent email, child name, UUID | Dev 1 auth only |
| Learning | Mastery states, attempts, skill evidence | Adaptive engine |
| Analytics | Aggregate, anonymized events | Analytics pipeline |
| Model eval | Synthetic/anonymized datasets | Dev team |

### 1.2 Anonymous profile key

All adaptive engine inputs MUST use `anonymousProfileKey` — a pseudonymous
identifier that cannot be linked to identity data without explicit mapping.
Child UUID is NEVER sent to model services.

### 1.3 Prohibited in analytics events

```
GPS coordinates        — NEVER
Contact list          — NEVER
Advertising ID        — NEVER
Audio/video recording — NEVER
Keystroke outside game — NEVER
Child display name    — NEVER
Parent email/credentials — NEVER
Device serial number  — NEVER
Cross-app tracking   — NEVER
```

---

## 2. Bias Prevention

### 2.1 Fairness criteria

The system must NOT produce systematically different recommendations based on:

| Factor | Protection |
|--------|------------|
| Device performance | Timing normalized for accessibility |
| Language | All languages treated equally |
| Offline status | Offline ≠ worse recommendations |
| Accessibility settings | Screen reader → no time penalty |
| Session frequency | No penalty for intermittent use |

### 2.2 Accessibility normalization

When `accessibilityMode: true`:
- Duration-based signals are suppressed
- Hints are not penalized as heavily
- Timing evidence is flagged for normalization

### 2.3 Prohibited inferences

```
❌ Inferring learning disabilities from session patterns
❌ Inferring IQ or cognitive ability from timing data
❌ Labelling children as "slow", "weak", "behind"
❌ Comparing children to each other
❌ Predicting future academic performance
```

---

## 3. Data Retention

- Individual learning events: 90-day rolling window
- Aggregate analytics: indefinite
- Mastery states: retained until child profile deleted
- Deletion propagation: when child deleted, delete all mastery, events, recommendations

---

## 4. Privacy review checklist

- [ ] No child UUID in AI service calls
- [ ] No parent credentials in model context
- [ ] Anonymous profile key used in all adaptive engine calls
- [ ] Analytics events validated for prohibited fields
- [ ] Deletion hooks tested for all adaptive data
- [ ] No cross-child comparison in any UI or analytics
- [ ] Timing data normalized in accessibility mode
- [ ] Prompt injection protection for admin content tools
