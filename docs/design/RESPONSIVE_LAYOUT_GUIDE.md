# Responsive Layout Guide — MI Academy

- **Owner:** Dev 4 | **Date:** 2026-07-17 | **Status:** Normative
- Companion to `RESPONSIVE_DESIGN_AUDIT.md` (findings) — this doc is the rulebook.

## 1. Breakpoints

```text
compact:  width < 600 dp
medium:   600 ≤ width < 840 dp
expanded: width ≥ 840 dp
```

Implementation: one `MiBreakpoint.of(context)` helper in `packages/design_system`.
Screens branch on the enum — never on raw pixel checks scattered in widgets.

## 2. Global rules

1. **Never scale a phone layout up.** Tablet gets more content area, larger
   game canvas, multi-column data — not bigger buttons and longer text lines.
2. Content max-width: reading content 640; dashboards 1040; centered beyond that.
3. Navigation: `compact/medium` → bottom bar (Child) / app bar (Parent);
   `expanded` → `NavigationRail` left.
4. Grids: `SliverGridDelegateWithMaxCrossAxisExtent` (cards maxExtent 280),
   never fixed `crossAxisCount`.
5. Touch targets do **not** shrink at any breakpoint (floor 56 Child / 48 Parent).
6. Every screen spec ships all three breakpoint layouts + landscape note (§39).
7. Text scale 1.0 / 1.3 / 2.0 must not clip at any breakpoint (QA gate).
8. Safe areas respected on every screen; game shell insets HUD, not canvas.

## 3. Orientation policy

| Surface | Policy |
|---|---|
| App shell (home, map, parent) | Portrait preferred; landscape supported on medium+ |
| Memory Cards, Word Builder, Sound Match, Robot Commands | Both; grid re-flows |
| Math Race | Landscape preferred (track); portrait fallback = vertical track |
| Math Supermarket | Portrait preferred (shelf scroll) |

Games declare orientation in their asset/game manifest; the shell locks it.

## 4. Per-surface layout contracts

### Child Home
- compact: single column; hero CTA `Tiếp tục học` (full-width, 72 high) → daily
  mission card → world-map entry card → recently played row.
- medium: two-column below hero (mission | map entry), bottom bar keeps 3 items max.
- expanded: NavigationRail; hero left 60% / MI + garden preview right 40%.

### World map
- compact: vertical scrolling map, max 2.5 screens tall, zone spacing ≥ 24.
- medium/expanded: whole map fits viewport; zones scale with the artboard, never
  stretch (artboard 1200×900 master, letterboxed with sky/ground extension art).

### Parent dashboard
- compact: stacked summary cards.
- medium: 2-col card grid.
- expanded: 3-col grid + rail; charts max-width 480 each with text summary beside.

### Game shell (see `design/games/GAME_SHELL_SPEC.md`)
- Header fixed 64 (compact) / 72 (expanded).
- Bottom interaction tray: fixed height per game family (choices 96–120,
  letter tiles 120–160, command blocks 140).
- Canvas takes remaining space, centered, max aspect deviation handled by
  gutters in `color.background`, never by stretching game art.

### Onboarding (parent)
- All breakpoints: single centered card, max-width 560, progress dots top,
  back button always visible.

## 5. Handoff requirement

A layout is "specified" only when the spec table lists: breakpoint × (columns,
nav pattern, hero size, tray height, landscape behavior). Wireframes in
`design/screens/` follow this format.
