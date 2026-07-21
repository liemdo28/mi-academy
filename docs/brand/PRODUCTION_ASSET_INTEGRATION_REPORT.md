# Mi Academy Production Asset Integration Report

Last updated: 2026-07-20

## Verdict

Production brand readiness: **NOT READY**.

No final designer-approved production artwork was found in the current workspace or in the supplied attachment folder for this phase. The app remains on centralized temporary vector placeholders for logo, mascot, brand icons, and Android adaptive icon layers.

## Assets Supplied

- None found in `assets/branding/`.
- None found in `packages/design_system/assets/branding/`.
- The phase attachment only contained request text, not production SVG or PNG exports.

## Assets Accepted

- None.

## Assets Rejected

- None. No production asset files were available to inspect.

## Assets Still Missing

Required source files still missing from `assets/branding/`:

- Logo SVGs: `mi_academy_primary.svg`, `mi_academy_stacked.svg`, `mi_academy_symbol.svg`, `mi_academy_monochrome.svg`.
- Mascot SVGs: `welcome.svg`, `success.svg`, `thinking.svg`, `confused.svg`, `excited.svg`, `encouraging.svg`, `try_again.svg`, `celebration.svg`, `apology.svg`, `love.svg`, `sleeping.svg`, `surprised.svg`.
- Learning icons: `alphabet.svg`, `numbers.svg`, `logic.svg`, `memory.svg`, `writing.svg`, `listening.svg`.
- Reward icons: `reward_star.svg`, `achievement.svg`, `progress.svg`.
- Profile icons: `profile.svg`, `parent.svg`, `report.svg`.
- Navigation icons: `world.svg`, `exploration.svg`, `garden.svg`, `offline.svg`.
- Android app icon sources: `foreground.svg`, `background.svg`, `monochrome.svg`, `play_store_512.png`.
- iOS app icon source: `app_icon_master_1024.png`.

Total missing production source assets: **37**.

## Integration Status

- Logo: still uses centralized placeholder fallback.
- Mascot: still uses centralized placeholder fallback for all emotions.
- Brand icons: still use centralized fallback drawing and placeholder paths.
- Android app icon: adaptive and round adaptive XML are configured, but both still reference placeholder foreground and monochrome layers.
- iOS app icon: asset catalog is structurally present, but final branded raster exports are still required.

## Placeholder Removal Status

No placeholder files or fallback code were removed in this phase because no approved replacement assets were available.

Temporary placeholders remain intentionally isolated under:

- `assets/branding/placeholders/`
- `packages/design_system/assets/branding/placeholders/`
- Android launcher placeholder vector layers in `apps/mobile/android/app/src/main/res/drawable/`

## Golden Preview Status

Goldens were not regenerated for this phase. Regenerating visual baselines without final artwork would lock in placeholder imagery as the expected production result.

Existing Home Screen golden coverage from Phase 1 remains the current visual baseline:

- Phone Vietnamese.
- Phone English.
- Tablet Vietnamese.
- Tablet English.

## Automated Validation

Added `tools/validate_brand_assets.dart`.

Use:

- `dart run tools\validate_brand_assets.dart` for a non-failing status report.
- `dart run tools\validate_brand_assets.dart --strict` as the production gate. This intentionally fails until all required production assets and app icon layers are supplied.

The validator checks:

- Required source assets.
- Matching runtime design-system asset copies.
- SVG structure and common production blockers.
- Android launcher icon references.
- iOS AppIcon catalog structure.
- Placeholder references.
- Unexpected production files that are not mapped by `MiBrandAssets`.

## Deviations From Approved Brand Guide

- Final mascot artwork is absent, so the child character in the brand reference is not yet represented by approved production art.
- Final logo artwork is absent, so exact Mi Academy lockups are not yet represented by approved production art.
- Final sticker-style icons are absent, so brand category icons still depend on centralized fallbacks.
- Android and iOS app icons are not final branded exports.

## Designer Actions Required

1. Provide all 37 required production source assets using the exact filenames in `ASSET_REQUIREMENTS.md`.
2. Confirm SVGs use transparent backgrounds, outlined text, no embedded raster images, and no external references.
3. Provide Android adaptive foreground, background, monochrome, legacy launcher PNGs, and Play Store 512 export.
4. Provide iOS 1024 source master and complete generated AppIcon raster set.
5. Re-run the strict validator and only then update app icon assets and visual goldens.
