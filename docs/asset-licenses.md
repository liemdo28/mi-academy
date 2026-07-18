# Asset Licenses

This file records asset-license status for production content.

## Milestone 2 Slice - Alphabet Explorer

Alphabet Explorer adds no new image or audio files. Its 95 levels use text
letters and words only, with empty `assetRefs`, so there are no new external
asset licenses to record for this slice.

Validation evidence:
- `python tools/content_schema_validator.py` verifies asset references.
- `python tools/content_safety_audit.py --json` scans child-facing content.

## Milestone 2 Slice 2 - Missing Letter

Missing Letter adds no new image or audio files. Its 75 levels use text
words, letter gaps, choices, and hints only, with empty `assetRefs`, so
there are no new external asset licenses to record for this slice.

Validation evidence:
- `python tools/content_schema_validator.py` verifies asset references.
- `python tools/content_schema_validator.py --check-malformed` verifies
  Missing Letter malformed fixtures are rejected.
- `python tools/content_safety_audit.py --json` scans child-facing content.

Future Milestone 2 games that introduce pictures, silhouettes, audio, or
generated visuals must record stable asset IDs, source/license details,
semantic descriptions, child-safety review state, and usage references here
before being marked complete.
