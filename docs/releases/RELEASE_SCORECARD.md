# MI Academy — Release Scorecard Template

> **Per-game quality score (max 100)**
> **Required: 85/100 total, 20/25 educational, 10/10 child safety**

---

## Game: _______________

| Category | Weight | Score | Max | Notes |
|----------|--------|-------|-----|-------|
| **Educational value** | 25 | | 25 | Clear objective, correct content, practice, explanation |
| **Usability** | 20 | | 20 | Child-friendly, tutorial works, buttons usable, no stuck states |
| **Engagement** | 15 | | 15 | Fun, varied, no dark patterns, interesting interaction |
| **Accessibility** | 15 | | 15 | Audio, subtitle, touch target ≥48px, reduced motion, tap alternative |
| **Technical quality** | 15 | | 15 | Stable, offline, save/restore, performant, tested |
| **Child safety** | 10 | | 10 | No ads, no links, no pressure, no excess data, no harmful content |
| **TOTAL** | 100 | | 100 | |

---

## Release gate checklist

- [ ] Total score ≥ 85/100
- [ ] Educational value ≥ 20/25
- [ ] Child safety = 10/10 (mandatory)
- [ ] Zero P0 bugs
- [ ] Zero P1 bugs
- [ ] No high privacy issues
- [ ] No license blockers
- [ ] Vietnamese + English content complete
- [ ] All unit tests pass
- [ ] All contract tests pass
- [ ] All content validation passes

---

## Evidence required from Dev 1 & Dev 2

| Category | Evidence needed |
|----------|----------------|
| Technical quality | Save/restore works (screenshot), offline works (screenshot), performance numbers |
| Usability | Screen recording of flow, no "stuck" states verified |
| Accessibility | Screen reader output, touch target measurement |
| Educational | Skill IDs referenced, explanation content verified |
| Engagement | No dark patterns confirmed, interaction varied |

---

## Approval

- [ ] Dev 1 sign-off: _______________ (date)
- [ ] Dev 2 sign-off: _______________ (date)
- [ ] Dev 3 sign-off: _______________ (date)
- [ ] Release approved: _______________ (date)
