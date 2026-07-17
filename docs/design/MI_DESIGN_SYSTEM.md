# MI Design System v1.0 — Official Token Specification

- **Owner:** Dev 4 | **Date:** 2026-07-17 | **Status:** Normative
- Implementation target: `packages/design_system` (single source of truth).
  `apps/mobile/lib/config/theme.dart` is deprecated and will be deleted;
  `mi_game_ui` re-exports these tokens with game-specific aliases only.

## 0. Brand decision

MI Academy's identity is the **"Soft Violet" family** anchored on `#6C63FF`
(already used by all games and the original brand spec). The Tailwind-blue
palette in `packages/design_system` is retired. Rationale in
`DESIGN_SYSTEM_AUDIT.md` §2.

## 1. Color tokens (semantic layer — the only layer screens may use)

| Token | Value | Usage |
|---|---|---|
| `color.primary` | `#6C63FF` | Primary actions, active states, MI brand accents |
| `color.primarySoft` | `#E9E7FF` | Selected backgrounds, chips, plan-item icon wells |
| `color.secondary` | `#FF6584` | Secondary highlights, garden/reward warmth |
| `color.accent` | `#FFC94D` | Stars, celebration, collectibles |
| `color.background` | `#F7F7FE` | App scaffold |
| `color.surface` | `#FFFFFF` | Cards, sheets |
| `color.surfaceRaised` | `#FFFFFF` + shadow `#14000000`, y2 blur8 | Elevated cards, overlays |
| `color.textPrimary` | `#2D2D5F` | Headings, body |
| `color.textSecondary` | `#6B6B8E` | Captions, metadata |
| `color.border` | `#E3E2F2` | Dividers, input borders |
| `color.success` | `#2BB673` | Correct feedback (always + icon/text/audio) |
| `color.warning` | `#F5A623` | Hints used, gentle warnings |
| `color.error` | `#FF7043` | Soft error (never harsh red `#EF4444`) |
| `color.info` | `#42A5F5` | Hints available, informational |

Parent Mode overrides: same hues, desaturated backgrounds
(`background → #F5F6F8`, decoration removed). Parent Mode is a *restrained
skin*, not a different palette.

High-contrast variants (token suffix `.hc`): textPrimary → `#14142E`,
border → `#8A88A8`, primary → `#4B43D6`, error → `#D84315`. Every semantic
token MUST have an `.hc` value in the Dart implementation.

Rules:
- No `Color(0x...)` literals outside the token file. CI grep gate.
- Color is never the only signal (§7 of the brief): pair with icon + text/audio.

## 2. Typography tokens

**Family:** Nunito (SIL OFL 1.1, full Vietnamese coverage). Weights 400/600/700/800.
Fallback chain: Nunito → system sans (Roboto / SF). **Must be bundled in
`apps/mobile/pubspec.yaml`** — bundling task belongs to the Wave 1 integration PR.
No decorative fonts for learning content.

| Token | Size/weight/line-height | Maps to Flutter |
|---|---|---|
| `text.display` | 36 / 800 / 1.2 | displayLarge |
| `text.headingLarge` | 28 / 800 / 1.25 | headlineLarge |
| `text.headingMedium` | 24 / 700 / 1.3 | headlineMedium |
| `text.headingSmall` | 20 / 700 / 1.3 | headlineSmall |
| `text.bodyLarge` | 18 / 600 / 1.5 | bodyLarge |
| `text.bodyMedium` | 16 / 600 / 1.5 | bodyMedium |
| `text.bodySmall` | 14 / 600 / 1.45 | bodySmall |
| `text.labelLarge` | 18 / 700 / 1.2 | labelLarge (buttons) |
| `text.labelMedium` | 14 / 700 / 1.2 | labelMedium |
| `text.numberLarge` | 44 / 800 / 1.1, tabular figures | custom (math games) |

Child Mode floors: body text never below 16; buttons never below 18.
All styles must survive 1.3× and 2.0× `textScaler` without clipping
(min-height containers, never fixed height around text).

## 3. Spacing tokens

`space.2, space.4, space.8, space.12, space.16, space.24, space.32, space.48, space.64`
(values = names, in logical px). Existing `space5(20)`/`space10(40)` are
deprecated; migrate to nearest step.

## 4. Radius tokens

| Token | Value | Usage |
|---|---|---|
| `radius.small` | 8 | Chips, inline tags |
| `radius.medium` | 12 | Inputs, small cards |
| `radius.large` | 16 | Cards (standard) |
| `radius.xLarge` | 24 | Hero cards, overlays, buttons in Child Mode |
| `radius.round` | 999 | Avatars, circular buttons |

## 5. Motion tokens (summary — full spec in `docs/animation/MOTION_SYSTEM.md`)

| Token | Duration | Easing |
|---|---|---|
| `motion.instant` | 0 ms | — |
| `motion.fast` | 120 ms | easeOut |
| `motion.normal` | 240 ms | easeInOut |
| `motion.slow` | 400 ms | easeInOut |
| `motion.celebration` | 1200–3000 ms, skippable | custom |

Every motion consumer must branch on reduced-motion (§ MOTION_SYSTEM).

## 6. Elevation

Three levels only: `flat` (none), `raised` (y2 blur8 #14000000),
`overlay` (y8 blur24 #1F000000 + scrim `#66201F4D`).

## 7. Touch targets (normative, §9)

- Age 5–7 surfaces: ≥ 56×56; age 8–12: ≥ 48×48; gap between targets ≥ 8.
- MVP ships one child tier → **56×56 is the floor for all Child Mode targets**.
- Exit never adjacent to continue. Every drag has a tap alternative.

## 8. Icon system (§19)

Own SVG set, 24×24 grid, 2 px stroke, rounded caps, filled variant for active
states. Minimum render size 20. Every icon ships with: outlined + filled,
high-contrast variant, accessibility label key (vi + en).
V1 set (20): play, pause, replay, audio, mute, slow-audio, hint, exit, home,
world, parent, settings, download, offline, lock, complete, star, badge,
garden, language, accessibility.
IDs: `icon_<name>_<variant>_v01.svg` under `assets/icons/`.

## 9. Component library

Inventory + required states in `design/components/COMPONENT_INVENTORY.md`.
One state-widget family (Error/Empty/Loading/Offline) lives in
`design_system`; `mi_game_ui` skins it, never re-implements it.

## 10. Migration plan (with Dev 1/Dev 2)

1. `design_system`: replace `MiTokens` palette with §1–§6 tokens, keep old
   names as `@Deprecated` aliases for one wave.
2. `mi_game_ui`: point `MiGameColors` at the semantic tokens (values already
   match the violet family — mostly a re-export).
3. Delete `apps/mobile/lib/config/theme.dart`; fix `main.dart`/`splash_screen.dart`
   literals.
4. Bundle Nunito; add `fonts:` section; Dev 3 records OFL license in manifest.
5. CI: add grep gate for raw hex colors outside `packages/design_system`.
