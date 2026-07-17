# MI Academy — Privacy Data Map

> **Version:** 1.0.0
> **Date:** 2026-07-17

---

## What MI Academy collects

| Data | Where collected | Purpose | Stored where | Shared? |
|------|----------------|---------|-------------|---------|
| Child nickname | On-device creation | Profile identification | Local (Hive) + PostgreSQL | Never |
| Avatar selection | On-device | Profile personalization | Local + PostgreSQL | Never |
| Age group | On-device | Content filtering | Local + PostgreSQL | Never |
| Language preference | On-device | Localization | Local | Never |
| Game progress | During gameplay | Adaptive difficulty, mastery | Local + PostgreSQL (sync) | Never |
| Daily session time | During gameplay | Parent dashboard | Local + PostgreSQL | Never |
| Stars & badges | During gameplay | Reward system | Local + PostgreSQL | Never |

## What MI Academy does NOT collect

| ❌ Not collected | Why |
|-----------------|-----|
| Real name / full name | Not needed — nickname only |
| Email address | Not needed for child |
| Phone number | Not needed |
| GPS / location | Never |
| Contacts | Never |
| Camera | Never |
| Microphone (except game voice activity, with consent) | Privacy |
| Advertising identifier | No ads |
| IP address (only for API routing, not stored) | Standard |
| Biometric data | Never |
| Social media accounts | No social features |

## Data flow

```
Child plays game
  → Progress stored locally (Hive)
  → Optional: sync to PostgreSQL via authenticated API only when a parent-enabled backend URL is configured
  → Parent views dashboard (PIN-protected)
  → No data leaves the device without explicit parent consent
```

The mobile app does not embed a backend URL by default. Parent/sync API access
must be enabled at build time with `MI_ACADEMY_API_BASE_URL`, keeping the
child-facing MVP offline-first unless a parent explicitly opts into sync.

## Data retention

- Local data: persists until parent deletes child profile
- Server data: can be deleted on parent request
- No automatic data expiration

## Parent rights

- View all stored data via parent dashboard
- Export data as privacy-safe JSON through `GET /api/v1/parent/export`
- Delete child profile and all associated child-owned data
- No data recovery after deletion

Current local backend tests verify the parent export contains parent and child
summaries, daily sessions, progress, reward names, aggregate attempt counts, and
privacy flags. The export excludes child contact data, location data, social/ad
data, and raw answer payloads. Local cascade tests verify child-owned profile,
session, progress, attempt, and reward rows are removed while parent account and
shared reward catalog rows remain. Deployed API verification is still pending.

## COPPA / child privacy compliance

- No collection of personal information from children under 13
- No behavioral tracking for advertising
- No third-party data sharing
- Parental consent required for any data sync
