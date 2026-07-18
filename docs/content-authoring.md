# Content authoring guide

How to add or edit a level in one of the six existing games, against the
schema described in `docs/content-schema.md`.

## Where content lives

Each game's levels are one JSON file: `apps/mobile/assets/levels/<gameId>.json`,
shaped as `{"gameId": ..., "schemaVersion": "1.0.0", "levels": [...]}`.

## Adding a level

1. Copy an existing level entry in the target game's file as a starting
   point — this guarantees you inherit the right shape for that game's
   `localizedContent` fields (Word Builder's `letters`/`targetWord`,
   Sound Match's `options`/`correctAnswer`, Robot Commands' `metadata.grid`,
   etc. all differ per game; there is no one generic template).
2. Give it a unique `id` following the game's existing prefix convention
   (e.g. `wb-lv11` for an 11th Word Builder level) — run
   `python tools/content_schema_validator.py` after adding it; a duplicate
   ID (even against a *different* game's file) is caught and reported by
   name.
3. Write both `localizedContent.vi` and `localizedContent.en` — `vi` is a
   hard requirement (the schema rejects a level missing it), and leaving
   `en` out means an English-locale child sees Vietnamese content via the
   fallback chain, which is correct *behavior* but not a complete English
   experience.
4. Set `metadata.ageGroup` to one of `junior` | `explorer` | `master` (see
   `docs/age-bands.md`) and `metadata.skillIds` to real IDs from
   `content/skills/skill_taxonomy.json` — an invented skill ID is caught by
   `tools/content_schema_validator.py`'s taxonomy cross-check, by name.
5. Set `difficulty` (1-5) to reflect where this level sits in that game's
   difficulty ramp — see each game's tier design in `docs/game-catalog.md`
   / the Milestone 1 spec for what should materially change between tiers
   (not just bigger numbers).
6. Leave `contentVersion`, `estimatedSeconds`, `publicationState` at their
   defaults (1, 60, `"published"`) unless you have a specific reason to
   change them (see `docs/content-schema.md`'s migration policy for when
   `contentVersion` should be bumped).

## Validating before committing

Run, in order:

```bash
python tools/content_validator/validate_content.py     # structural + curriculum checks
python tools/content_schema_validator.py                # schema + skill-tag + duplicate-ID checks
python tools/level_validator/solve_levels.py             # confirms the level is actually solvable
```

All three are also enforced in CI (`.github/workflows/ci.yml`'s
`content-and-safety` job) — a level that fails any of them will fail the
same way in CI as it does locally.

## Editing an existing level

Prefer editing the level's content in place over deleting and recreating
it with a new `id` — a child's saved progress is keyed off the level `id`
(see `docs/offline-sync.md`), so changing the ID orphans that progress. If
the *meaning* of the level changes enough that old progress against it is
no longer valid (e.g. the correct answer changes), bump `contentVersion`
and document why in the commit message, per `docs/content-schema.md`'s
migration policy.

## What NOT to do

- Don't pad a game's level count by duplicating a level's content under a
  new ID with cosmetic changes — the content minimums in the Milestone 1
  spec are about genuine variety, not ID count (see `docs/game-catalog.md`).
- Don't invent a new `metadata.skillIds` value instead of using or adding to
  `content/skills/skill_taxonomy.json` — an ad hoc tag breaks skill-evidence
  tracking silently (this exact drift was found and fixed once already,
  see `docs/release-audit.md`'s skill-taxonomy-alignment finding).
- Don't hardcode a level's user-facing strings anywhere outside
  `localizedContent` — see `docs/localization.md`.
