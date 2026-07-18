# MI Academy — PR #4 Final Production Audit

**Repository:** liemdo28/mi-academy
**Branch:** `fix/full-phase-1-to-19`
**PR:** #4 (Draft — not merged)
**Date:** 2026-07-18
**Auditor role:** Lead Software Engineer / Principal Reviewer / QA Lead / Release Manager / Production Auditor

This audit re-verified the repository from source rather than trusting prior
session reports. Three independent read-only sweeps were run across the
entire repo (dead code/TODO/debug artifacts; duplicate contracts/models;
unused providers/routes/migrations/DB tables), findings were individually
re-verified by hand before acting on them, and every confirmed
repository-controlled issue that was safe to fix has been fixed in this pass.

---

## 1. Executive Summary

The repository is in materially good shape for **internal beta**, not for a
full production launch. Every phase of the original 19-phase spec has a
concrete, evidence-backed status (see `docs/final/PHASE_19_FINAL_VALIDATION_2026-07-18.md`
for the full phase table — not reproduced here). This audit's fresh sweep
found and fixed a small number of additional repository-controlled issues
(dead scratch files, a dead stub package pair, one dead Riverpod provider)
that prior passes had missed, and confirmed — by checking source, not
assumption — that several previously-flagged risks (duplicate contracts,
orphaned game logic, migration drift) are either already resolved or are not
actually dead code. **No P0 or P1 issues remain in repository-controlled
code.** The remaining gaps are either genuine external-infrastructure
blockers (no production database/deployment exists) or explicit, documented
technical-debt/design decisions that require product input, not more code.

## 2. Repository Health

- 141 files changed across this PR relative to `main` (`git diff --stat
  main...fix/full-phase-1-to-19`), spanning backend routes/models/migrations,
  mobile screens/providers/games, contracts, CI, and docs.
- No committed secrets (`gitleaks` scan clean, part of CI).
- No stray scratch files remain in `apps/api/` after this pass (`_write.py`,
  `_w.py` removed — one-line debug helpers with zero references).
- Root-level dead stub packages (`routes/__init__.py`, `middleware/__init__.py`,
  whitespace-only, flagged as a shadowing risk in an old infrastructure audit)
  removed. `schemas/level.schema.json` at repo root was correctly left alone
  — it's a real, in-use content schema, not part of the dead stub trio.

## 3. Architecture Health

- Layer boundaries hold: games (`apps/mobile/lib/src/games/**`) never call
  the API or Hive directly — verified again this pass by re-checking every
  game screen's constructor for `ApiService`/token/Hive references (none
  found beyond `GameScreen`, the intended platform-owned caller).
- `packages/game_core` (Python) was initially misflagged by an automated
  scan as an "orphaned Dart package" purely because it lives under
  `packages/`; verified by hand that it's a substantial, actively-tested
  Python package (`pytest packages/game_core/tests`, part of every CI run)
  — corrected before taking any action, since deleting it would have broken
  CI and destroyed real game-engine logic.
- Contract layer (`contracts/shared_contracts.py`) is a single registry of
  23 contracts; the 4 with "Source: ..." docstrings were already verified
  field-by-field against their real Dart sources in a prior pass (stale
  `shared_models.dart` references corrected). This pass's independent sweep
  found the same result — no new drift — plus surfaced that ~10 other
  contract classes (`ParentProfileContract`, `RewardContract`, etc.) carry
  no source-file annotation at all. Not confirmed drift, but unverifiable as
  written; flagged as follow-up (§7).

## 4. Code Quality

- `flutter analyze`: **0 issues** (re-verified after every change in this
  pass).
- No `debugPrint`/stray `print(` in shipped Dart or Python application code
  (only legitimate CLI/report output in `tools/*.py`).
- No disabled/commented-out code blocks found across a 17-candidate manual
  review — every long comment run inspected was substantive documentation,
  not dead code.
- No unused imports found in a 10-file sample (5 Dart, 5 Python) across
  `apps/`.

## 5. Technical Debt (repository-controlled, explicitly not fixed this pass — reasons given)

1. **`packages/learning_core/lib/src/content_service.dart`** — 5 stub
   methods with `// TODO: Load from Hive...` comments. The package itself
   has zero referencing `pubspec.yaml` anywhere in the repo (confirmed),
   so this is unwired, not merely incomplete — implementing real
   persistence in a package nothing currently uses would be speculative
   feature-building, not a fix. Left as-is; a product decision is needed on
   whether this package is still planned or should be retired.
2. **Orphaned-but-substantial Dart packages** (`adaptive_core`,
   `adaptive_testing`, `api_client`, `content_intelligence`,
   `model_evaluation`, `ai_safety`) — each has real code (1-7 files) and a
   valid `pubspec.yaml`, but zero referencing `path:` dependency anywhere.
   These plausibly represent deliberate future-phase infrastructure (the
   adaptive-learning work has been explicitly documented across multiple
   phase reports as "exists, not yet wired in"), so deleting them wholesale
   without confirming intent would risk destroying legitimate planned work.
   **Not deleted. Flagged for a product/architecture decision**, not
   silently left ambiguous.
3. **Backend admin CRUD/analytics endpoints with no caller**
   (`create_lesson`, `update_lesson`, `delete_lesson`, `create_question`,
   `create_game`, `update_game`, `get_analytics`,
   `get_completion_rate` in `apps/api/routes/admin.py`) — verified
   `apps/admin`'s `lessons_screen.dart`/`games_screen.dart`/
   `questions_screen.dart` make **zero HTTP calls at all** (pure UI
   scaffold, no backend wiring whatsoever). These backend endpoints are
   real, intentional, forward-looking API surface for a not-yet-built admin
   UI, not accidental dead code — confirmed by checking for actual callers,
   not assumed. Left in place; wiring `apps/admin` to them is legitimate
   future work, not a defect to delete.
4. **Contract classes with no "Source:" docstring** in
   `contracts/shared_contracts.py` (`ParentProfileContract`,
   `ChildProfileContract`, `AuthSessionContract`, `LessonContract`,
   `SkillContract`, `RewardContract`, `SyncEventContract`,
   `MasteryEvidenceContract`, `RecommendationContract`,
   `ContentManifestContract`, `AssetManifestContract`, `ApiErrorContract`)
   — unlike the 4 already-verified contracts, these have no way to check
   for drift against a specific file since none is cited. Not proven wrong,
   just unverifiable as written. Follow-up: annotate each with its real
   current source (Python schema, Dart model, or JSON schema file) so
   future drift is at least checkable.
5. **`RefreshToken` model never referenced directly in `routes/*.py`** —
   false-positive-adjacent: it's used via `apps/api/dependencies.py`'s
   `create_refresh_token`/`redeem_refresh_token`/`revoke_all_refresh_tokens`,
   which the auth routes call. Not dead code, just indirected through a
   shared dependency module — noted so a future literal grep doesn't
   misclassify it as unused again.

## 6. Duplicate Components

**None found requiring migration.** The three-agent sweep specifically
checked for duplicate Lesson/Child/Progress/Reward models across both Dart
and Python and found each core concept has exactly one canonical
implementation per language, with the Python Pydantic-schema-vs-SQLAlchemy-
model split being intentional API/DB layering, not accidental duplication.
The previously-known contract drift (stale `shared_models.dart` docstring
references) was already fixed in an earlier pass and re-confirmed correct
here.

## 7. Remaining Repository Work

- Annotate the 12 un-sourced contract classes in `contracts/shared_contracts.py`
  with their real current source file (bounded, low-risk documentation work).
- Decide the fate of `learning_core` and the 6 orphaned-but-substantial
  packages listed in §5.2 — keep-and-wire vs. retire. This is a product
  decision, not a technical one.
- Full contract-type unification (one source of truth for Lesson/Child/
  Parent/Skill/Progress across Python+Dart, possibly via codegen) — deferred
  in an earlier pass at the user's explicit direction as a design decision,
  not a bug fix; still open.
- Wiring `apps/admin` to its own backend (currently a UI-only scaffold with
  zero HTTP calls).

## 8. External Blockers (genuinely infrastructure-dependent — not fixable by more code here)

- No production database, staging environment, or deployment target exists
  anywhere (`docs/infrastructure/ENVIRONMENT_STRATEGY.md` correctly marks
  `development`/`staging`/`production` as "not yet provisioned").
- No backup/restore tooling — meaningless to build before a production
  database exists (`docs/disaster-recovery/BACKUP_RESTORE_BASELINE.md` is
  an honest gap-tracking document, verified still accurate).
- No monitoring/alerting/error-tracking service wired up (structured
  logging + health endpoints exist and are real, but nothing aggregates or
  alerts on them).
- No device/emulator available in this environment at any point across this
  effort — all mobile verification is `flutter analyze` + `flutter test`,
  never a running app on a device. OS-level scenarios (airplane mode, real
  network loss, real jank/startup profiling) cannot be honestly claimed as
  verified.
- No cloud infrastructure provisioned — cost, rollback mechanism, and
  container/image publishing are all not-yet-applicable per the existing
  infrastructure audit (corrected copy now current as of this effort).

## 9. Test Results (verified moments before this report was finalized)

- Backend/game-core Python: **159/159 passing** —
  `pytest tests test packages/game_core/tests -q`.
- Mobile Flutter: **71/77 passing** — the 6 failures are golden-image pixel
  diffs, expected (goldens are Linux-CI-rendered; local re-run here is on
  Windows). CI itself is green for these tests.
- `flutter analyze`: **0 issues.**
- `python tools/child_safety_audit.py`: **pass**, 0 failures, 2 pre-existing
  informational warnings (network/connectivity dependency declarations,
  expected for a backend-synced app).

## 10. CI Status

**7/7 jobs green** as of the last push (`2692e75`):
`content-and-safety`, `secret-scans` (SAST/dependency scans are
report-only by design, non-blocking), `python-tests`, `postgres-integration`
(new this effort — runs the full Alembic chain against real Postgres and
boots the app under production config with Redis), `mobile-test-build`,
`ios-build`, `android-release-signing`.

## 11. Documentation Status

Updated/verified current as of this audit:
- `docs/final/NEXT_PHASE_PLAN.md` — every item has a concrete status
  (DONE/PARTIAL/deferred), cross-referenced with evidence.
- `docs/final/PHASE_19_FINAL_VALIDATION_2026-07-18.md` — full 19-phase
  status table.
- `docs/infrastructure/INFRASTRUCTURE_AUDIT.md` — corrected; was stale on
  6+ of its 9 priority findings (Alembic, asyncpg, secret-key guard,
  logging/health endpoints, Dockerfile hardening, Redis-backed rate
  limiting were all already resolved but the doc still described them as
  gaps).
- This document is new.

## 12. Security Review

Three concretely exploitable gaps found and fixed in an earlier pass this
effort (each with a regression test): refresh tokens were plain JWTs with
no server-side revocation (logout did nothing); the parent PIN had no
server-side brute-force lockout; the rate limiter trusted a spoofable
`X-Forwarded-For` header unconditionally. Re-verified all three fixes are
still in place and tested. No new security issues found in this pass's
fresh sweep. Broader pentest-style review remains out of scope (documented,
not silently skipped).

## 13. Accessibility Review

`reduceMotion` is wired end-to-end (parent toggle → game animation) for the
one game with an actual animation (Memory Cards — verified this pass that
it is the *only* game with any `AnimatedContainer`/`AnimationController` in
its codebase; the other 5 have none, so there was nothing else to wire).
Screen-reader `Semantics` labels added to Word Builder's letter tiles.
High-contrast/large-text/screen-reader toggles remain unwired — documented,
not fixed this pass.

## 14. Performance Review

3 N+1 queries fixed (`selectinload` on lesson→subject relationships), 2
missing indexes added (`daily_sessions.child_id`,
`child_rewards(child_id, unlocked_at)`), explicit Postgres connection-pool
sizing added. No device-based profiling possible in this environment —
documented as a limitation, not claimed as covered.

## 15. Release Readiness

Not production-ready as a deployed service (no environment exists to
deploy to). Ready as a **verified, tested, CI-green internal-beta
candidate** for the repository-controlled scope of work.

## 16. Risk Assessment

| Risk | Severity | Status |
|---|---|---|
| Contract drift silently reintroduced | Low | Guarded by `test_dart_contract_sources_still_declare_their_required_fields` for the 4 verified contracts; the other 12 contracts remain unverifiable as written (§5.4) |
| Orphaned packages accidentally deleted in a future cleanup pass without checking usage | Medium (process risk, not current-state risk) | This audit's own initial automated scan nearly misclassified `packages/game_core` (Python, actively CI-tested) as a dead Dart package — corrected before acting. Future cleanup passes must verify by hand, not trust automated scans alone |
| Production deployment attempted before infrastructure exists | High if attempted | Explicitly documented as not-ready in multiple places; recommendation below is unambiguous |
| Admin backend endpoints exposed with no consuming UI | Low | Real auth-gated endpoints, not a security hole by themselves, but worth noting in release notes so nobody assumes admin functionality is user-facing yet |

## 17. Recommendation

**GO WITH CAVEATS** — for internal beta only, not full production launch.

Reasons:
- No P0 or P1 repository-controlled issue remains open. Everything found in
  this fresh audit that was safe to fix has been fixed and verified (CI
  7/7 green, 159/159 backend tests, 71/77 mobile tests with the 6 failures
  being pre-existing documented golden-image diffs, 0 `flutter analyze`
  issues).
- The caveats are entirely infrastructure/product-decision items, not code
  defects: no production database/deployment exists, no device QA has ever
  been possible in this environment, and a handful of orphaned packages
  need a keep-or-retire product decision rather than a code fix.
- Do not merge this PR expecting it to represent a deployable production
  system today — it represents a repository that is ready for the *next*
  steps (provision an environment, get a device for QA, decide on the
  orphaned packages) rather than a system that has completed them.

---

## Files changed this pass

- `apps/api/_write.py` (deleted)
- `apps/api/_w.py` (deleted)
- `routes/__init__.py` (deleted, root-level dead stub)
- `middleware/__init__.py` (deleted, root-level dead stub)
- `apps/mobile/lib/providers/providers.dart` (removed dead `lessonCatalogProvider`)
- `docs/infrastructure/INFRASTRUCTURE_AUDIT.md` (corrected stale findings, prior pass)
- `docs/final/PHASE_19_FINAL_VALIDATION_2026-07-18.md` (new, prior pass)
- This document (new)

## Justification for every change

See commit `2692e75` ("chore: final-audit cleanup") for the full reasoning
per file, cross-referenced above in §2 and §5.

## Remaining caveats

See §8 (External Blockers) and §5 (Technical Debt) — nothing here is hidden
or silently deferred; every item has an explicit owner-decision or
infrastructure dependency named.

## Merge recommendation

Do not merge to `main` without an explicit decision from the user, per this
effort's standing instruction. This report supports a **GO WITH CAVEATS**
recommendation for continued internal-beta use of this branch, not an
autonomous merge.

## Follow-up work for PR #5 (Internal Beta Hardening)

1. Provision a real `development`/`staging` environment per
   `docs/infrastructure/ENVIRONMENT_STRATEGY.md` and re-run the
   `postgres-integration` CI job's equivalent against it.
2. Get a physical device or emulator into the workflow and re-verify every
   "not device-tested" item flagged across `docs/final/PHASE_19_FINAL_VALIDATION_2026-07-18.md`.
3. Decide keep-vs-retire for `learning_core` and the 6 orphaned-but-substantial
   packages (§5.1-5.2).
4. Annotate the 12 un-sourced contracts in `contracts/shared_contracts.py`
   with their real current source (§5.4) — bounded, safe, low-risk.
5. Either wire `apps/admin` to its backend or explicitly deprioritize it for
   this beta round.
6. Broader security review (pentest-style) beyond the 3 targeted fixes
   already made.
