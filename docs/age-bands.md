# Age bands

Verified directly against `content/curriculum/age_*.json` (already implemented,
not a new proposal) and mapped to the three age groups required by the MI
Academy 1.0 master spec (§4).

| Internal `ageGroup` id | Spec age band | Label (vi) | Label (en) | Curriculum file |
|---|---|---|---|---|
| `junior` | 5–7 | MI Junior (5–7 tuổi) | MI Junior (5–7 years) | `content/curriculum/age_5_7.json` |
| `explorer` | 8–10 | MI Explorer (8–10 tuổi) | MI Explorer (8–10 years) | `content/curriculum/age_8_10.json` |
| `master` | 11–12 | MI Master (11–12 tuổi) | MI Master (11–12 years) | `content/curriculum/age_11_12.json` |

Each curriculum file lists, per subject (`letters`, `math`, `logic`, plus
`science`/`creative` in the skill taxonomy), the skill IDs appropriate to
that age band and a bilingual description. This already matches the
per-age-band design guidance in the master spec (§4.1–4.3):

- **Junior (5–7):** short sentences, large icons, single-task screens,
  select/drag/drop/match/listen interactions over typing — see
  `content/curriculum/age_5_7.json`'s skill list, all drawn from
  recognition/matching-tier skills (`letters.recognition.*`,
  `letters.case_matching`, etc.) rather than open text entry.
- **Explorer (8–10):** multi-step tasks, increasing difficulty, applied
  word problems, short reading comprehension, simple logic sequences.
- **Master (11–12):** longer challenges, multi-step puzzles, fractions,
  exclusion-based deduction, situational content — deliberately excludes
  the youngest-skewing reward framing.

## Gap against the master spec

The spec's age-band design guidance (touch target sizing, feedback style,
countdown avoidance, etc.) is a **UI/UX and content-authoring discipline**,
not just a data model — the age-band *data* already exists and is used by
existing games' difficulty/content selection, but there is no automated
check that a given age band's UI actually follows the interaction-style
rules above (e.g. nothing currently asserts "Junior-tier games never use a
countdown timer" or "Junior touch targets are ≥56×56"). This should be a
content-review-checklist item (see `docs/content-review-checklist.md`) and,
ideally, part of each new game's Definition-of-Done review rather than an
automated gate, since it's a design judgment call per game.
