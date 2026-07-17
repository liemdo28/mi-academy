# Child Home v2 — Wireframe & Specification

- **Screen:** child_home | **Target age:** 5–12 (single MVP tier) | **Owner:** Dev 4
- **Purpose:** one obvious way to continue learning; everything else secondary.

## Layout — compact (phone portrait)

```text
┌─────────────────────────────────┐
│ [MI head]  Chào Minh! 👋   [⚿] │  ← header 64; ⚿ = parent gate, discreet,
│                                 │     top-right, monochrome, hold-to-open
│ ┌─────────────────────────────┐ │
│ │  ▶  TIẾP TỤC HỌC            │ │  ← hero CTA, full-width, h72,
│ │     Ghép chữ — còn 2 bài    │ │     color.primary, voice on focus
│ └─────────────────────────────┘ │
│                                 │
│ Nhiệm vụ hôm nay        ○○●     │  ← daily mission card, progress dots
│ ┌─────────────────────────────┐ │
│ │ 🞊 Hoàn thành 1 bài toán    │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌──────────────┬──────────────┐ │
│ │  Bản đồ      │  Vườn        │ │  ← world map entry + Achievement
│ │  thế giới    │  thành tích  │ │     Garden entry, illustrated tiles
│ └──────────────┴──────────────┘ │
│                                 │
│ Chơi gần đây  ───────────────▶  │  ← horizontal row, GameCard ×N
│ [🂠][🔤][🤖]                    │
├─────────────────────────────────┤
│   [Trang chủ]  [Bản đồ]  [Vườn] │  ← 3 live tabs ONLY (no parent tab,
└─────────────────────────────────┘     no dead tabs)
```

- medium: mission + map/garden row become one 2-col band under hero.
- expanded: NavigationRail left; right column shows MI (hover idle) + garden preview; content max-width 1040.

## Components
PrimaryButton(hero) · LessonCard · SubjectCard→(moved to world map) ·
GameCard · ProgressDots · TabBar(3) · MI widget (head, idle) · ParentGateIcon.

## States
- Loading: skeleton cards (no spinner-only), MI neutral.
- Error: MiErrorState + retry, MI error_recovery, voice "Có lỗi nhỏ, thử lại nhé."
- Empty (new user): hero becomes "Bắt đầu học", mission hidden, map highlighted.
- Offline: banner chip "Đang học ngoại tuyến" (info color), content from cache.

## Interactions & audio
- First open of day: MI welcome line (voice, skippable, once/day max).
- Hero CTA reads its label aloud on long-press (pre-reader support).
- Parent gate: hold 3 s → PIN pad (never in tab bar).
- Pull-to-refresh removed for child; auto-refresh on resume.

## Accessibility
- All targets ≥ 56; tab labels icon+text; screen-reader labels vi/en
  (e.g. "Tiếp tục bài Ghép chữ, còn 2 bài"); reduced-motion: MI still frame;
  large-text: cards grow, hero wraps to 2 lines max then ellipsis + voice.

## Removed vs v1
Dead tabs "Sao"/"Huy hiệu"; settings icon push; 5-subject grid (lives in
world map now); pull-to-refresh dependency.

## Asset IDs
`character_mi_face_welcome_v01`, `illustration_home_worldmap-tile_v01`,
`illustration_home_garden-tile_v01`, `icon_parent_outlined_v01`,
`icon_home/world/garden_{outlined,filled}_v01`.

## Acceptance criteria
1. One dominant CTA; ≤ 4 primary choices visible on first paint.
2. No dead controls. 3. Parent entry requires deliberate gesture.
4. Fully navigable by a non-reader using icons + voice.
5. Passes tablet/large-text/reduced-motion visual QA.
