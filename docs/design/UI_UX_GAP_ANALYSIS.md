# UI/UX Gap Analysis — MI Academy

- **Owner:** Dev 4
- **Date:** 2026-07-17
- **Input:** `DESIGN_SYSTEM_AUDIT.md`, screen walkthrough of `apps/mobile/lib/screens/` and the 6 game screens under `lib/src/games/`

## 1. Screens that exist today

Splash, Login, Child Selector, Child Home, Game Screen (launcher), Parent PIN,
Parent Dashboard, Parent Settings, plus 6 game screens (Memory Cards, Word
Builder, Sound Match, Choice/quiz, Robot Commands; Math Race & Math Supermarket
run through level JSON in `apps/mobile/assets/levels/`).

## 2. Gap matrix vs product requirements

| Required experience | Current state | Gap severity |
|---|---|---|
| MI robot guide present across app | Does not exist anywhere (no art, no widget, no voice) | **Critical** |
| World map (6 zones: Alphabet City, Math Kingdom, Logic Island, Science Lab, Creative House, Achievement Garden) | Does not exist; Child Home shows a flat subject grid | **Critical** |
| Child Home per spec (§14): greeting, daily mission, "Tiếp tục học" primary CTA, world map entry, garden, recently played, discreet parent gate | Greeting ✓; plan list ✓; no primary CTA, no map/garden/recent, parent entry is a bare settings icon | **High** |
| Parent onboarding flow (§15: 10 steps) | Only login exists; no product promise, no accessibility prefs, no time limit setup, no starter download step | **High** |
| Parent dashboard (§16) | Basic screen exists; needs audit against chart/text-summary/no-comparison rules | Medium |
| Two distinct UI layers (Child vs Parent mode) | Same theme/layout language for both | **High** |
| Voice guidance for pre-readers (5–7) | No voice assets (silent placeholders), no replay affordance on app screens | **Critical** |
| Icon + text for every action | Emoji + text; icons not controllable | High |
| Reduced motion / high contrast / large text | Not implemented in app shell; `mi_game_accessibility` package unverified in UI | **High** |
| Localization vi/en | vi strings hard-coded in screens (`'Chào $nickname'`); `packages/localization` exists but screens don't use it | High |
| Offline states | `OfflineIndicator` exists in game UI only; app screens have no offline state | Medium |
| Age-tier visual differentiation (5–7 / 8–10 / 11–12) | None — single UI for all ages | Medium (MVP: acceptable to ship one tier, must not feel "babyish") |

## 3. Screen-level defects found

### Child Home (`child_home_screen.dart`)
- **Two dead navigation tabs** ("Sao", "Huy hiệu") — tapping does nothing.
  Dead buttons are a direct child-trust violation (§ risk report R1).
- Parent area is reachable in **one tap** from both the app bar and the tab bar
  with no parent gate on the tap itself (PIN screen exists downstream — verify
  route guard with Dev 1; the affordance still shouldn't sit in the child tab bar).
- Primary action is ambiguous: plan list, subject grid, and 4 tabs compete.
  Spec requires one dominant CTA: `Tiếp tục học`.
- Pull-to-refresh as the only refresh mechanism is undiscoverable for children.
- `childAspectRatio: 1.3` + `crossAxisCount: 2` grid breaks on tablet (see
  `RESPONSIVE_DESIGN_AUDIT.md`).

### Login / Splash
- Splash uses hard-coded off-token colors.
- Login is parent-facing but uses the same visual language as child screens.

### Games (shell level)
- Consistent header widgets exist (good), but palette differs from app shell.
- Completion overlay copy and celebration length not yet validated against
  §17 rules ("no You win/You lose") — coordinate with Dev 2/Dev 3.

## 4. Flows that must be designed before build (prototype list, §29)

Priority order:
1. Child Home v2 (wireframe delivered: `design/screens/CHILD_HOME_WIREFRAME.md`)
2. World map (blocked on zone illustration direction)
3. Parent onboarding (10-step)
4. Game shell: tutorial → play → hint → pause → completion (spec delivered:
   `design/games/GAME_SHELL_SPEC.md`)
5. Parent dashboard v2 (wireframe delivered: `design/screens/PARENT_DASHBOARD_WIREFRAME.md`)
6. Parent gate hardening (current PIN flow UX review)

## 5. What is genuinely good and should be kept

- `mi_game_ui` widget coverage (header, hint, pause, tutorial, completion,
  feedback bubble, progress dots) — right abstraction, needs re-skin only.
- Error/Empty/Loading state widgets exist and are used on Child Home.
- Soft error color choice in games (`#FF7043` not harsh red).
- Golden-test infrastructure in `mi_game_ui`.
- Child-safe copy tone already present in places ("Hãy bắt đầu học ngay!").

## 6. Dependencies on other devs

| Dev | What I need | What they need from me |
|---|---|---|
| Dev 1 | Route-guard confirmation for `/parent`; data fields for dashboard charts; nav contract | Token package migration PR review; Child Home v2 spec; onboarding flow |
| Dev 2 | Game canvas dimensions + animation hooks per game | Unified `mi_game_ui` skin; Memory Cards asset kit; motion tokens |
| Dev 3 | Copy review of all child-facing strings; license review of chosen font/icon set | Audio metadata schema; asset manifest structure; localization keys for new screens |
