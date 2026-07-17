# Responsive Design Audit — MI Academy

- **Owner:** Dev 4
- **Date:** 2026-07-17

## 1. Summary

The app is **phone-portrait only in practice**. No breakpoints exist, no layout
adapts to width, and no screen was designed for tablet. On a tablet the current
UI is a stretched phone layout — explicitly prohibited by the design brief (§10).

## 2. Findings

| Area | Finding | Evidence |
|---|---|---|
| Breakpoints | None defined anywhere; no `LayoutBuilder`/width checks in `apps/mobile/lib` screens | grep: no adaptive layout code |
| Child Home grid | `GridView.count(crossAxisCount: 2)` fixed — 2 huge cards per row on tablet, stretched aspect ratio | `child_home_screen.dart:167-173` |
| Navigation | `BottomNavigationBar` only; no `NavigationRail` for expanded widths | `child_home_screen.dart:83` |
| Parent dashboard | Single column; spec requires multi-column on tablet | `parent_dashboard_screen.dart` |
| Orientation | No landscape handling; games do not declare orientation requirements | all game screens |
| Safe areas | Not audited per screen; app bar transparent variant in dead `MITheme` suggests no consistent safe-area policy | `config/theme.dart:78` |
| Max content width | None — text lines will exceed comfortable reading width on tablets | all screens |
| Touch targets at scale | Sizes are fixed logical px (good baseline: buttons 56 high) but density of layout is not re-computed per width | `design_system/MiButton` |
| Text scaling | `textScaler` never consulted; large-text mode will clip fixed-height widgets | audit grep |

## 3. Adopted breakpoint system (normative — see RESPONSIVE_LAYOUT_GUIDE.md)

```text
compact:  < 600 dp   (phones)
medium:   600–839 dp (small tablets, phones landscape)
expanded: ≥ 840 dp   (tablets, web tablet-sized, large screens)
```

## 4. Required per-screen behavior (targets for Wave 1)

| Screen | compact | medium | expanded |
|---|---|---|---|
| Child Home | 1-col, bottom bar | 2-col content, bottom bar | content max-width 1040, NavigationRail, world-map hero larger |
| World map | vertical scroll map | full map fits | full map fits, zones larger, no stretching |
| Parent dashboard | stacked cards | 2-col card grid | 2–3-col grid + side nav |
| Game shell | portrait, bottom interaction tray | game area grows, tray fixed height | game area centered w/ max width, side gutters |
| Onboarding | single card | centered card 560 max | centered card 560 max |

## 5. Rules (enforced going forward)

1. No `GridView.count` with a hard-coded `crossAxisCount` — use
   `SliverGridDelegateWithMaxCrossAxisExtent` or a breakpoint helper.
2. Every new screen spec must include all three breakpoint layouts (§39).
3. Games declare their supported orientations in their manifest; the shell
   locks orientation accordingly.
4. All fixed-height containers must survive 1.3× and 2.0× text scale
   (visual QA gate, see `docs/visual-qa/` checklist).
5. Tablet QA is part of Definition of Done — a screen without a tablet
   screenshot in review is not done.
