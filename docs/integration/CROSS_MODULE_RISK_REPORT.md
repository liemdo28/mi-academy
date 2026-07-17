# MI Academy — Cross-Module Risk Report

**Date:** 2026-07-17  
**Owner:** Dev 7  
**Status:** Wave 0 — Audit

---

## 1. Summary

Identified 18 cross-module integration risks across 6 teams. Top risks: game result flow (P1), snapshot persistence (P1), adaptive evidence parsing (P1), and OpenAPI client generation (P0).

---

## 2. Risk Register

| ID | Risk | From | To | Severity | Trigger |
|----|------|------|-----|----------|---------|
| CMR-01 | Game result loses 60% of data on sync | Dev 2 (Game) | Dev 1 (Backend) | INT-P1 | Game sends MiGameResult, backend expects GameCompleteRequest |
| CMR-02 | Game launches with no content/settings | Dev 2 (Game) | Dev 1 (Backend) | INT-P1 | Game calls /games/{id}/start, gets back only session_id |
| CMR-03 | No snapshot persistence across app restart | Dev 2 (Game) | Dev 1 (Backend) | INT-P1 | MiGameSnapshot has no API |
| CMR-04 | Mobile has no API client | Dev 4 (Mobile) | Dev 1 (Backend) | INT-P0 | No generated Dart API client exists |
| CMR-05 | OpenAPI spec missing | Dev 1 (Backend) | All | INT-P0 | No spec means no code generation |
| CMR-06 | Adaptive engine cannot parse skill evidence | Dev 5 (Adaptive) | Dev 2 (Game) | INT-P1 | skillEvidence is untyped Map |
| CMR-07 | Analytics events have no schema | Dev 5 (Analytics) | Dev 1 (Backend) | INT-P1 | No analytics event schema |
| CMR-08 | Accessibility settings silently dropped | Dev 2 (Game) | Dev 1 (Backend) | INT-P2 | Backend only stores high_contrast |
| CMR-09 | Mobile imports backend code directly | Dev 4 (Mobile) | Dev 1 (Backend) | INT-P2 | Security boundary violation |
| CMR-10 | Content package has no version contract | Dev 3 (Content) | Dev 2 (Game) | INT-P2 | No content version in API response |
| CMR-11 | Game SDK doesn't exist as separate package | Dev 2 (Game) | Dev 1 (Platform) | INT-P1 | Games depend on internal packages |
| CMR-12 | Offline sync has no conflict resolution | Dev 1 (Backend) | Dev 6 (DevOps) | INT-P1 | No strategy for sync conflicts |
| CMR-13 | Skill taxonomy not shared across modules | All | All | INT-P2 | Each module uses different skill IDs |
| CMR-14 | Localization keys not generated as constants | Dev 4 (UI) | Dev 1 (Platform) | INT-P2 | Hard-coded strings in game |
| CMR-15 | Asset references not typed as constants | Dev 4 (Assets) | Dev 2 (Game) | INT-P2 | String-based asset paths |
| CMR-16 | Snapshot schema version not checked | Dev 2 (Game) | Dev 1 (Platform) | INT-P2 | Old snapshots silently fail |
| CMR-17 | Mock services missing | All | Dev 7 | INT-P0 | No dev environment without backend |
| CMR-18 | Content schema not enforced at runtime | Dev 3 (Content) | Dev 2 (Game) | INT-P2 | Content loaded without validation |

---

## 3. Critical Path — MVP Flow

The minimum integration path for MVP:

```
Parent registration → Parent login → Create child →
Set age/language → Download starter content →
Enter Child Home → Receive daily session →
Start lesson → Launch Memory Cards game →
Complete game → Save result → Update mastery →
Unlock reward → Update parent dashboard → Sync online
```

**Blocked steps (no implementation today):**
- ❌ Download starter content (no content API)
- ❌ Launch Memory Cards (no game SDK)
- ❌ Save result (SaveGameResultRequest empty)
- ❌ Update mastery (no mastery evidence API)
- ❌ Unlock reward (no reward API integration)
- ❌ Parent dashboard update (no push mechanism)

**Estimated unblocked steps: 3/11**

---

## 4. Integration Readiness Checklist

| Module | Contract | Mock | Fixture | Adapter | Test | Ready |
|--------|----------|------|---------|---------|------|-------|
| Auth | ❌ OpenAPI | ❌ | ❌ | ❌ | ❌ | ❌ |
| Child Profile | ❌ OpenAPI | ❌ | ❌ | ❌ | ❌ | ❌ |
| Lesson | ❌ OpenAPI | ❌ | ❌ | ❌ | ❌ | ❌ |
| Content | ❌ JSON Schema | ❌ | ❌ | ❌ | ❌ | ❌ |
| Game Launch | ❌ OpenAPI | ❌ | ❌ | ❌ | ❌ | ❌ |
| Game Result | ❌ OpenAPI | ❌ | ❌ | ❌ | ❌ | ❌ |
| Snapshot | ❌ OpenAPI | ❌ | ❌ | ❌ | ❌ | ❌ |
| Progress | ❌ OpenAPI | ❌ | ❌ | ❌ | ❌ | ❌ |
| Sync | ❌ OpenAPI | ❌ | ❌ | ❌ | ❌ | ❌ |
| Adaptive | ❌ OpenAPI | ❌ | ❌ | ❌ | ❌ | ❌ |
| Analytics | ❌ Event Schema | ❌ | ❌ | ❌ | ❌ | ❌ |
| Rewards | ❌ OpenAPI | ❌ | ❌ | ❌ | ❌ | ❌ |

**Integration-ready modules: 0/12**
