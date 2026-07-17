# MI Academy — Offline Sync Report

**Date:** 2026-07-17
**Owner:** Platform & Learning Lead

---

## 1. Architecture

The offline-first architecture uses a local-first approach where the mobile app operates fully without connectivity, syncing to the server when available.

### 1.1 Data Flow

```
┌─────────────────────────────────────────────────────────┐
│                     MOBILE APP                          │
│                                                          │
│  ┌──────────┐    ┌──────────────┐    ┌────────────┐  │
│  │ UI Layer │ ← │ Repositories  │ ← │ Data Sources│  │
│  └──────────┘    └──────────────┘    └────────────┘  │
│                          ↑                  ↑             │
│                   ┌──────┴──────┐   ┌────┴────┐       │
│                   │ SyncService  │   │ Hive Box │       │
│                   └──────┬──────┘   └─────────┘       │
└──────────────────────────┼──────────────────────────────┘
                          │ (when online)
                          ▼
                   ┌────────────────┐
                   │  REST API      │
                   │ /sync/*        │
                   └────────────────┘
```

### 1.2 Sync Queue

Items are queued in Hive and processed FIFO:

| Type | Description | Endpoint |
|---|---|---|
| `attempt` | Game attempt record | POST /sync/attempts |
| `progress` | Lesson progress update | POST /sync/progress |
| `snapshot` | Game save state | Optional |
| `reward_unlock` | New reward unlocked | POST /rewards/check |
| `session_end` | Session duration logged | Session endpoint |

### 1.3 Hive Boxes

| Box | Content | Encryption |
|---|---|---|
| `auth` | Access + refresh tokens | ✅ flutter_secure_storage |
| `profiles` | Child profiles | ❌ |
| `lessons` | Cached lesson JSON | ❌ |
| `levels` | Cached level JSON | ❌ |
| `progress` | Local progress records | ❌ |
| `attempts` | Local attempt records | ❌ |
| `snapshots` | Game snapshots | ❌ |
| `rewards` | Unlocked rewards | ❌ |
| `sync_queue` | Pending sync items | ❌ |
| `settings` | App settings | ❌ |
| `mastery` | Skill mastery records | ❌ |

---

## 2. Sync Protocol

### 2.1 Offline Behavior

1. User plays game → `MiGameResult` produced
2. Result saved to Hive `attempts` box
3. `SyncQueueItem` created and saved to `sync_queue` box
4. If network available → sync immediately
5. If offline → item stays in queue

### 2.2 Online Behavior (Auto-Sync)

1. `ConnectivityPlus` detects network restored
2. `SyncService.sync()` called
3. Queue drained oldest-first (FIFO)
4. Each item POST'd to appropriate endpoint
5. Server processes idempotently (by attempt ID)
6. Item marked `completed` only after server confirms
7. Local data NOT deleted until confirmed

### 2.3 Conflict Resolution

- **Server-wins** for progress — server is authoritative
- **Idempotent attempts** — duplicate `attemptId` is ignored
- **No local deletions** before server confirm — prevents data loss

---

## 3. Files Created

| File | Purpose |
|---|---|
| `packages/offline_sync/pubspec.yaml` | Package config |
| `packages/offline_sync/lib/offline_sync.dart` | Exports |
| `packages/offline_sync/lib/src/sync_queue.dart` | Queue item model + Hive adapter |
| `packages/offline_sync/lib/src/sync_service.dart` | Background sync service |
| `packages/offline_sync/lib/src/hive_boxes.dart` | Box names + init |

---

## 4. Testing Gaps

| Test | Status |
|---|---|
| Sync queue FIFO ordering | ⚠️ Not written |
| Offline → online transition | ⚠️ Not written |
| Duplicate attempt handling | ⚠️ Not written |
| Max retry (5) behavior | ⚠️ Not written |
| Conflict resolution | ⚠️ Not written |
| Crash recovery | ⚠️ Not written |

---

## 5. Known Limitations

1. HTTP sync calls in `SyncService` are stubs — need Dio implementation
2. `SyncQueueItem` Hive adapter (`sync_queue.g.dart`) needs `build_runner`
3. Auth box encryption uses `flutter_secure_storage` but box itself is not encrypted
4. No sync status UI in mobile app yet
5. No background worker for sync (Workmanager not wired)

---

## 6. Next Steps

1. Wire Dio HTTP client into `SyncService`
2. Add sync status to parent dashboard
3. Write sync integration tests
4. Add sync indicator to child home screen
5. Implement background sync with Workmanager

---

*End of Offline Sync Report*
