# Mastery Engine Report — MI Academy

> **Date:** 2026-07-17
> **Owner:** Adaptive Learning AI & Analytics Lead
> **Package:** `packages/mastery_core`

---

## 1. Scope

Rule-based skill mastery calculation engine. Computes mastery scores from
multiple evidence dimensions, maintains confidence, tracks status, and enforces
safety bounds on single-attempt delta.

---

## 2. Architecture

```
MasteryConfig (weights, thresholds, limits)
    └── MasteryEngine.evaluate()
            ├── Score computation (accuracy, independence, difficulty, retention, consistency)
            ├── Hint penalty application
            ├── Maximum delta enforcement (+0.08 / -0.04)
            ├── Confidence calculation
            ├── Status determination
            ├── Difficulty recommendation
            └── MasteryResult (state + components + reasonCodes)
```

---

## 3. Score Components

| Component | Weight | Description |
|-----------|--------|-------------|
| Accuracy | 35% | correct / total attempts |
| Independence | 20% | correct without hints / total correct |
| Difficulty | 15% | bonus scaled by difficulty level |
| Retention | 20% | practice spacing bonus |
| Consistency | 10% | recent attempt correctness |

---

## 4. Safety Bounds

| Rule | Value |
|------|-------|
| Max single-attempt increase | +0.08 |
| Max single-attempt decrease | -0.04 |
| First attempt initialization | 50% of raw score |
| Mastery threshold | 0.80 |
| Proficient threshold | 0.65 |
| Introduced threshold | 0.15 |

---

## 5. Inputs

- `MasteryState currentState` — previous state (nullable for new skill)
- `AttemptEvidence attempt` — single attempt evidence
- `bool accessibilityMode` — suppress timing penalties

---

## 6. Outputs

- `MasteryResult` with:
  - `updatedState: MasteryState` — new state
  - `scoreComponents: ScoreComponents` — breakdown
  - `confidenceComponents: ConfidenceComponents` — breakdown
  - `reasonCodes: List<String>` — always non-empty
  - `engineVersion: String` — "mastery-rule-v1"
  - `delta: double` — score change
  - `warningCodes: List<String>` — non-blocking issues

---

## 7. Versions

| Version | Status | Notes |
|---------|--------|-------|
| mastery-rule-v1 | experimental | Initial implementation |

---

## 8. Offline Compatibility

✅ Fully offline — pure computation, no network dependency.

---

## 9. Privacy

✅ No PII required. Uses `childId` and `skillId` only.

---

## 10. Known Limitations

- No cross-skill transfer learning (each skill is independent)
- No demographic adjustment
- No temporal model for forgetting curves (spaced repetition handles this)
- Statistical calibration requires aggregate data (TBD for Wave 2)

---

## 11. Next Actions

- [ ] Complete unit tests for all edge cases
- [ ] Validate against synthetic evaluation scenarios
- [ ] Shadow mode evaluation campaign
- [ ] Dev 1 integration with `mi_game_progress`
