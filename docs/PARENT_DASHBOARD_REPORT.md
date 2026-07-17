# MI Academy — Parent Dashboard Report

**Date:** 2026-07-17
**Owner:** Platform & Learning Lead

---

## 1. Features

### 1.1 Backend (API)

| Feature | Endpoint | Status |
|---|---|---|
| Today's summary | GET `/api/v1/parent/reports` | ✅ Implemented |
| Weekly report | GET `/api/v1/parent/reports/weekly` | ✅ Implemented |
| Profile management | GET/PUT `/api/v1/parent/profile` | ✅ Implemented |
| PIN management | PUT `/api/v1/parent/pin` | ✅ Implemented |
| PIN verification | POST `/api/v1/parent/pin/verify` | ✅ Implemented |
| Child management | `/api/v1/parent/children/*` | ✅ Implemented |
| Data export | GET `/api/v1/parent/export` | ✅ Implemented locally; deployed proof pending |
| Data deletion | DELETE `/api/v1/parent/children/{id}` | ✅ Cascade covered by local API test; deployed proof pending |

### 1.2 Mobile (Flutter)

| Feature | Screen | Status |
|---|---|---|
| PIN entry | ParentPINScreen | ⚠️ Not created |
| PIN set/change | ParentSettingsScreen | ⚠️ Not created |
| Biometric auth | ParentPINScreen | ⚠️ Not created |
| Child selector | ChildSelectorScreen | ✅ Created |
| Daily summary | ParentDashboardScreen | ⚠️ Skeleton |
| Weekly report | ParentDashboardScreen | ⚠️ Skeleton |
| Time usage chart | ParentDashboardScreen | ⚠️ Not created |
| Subject progress | ParentDashboardScreen | ⚠️ Not created |
| Skill strengths | ParentDashboardScreen | ⚠️ Not created |
| Audio settings | ParentSettingsScreen | ⚠️ Not created |
| Daily limit control | ParentSettingsScreen | ⚠️ Not created |
| Offline download | ParentSettingsScreen | ⚠️ Not created |

---

## 2. API Data

### 2.1 Today's Report (`ParentReportSummary`)

```json
{
  "total_children": 2,
  "total_stars_today": 5,
  "total_games_today": 3,
  "total_lessons_today": 2,
  "total_time_minutes_today": 45
}
```

### 2.2 Weekly Report (`WeeklyReportEntry[]`)

```json
[
  {
    "date": "2026-07-10",
    "duration_seconds": 2700,
    "lessons_completed": 3,
    "games_completed": 5
  }
]
```

---

## 3. Security Requirements

| Requirement | Status |
|---|---|
| PIN or biometric required | ⚠️ Backend ready, mobile pending |
| Max 3 taps to access | ⚠️ Navigation needs design |
| Child mode cannot see parent info | ✅ Design requirement met |
| No parent email in child UI | ✅ Design requirement met |

---

## 4. Files Created

| File | Purpose |
|---|---|
| `apps/api/routes/parent.py` | Backend parent routes |
| `apps/api/schemas/reports.py` | Report schemas |
| `apps/api/schemas/parent.py` | Parent profile schemas |
| `apps/mobile/lib/screens/child_selector_screen.dart` | Child profile selector |

---

## 5. Known Limitations

1. **PIN screen** — backend ready but mobile screen not created
2. **Weekly charts** — data available but UI not built
3. **Time usage** — `DailySession` table exists but no real-time tracking
4. **Data export** — implemented locally; needs deployed API verification
5. **Data deletion** — cascade implemented locally; needs deployed API verification
6. **Parent dashboard** — existing skeleton needs full implementation

---

## 6. Next Steps

1. Create `ParentPINScreen` with biometric support (`local_auth`)
2. Implement `ParentDashboardScreen` with real data
3. Add weekly chart visualization (fl_chart)
4. Verify data export endpoint against a deployed API
5. Verify GDPR data deletion cascade against a deployed API
6. Add sync status indicator to parent dashboard

---

*End of Parent Dashboard Report*
