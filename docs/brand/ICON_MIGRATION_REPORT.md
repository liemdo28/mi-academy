# Mi Academy Icon Migration Report

Last updated: 2026-07-20

## Inventory Summary

Classification used during the audit:

- A: platform-standard action icon retained.
- B: Mi Academy branded icon migrated to `MiBrandIcon`.
- C: game-content illustration retained in game logic.
- D: centralized placeholder pending final designer art.
- E: obsolete or duplicated implementation removed.

## Migrated Branded Icons

- Home: parent gate, bottom navigation, progress badges, game category cards.
- Profile selection: child profile avatar placeholders.
- World map: learning-zone chips.
- Garden: empty state and reward cards.
- Parent dashboard: report title, stats, empty states, child profile marker.
- Parent settings: offline content and data export rows.
- Debug game launcher: profile card, status chips, parent card, game cards, parent metric/info cards.
- Choice engine hero panels: category visuals now accept `MiBrandIcon`.
- Shared game UI and shared engines: reward/result stars use `MiBrandIcon.rewardStar`.

## Retained Material/System Icons

Retained because they are platform-standard actions or game mechanics:

- Back, close, chevron, drag handle.
- Play, pause, replay, undo, refresh.
- Volume on/off.
- Hint/lightbulb action controls.
- Settings button.
- Delete/destructive data action.
- Text fields, lock, fingerprint, language, accessibility, and parent PIN keypad controls.
- Robot Commands directional/block symbols and Memory Cards content placeholders because they are gameplay content, not brand category chrome.

## Remaining Direct Icon Usages

Remaining direct `Icons.*` usage is intentional in action controls, parent/auth system controls, and game-content mechanics. No migrated feature code uses raw `assets/branding/` paths or direct `SvgPicture` loading.

## Placeholder Status

`MiBrandIconView` uses centralized fallback drawing and placeholder SVG fallback paths until final designer assets are available. These placeholders are not final production art.

Missing final icon assets:

- Learning: alphabet, numbers, logic, memory, writing, listening.
- Rewards: reward star, achievement, progress.
- Profile: profile, parent, report.
- Navigation: world, exploration, garden, offline.

## Deprecated APIs

- Removed: `MiMascotReactionType`.
- Canonical mascot API: `MiMascotReaction(emotion: MiMascotEmotion...)`.
- Canonical brand icon API: `MiBrandIconView(icon: MiBrandIcon...)`.

## App Icon Configuration

Android:

- Adaptive icon XML is configured for standard and round launcher icons.
- Foreground and monochrome placeholder vector layers exist.
- Background color is set to Cloud White.
- Legacy `mipmap-* / ic_launcher.png` fallback files remain.
- Final foreground/background/monochrome/Play Store 512 exports are still missing.
- `tools/validate_brand_assets.dart --strict` flags both adaptive icon XML files until placeholder layers are replaced.

iOS:

- AppIcon asset catalog exists with required slots.
- Final branded source-master and production exports are still missing.
- Final App Store icon must be 1024x1024 with no transparency.

## Production Validation

- Added a production asset validator at `tools/validate_brand_assets.dart`.
- Current validator status is **NOT READY** because no final production asset files are present in the expected handoff folders.
- No visual goldens were regenerated in this pass because the final artwork is absent.

## Designer Deliverables Still Required

- Final brand icon SVGs listed in `ASSET_REQUIREMENTS.md`.
- Final logo SVGs.
- Final mascot SVGs for all 12 emotions.
- Android adaptive foreground/background/monochrome layers and Play Store icon.
- iOS source master and complete final AppIcon export set.
