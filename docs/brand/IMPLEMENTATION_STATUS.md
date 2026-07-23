# Mi Academy Brand Implementation Status

Last updated: 2026-07-23

## Complete In Current Scope

- Shared design tokens include the approved color palette, typography roles, spacing, radii, shadows, component sizing, motion tokens, and device classes.
- Reusable brand components are available: `MiPrimaryButton`, `MiSecondaryButton`, `MiGameCard`, `MiProgressCard`, `MiAchievementBadge`, `MiMascotReaction`, `MiSectionHeader`, `MiBottomNavigation`, and `MiAcademyLogo`.
- `MiBrandAssets` centralizes logo, mascot, and brand icon paths with typed enums and placeholder fallbacks.
- `MiMascotReaction` supports 12 approved emotions, optional localized message text, semantics, decorative mode, animation mode, and reduced-motion behavior.
- `MiBrandIconView` centralizes brand icon rendering, placeholder fallback, semantics, decorative mode, disabled state, light/dark surface support, and enum-to-asset mapping.
- Home Screen uses the Phase 1 brand shell with mascot welcome area, progress visibility, large game cards, bottom navigation, phone/tablet layouts, and Vietnamese/English copy.
- Completion, tutorial, loading, error, and retry game surfaces now reference semantic mascot emotions.
- Brandable icons in Home, profile selection, world map, garden, parent progress surfaces, settings data rows, debug launcher, choice-engine hero panels, shared result stars, and shared engine completion summaries use `MiBrandIcon`.
- Deprecated `MiMascotReactionType` compatibility API has been removed after all external call sites migrated to `MiMascotEmotion`.

## Placeholder Assets

Codex-generated candidate assets are now present for:

- All logo variants.
- All 12 mascot emotions.
- Initial learning, reward, navigation, and profile brand icons.
- Android and iOS app icons.

These assets pass the automated production asset gate. Human/designer approval is still required before treating the visuals as final brand sign-off.

## App Icon Status

- Android: adaptive icon XML, foreground vector, monochrome vector, round icon, and legacy launcher fallback are configured. The adaptive XML files no longer reference placeholder layers.
- iOS: full AppIcon app icon set exists, and a generated 1024 source master is present for designer review.

## Production Asset Validation

- Added `tools/validate_brand_assets.dart` as the production readiness gate.
- Non-strict mode prints a readiness report without failing local workflows.
- Strict mode fails until all required logo, mascot, icon, and app icon source assets are present and no launcher placeholder layers remain.
- Current status: **READY** for automated asset validation; pending human visual approval.

## Known Deviations

- The mascot artwork is a centralized placeholder, not final character art.
- The logo artwork is a centralized placeholder, not final logo art.
- Shared game controls still use Material symbols for platform-standard actions such as close, back, play, pause, volume, hint, drag, and settings.
- Existing non-Home screens have not been visually migrated yet.

## Recommended Next Phase

Phase 3 should bring in approved production SVG/icon exports, replace placeholder app icon layers, and then migrate remaining full game-screen visuals beyond shared category/result surfaces.
