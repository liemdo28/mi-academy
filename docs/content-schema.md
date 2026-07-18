# Versioned content schema (WS3)

Status: implemented and verified 2026-07-18. This document describes what
exists in the repository today, not an aspirational design.

## Envelope

The canonical schema is `schemas/level.schema.json` (JSON Schema, draft
2020-12). It formalizes the shape every entry in
`apps/mobile/assets/levels/*.json`'s `levels` array must have:

```json
{
  "id": "wb-lv01",
  "gameId": "word_builder",
  "levelNumber": 1,
  "difficulty": 1,
  "contentVersion": 1,
  "estimatedSeconds": 60,
  "publicationState": "published",
  "localizedContent": {
    "vi": {"prompt": "Ghép chữ thành từ!", "targetWord": "mèo", "letters": ["m","è","o"]},
    "en": {"prompt": "Build the word!", "targetWord": "cat", "letters": ["c","a","t"]}
  },
  "hints": [{"text": "Chữ đầu tiên là M"}],
  "metadata": {"ageGroup": "junior", "skillIds": ["letters.word_building"]}
}
```

Design decisions, and why they differ from a naive per-locale-file layout:

- **One record per level, both locales bundled together** (`localizedContent.vi`
  and `.en` in the same object), not one file/record per locale. This is
  the pattern real content already used before this schema was formalized;
  keeping it means a level's Vietnamese and English content can never drift
  out of sync by editing one locale's file and forgetting the other — VI/EN
  parity is structural, not a separate check to remember to run.
- **`id` is a short, readable, per-game-prefixed string** (`wb-lv01`,
  `mc-lv1-001`), not a UUID. Real content already used this convention;
  uniqueness is enforced by the validator (see below) scanning across all
  games, not by a UUID format constraint.
- **`ageBand` and `skillTags` are not separate top-level fields.** They are
  read from `metadata.ageGroup` and `metadata.skillIds` respectively (both
  already used by real content before this schema existed) via computed
  accessors (`MiLevel.ageBand`, `MiLevel.skillTags` in Dart;
  `ContentItem.age_band`, `ContentItem.skill_tags` in Python) rather than
  duplicated as their own stored fields. One place to disagree with itself
  is better than two.
- **`options` accepts two shapes**: a structured object
  (`{"id", "text", "correct"}`, used by the Choice Engine games — Math Race,
  Math Supermarket) or a plain string (used by Sound Match, paired with a
  separate `correctAnswer` field). Both are real, currently-shipping
  patterns — the schema was written to describe what exists, not to force
  a premature single shape onto games with genuinely different answer
  models.
- **`contentVersion`, `estimatedSeconds`, `publicationState` are new** (this
  pass) — see Migration policy below.

## Typed models

- **Dart**: `packages/mi_game_core/lib/src/models/mi_level.dart`'s `MiLevel`
  class, populated by `packages/mi_game_content/lib/src/content_loader.dart`'s
  `ContentLoader.parseLevel`. Parsing throws `ContentLoadException` with an
  actionable message for structurally invalid input (missing required
  field, out-of-range difficulty, invalid `publicationState`) — callers
  (`GameScreen._loadLevels`) already catch this and show a recoverable
  error state rather than crashing.
- **Python**: `apps/api/schemas/content_item.py`'s `ContentItem` (Pydantic).
  Not currently wired to a live backend endpoint — the six existing games
  ship content as bundled mobile assets, not via a backend content API —
  but validates against the *same* rules, proven by
  `tests/test_content_item_schema.py` accepting every real production level
  and rejecting the same malformed fixtures the mobile-side validator
  rejects (see "Cross-platform parity" below).

## Validation

Three layers, each catching what the others structurally can't:

1. **`schemas/level.schema.json`** (JSON Schema) — structural shape,
   enums, ranges, required fields. Enforced by both
   `tools/content_schema_validator.py` (Python, via the `jsonschema`
   library) and `apps/api/schemas/content_item.py` (Pydantic).
2. **`packages/mi_game_content/lib/src/content_validator.dart`**
   (`ContentValidator`) — the Dart-side equivalent, plus duplicate-ID
   detection within one game's level list. Runs in the mobile app's own
   test suite and (via `ContentLoader`) at content-load time.
3. **`tools/content_schema_validator.py`** — repository-level checks a
   generic schema can't express: every `metadata.skillIds` entry exists in
   `content/skills/skill_taxonomy.json`; level IDs are unique *across all
   six games*, not just within one game's own file; `assetRefs` entries
   that look like real file paths (contain `/` or a file extension) point
   at files that exist (bare symbolic keys like `"mi-fruit-apple"`,
   resolved by an in-app icon lookup rather than a filesystem asset, are
   correctly not flagged).

Run the repository-level validator:

```bash
python tools/content_schema_validator.py            # validates real content, exit 0 only if all valid
python tools/content_schema_validator.py --check-malformed   # proves malformed fixtures are rejected
```

Both are wired into `.github/workflows/ci.yml`'s `content-and-safety` job.

## Negative-test proof

`content/fixtures/malformed/*.json` — five deliberately broken fixtures,
each proven (via `tools/content_schema_validator.py --check-malformed` and
`tests/test_content_schema_validator.py` /
`tests/test_content_item_schema.py`) to fail with an actionable message:

| Fixture | What's wrong | Caught by |
|---|---|---|
| `missing_locale.json` | No `vi` key in `localizedContent` | schema `required: ["vi"]` |
| `invalid_difficulty.json` | `difficulty: 9` (valid range is 1-5) | schema `maximum: 5` |
| `unknown_skill_tag.json` | `skillIds` references a tag not in the taxonomy | `cross_check_skill_tags` |
| `duplicate_id_a.json` / `duplicate_id_b.json` | Same `id`, different games | cross-file duplicate-ID check |

## Cross-platform parity

`tests/test_content_item_schema.py::test_every_real_production_level_validates`
asserts all 60 real levels (6 games × 10 levels each, at time of writing)
parse successfully through the *Python* model. The equivalent Dart-side
proof is `tools/content_validator/validate_content.py` (already CI-gated)
plus `packages/mi_game_content/test/mi_game_content_test.dart`'s
`ContentLoader`/`ContentValidator` tests. Both sides agree on: required
fields, difficulty range, the `vi`-required locale rule, and the new
`contentVersion`/`estimatedSeconds`/`publicationState` field constraints.

## Migration policy

**Schema version lifecycle**: `schemas/level.schema.json`'s top-level
`"version"` field (currently `"1.0.0"`) and each level pack file's own
`schemaVersion` field (e.g. `apps/mobile/assets/levels/word_builder.json`'s
`"schemaVersion": "1.0.0"`) move together. A **patch** bump (1.0.0 → 1.0.1)
means a clarification or additive-optional-field change — old content
keeps parsing with no code change (this is exactly what happened when
`contentVersion`/`estimatedSeconds`/`publicationState` were added: every
existing level file was migrated to include them with safe defaults, and
`ContentLoader`/`ContentItem` both treat them as optional-with-defaults so
even a level file that *hadn't* been migrated would still parse). A
**minor** bump (1.x → 2.0) means a field that was optional becomes
required, or a shape changes (e.g. if `options` ever dropped the
plain-string form) — this requires a real migration pass across all
content files, not just a schema-file edit.

**Backward compatibility**: `ContentLoader.parseLevel` and `ContentItem`
both default every WS3-added field, so a level file written before this
schema pass still parses today. The only *new* hard requirement introduced
this pass is `localizedContent.vi` — already true of 100% of existing
content (verified directly), so this didn't require any migration.

**Migration procedure** (for a future minor/major bump): 1) update
`schemas/level.schema.json`, `MiLevel`/`ContentLoader`, and `ContentItem`
together in one reviewable commit; 2) run
`tools/content_schema_validator.py` against real content — every failure
it reports is a level that needs updating; 3) update the real content
files; 4) bump the file-level `schemaVersion` only once all levels in that
file pass; 5) re-run the full validator + `tools/level_validator/solve_levels.py`
(solvability must survive the migration) before merging.

**Deprecation**: a level is retired by setting `publicationState: "archived"`,
not by deleting it — this preserves any existing child's saved progress
against that level's stable `id` (see docs/offline-sync.md for how progress
keys off level `id`, not array position).

**Rollback**: since migrations are additive/optional-field changes at the
current schema version, rollback is reverting the commit that changed
content — no destructive schema migration exists yet that would need a
data-level rollback plan. This section will need a real rollback procedure
once schema 2.0 work begins.

**Mobile fallback behavior**: `MiLevel.contentForLocale(locale)` falls back
deterministically: requested locale → `vi` → whatever locale is actually
present. A structurally invalid level throws `ContentLoadException` at
load time, which `GameScreen._loadLevels` catches and turns into a
recoverable error screen (retry action), never a crash.
