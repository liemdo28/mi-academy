# Design System Audit — MI Academy

- **Owner:** Dev 4 (UI/UX, Art, Animation & Audio Lead)
- **Date:** 2026-07-17
- **Scope:** All existing UI code, themes, tokens, components, and assets in `apps/mobile` and `packages/*`
- **Status of codebase at audit time:** commit `24eaf51`

## 1. Summary

The codebase has **three competing color/token systems**, a theme that references a
font that is never bundled, and **zero production visual assets**. The component
layer is partially built (two widget packages) but there is no single source of
truth a developer can follow. Before any new screens are designed, the token
layer must be unified.

**Verdict: FOUNDATION NOT READY — token unification is the blocking task.**

## 2. Token sources found (the core problem)

| # | Source | Palette | Used by | Status |
|---|--------|---------|---------|--------|
| 1 | `apps/mobile/lib/config/theme.dart` (`MITheme`) | Purple `#6C63FF`, pink `#FF6584`, yellow `#FFD166` | **Nothing** (only `main.dart`/`splash_screen.dart` reference stray colors) | Dead code — delete after migration |
| 2 | `packages/design_system` (`MiTokens`/`MiTheme`) | Blue `#2563EB`, orange `#F97316` (Tailwind palette) | `app.dart` applies `MiTheme.light`; all app screens | **Active app theme** |
| 3 | `packages/mi_game_ui` (`MiGameColors`) | Purple `#6C63FF`, pink `#FF6584`, teal `#00BCD4` | All 6 MVP games | **Active game theme** |

**Consequence:** the app shell is blue, every game is purple. A child moving from
Child Home into Memory Cards experiences a brand switch. This is the single
largest consistency defect.

**Decision needed (proposed in `MI_DESIGN_SYSTEM.md`):** unify on the purple
identity (`#6C63FF` family) because (a) both game packages and the original
brand spec use it, (b) the blue `#2563EB` palette is a verbatim Tailwind default
palette and carries no brand identity, and (c) purple is not owned by major
competitors in this category (Duolingo green, Khan blue).

## 3. Color findings

- Hard-coded `Color(0x...)` values outside token files: `main.dart` (2),
  `splash_screen.dart` (2), plus inline borders in `config/theme.dart`.
- `MiTokens` has no semantic layer — screens use raw names (`primaryBlue`,
  `accentPink`), so a palette change requires touching every screen. Section 7
  of the design brief requires semantic tokens (`color.primary`, `color.surface`…).
- `darkTheme: MiTheme.light` in `app.dart` — intentional (no dark mode) but
  undocumented; keep, and document as a decision.
- No high-contrast variant exists for any token.
- Feedback colors: `MiGameColors.error = #FF7043` (soft orange-red) is a good
  child-safe choice; `MiTokens.error = #EF4444` (hard red) is not. Unify on soft.

## 4. Typography findings

- `packages/design_system` sets `fontFamily: 'Nunito'` — **but no font is bundled**
  (`apps/mobile/pubspec.yaml` has no `fonts:` section). The app silently falls back
  to Roboto/system font. Nunito has full Vietnamese support, so the fix is to
  actually bundle it, not to remove it.
- Two incompatible text scales exist (`MITheme` 16–32 px vs `MiTokens` 12–36 px).
- No `text.numberLarge` style for math games; games hard-code font sizes.
- No text-scaling audit has ever been run (`MediaQuery.textScaler` is never read).
- No explicit fallback chain for Vietnamese diacritics documented.

## 5. Spacing & radius findings

- `MiTokens` spacing (4/8/12/16/20/24/32/40/48) is close to the required scale
  (2/4/8/12/16/24/32/48/64) — missing `2` and `64`, extra `20`/`40`.
- `MITheme` uses ad-hoc paddings (14, 18, 24) — dead code, ignore.
- Radius scales differ: `MiTokens` (8/12/16/24/9999) vs `MITheme` (16/20).
  Cards in the app are 16 px, cards in games vary.

## 6. Component findings

| Component (required, §8) | Exists? | Where | Notes |
|---|---|---|---|
| PrimaryButton | Partial | `design_system/MiButton` | No loading/disabled/high-contrast states |
| Card | Partial | `design_system/MiCard` | Tap-only, no focus state |
| Loading/Error/Empty states | Yes | `design_system` (MiLoading/MiErrorState/MiEmptyState) | Good baseline |
| GameHeader, ProgressDots, HintButton, PauseButton, AudioButton, TutorialOverlay, CompletionOverlay, FeedbackBubble, ExitConfirmation, OfflineIndicator, RetryPrompt | Yes | `mi_game_ui` | Reasonable coverage; states not audited per-widget yet |
| ParentPINPad | Screen-level only | `parent_pin_screen.dart` | Not a reusable component |
| ChoiceCard, LessonCard, SubjectCard, ProfileCard, AvatarSelector, ProgressBar, Badge, Sticker, RewardCard, Dialog, BottomSheet, Tooltip, Toast, TabBar, NavigationRail, HintPanel | **No** | — | To be specified |

Duplicates: two `ErrorState` implementations (design_system + mi_game_ui), two
loading widgets. Must converge into one library with a game skin.

- `mi_game_ui` has golden tests (`mi_game_ui_golden_test.dart`) — good, extend
  this pattern to `design_system`.

## 7. Motion findings

- No motion tokens exist anywhere. Durations are hard-coded inside game widgets.
- No reduced-motion handling in app screens (`MediaQuery.disableAnimations`
  never read in `apps/mobile/lib`). `mi_game_accessibility` package exists —
  integration with UI layer must be verified with Dev 2.

## 8. Iconography findings

- **All icons are either Material defaults or Unicode emoji** (📚 🎮 📝 🔢 🧠 🔬 🎨 📖).
- Emoji render differently per OS/vendor and cannot be color-controlled,
  size-tuned, or given high-contrast variants. Not acceptable for production.
- No custom icon set, no accessibility labels convention.

## 9. Asset findings

See `ASSET_PRODUCTION_STATUS.md` for the full inventory. Headline:
**0 images, 0 fonts, 0 animations; 20 audio files, all silent placeholders.**

## 10. Prioritized remediation (feeds UI_UX_GAP_ANALYSIS)

1. **P0** — Publish unified token spec (`MI_DESIGN_SYSTEM.md`) and migrate
   `packages/design_system` + `mi_game_ui` to it. Delete `config/theme.dart`.
2. **P0** — Bundle Nunito (Vietnamese subset) in `apps/mobile/pubspec.yaml`.
3. **P0** — Replace emoji icons with a licensed/owned SVG icon set.
4. **P1** — Add semantic color layer + high-contrast variants.
5. **P1** — Merge duplicate state widgets (one Error/Loading/Empty family).
6. **P1** — Add motion tokens + reduced-motion variants (see `MOTION_SYSTEM.md`).
7. **P2** — Component state matrix (default/pressed/focus/disabled/loading/error/high-contrast/large-text) for every widget in both packages.
