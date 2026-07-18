# Content Review Checklist

Use this checklist for every content batch before it can move beyond
`technically_validated`.

## Required Review Fields

| Field | Required value |
|---|---|
| Reviewer | Named reviewer or `automated validator only` |
| Locale | `vi`, `en`, or both |
| Game | Stable game ID |
| Item count | Number of reviewed items |
| Rejected count | Number of rejected items |
| Rejection reasons | Concrete reasons, or `none` |
| Approval date | ISO date, or `not approved` |
| Content version | File/schema content version |
| Status | `draft`, `technically_validated`, `language_reviewed`, `education_reviewed`, or `approved` |

## Review Criteria

- Age appropriate for the mapped age band.
- Language is accurate for the locale; Vietnamese diacritics are correct.
- Exactly one answer is correct unless the game mode explicitly supports multi-select.
- Distractors are plausible but not ambiguous.
- Skill tags exist in `content/skills/skill_taxonomy.json`.
- Difficulty tier matches the cognitive load of the item.
- Child-facing wording is calm and non-punitive.
- Content is culturally neutral and child-safe.
- Asset references are licensed and semantically appropriate.

## Current Batch Ledger

| Date | Game | Locale | Count | Rejected | Status | Evidence |
|---|---|---|---:|---:|---|---|
| 2026-07-18 | `alphabet_explorer` | `vi`, `en` | 95 | 0 | `technically_validated` | `python tools/content_schema_validator.py`; `python tools/content_safety_audit.py --json`; `flutter test test/alphabet_explorer_content_test.dart` |
| 2026-07-19 | `missing_letter` | `vi`, `en` | 75 | 0 | `technically_validated` | `python tools/content_schema_validator.py`; `python tools/content_schema_validator.py --check-malformed`; `python tools/content_safety_audit.py --json`; `flutter test test/missing_letter_content_test.dart`; detailed checklist: `docs/content-review/missing-letter-review-checklist.csv` |

## Missing Letter Review State

| Review gate | Status | Reviewer | Date |
|---|---|---|---|
| `technical_validation` | `approved` | automated validator only | 2026-07-19 |
| `language_review_vi` | `pending` | not assigned | not approved |
| `language_review_en` | `pending` | not assigned | not approved |
| `education_review` | `pending` | not assigned | not approved |

`docs/content-review/missing-letter-review-checklist.csv` contains one row
per item and locale with target word, incomplete display word, correct
answer, distractors, ambiguity check, spelling check, age-tier check, and
reviewer status. All human review fields remain pending.

No qualified human education review has been completed for these batches
yet, so they must not be labeled `education_reviewed` or `approved`.
