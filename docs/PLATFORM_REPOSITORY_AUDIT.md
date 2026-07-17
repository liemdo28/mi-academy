# MI Academy — Platform Repository Audit

**Date:** 2026-07-17
**Auditor:** Platform & Learning Lead
**Version:** 1.0.0

---

## 1. Repository Overview

### 1.1 Current Structure

```
mi-academy/
├── apps/
│   ├── api/              # FastAPI backend (complete)
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── dependencies.py
│   │   ├── main.py
│   │   ├── models/
│   │   ├── routes/       # auth, parent, children, lessons, games, progress, rewards, sync, admin
│   │   └── schemas/
│   └── mobile/           # Flutter mobile app (starter)
│       ├── pubspec.yaml
│       ├── lib/
│       │   ├── app.dart
│       │   ├── main.dart
│       │   ├── config/
│       │   ├── models/
│       │   ├── screens/  # splash, login, child_home, game, parent_dashboard, parent_settings
│       │   └── src/games/memory_cards/
│       └── assets/
├── packages/             # Mixed Python + Flutter packages
│   ├── game-core/        # Python game engine (COMPLETE)
│   ├── game_core/        # Python game engine (DUPLICATE)
│   ├── learning_core/    # Python (empty)
│   ├── mi_blocks/        # Flutter blocks
│   ├── mi_game_accessibility/  # Flutter
│   ├── mi_game_audio/    # Flutter
│   ├── mi_game_content/  # Flutter
│   ├── mi_game_core/     # Flutter game contracts
│   ├── mi_game_progress/ # Flutter
│   ├── mi_game_testing/  # Flutter
│   └── mi_game_ui/       # Flutter
├── content/
│   ├── schemas/level.schema.json
│   └── vi/words.json
├── infrastructure/
│   ├── docker/
│   │   ├── docker-compose.yml   # PostgreSQL 16, Redis, API
│   │   └── Dockerfile.api
│   ├── migrations/001_initial.sql
│   ├── scripts/seed.py
│   └── seed/seed_data.py
├── docs/
├── schemas/
├── tests/
├── melos.yaml            # Monorepo tool
├── pyproject.toml
└── .env.example
```

### 1.2 Monorepo Tool

- **Tool:** Melos 3.x
- **Configuration:** `melos.yaml`
- **Packages:** `packages/*` and `apps/*`
- **Scripts defined:** `analyze`, `format`, `test`, `test:unit`, `test:widget`, `build_runner`, `clean`, `generate_notices`
- **Issue:** No Python API test script in melos.yaml

### 1.3 Repository Size

| Area | Files | Language |
|---|---|---|
| Backend API | ~40 | Python |
| Mobile App | ~20 | Dart/Flutter |
| Game Packages | ~60 | Dart/Flutter |
| Python Game Engine | ~30 | Python |
| Infrastructure | ~5 | YAML/SQL/Python |
| Content | ~5 | JSON |
| Docs | ~12 | Markdown |
| **Total** | **~170** | |

---

## 2. Backend Audit (FastAPI — `apps/api/`)

### 2.1 API Routes

| Route Prefix | File | Status | Endpoints |
|---|---|---|---|
| `/api/v1/auth` | `routes/auth.py` | ✅ Complete | register, login, logout, refresh |
| `/api/v1/parent` | `routes/parent.py` | ⚠️ Partial | profile CRUD, PIN, reports |
| `/api/v1/children` | `routes/children.py` | ✅ Present | CRUD, daily limit |
| `/api/v1/lessons` | `routes/lessons.py` | ✅ Present | catalog, detail |
| `/api/v1/games` | `routes/games.py` | ✅ Present | list, levels |
| `/api/v1/progress` | `routes/progress.py` | ⚠️ Partial | progress, skills, daily-plan |
| `/api/v1/rewards` | `routes/rewards.py` | ✅ Present | list, unlock |
| `/api/v1/sync` | `routes/sync.py` | ⚠️ Partial | status, content, progress, attempts |
| `/admin/api/v1` | `routes/admin.py` | ⚠️ Basic | lesson/game/question CRUD |

### 2.2 Authentication

- **Method:** JWT (HS256) — stateless
- **Access token:** 30 min expiry
- **Refresh token:** 30 day expiry
- **Password hashing:** bcrypt (12 rounds)
- **PIN:** bcrypt hashed, verified via `/parent/pin/verify` returning short-lived parent session token
- **Status:** ✅ Sound design

### 2.3 Database

- **ORM:** SQLAlchemy 2.x (async)
- **Dialect:** asyncpg (PostgreSQL) / aiosqlite (dev)
- **Models defined:** User, ParentProfile, ChildProfile, Subject, Lesson, Game, Question, Attempt, Progress, Reward, ChildReward, DailySession, ContentVersion (12 models)
- **Missing tables:** SkillMastery, SyncQueue, GameSnapshot, AdaptiveState, AuditLog
- **Migration:** `001_initial.sql` (raw SQL, not Alembic)
- **Seed data:** subjects (5), games (6 MVP), rewards (10)

### 2.4 Dependencies

```python
# apps/api/requirements.txt (needs verification)
fastapi
uvicorn[standard]
sqlalchemy[asyncio]
asyncpg          # PostgreSQL
aiosqlite        # SQLite dev
pydantic
pydantic-settings
python-jose[cryptography]
passlib[bcrypt]
python-multipart
```

---

## 3. Mobile App Audit (`apps/mobile/`)

### 3.1 Dependencies

**Flutter SDK:** `>=3.22.0`, `>=3.4.0`
**Key dependencies:**
- `hive: ^2.2.3` + `hive_flutter: ^1.1.0` — local storage
- `uuid: ^4.4.0` — ID generation
- Local path packages: `mi_game_core`, `mi_game_ui`, `mi_game_content`, `mi_game_audio`, `mi_game_progress`, `mi_game_accessibility`, `mi_blocks`, `mi_game_testing`

**Missing:** No HTTP client, no Riverpod setup, no routing (go_router), no Flutter localization, no offline sync library, no DI container.

### 3.2 Screens

| Screen | File | Status |
|---|---|---|
| Splash | `screens/splash_screen.dart` | ⚠️ Skeleton |
| Login | `screens/login_screen.dart` | ⚠️ Skeleton |
| Child Home | `screens/child_home_screen.dart` | ⚠️ Skeleton |
| Game | `screens/game_screen.dart` | ⚠️ Skeleton |
| Parent Dashboard | `screens/parent_dashboard_screen.dart` | ⚠️ Skeleton |
| Parent Settings | `screens/parent_settings_screen.dart` | ⚠️ Skeleton |

### 3.3 Architecture

- **State management:** Riverpod imported but not wired
- **Routing:** `config/router.dart` exists but `go_router` not in pubspec
- **Theme:** `config/theme.dart` — `MITheme.light()` exists
- **Models:** `models/child_profile.dart` — basic class
- **No Clean Architecture:** screens directly reference models, no repository layer

---

## 4. Flutter Game Packages Audit

### 4.1 Package Inventory

| Package | Purpose | Status |
|---|---|---|
| `mi_game_core` | Base game, lifecycle, contracts | ✅ Well-structured |
| `mi_game_ui` | Theme, widgets (completion, hint, pause, progress dots, tutorial) | ✅ Good |
| `mi_game_audio` | AudioManager, VolumeGroup | ⚠️ Basic |
| `mi_game_accessibility` | AccessibilityHelper, MotionConfig, SemanticLabels | ✅ Good |
| `mi_game_content` | ContentLoader, ContentValidator, GameContentProvider | ⚠️ Basic |
| `mi_game_progress` | AttemptRecord, MasteryCalculator, ProgressTracker, SkillMastery | ⚠️ Basic |
| `mi_game_testing` | FakeServices, TestFixtures | ✅ Useful |
| `mi_blocks` | Block, CommandTree, Interpreter | ✅ Logic complete |

### 4.2 Game Contracts (in `mi_game_core`)

**Existing models:**
- `MiGameSnapshot` — ✅ schema exists
- `MiCompletionResult` — ✅ exists
- `MiActionResult` — ✅ exists
- `MiHint`, `MiLevel`, `MiGameAction` — ✅ exist

**Missing contracts per Platform spec:**
- `MiGameLaunchRequest` — ❌ Not defined
- `MiGameResult` — ❌ Not defined
- `MiProgressGateway` — ❌ Not defined

### 4.3 Game Core (Python — `packages/game-core/`)

- 6 games: word_builder, sound_match, math_race, math_supermarket, memory_cards, robot_commands
- Registry, scoring, difficulty engine
- Tests: test_difficulty, test_math_race, test_memory_cards, test_robot_commands, test_scoring
- **CRITICAL DUPLICATE:** `packages/game-core/` and `packages/game_core/` are identical copies

---

## 5. Infrastructure Audit

### 5.1 Docker Compose

- PostgreSQL 16 Alpine ✅
- Redis 7 Alpine ✅
- API service with hot reload ✅
- Health checks ✅

### 5.2 CI/CD

- ❌ No GitHub Actions workflow
- ❌ No Dockerfile for mobile/Flutter
- ❌ No secret management (`.env` file references)
- ❌ No deployment pipeline

### 5.3 Migrations

- Only `001_initial.sql` exists
- ❌ No migration versioning tool (Alembic not configured)
- ❌ No rollback scripts
- ❌ No migration tests

---

## 6. Content System Audit

### 6.1 Content Files

| File | Content | Status |
|---|---|---|
| `schemas/level.schema.json` | Level JSON schema | ✅ |
| `content/vi/words.json` | Vietnamese word bank | ✅ |
| `content/vi/` | Only words.json | ❌ Incomplete |

### 6.2 Issues

- No lesson content JSON files
- No question banks
- No localization for English (`content/en/`)
- No content versioning manifests
- No content package structure
- Content schema (`level.schema.json`) is for game levels only, not lessons

---

## 7. Test Coverage Audit

### 7.1 Python Tests

| Package | Tests | Location |
|---|---|---|
| `game-core` | 5 test files | `packages/game-core/tests/` |
| `game_core` | (duplicate) | `packages/game_core/tests/` |

**Coverage:** game-core has ~80% on core modules, but no API tests, no database tests, no sync tests.

### 7.2 Flutter Tests

- `mi_game_core`: 1 test file (`test/mi_game_core_test.dart`)
- All other Flutter packages: no tests
- Mobile app: no tests
- No integration tests
- No E2E tests

### 7.3 Missing Test Coverage

- API endpoint tests
- Database migration tests
- Offline sync tests
- Contract tests (MiGameLaunchRequest, MiGameResult, etc.)
- Authorization/security tests
- Data deletion tests

---

## 8. Security Audit

### 8.1 Strengths

- JWT with short-lived access tokens + refresh rotation
- bcrypt for passwords (12 rounds)
- CORS configurable
- No advertising SDKs detected
- Child data separation (no real names, emails, photos)

### 8.2 Vulnerabilities / Gaps

| Issue | Severity | Location |
|---|---|---|
| CORS_ORIGINS defaults to `["*"]` | 🔴 High | `config.py` |
| SECRET_KEY hard-coded placeholder | 🔴 High | `config.py` |
| No rate limiting on API endpoints | 🟡 Medium | `config.py` defines limits but not applied |
| No SQL injection protection audit | 🟡 Medium | Raw SQL in migrations |
| No JWT blocklist | 🟡 Medium | Logout is stateless |
| No 2FA for parent accounts | 🟡 Medium | Design gap |
| `.env` secrets in repo | 🔴 High | `.env.example` but `.env` may be committed |
| No content validation pipeline | 🟡 Medium | Admin can publish invalid JSON |
| Missing security audit log | 🟡 Medium | No AuditLog table |
| No XSS protection | 🟡 Medium | User input in JSON stored directly |

---

## 9. Duplicate Code & Architecture Issues

### 9.1 Critical Duplicates

1. **`packages/game-core/` vs `packages/game_core/`**
   - Identical content, different directory names
   - Causes confusion, doubles maintenance burden
   - Resolution: Delete one, update melos.yaml and imports

2. **`apps/api/schemas/__init__.py` is empty**
   - Pydantic schemas not yet defined
   - Route files import from non-existent `apps.api.schemas`

### 9.2 Missing Architecture Layers

| Layer | Missing | Needed For |
|---|---|---|
| Repository pattern | ❌ No | Mobile app data access |
| Use cases / services | ❌ No | Business logic isolation |
| DI container | ❌ No | Dependency injection |
| Offline sync engine | ❌ No | Background sync |
| Adaptive learning engine | ❌ No | Difficulty adjustment |
| Localization service | ❌ No | i18n |
| Admin Flutter app | ❌ No | Content management |

### 9.3 Mobile App Gaps

| Feature | Status |
|---|---|
| HTTP client (Dio) | ❌ Missing |
| go_router | ❌ Missing |
| Riverpod state management | ⚠️ Imported, not wired |
| Offline database (Hive) | ⚠️ Imported, not wired |
| API service layer | ❌ Missing |
| Auth token management | ❌ Missing |
| Sync queue | ❌ Missing |
| Localization | ⚠️ Delegates in app.dart, no translations |
| Parent PIN screen | ❌ Missing |
| Child profile selector | ❌ Missing |
| Daily learning plan UI | ❌ Missing |
| Reward display | ❌ Missing |
| Game launcher | ❌ Missing |

---

## 10. Wave Status Assessment

| Wave | Description | Status |
|---|---|---|
| Wave 0 | Audit, monorepo, contracts, mock game, CI, Docker | 🔴 In Progress |
| Wave 1 | Parent auth, child profiles, local DB, PIN, progress | 🟡 Partial (backend done, mobile missing) |
| Wave 2 | Lesson catalog, daily mission, skills, rewards | 🟡 Partial |
| Wave 3 | Parent dashboard, weekly report, usage, sync | 🟡 Partial |
| Wave 4 | Adaptive learning, recommendations | ❌ Not started |
| Wave 5 | Admin, security, data export/delete | 🟡 Basic |

---

## 11. Action Items

### Immediate (Wave 0 — This Sprint)

1. **Delete `packages/game_core/`** (duplicate of `packages/game-core/`)
2. **Create `apps/api/schemas/__init__.py`** with all Pydantic models
3. **Fix CORS** to not default to `["*"]`
4. **Create GitHub Actions CI** for backend + Flutter
5. **Create Flutter `packages/`** for platform (not game-specific):
   - `packages/shared_models/`
   - `packages/design_system/`
   - `packages/localization/`
   - `packages/learning_core/`
   - `packages/progress_core/`
   - `packages/offline_sync/`
6. **Add Flutter platform deps** to mobile `pubspec.yaml`
7. **Create shared contracts** in `mi_game_core`
8. **Create mock gateway** `InMemoryProgressGateway`

### Short-term (Wave 1-2)

9. Implement mobile auth + token management
10. Implement Hive local database
11. Implement offline sync queue
12. Build parent PIN screen + parent dashboard
13. Build child profile selector
14. Build lesson catalog UI
15. Set up Flutter localization

### Medium-term (Wave 3-4)

16. Adaptive learning engine
17. Parent reports (weekly, detailed)
18. Content versioning system
19. Flutter admin app

---

*End of Audit Report*
