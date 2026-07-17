# Parent Dashboard v2 — Wireframe & Specification

- **Screen:** parent_dashboard | **Audience:** parents | **Owner:** Dev 4
- **Purpose:** answer "Hôm nay con học gì, thế nào?" in under 10 seconds,
  then expose controls. Parent Mode skin: desaturated background `#F5F6F8`,
  no child decoration, minimal animation (fade only).

## Layout — compact (phone portrait)

```text
┌─────────────────────────────────┐
│ ←  Bảng điều khiển   [Minh ▾]   │  ← child switcher
│ ┌─────────────────────────────┐ │
│ │ HÔM NAY                     │ │  ← Today summary: minutes, lessons,
│ │ 18 phút · 2 bài · 1 game    │ │     one text sentence, NO score talk
│ │ "Minh luyện ghép vần tốt."  │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ TUẦN NÀY        ▂▅▃▆▂▁▄     │ │  ← weekly time bar chart (1 color)
│ │ Tổng 96 phút                │ │     + text summary line
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ MÔN HỌC                     │ │  ← subject progress: label + thin bar
│ │ Chữ cái  ████████░░  Tốt    │ │     + word, not % alone
│ │ Toán     █████░░░░░  Đang…  │ │
│ └─────────────────────────────┘ │
│ ┌──────────────┬──────────────┐ │
│ │ Điểm mạnh    │ Cần luyện    │ │  ← skill chips, max 3 each
│ └──────────────┴──────────────┘ │
│ Game gần đây ▸                  │
│ ────────────────────────────    │
│ ⚙ Giới hạn thời gian  [30 ph ▾] │
│ ⬇ Tải nội dung offline          │
│ ⚙ Cài đặt · hồ sơ · trợ năng    │
│ ⤓ Xuất dữ liệu   🗑 Xoá dữ liệu │  ← delete = double confirm
└─────────────────────────────────┘
```

- medium: cards in 2-col grid; expanded: 3-col + NavigationRail; charts
  max-width 480, text summary sits beside chart.

## Chart rules (§16)
One accent color per chart; axis labels ≥ 12; every chart paired with a plain
text sentence; **no comparison to other children, no streaks, no pressure
framing** ("Cần cố gắng hơn" ❌ → "Có thể luyện thêm phép cộng" ✅).

## States
Loading skeletons; error w/ retry; empty (new child): explainer + "Con chưa có
hoạt động — bắt đầu từ Trang của bé"; offline: cached data + timestamp chip.

## Data needed from Dev 1
today {minutes, lessonsCompleted, gamesPlayed, highlight}; weekly minutes[7];
subjectProgress[{subject, level 0–1, label}]; skillStrengths[≤3];
skillsToPractice[≤3]; recentGames[{gameId, playedAt, durationMin}];
settings {dailyLimitMin, locale, accessibility flags}; export/delete endpoints.

## Accessibility
Charts have semantic descriptions; all rows ≥ 48 target; large-text reflows to
single column; screen-reader order: summary → charts → actions.

## Acceptance criteria
1. Today summary readable without scrolling on 360-wide device.
2. Every chart has a text equivalent. 3. Destructive actions double-confirmed.
4. No gamification pressure language anywhere.
