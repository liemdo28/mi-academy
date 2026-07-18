# Skill taxonomy

The MI Academy 1.0 master spec (§8.1) lists 23 target skill tags across
`literacy.*`, `math.*`, `logic.*`, and `creativity.visual`. This document
records what's **already implemented and verified**, not a fresh design —
`content/skills/skill_taxonomy.json` predates this spec and already covers
the same ground with more granularity: **5 subjects, 62 skill IDs**,
verified via:

```
python3 -c "
import json
d = json.load(open('content/skills/skill_taxonomy.json', encoding='utf-8'))
print([s['subjectId'] for s in d['subjects']], sum(len(s['skills']) for s in d['subjects']))
"
# -> ['letters', 'math', 'logic', 'science', 'creative'] 62
```

## Mapping: spec tag → existing subject/skill IDs

| Spec tag (§8.1) | Existing subject | Example existing skill IDs |
|---|---|---|
| `literacy.alphabet` | `letters` | `letters.recognition.uppercase`, `letters.recognition.lowercase`, `letters.case_matching` |
| `literacy.phonics` | `letters` | `letters.initial_sound`, `letters.rhyming` |
| `literacy.vocabulary` | `letters` | `letters.word_building` |
| `literacy.spelling` | `letters` | (covered by `letters.word_building` tier; a dedicated `letters.spelling` tag should be added when Game 07 "Chính tả nhanh" is built) |
| `literacy.sentence` | `letters` | `letters.simple_sentences` |
| `literacy.reading` | `letters` | `letters.listening_comprehension` (reading-comprehension-specific tag needed for Game 09) |
| `math.counting` | `math` | (existing `math` subject skills cover counting/number sense; exact IDs not enumerated here — see `skill_taxonomy.json` directly) |
| `math.numberSense` / `.addition` / `.subtraction` / `.multiplication` / `.division` / `.time` / `.measurement` / `.geometry` / `.fractions` | `math` | See `content/curriculum/age_*.json`'s `math` skill lists per age band |
| `logic.memory` / `.pattern` / `.sequence` / `.spatial` / `.deduction` / `.algorithm` | `logic` | See `logic` subject in `skill_taxonomy.json` |
| `creativity.visual` | `creative` | Existing `creative` subject |

Two subjects (`science`, `creative`) already exist in the taxonomy beyond
what the master spec's §8.1 list names, which is fine — the spec's list is
a minimum, not a ceiling.

## Per-skill evidence rules (already implemented, exceeds spec)

Every skill entry already carries `prerequisites` (a real dependency graph,
not just a flat tag) and `evidenceRules` (`minimumAttempts`,
`minimumAccuracy`, `maximumHintRatio`) used to compute mastery — this is
more rigorous than the spec's minimum requirement ("mỗi level phải map tới
ít nhất một skill"). Example:

```json
{
  "skillId": "letters.word_building",
  "prerequisites": ["letters.recognition.lowercase", "letters.initial_sound"],
  "evidenceRules": {"minimumAttempts": 8, "minimumAccuracy": 0.75, "maximumHintRatio": 0.4}
}
```

## Gap

- The 24 not-yet-built games (see `docs/game-catalog.md`) have no skill IDs
  yet since their content doesn't exist. Each new game must add its skill
  IDs to `skill_taxonomy.json` (with prerequisites/evidence rules) as part
  of its Definition-of-Done, not invent a separate ad hoc tagging scheme.
- No automated check currently verifies every *level* (as opposed to every
  skill definition) actually references a valid, existing skill ID — a
  schema-validation gap worth closing before more content is authored at
  scale (see `docs/content-schema.md` validation requirements).
