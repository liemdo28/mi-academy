# MI Academy — Platform Gap Analysis

**Date:** 2026-07-17
**Owner:** Platform & Learning Lead
**Version:** 1.0.0

---

## 1. Gap Summary

This document maps what exists vs. what must be built, organized by Platform domain. Dev 2 responsibilities are marked separately.

---

## 2. Shared Contracts & Models

| Contract / Model | Owner | Status | Gap |
|---|---|---|---|
| `MiGameLaunchRequest` | Platform + Dev 2 | ❌ Missing | Must define together |
| `MiGameResult` | Platform + Dev 2 | ❌ Missing | Must define together |
| `MiGameSnapshot` | Platform + Dev 2 | ⚠️ Partial | Exists in `mi_game_core` but needs version field |
| `MiProgressGateway` (interface) | Platform | ❌ Missing | Must define for both Flutter and mock |
| `AccessibilityPreferences` | Platform | ❌ Missing | Needs schema |
| `AudioPreferences` | Platform | ⚠️ Partial | Exists in `mi_game_audio` but not platform-level |
| `InMemoryProgressGateway` | Platform | ❌ Missing | Mock for Dev 2 |
| Child profile fixtures | Platform | ❌ Missing | Mock data |
| Level fixtures | Platform | ❌ Missing | Mock data |

---

## 3. Authentication & Profiles

| Feature | Backend | Mobile | Gap |
|---|---|---|---|
| Parent registration | ✅ Done | ❌ Not wired | Mobile UI + API call |
| Parent login | ✅ Done | ❌ Not wired | Mobile UI + token storage |
| Parent logout | ✅ Done | ❌ Not wired | Token clearing |
| Refresh token | ✅ Done | ❌ Not wired | Token refresh logic |
| Parent PIN set | ✅ Done | ❌ Not wired | PIN screen |
| Parent PIN verify | ✅ Done | ❌ Not wired | Biometric/PIN entry |
| Child profile CRUD | ✅ Done | ❌ Not wired | Profile creation/selection |
| Daily time limit | ✅ Done | ❌ Not wired | Usage enforcement |
| Multiple children | ✅ Done | ⚠️ Partial | Mobile selector missing |
| Age group (junior/explorer/master) | ✅ Done | ❌ Not wired | Child profile selection |
| Child avatar | ✅ Done | ❌ Not wired | Avatar picker |
| **Child data minimization** | ✅ Done | ✅ Good | No full name, email, photo |

---

## 4. Learning Content System

| Feature | Backend | Mobile | Gap |
|---|---|---|---|
| Lesson schema | ✅ SQL | ❌ No schema | Mobile lesson model |
| Game level schema | ⚠️ Basic | ❌ No schema | Mobile level model |
| Question schema | ✅ SQL | ❌ No model | Mobile question model |
| Asset manifest | ❌ None | ❌ None | Content versioning manifest |
| Localization schema | ❌ None | ❌ None | Flutter ARB files |
| Content package structure | ❌ None | ❌ None | JSON-based content |
| Content versioning | ⚠️ Basic | ❌ None | Version check on sync |
| Content rollback | ❌ None | ❌ None | Admin rollback |
| JSON validation | ❌ None | ❌ None | Pydantic + JSON Schema |
| **Lesson engine** | ⚠️ Partial | ❌ None | Complete lesson flow |
| **Daily missions** | ⚠️ Basic | ❌ None | Mission UI |
| **Recommended lessons** | ❌ None | ❌ None | Adaptive engine |
| **Subject/skill mapping** | ⚠️ Basic | ❌ None | Skill model |

---

## 5. Progress System

| Feature | Backend | Mobile | Gap |
|---|---|---|---|
| Save attempts | ✅ Done | ❌ Not wired | Mobile → API call |
| Game results | ✅ Done | ❌ Not wired | `MiGameResult` flow |
| Lesson progress | ✅ Done | ❌ Not wired | Progress tracking |
| Skill evidence | ❌ None | ❌ None | SkillMastery model |
| Mastery score | ❌ Not calculated | ❌ None | `MasteryCalculator` |
| Hint usage | ✅ Done | ❌ Not wired | Tracking |
| Session duration | ⚠️ DailySession | ❌ Not tracked | Real-time tracking |
| Daily usage | ⚠️ Basic | ❌ None | Time enforcement |
| Review due date | ❌ None | ❌ None | Spaced repetition |
| Idempotent sync | ⚠️ Basic | ❌ None | Sync queue |
| **No duplicate results** | ⚠️ Basic | ❌ None | `attemptId` dedup |
| **Crash recovery** | ❌ None | ❌ None | Local + server reconciliation |

---

## 6. Adaptive Learning

| Feature | Status | Gap |
|---|---|---|
| Correct rate tracking | ❌ None | Per-skill performance history |
| Attempt count tracking | ⚠️ Basic | Already in Attempt |
| Hint count tracking | ⚠️ Basic | Already in Attempt |
| Difficulty history | ❌ None | Per-lesson difficulty state |
| Spaced repetition | ❌ None | Review due date calculation |
| Silent difficulty reduction | ❌ None | No negative feedback |
| No speed pressure | ❌ None | Duration not weighted |
| No streak punishment | ✅ N/A | No streak system yet |
| Adaptive engine | ❌ None | Full engine to build |

---

## 7. Offline-First

| Feature | Backend | Mobile | Gap |
|---|---|---|---|
| Local session storage | ❌ None | ❌ None | Hive setup |
| Child profiles offline | ❌ None | ❌ None | Profile cache |
| Content offline | ❌ None | ❌ None | Content download |
| Lessons offline | ❌ None | ❌ None | Lesson JSON cache |
| Levels offline | ❌ None | ❌ None | Level JSON cache |
| Progress offline | ❌ None | ❌ None | Local progress DB |
| Snapshots offline | ❌ None | ❌ None | Snapshot storage |
| Rewards offline | ❌ None | ❌ None | Reward cache |
| **Sync queue** | ⚠️ Basic | ❌ None | Pending item queue |
| **Upload on reconnect** | ❌ None | ❌ None | Background sync |
| **Conflict resolution** | ❌ None | ❌ None | Server-wins or merge |
| **Don't delete before confirm** | ❌ None | ❌ None | Confirmation protocol |

---

## 8. Parent Dashboard

| Feature | Backend | Mobile | Gap |
|---|---|---|---|
| Today overview | ⚠️ Basic | ❌ None | Dashboard UI |
| Weekly report | ⚠️ Basic | ❌ None | Report charts |
| Time usage | ⚠️ Basic | ❌ None | Usage graph |
| Subject progress | ⚠️ Basic | ❌ None | Subject cards |
| Skill strengths | ❌ None | ❌ None | Skill analysis |
| Skills needing practice | ❌ None | ❌ None | Weak skill detection |
| Lessons completed | ⚠️ Basic | ❌ None | Lesson list |
| Game activity | ⚠️ Basic | ❌ None | Game history |
| Daily limit control | ✅ Done | ❌ None | Limit setting UI |
| Audio settings | ❌ None | ❌ None | Volume controls |
| Offline download | ❌ None | ❌ None | Content download UI |
| Data export | ❌ None | ❌ None | Export JSON/CSV |
| Delete child data | ❌ None | ❌ None | GDPR deletion |
| **PIN lock (< 3 taps)** | ✅ Backend | ❌ None | PIN screen |
| **Biometric** | ❌ None | ❌ None | Biometric auth |

---

## 9. Reward Foundation

| Feature | Backend | Mobile | Gap |
|---|---|---|---|
| MI Stars | ⚠️ Basic | ❌ None | Star counter |
| Badges | ✅ Done | ❌ None | Badge display |
| Stickers | ❌ None | ❌ None | Sticker model |
| Avatar accessories | ❌ None | ❌ None | Accessory model |
| Garden items | ❌ None | ❌ None | Garden model |
| Room items | ❌ None | ❌ None | Room model |
| Stories | ❌ None | ❌ None | Story reward |
| Unlock logic | ❌ None | ❌ None | Progress-based unlock |
| **No loot boxes** | ✅ N/A | ✅ Good | Deterministic rewards |
| **No random reward** | ✅ N/A | ✅ Good | Fixed criteria |
| **No paid reward** | ✅ N/A | ✅ Good | No IAP |

---

## 10. Admin Dashboard

| Feature | Backend | Mobile | Gap |
|---|---|---|---|
| Admin login | ⚠️ Basic | ❌ None | Web admin app |
| Role permissions | ❌ None | ❌ None | RBAC |
| Lesson CRUD | ⚠️ Basic | ❌ None | Admin web UI |
| Question CRUD | ⚠️ Basic | ❌ None | Admin web UI |
| Game level CRUD | ❌ None | ❌ None | Level editor |
| Localization management | ❌ None | ❌ None | Translation UI |
| Media upload | ❌ None | ❌ None | File storage |
| Content preview | ❌ None | ❌ None | Preview before publish |
| Draft mode | ❌ None | ❌ None | Draft/publish flow |
| Publish workflow | ❌ None | ❌ None | Publish with validation |
| Version rollback | ❌ None | ❌ None | Revert button |
| Error monitoring | ❌ None | ❌ None | Logging/metrics |
| Basic analytics | ❌ None | ❌ None | Usage dashboard |

---

## 11. Integration (Platform ↔ Dev 2)

| Contract | Status | Action |
|---|---|---|
| `MiGameLaunchRequest` | ❌ Not defined | Co-author spec |
| `MiGameResult` | ❌ Not defined | Co-author spec |
| `MiProgressGateway` | ❌ Not defined | Platform defines, Dev 2 uses |
| Game launcher flow | ❌ Not built | Mock launcher first |
| End-to-end mock flow | ❌ Not built | Build together |
| Child → Lesson → Game → Result | ❌ Not wired | Integration test |

---

## 12. Security & Privacy

| Requirement | Status | Gap |
|---|---|---|
| No advertising SDK | ✅ Not present | Audit before release |
| No external tracking | ✅ Not present | Audit before release |
| No GPS | ✅ Not present | Don't add |
| No contacts access | ✅ Not present | Don't add |
| No public profile | ✅ Not present | Don't add |
| No child-to-child chat | ✅ Not present | Don't add |
| No external links in child mode | ❌ None | Link blocker |
| No parent creds in game | ✅ Design good | Verify in integration |
| No sensitive data logging | ❌ None | Logging audit |
| Data export workflow | ❌ None | Export endpoint |
| Data deletion workflow | ❌ None | Cascade delete |
| Secrets out of repo | ⚠️ Partial | `.env` may be committed |

---

## 13. Localization

| Language | Content | UI | Gap |
|---|---|---|---|
| Vietnamese (vi) | ⚠️ words.json | ❌ None | Full lesson content |
| English (en) | ❌ Missing | ❌ None | Full translation |
| ARB files | ❌ Missing | ❌ None | Flutter intl |
| RTL support | N/A | ❌ None | Future-proofing |
| Pluralization | ❌ None | ❌ None | ICU messages |

---

## 14. Testing Gaps

| Test Type | Status | Coverage Target | Gap |
|---|---|---|---|
| Unit tests — API | ❌ None | 85% | Write FastAPI tests |
| Unit tests — Mobile | ❌ None | 80% | Widget tests |
| Database tests | ❌ None | 80% | Migration + query tests |
| Migration tests | ❌ None | 80% | Alembic + rollback |
| Contract tests | ❌ None | 100% | All contract serialization |
| Integration tests | ❌ None | 60% | API + DB + cache |
| Offline sync tests | ❌ None | 70% | Sync queue + conflict |
| Crash recovery tests | ❌ None | 60% | Kill + restart |
| Authorization tests | ❌ None | 90% | JWT + PIN + RBAC |
| Data deletion tests | ❌ None | 100% | Cascade + export |
| Localization tests | ❌ None | 80% | All strings translated |
| E2E tests | ❌ None | 40% | Full user flows |
| Contract tests (game↔platform) | ❌ None | 100% | Launch request/result |

---

## 15. Wave-Phase Gap Map

| Wave | Features | Completion | Critical Gaps |
|---|---|---|---|
| Wave 0 | Audit, monorepo, contracts, CI, Docker | 30% | Shared contracts, CI, mock gateway |
| Wave 1 | Auth, profiles, local DB, PIN, progress | 40% | Mobile auth wiring, Hive setup, PIN screen |
| Wave 2 | Lesson catalog, daily mission, skills, rewards, offline content | 20% | Lesson engine, reward unlock, content cache |
| Wave 3 | Parent dashboard, reports, usage, sync queue | 10% | Dashboard UI, sync engine, usage tracking |
| Wave 4 | Adaptive learning, recommendations, content versioning | 0% | Full engine, spaced repetition |
| Wave 5 | Admin, security, data export/delete | 10% | Admin app, GDPR, security hardening |

---

## 16. Dev 2 Coordination Points

| Topic | Platform Delivers | Dev 2 Delivers |
|---|---|---|
| `MiGameLaunchRequest` | Fields list, serialization | Game expects these fields |
| `MiGameResult` | Fields list, serialization | Game produces these fields |
| `MiProgressGateway` | Interface definition | Implements for real storage |
| InMemoryProgressGateway | Mock implementation | Uses for game dev |
| Child fixtures | Profile data | Game reads child context |
| Level fixtures | Level content | Game renders levels |
| Game launcher | Mock launcher | Real launcher integration |
| End-to-end test | Full mock flow | Game integrated |

---

*End of Gap Analysis*
