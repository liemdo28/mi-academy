# Mi Academy Asset Requirements

This document defines the production asset handoff for the Mi Academy brand system. Temporary placeholders are allowed only under `assets/branding/placeholders/` and `packages/design_system/assets/branding/placeholders/`.

## Source Structure

- `assets/branding/logo/` stores approved source logo SVGs.
- `assets/branding/mascot/` stores approved source mascot SVGs.
- `assets/branding/icons/learning/` stores learning category icons.
- `assets/branding/icons/navigation/` stores navigation icons.
- `assets/branding/icons/rewards/` stores achievement and reward icons.
- `assets/branding/icons/profile/` stores profile and account icons.
- `assets/branding/app_icon/android/` stores Android app icon production exports.
- `assets/branding/app_icon/ios/` stores iOS app icon production exports.

Runtime Flutter assets live in the matching `packages/design_system/assets/branding/` folders. App and feature code must use `MiBrandAssets`, `MiAcademyLogo`, and `MiMascotReaction` instead of raw asset paths.

## Logo Deliverables

Required SVG files:

- `mi_academy_primary.svg`
- `mi_academy_stacked.svg`
- `mi_academy_symbol.svg`
- `mi_academy_monochrome.svg`

Requirements:

- Transparent background.
- No embedded raster images.
- Text converted to outlines, or verified font-independent rendering.
- Colors match the approved palette: `#FF8A00`, `#4CAF50`, `#4A90E2`, `#8E6BFF`, `#FFD23F`, `#1E2A44`, `#F4F6FA`.
- Works on light and dark backgrounds.

## Mascot Deliverables

Required SVG files:

- `welcome.svg`
- `success.svg`
- `thinking.svg`
- `confused.svg`
- `excited.svg`
- `encouraging.svg`
- `try_again.svg`
- `celebration.svg`
- `apology.svg`
- `love.svg`
- `sleeping.svg`
- `surprised.svg`

Requirements:

- Transparent background.
- Consistent safe bounds and visual center across all emotions.
- No speech text baked into artwork.
- No photography or AI artifact textures.
- Friendly, child-safe expression language aligned with the brand guide.

## Brand Icon Deliverables

Initial required SVG files:

- `icons/learning/alphabet.svg`
- `icons/learning/numbers.svg`
- `icons/learning/logic.svg`
- `icons/learning/memory.svg`
- `icons/learning/writing.svg`
- `icons/learning/listening.svg`
- `icons/rewards/reward_star.svg`
- `icons/rewards/achievement.svg`
- `icons/rewards/progress.svg`
- `icons/profile/profile.svg`
- `icons/profile/parent.svg`
- `icons/profile/report.svg`
- `icons/navigation/world.svg`
- `icons/navigation/exploration.svg`
- `icons/navigation/garden.svg`
- `icons/navigation/offline.svg`

Requirements:

- Rounded, sticker-like vector style.
- Transparent background.
- No emoji glyphs.
- No duplicated inline SVG paths in screen code.

## App Icon Deliverables

Current app icon configuration audit:

- Android currently uses legacy `mipmap-*/ic_launcher.png` files only.
- Android adaptive icon foreground/background XML and source layers are not present.
- iOS has a complete `Runner/Assets.xcassets/AppIcon.appiconset` PNG set, but it is not yet the final Mi Academy icon.

Required Android exports:

- `assets/branding/app_icon/android/foreground.svg`
- `assets/branding/app_icon/android/background.svg`
- `assets/branding/app_icon/android/monochrome.svg`
- Legacy `ic_launcher.png` for mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi.
- Play Store 512x512 icon.

Required iOS exports:

- `assets/branding/app_icon/ios/app_icon_master_1024.png`
- Complete AppIcon app icon set from 20pt through 1024pt.
- 1024x1024 marketing icon without alpha.

## Replacement Workflow

1. Add approved source files under `assets/branding/`.
2. Copy runtime SVGs into `packages/design_system/assets/branding/`.
3. Keep placeholders only in `placeholders/`.
4. Run `dart run tools\validate_brand_assets.dart` for a readable readiness report.
5. Run `dart run tools\validate_brand_assets.dart --strict` as the production gate.
6. Run design system asset tests.
7. Run app and shared game widget/golden tests.
8. Update this document if new registry enum values are introduced.

## Validation Checklist

- `flutter format` passes for touched Dart files.
- `flutter analyze` passes in affected packages.
- `dart run tools\validate_brand_assets.dart --strict` passes.
- Widget tests pass for Home, shared game overlays, and design system assets.
- Golden previews are regenerated for phone/tablet Vietnamese and English Home.
- No migrated feature code contains raw `assets/branding/` paths.
- No placeholder asset is presented as a final production asset.
