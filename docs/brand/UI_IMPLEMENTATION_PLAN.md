# Mi Academy Brand Implementation Plan

This plan turns the approved brand reference into repo-level implementation rules. The reference image at `docs/brand/mi-academy-brand-reference.png` is visual direction only, not a production asset sheet.

## Required first steps for UI work

Before making any UI, branding, asset, theme, typography, or game-screen change:

1. Read the root `AGENTS.md`.
2. Read `docs/brand/BRAND_GUIDELINES.md`.
3. Inspect `docs/brand/mi-academy-brand-reference.png`.
4. Review the existing project mapping or knowledge graph.
5. Inspect only the relevant design system, app shell, shared game UI, localization, requested screen, and directly related tests.

Do not recursively scan the entire repository by default.

## Phase 0: Audit

Do not implement production UI changes in this phase.

Audit:

- Existing design tokens and theme architecture
- Typography and font loading
- Current icon and illustration handling
- Existing app shell and navigation
- Shared game components
- Responsive behavior for phone and tablet
- Localization architecture
- Existing mascot, avatar, or feedback assets
- Screens that still use generic Material styling
- Tests affected by a brand-system migration

Deliver:

- Current-state audit
- Gaps against `BRAND_GUIDELINES.md`
- Proposed asset architecture
- Proposed theme/token architecture
- Reusable component list
- Recommended reference screen
- Exact files expected to change
- Risks and blockers
- Phased implementation plan
- Acceptance criteria for each phase

Clearly distinguish between assets Codex can generate or construct safely, assets requiring final designer approval, and temporary development placeholders.

## Phase 1: Brand foundation and Home Screen

Implement the brand foundation and apply it only to the app shell and Home Screen first.

Scope:

- Extend shared semantic colors, typography roles, spacing, radii, shadows, component sizing, motion tokens, and device classes.
- Add reusable components: `MiPrimaryButton`, `MiSecondaryButton`, `MiGameCard`, `MiProgressCard`, `MiAchievementBadge`, `MiMascotReaction`, `MiSectionHeader`, and `MiBottomNavigation`.
- Implement the approved color palette from `BRAND_GUIDELINES.md`.
- Configure Nunito Rounded with Vietnamese and English support.
- Rebuild the Home Screen with a friendly illustrated hierarchy, large game-category cards, mascot welcome area, visible progress, phone and tablet layouts, and localized copy.
- Use temporary vector placeholders only when final mascot assets do not exist. Centralize these placeholders so they can be replaced without changing screen code.

Do not update all games in this phase.

Validation:

- Formatter passes
- Analyzer passes
- Existing tests pass
- New widget tests cover the Home Screen
- No overflow at supported breakpoints
- Screenshots or golden previews exist for phone Vietnamese, phone English, tablet Vietnamese, and tablet English

Completion report:

- Files changed
- Tests executed
- Unresolved visual assets
- Deviations from the approved brand guide
- Recommended next phase

## Phase 2: Shared game UI migration

Apply the approved tokens and reusable components to shared game surfaces before touching individual games.

Prioritize:

- Game shell
- Result and feedback states
- Category cards
- Progress and reward states
- Mascot reaction slots
- Navigation and parent-safe areas

Acceptance criteria:

- Shared components use brand tokens
- Game screens keep touch targets at least 48 logical pixels
- Vietnamese and English layouts do not overflow
- No production emoji placeholders
- No real-child photography

## Phase 3: Individual game migration

Migrate games in small batches after the shared game UI is stable.

For each game:

- Keep game rules and learning behavior unchanged unless explicitly requested.
- Replace local style constants with shared tokens.
- Use the canonical mascot and approved reaction vocabulary.
- Add or update focused widget tests for changed UI states.
- Capture representative phone and tablet screenshots.

## Phase 4: Asset finalization

Replace temporary development placeholders with approved production assets.

Required final assets:

- Logo variants
- Light and dark app icons
- Canonical mascot source file
- Mascot reaction set
- Core learning icon family
- Reward and achievement icons
- Vector-compatible exports
- Asset license and ownership notes

Do not claim production completion while placeholder assets remain.

## Phase 5: Motion and polish

Add restrained motion only after static UI is stable.

Motion must:

- Support reduced-motion behavior
- Avoid flashing
- Reinforce learning feedback
- Keep the mascot friendly and emotionally expressive
- Avoid futuristic or robotic AI tropes

## Implementation order

Brand reference -> Brand guidelines -> `AGENTS.md` -> audit -> theme/token system -> one reference screen -> visual review -> shared components -> app migration -> animation and mascot polish.
