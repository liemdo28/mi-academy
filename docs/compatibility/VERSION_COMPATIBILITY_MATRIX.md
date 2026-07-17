# MI Academy — Version Compatibility Matrix

**Date:** 2026-07-17  
**Owner:** Dev 7  
**Status:** Wave 0 — Initial

---

## 1. Overview

This matrix tracks compatibility between major versions of MI Academy components. It is updated on every release.

---

## 2. Component Versions

| Component | Current Version | Schema Version | API Version |
|-----------|----------------|----------------|-------------|
| Mobile App | 1.0.0 | 1 | 1 |
| Backend API | 1.0.0 | 1 | 1 |
| Game SDK | 1.0.0 | 1 | N/A |
| Content Package | 1.0.0 | 1 | N/A |
| Adaptive Engine | 1.0.0 | 1 | 1 |
| Analytics | 1.0.0 | 1 | N/A |
| Shared Models | 1.0.0 | 1 | N/A |

---

## 3. Compatibility Matrix

| Mobile | Backend | Content | Game SDK | Snapshot Schema | Status | Notes |
|--------|---------|---------|----------|-----------------|--------|-------|
| 1.0.0 | 1.0.0 | 1 | 1 | 1 | ✅ Supported | Baseline |
| 1.0.0 | 1.0.1 | 1 | 1 | 1 | ✅ Supported | Patch — backend bug fixes |
| 1.0.1 | 1.0.0 | 1 | 1 | 1 | ✅ Supported | Mobile bug fixes only |
| 1.0.0 | 1.1.0 | 1 | 1 | 1 | ✅ Supported | Minor — new optional fields |
| 1.0.0 | 2.0.0 | 1 | 1 | 1 | ⚠️ Needs Adapter | **Planned** — breaking API changes |
| 1.0.0 | 2.0.0 | 2 | 1 | 1 | ❌ Breaking | Content version mismatch |
| 1.1.0 | 2.0.0 | 2 | 1 | 1 | ✅ Supported | **Planned** — full backward compat |
| 1.0.0 | 1.0.0 | 2 | 1 | 1 | ⚠️ Needs Content Migration | Auto-migration planned |
| 1.0.0 | 1.0.0 | 1 | 2 | 1 | ⚠️ Needs Game SDK Migration | Game SDK v2 planned |

---

## 4. Contract Version History

### Game Contracts (kGameContractVersion = 1)

| Version | Date | Breaking? | Changes |
|---------|------|-----------|---------|
| 1 | 2026-07-17 | — | Initial — MiGameLaunchRequest, MiGameResult, MiGameSnapshot |
| 2 | TBD | TBD | TBD |

### Progress Contracts

| Version | Date | Breaking? | Changes |
|---------|------|-----------|---------|
| 1 | 2026-07-17 | — | Initial — LessonProgress, LessonStatus enum |

---

## 5. Snapshot Compatibility

| Snapshot Schema Version | Can Restore On | Notes |
|-------------------------|---------------|-------|
| 1 | Mobile 1.0.0+ | Baseline version |
| 1 | Mobile 1.1.0+ | Forward compatible |
| 1 | Mobile 2.0.0+ | **Requires adapter** |

**Migration path for snapshot v1 → v2:**
- Automatic migration via `SnapshotMigrator` adapter
- Old snapshot preserved during migration
- Rollback possible if migration fails

---

## 6. Content Package Compatibility

| Content Version | Mobile Version | Status | Migration |
|-----------------|---------------|--------|-----------|
| 1 | 1.0.0 | ✅ Supported | None needed |
| 2 | 1.0.0 | ⚠️ Migration needed | Content migrator |
| 2 | 1.1.0+ | ✅ Supported | Auto-migration |
| 3 | TBD | ❌ Breaking | Requires mobile update |

---

## 7. Update Policy

- **Patch (1.0.x → 1.0.y):** Always backward compatible. No migration needed.
- **Minor (1.x.0 → 1.y.0):** Backward compatible. New optional fields added. No migration needed.
- **Major (x.0.0 → y.0.0):** May be breaking. Adapter required. Migration documented.

---

## 8. Compatibility Test Schedule

| Release | Tests Required |
|---------|---------------|
| Any patch | Smoke tests pass |
| Any minor | Contract tests