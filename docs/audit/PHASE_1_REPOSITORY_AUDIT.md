# Phase 1 — Repository Audit (refresh)

**Scope:** Verification pass confirming `docs/audit/REPOSITORY_AUDIT.md`, `DUPLICATE_ANALYSIS.md`, and `PRODUCTION_BLOCKERS.md` (written during the `fix/full-integration-production` session, now merged to `main`) are still accurate. Per instruction, nothing here is assumed from the old reports without a fresh check against current code — see evidence per item below. This is **not** a new ground-up audit of content/assets/security/performance/CI/admin; those remain unaudited (see `docs/final/KNOWN_LIMITATIONS.md`).

## What was re-verified this session

| Prior finding | Still true? | Evidence |
|---|---|---|
| `main.dart` boots a standalone game-picker; `app.dart`'s real `MiAcademyApp`/GoRouter flow is unreachable | **Yes, confirmed** | `apps/mobile/lib/main.dart:29` still defines its own `MiAcademyApp`; `void main()` still calls `runApp(MiAcademyApp(...))` from this file, not `app.dart`'s. |
| `math_race_screen.dart` / `math_supermarket_screen.dart` are dead and don't compile | **Yes, confirmed** | `flutter analyze` reproduces the same 19 issues as before (see `PHASE_1_TEST_BASELINE.md`); `grep` for references to either file outside itself: zero matches. |
| Only Memory Cards has full completion telemetry (`MiCompletionResult`) | **Yes, confirmed** | `grep -rn "onComplete" apps/mobile/lib/src/games` shows only `memory_cards_screen.dart` takes `void Function(MiCompletionResult)`; `word_builder_screen.dart`, `sound_match_screen.dart`, `robot_commands_screen.dart`, `choice_game_screen.dart` (used for math_race/math_supermarket in the live game picker) have no completion callback at all. |
| Backend/mobile test baselines (130 / 55 passing) | **Yes, confirmed** | See `PHASE_1_TEST_BASELINE.md`, captured fresh this session before any changes. |

## Fixed this session (Phase 4 + Phase 7 partial)

See `docs/final/INTEGRATION_REPORT.md` (to be updated) for the change log. Summary: `main.dart` now boots the real `app.dart` flow with auth-state-aware routing; the two dead game files are removed.

## Still not audited (carried forward, unchanged from prior session)

Content/curriculum, assets/licensing, localization completeness, accessibility, security hardening, performance, CI overhaul, Postgres+Redis production-like validation, monitoring/backup/restore/rollback, Android release signing. See `docs/final/KNOWN_LIMITATIONS.md` and `docs/final/NEXT_PHASE_PLAN.md` for the prioritized list — unchanged in priority by this session's work, since none of these areas were touched.
