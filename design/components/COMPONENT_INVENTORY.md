# Component Inventory — MI Academy Design System

- **Owner:** Dev 4 | **Date:** 2026-07-17
- Required states for EVERY component (§8): default, hover (web), pressed,
  focus, disabled, loading, error, high-contrast, large-text.
- Legend: ✅ exists · 🔶 exists-needs-rework · ❌ to build · Wave = build wave

| Component | Status | Location today | Wave | Notes |
|---|---|---|---|---|
| PrimaryButton | 🔶 | `design_system/MiButton` | 1 | Add loading/disabled/hc states; 56 min-height child mode |
| SecondaryButton | ❌ | — | 1 | Outlined variant of MiButton |
| IconButton | 🔶 | Material default used | 1 | Wrap with 56 target + label requirement |
| CircularButton | ❌ | — | 1 | Audio/replay buttons in games |
| ChoiceCard | ❌ | — | 2 | Sound Match / quiz answers; selected/correct/settle states |
| GameCard | ❌ | — | 1 | Recently-played row |
| LessonCard | 🔶 | inline `_buildPlanItem` in child_home | 1 | Extract to design_system |
| SubjectCard | 🔶 | inline `_buildSubjectGrid` | 1 | Extract; real icons not emoji |
| ProfileCard | 🔶 | child_selector_screen inline | 1 | |
| AvatarSelector | ❌ | — | 1 | Onboarding step 4 |
| ProgressBar | ❌ | — | 1 | Also reduced-motion race substitute |
| ProgressDots | ✅ | `mi_game_ui` | — | Re-skin to tokens |
| Badge / Sticker / RewardCard | ❌ | — | 3 | Achievement Garden |
| Dialog | 🔶 | Material default | 1 | xLarge radius, overlay elevation |
| BottomSheet | ❌ | — | 2 | |
| Tooltip / Toast | ❌ | — | 2 | Toast motion per MOTION_SYSTEM §6 |
| ParentPINPad | 🔶 | screen-level `parent_pin_screen` | 1 | Extract as component + gate interaction |
| TabBar | 🔶 | BottomNavigationBar w/ dead tabs | 1 | 3 live items max, child mode |
| NavigationRail | ❌ | — | 2 | expanded breakpoint |
| GameHeader | ✅ | `mi_game_ui` | — | Verify exit/continue spacing rule |
| TutorialOverlay | ✅ | `mi_game_ui` | — | Add MI + voice slot |
| HintPanel / HintButton | ✅ | `mi_game_ui` | — | |
| CompletionOverlay | ✅ | `mi_game_ui` | — | Copy audit (§17), skippable celebration |
| ErrorState | 🔶 duplicated | design_system **and** mi_game_ui | 1 | Merge: one family, game skin |
| EmptyState | ✅ | design_system | — | |
| OfflineState | 🔶 | mi_game_ui OfflineIndicator only | 1 | App-shell variant needed |
| LoadingState | 🔶 duplicated | both packages | 1 | Merge |
| AudioButton | ✅ | mi_game_ui | — | Add slow-audio variant |
| PauseButton | ✅ | mi_game_ui | — | |
| FeedbackBubble | ✅ | mi_game_ui | — | Attach to MI face states |
| ExitConfirmation | ✅ | mi_game_ui | — | Child-readable copy check |

## Build order

Wave 1 unblocks Child Home v2 + Memory Cards; Wave 2 unblocks Word
Builder/Sound Match; Wave 3 adds rewards. Merging the duplicated state widgets
happens in the same PR as the token migration (one review for Dev 1 + Dev 2).
