# Level Health Report — MI Academy

> **Date:** 2026-07-17
> **Owner:** Adaptive Learning AI & Analytics Lead

---

## 1. Overview

Level health analysis detects content with anomalous performance data.
Does NOT auto-fix or auto-publish. Creates review requests for Dev 3.

---

## 2. Health Indicators

| Indicator | Healthy | Warning | Critical |
|-----------|---------|---------|---------|
| Completion rate | ≥ 0.70 | 0.50–0.70 | < 0.50 |
| Median attempts | ≤ 3 | 4–5 | > 5 |
| Hint rate | < 0.40 | 0.40–0.60 | > 0.60 |
| Abandon rate | < 0.10 | 0.10–0.20 | > 0.20 |

---

## 3. Review Triggers

Level enters `reviewRequired` when:
- Completion rate is significantly below expected (≥ 10% gap)
- Hint rate exceeds 60%
- Abandon rate exceeds 20%
- Anomalous median duration detected
- Crash/error events clustered at level

---

## 4. Review Request Flow

```
Level anomaly detected
→ Create LevelHealth report
→ Flag with reviewRecommended: true
→ Add reasonCodes (e.g., "COMPLETION_BELOW_EXPECTED")
→ Send to Dev 3 review queue
→ Dev 3 decides: fix, reject, or approve
→ Only Dev 3 can publish
```

---

## 5. Next Actions

- [ ] Define expected completion rates per game type from baseline
- [ ] Set minimum sample size (recommend ≥ 30 attempts)
- [ ] Integrate with Dev 3 CMS review workflow
- [ ] Build automated anomaly alerting
