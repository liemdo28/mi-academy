# MI Academy — Backend API Report

**Date:** 2026-07-17
**Owner:** Platform & Learning Lead

---

## 1. API Overview

| Property | Value |
|---|---|
| Framework | FastAPI |
| Version | 1.0.0 |
| Database | PostgreSQL 16 + SQLite dev |
| ORM | SQLAlchemy 2.x (async) |
| Auth | JWT (HS256) |
| Port | 8000 |

---

## 2. Routes

### 2.1 Authentication (`/api/v1/auth`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/register` | None | Register parent account |
| POST | `/login` | None | Login, returns tokens |
| POST | `/logout` | Access token | Stateless logout |
| POST | `/refresh` | Refresh token | Rotate tokens |

### 2.2 Parent (`/api/v1/parent`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/profile` | Access token | Get parent profile |
| PUT | `/profile` | Access token | Update profile |
| PUT | `/pin` | Access token | Set/change PIN |
| POST | `/pin/verify` | None | Verify PIN → parent session |
| GET | `/reports` | Access token | Today's summary |
| GET | `/reports/weekly` | Access token | Weekly per-child report |
| GET | `/export` | Access token | Privacy-safe parent data export |

### 2.3 Children (`/api/v1/children`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/{id}` | Access token | Child details |
| PUT | `/{id}` | Access token | Update child |
| GET | `/{id}/daily-plan` | Access token | Today's learning plan |

### 2.4 Lessons (`/api/v1/lessons`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/` | Optional | Lesson catalog (filterable) |
| GET | `/{id}` | Optional | Lesson detail + content |
| GET | `/{id}/levels` | Optional | Game levels |

### 2.5 Games (`/api/v1/games`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/` | Optional | All available games |
| GET | `/{id}/levels` | Optional | Levels for a game |

### 2.6 Progress (`/api/v1/progress`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/children/{id}/progress` | Access token | Per-lesson progress |
| GET | `/children/{id}/skills` | Access token | Skill mastery report |
| GET | `/children/{id}/daily-plan` | Access token | Adaptive recommendations |
| POST | `/game-result` | Access token | Save `MiGameResult` |

### 2.7 Rewards (`/api/v1/rewards`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/children/{id}` | Access token | Unlocked rewards |
| POST | `/children/{id}/check` | Access token | Check + unlock rewards |

### 2.8 Sync (`/api/v1/sync`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/status` | None | Content version info |
| GET | `/content` | None | Content delta by type |
| POST | `/progress` | Access token | Bulk upsert progress |
| POST | `/attempts` | Access token | Bulk insert attempts |

### 2.9 Admin (`/admin/api/v1`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/auth/login` | None | Admin login |
| GET | `/lessons` | Admin token | List lessons |
| POST | `/lessons` | Admin token | Create lesson |
| PUT | `/lessons/{id}` | Admin token | Update lesson |
| POST | `/lessons/{id}/publish` | Admin token | Publish |
| POST | `/lessons/{id}/rollback` | Admin token | Rollback version |
| GET | `/questions` | Admin token | List questions |
| POST | `/questions` | Admin token | Create question |
| PUT | `/questions/{id}` | Admin token | Update question |
| GET | `/games` | Admin token | List games |
| PUT | `/games/{id}` | Admin token | Update game |
| GET | `/content/versions` | Admin token | Version list |
| GET | `/analytics` | Admin token | Usage analytics |

---

## 3. Database Schema

### Tables

| Table | Rows | Purpose |
|---|---|---|
| `users` | — | Parent + admin accounts |
| `parent_profiles` | — | Parent settings, PIN hash |
| `child_profiles` | — | Child accounts (no PII) |
| `subjects` | 5 | Learning areas |
| `lessons` | — | Lesson metadata + content JSON |
| `games` | 6 | Game definitions (MVP) |
| `questions` | — | Question bank |
| `attempts` | — | Per-question attempt records |
| `progress` | — | Per-lesson progress per child |
| `rewards` | 10 | Reward definitions (MVP) |
| `child_rewards` | — | Unlocked rewards |
| `daily_sessions` | — | Daily usage aggregation |
| `content_versions` | — | Content versioning |

---

## 4. Security

| Feature | Status |
|---|---|
| Password hashing (bcrypt 12 rounds) | ✅ |
| JWT access token (30 min) | ✅ |
| JWT refresh token (30 days) | ✅ |
| Token rotation on refresh | ✅ |
| PIN hashing (bcrypt) | ✅ |
| Short-lived parent session token | ✅ |
| CORS restricted | ✅ (fixed from `["*"]`) |
| SQLAlchemy parameterized queries | ✅ |
| No secrets in code | ⚠️ (`.env` must be used) |
| Rate limiting | ⚠️ Config defined, not enforced |

---

## 5. Verification

| Check | Result |
|---|---|
| FastAPI import smoke (`from apps.api.main import app`) | ✅ |
| Parent report summary local API test | ✅ |
| Weekly report local API test | ✅ |
| Child-data deletion cascade local API test | ✅ |
| Parent export local API test | ✅ |
| Full Python suite | ✅ `91 passed` |

The child-data deletion test verifies `child_profiles`, `daily_sessions`, `progress`, `attempts`, and `child_rewards` are removed while the parent account and reusable reward catalog remain. The parent export test verifies the privacy-safe JSON export includes parent/child summaries, daily sessions, progress, reward names, aggregate attempt counts, and explicit privacy flags without raw answer payloads.

---

## 6. Known Issues

1. Deployed API smoke test is still pending; current proof is local/import + direct async route tests.
2. Parent export endpoint is implemented locally, but deployed API proof is still pending.
3. CORS defaulted to `["*"]` — fixed to empty list.
4. Rate limiting middleware is configured, but endpoint-specific production tuning still needs live verification.
5. No JWT blocklist — logout is stateless only.

---

## 7. Development

```bash
# Start API
uvicorn apps.api.main:app --host 0.0.0.0 --port 8000 --reload

# Docker (full stack)
docker compose -f infrastructure/docker/docker-compose.yml up

# Run migrations
psql $DATABASE_URL -f infrastructure/migrations/001_initial.sql
```

---

*End of Backend API Report*
