# Internal Beta Risk Register — v0.9.0-beta.1

| ID | Description | Area | Probability | Impact | Severity | Detection | Mitigation | Contingency | Owner | Status | Evidence | Stop condition |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| R1 | Cross-child data leakage | Privacy/Security | Low | Critical | P0 | Server-side ownership checks + tests; manual audit trace | `_child_belongs_to_parent` on every child-scoped route (re-verified this pass) | Immediate rollback, revoke affected sessions | Beta coordinator | Mitigated, monitored | `docs/final/PR4_FINAL_PRODUCTION_AUDIT_2026-07-18.md` §6 | Any confirmed instance |
| R2 | Offline attempt loss | Data integrity | Low | High | P1 | `offline_sync` test suite; queue durability design | Local-write-before-network-dependency; Hive-persisted queue survives restarts | Manual data recovery from device if reachable | Backend/mobile reliability eng | Mitigated, monitored | `packages/offline_sync/test/offline_sync_test.dart` | Any confirmed data-loss report |
| R3 | Duplicate reward issuance | Data integrity | Low | Medium | P1 | Unique constraint + idempotency tests | `UniqueConstraint(child_id, reward_id)` + SELECT-before-INSERT + `IntegrityError` catch | Manual dedup via DB query if it ever occurs | Backend reliability eng | Mitigated, monitored | `docs/final/PR4_FINAL_PRODUCTION_AUDIT_2026-07-18.md` §6 | Any confirmed duplicate |
| R4 | Corrupted progress from out-of-order sync | Data integrity | Low | Medium | P2 | Backend out-of-order guard test | `_compare_datetimes` early-return in `games.py` | N/A — protected by design | Backend reliability eng | Mitigated | Re-verified this pass, §"Network Test Matrix" | N/A |
| R5 | Authentication failure / stale-token loop | Reliability | Was Medium, now Low | High | P1 | This pass's concurrency audit | Serialized token refresh (fixed this pass) | Force logout + re-login if it recurs | Mobile reliability eng | Fixed this pass | `apps/mobile/test/api_service_session_expiry_test.dart` | Any observed forced-logout-with-valid-session report |
| R6 | Startup crash from corrupted local storage | Reliability | Was Medium, now Low | High | P1 | This pass's startup audit | Per-box corruption recovery + fatal-startup fallback UI (fixed this pass) | Uninstall/reinstall if the fallback itself fails | Mobile reliability eng | Fixed this pass | `packages/offline_sync/test/hive_corruption_recovery_test.dart` | Repeated startup crash reports |
| R7 | Content/asset corruption not caught before ship | Content | Low | Medium | P2 | `tools/content_validator/validate_content.py` (runs clean, re-confirmed) | CI-equivalent content validation | Hotfix content JSON, no code change needed | Content owner | Monitored | `docs/final/PR4_FINAL_PRODUCTION_AUDIT_2026-07-18.md` §5 (Phase 12/13) | Any child shown invalid/unsafe content |
| R8 | Release configuration error (wrong env pointing to wrong backend) | Release | Medium | High | P1 | Manual config review (this pass, partial) | `.env.example` + `APP_ENV` startup guard against default `SECRET_KEY` in production | Immediate config fix + redeploy | Release engineer | Partially mitigated — see hardening report §8 | `apps/api/config.py`'s `get_settings()` guard | Beta build silently talking to the wrong backend |
| R9 | Device incompatibility (crash on min-spec device) | Compatibility | Unknown | High | P1 | Device QA matrix | None yet — untested | Restrict beta to known-compatible device models | QA lead | **Not verified — no device available** | `docs/beta/DEVICE_QA_MATRIX.md` (plan only) | Confirmed crash on a supported minimum-spec device |
| R10 | Excessive crash rate during beta | Reliability | Unknown | High | P1 | Beta diagnostics (not yet built this pass — see hardening report §18) | N/A yet | Halt distribution | Beta coordinator | **Not built** | — | Crash rate exceeds an agreed (not-yet-set) threshold |
| R11 | Inability to collect diagnostics from testers | Operational | Medium | Medium | P2 | N/A | Local structured diagnostics export planned, not yet implemented this pass | Rely on manual tester reports via feedback channel | Beta coordinator | **Not built** | — | N/A |
| R12 | Inability to roll back | Release | Low | Critical | P0 | Migration reversibility check (this pass) | All 4 new migrations have working `downgrade()` (re-confirmed); offline-first design limits blast radius | N/A | Release engineer | Mitigated (repo-level), **not rehearsed** | `docs/beta/ROLLBACK_PLAN.md` | Any rollback attempt that fails |

## Notes

- Severities follow this PR's own P0-P3 definitions.
- "Mitigated, monitored" means repository-controlled evidence exists and
  the risk is considered low given that evidence, but ongoing beta
  monitoring is still the plan (not a guarantee).
- R9-R11 are honestly marked as unresolved — they require either a device
  or additional implementation work not completed in this pass.
