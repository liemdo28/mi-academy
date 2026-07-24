# Mi Academy Production Asset Integration Report

Last updated: 2026-07-24

## Verdict

Production asset gate: **READY for family testing**.

Codex-generated Mi Academy candidate artwork now exists for every required production source asset and passes the strict asset validator. These files unblock app builds and remove placeholder launcher references.

Designer/human visual approval is still required before treating the artwork as final brand sign-off for public store release.

## Assets Supplied

- 4 logo SVGs.
- 12 mascot emotion SVGs.
- 16 brand icon SVGs.
- 3 Android app icon source SVGs.
- Android Play Store 512 PNG source.
- iOS 1024 PNG source.

## Assets Accepted

- All 37 required source assets are present and pass automated validation.
- Runtime SVG copies exist under `packages/design_system/assets/branding/`.
- Android adaptive and round adaptive launcher XML now point at generated production vector layers instead of placeholder layers.

## Assets Rejected

- None.

## Assets Still Missing

- None for the automated production asset gate.
- Final designer-approved replacement artwork remains recommended before public store release.

## Integration Status

- Logo: generated SVG variants are present in source and runtime asset folders.
- Mascot: generated SVGs are present for all 12 emotions in source and runtime asset folders.
- Brand icons: generated SVGs are present for learning, reward, profile, and navigation icons.
- Android app icon: adaptive and round adaptive XML are configured and now reference generated foreground/monochrome layers.
- iOS app icon: asset catalog is structurally present and accepted by the validator; macOS/iOS device verification remains outside this Windows pass.

## Placeholder Removal Status

No centralized fallback code was removed because it remains useful for resilience if an asset fails to load. Android adaptive launcher XML no longer references placeholder layers.

Temporary placeholders remain intentionally isolated under:

- `assets/branding/placeholders/`
- `packages/design_system/assets/branding/placeholders/`
- Android launcher placeholder vector layers in `apps/mobile/android/app/src/main/res/drawable/`

## Golden Preview Status

Home Screen goldens were regenerated after replacing placeholder artwork:

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
- Placeholder references in production launcher config.
- Unexpected production files that are not mapped by `MiBrandAssets`.

## Deviations From Approved Brand Guide

- The generated art follows the approved palette and mascot direction, but it is still Codex-generated candidate art rather than designer-approved final artwork.
- The logo wordmark is built from vector shapes rather than a refined custom type treatment.
- PNG app icon sources are generated approximations and should receive final visual approval before store submission.

## Designer Actions Required

1. Review and approve or replace the generated logo, mascot, icon, and app icon art.
2. If replacing, keep the exact filenames in `ASSET_REQUIREMENTS.md`.
3. Confirm ownership/licensing for public release.
4. Re-run the strict validator and Home goldens after any replacement.
