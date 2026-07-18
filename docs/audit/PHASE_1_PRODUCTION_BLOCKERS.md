# Phase 1 — Production Blockers (baseline, before this session's Phase 4/7 fixes)

Captured at the start of `fix/full-phase-1-to-19`, before any changes. This is the baseline the rest of this session's checkpoints are measured against. Severity/status columns are updated inline where this session addressed the item; everything else is carried forward unchanged from `docs/audit/PRODUCTION_BLOCKERS.md`.

## P0

1. **Entry point split** — `main.dart` boots a standalone game-picker; the real login/child/dashboard flow (`app.dart` + `config/router.dart`) is unreachable from `runApp`.
   - File/component: `apps/mobile/lib/main.dart:20-29`, `apps/mobile/lib/app.dart:8`.
   - Root cause: two independently-authored `MiAcademyApp` classes were never reconciled after the GoRouter flow was built.
   - Impact: the shipped app cannot demonstrate the golden flow at all — every screen wired in the prior session is dead weight from the user's perspective.
   - Fix plan: this session's Phase 4 (see below).
   - Owner: this session.
   - Validation method: `flutter analyze` + `flutter test` + call-graph trace from `main()`.
   - **Status this session: addressed — see Phase 4 checkpoint below.**

## P1

2. **Two dead, non-compiling game files** — `math_race_screen.dart`, `math_supermarket_screen.dart`.
   - Root cause: superseded by `ChoiceGameScreen`, left in the tree, references an old `mi_game_ui` API (`GameScaffold`, `QuestionCard`, `AnswerButton`, `AnimatedFeedback`) that no longer exists.
   - Impact: `flutter analyze` never reports clean; risk of accidental re-import.
   - Fix plan: user explicitly named these files this session — delete after reference verification.
   - Owner: this session.
   - Validation method: `flutter analyze` clean + `flutter test` green.
   - **Status this session: addressed — see Phase 7 checkpoint below.**

3. **Only 1 of 6 games produces completion telemetry.** Not addressed this session (deferred to a follow-up "Phase 7 full" pass per the plan — Memory Cards Golden Flow was the priority; the other 5 games require game-engine-level instrumentation work, not just wiring).

4. **Rate limiting in-memory fallback isn't multi-replica safe.** Not addressed this session (Phase 15/17 scope).

5. **Contract fragmentation beyond MiGameResult** (`Lesson`/`Child`/`Parent`/`Skill`/`Progress`). Not addressed this session (Phase 3 scope).

## P2 (unaddressed, unchanged)

- `packages/game_core` (Python) unused by `apps/api`.
- `contracts/shared_contracts.py` used only by `tools/mi_cli`.
- `adaptive_core`/`mastery_core`/`recommendation_core`/`spaced_repetition` unwired to `apps/mobile`.
- Content/assets/localization/accessibility/security/performance/CI/admin — not audited.

See `docs/final/NEXT_PHASE_PLAN.md` for the full prioritized follow-up list (updated at the end of this session).
