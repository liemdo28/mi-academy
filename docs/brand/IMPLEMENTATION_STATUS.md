# Mi Academy Brand Implementation Status

Last updated: 2026-07-20

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

The current logo, mascot, brand icon, and Android adaptive icon layer visuals are temporary placeholders. The production asset validation gate reports **NOT READY** because final approved designer artwork has not been supplied in the expected folders. Final approved designer artwork is still required for:

- All logo variants.
- All 12 mascot emotions.
- Initial learning, reward, navigation, and profile brand icons.
- Android and iOS app icons.

## App Icon Status

- Android: adaptive icon XML, foreground placeholder, monochrome placeholder, round icon, and legacy launcher fallback are configured. Final foreground/background/monochrome/Play Store exports are still missing, and the production validator flags the placeholder adaptive layers.
- iOS: full AppIcon app icon set exists; final branded exports are still required.

## Production Asset Validation

- Added `tools/validate_brand_assets.dart` as the production readiness gate.
- Non-strict mode prints a readiness report without failing local workflows.
- Strict mode fails until all required designer-approved logo, mascot, icon, and app icon source assets are present and no launcher placeholder layers remain.
- Current status: **NOT READY** due to 37 missing production source assets and Android placeholder launcher layers.

## Known Deviations

- The mascot artwork is a centralized placeholder, not final character art.
- The logo artwork is a centralized placeholder, not final logo art.
- Shared game controls still use Material symbols for platform-standard actions such as close, back, play, pause, volume, hint, drag, and settings.
- Existing non-Home screens have not been visually migrated yet.

## Recommended Next Phase

Phase 3 should bring in approved production SVG/icon exports, replace placeholder app icon layers, and then migrate remaining full game-screen visuals beyond shared category/result surfaces.
