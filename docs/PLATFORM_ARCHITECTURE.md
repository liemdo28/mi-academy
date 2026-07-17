# MI Academy — Platform Architecture

**Date:** 2026-07-17
**Owner:** Platform & Learning Lead
**Version:** 1.0.0
**Status:** Design — Pending Implementation

---

## 1. Monorepo Structure

### 1.1 Target Directory Layout

```
mi-academy/
├── apps/
│   ├── mobile/              # Flutter app (iOS, Android, Web)
│   ├── admin/               # Flutter web admin dashboard
│   └── api/                 # FastAPI backend
├── packages/                # Shared Dart/Flutter packages
│   ├── shared_models/       # Cross-app data models
│   ├── design_system/       # MI Academy design tokens + widgets
│   ├── localization/         # i18n ARB files + service
│   ├── learning_core/        # Lesson engine, content loading
│   ├── progress_core/        # Progress tracking, mastery
│   ├── offline_sync/         # Sync queue, conflict resolution
│   ├── mi_contract_tests/    # Contract validation tests
│   └── (game packages)       # Dev 2 owned: mi_game_*, mi_blocks
├── content/
│   ├── schemas/              # JSON Schema definitions
│   │   ├── lesson.schema.json
│   │   ├── level.schema.json
│   │   ├── question.schema.json
│   │   └── reward.schema.json
│   ├── vi/                   # Vietnamese content
│   │   ├── lessons/
│   │   ├── questions/
│   │   └── manifest.json
│   ├── en/                   # English content
│   │   ├── lessons/
│   │   ├── questions/
│   │   └── manifest.json
│   └── seeds/                # Development seed data
├── infrastructure/
│   ├── docker/
│   │   ├── docker-compose.yml
│   │   ├── Dockerfile.api
│   │   └── Dockerfile.admin
│   ├── migrations/          # Alembic migrations
│   │   ├── versions/
│   │   └── env.py
│   └── scripts/
│       └── init_dev.sh
├── tests/
│   ├── api/
│   ├── db/
│   ├── sync/
│   ├── contracts/
│   └── e2e/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── deploy.yml
└── melos.yaml
```

### 1.2 Package Responsibilities

| Package | Owner | Responsibility |
|---|---|---|
| `shared_models` | Platform | Cross-app Dart classes: User, ChildProfile, Lesson, etc. |
| `design_system` | Platform | Theme, tokens, shared widgets |
| `localization` | Platform | ARB files, l10n service |
| `learning_core` | Platform | Lesson catalog, daily plan, content loading |
| `progress_core` | Platform | Mastery, adaptive engine, skill tracking |
| `offline_sync` | Platform | Sync queue, Hive adapters, conflict resolution |
| `mi_contract_tests` | Platform | Shared contract validation |
| `mi_game_core` | Dev 2 | Game base class, lifecycle, snapshot |
| `mi_game_ui` | Dev 2 | Game widgets |
| `mi_game_audio` | Dev 2 | Audio management |
| `mi_game_accessibility` | Dev 2 | Accessibility helpers |
| `mi_game_content` | Dev 2 | Game content loading |
| `mi_game_progress` | Dev 2 | Game-level progress |
| `mi_game_testing` | Dev 2 | Test helpers |
| `mi_blocks` | Dev 2 | Visual programming blocks |

---

## 2. Flutter Mobile App Architecture

### 2.1 App Layers

```
┌─────────────────────────────────────────┐
│  Screens (UI layer)                     │
│  SplashScreen, LoginScreen, ChildHome   │
│  ParentDashboard, ParentSettings        │
├─────────────────────────────────────────┤
│  Widgets (design system)                │
│  MIBottomNav, MICard, MILoading...     │
├─────────────────────────────────────────┤
│  State Management (Riverpod)            │
│  AuthNotifier, ChildNotifier,           │
│  LessonNotifier, ProgressNotifier       │
│  SyncNotifier, RewardNotifier          │
├─────────────────────────────────────────┤
│  Services (business logic)              │
│  AuthService, ProfileService,          │
│  LessonService, ProgressService,       │
│  SyncService, RewardService             │
├─────────────────────────────────────────┤
│  Repositories (data abstraction)        │
│  AuthRepository, ProfileRepository,    │
│  LessonRepository, ProgressRepository  │
│  ContentRepository, RewardRepository   │
├─────────────────────────────────────────┤
│  Data Sources                           │
│  RemoteDataSource (Dio HTTP)           │
│  LocalDataSource (Hive)                │
│  GameBridge (MiProgressGateway)        │
└─────────────────────────────────────────┘
```

### 2.2 Required Pub Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Local packages
  mi_game_core:          path: ../../packages/mi_game_core
  mi_game_ui:            path: ../../packages/mi_game_ui
  mi_game_content:       path: ../../packages/mi_game_content
  mi_game_audio:         path: ../../packages/mi_game_audio
  mi_game_progress:      path: ../../packages/mi_game_progress
  mi_game_accessibility: path: ../../packages/mi_game_accessibility
  mi_blocks:             path: ../../packages/mi_blocks
  shared_models:         path: ../../packages/shared_models
  design_system:          path: ../../packages/design_system
  localization:           path: ../../packages/localization
  learning_core:          path: ../../packages/learning_core
  progress_core:          path: ../../packages/progress_core
  offline_sync:           path: ../../packages/offline_sync

  # Networking
  dio: ^5.4.0
  retrofit: ^4.1.0

  # Local storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # State management
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # Routing
  go_router: ^14.0.0

  # Auth & Security
  flutter_secure_storage: ^9.0.0
  local_auth: ^2.2.0           # Biometrics
  crypto: ^3.0.3               # PIN hashing

  # Utilities
  uuid: ^4.4.0
  intl: ^0.19.0
  connectivity_plus: ^6.0.0     # Network status
  workmanager: ^0.5.2          # Background sync
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mi_game_testing: path: ../../packages/mi_game_testing
```

### 2.3 Hive Box Layout

| Box Name | Content | Encryption |
|---|---|---|
| `auth` | Access token, refresh token | ✅ Secure storage |
| `profiles` | Child profiles array | ❌ |
| `lessons` | Cached lesson JSON | ❌ |
| `levels` | Cached level JSON | ❌ |
| `progress` | Local progress records | ❌ |
| `attempts` | Local attempt records | ❌ |
| `snapshots` | Game snapshots | ❌ |
| `rewards` | Unlocked rewards | ❌ |
| `sync_queue` | Pending sync items | ❌ |
| `settings` | App settings, audio, accessibility | ❌ |

### 2.4 Game Launcher Flow

```
1. User selects child → Load child profile from Hive
2. User taps lesson → LessonService.loadLesson(id)
   → Returns Lesson with embedded GameLevel
3. Platform creates MiGameLaunchRequest:
   {
     childProfileId: "uuid",
     gameId: "word_builder",
     levelId: "level_1",
     language: "vi",
     ageGroup: "junior",
     accessibility: { highContrast: false, ... },
     audioPreferences: { musicVolume: 0.8, ... },
     levelContent: { ... },
     restoredState: null
   }
4. Platform calls GameLauncher.launch(launchRequest)
5. Game plays → produces MiGameResult
6. Platform receives result → MiProgressGateway.saveGameResult(result)
7. Platform updates mastery → ProgressCore.updateSkillMastery(result)
8. Platform shows result screen → Reward check
9. Parent report updated
```

---

## 3. FastAPI Backend Architecture

### 3.1 Layer Structure

```
apps/api/
├── main.py                  # FastAPI app, CORS, routers
├── config.py                # Settings from env
├── database.py             # AsyncEngine, session maker
├── dependencies.py          # Auth deps, DB session, rate limit
├── models/                  # SQLAlchemy models (ORM)
│   ├── __init__.py
│   ├── user.py
│   ├── parent.py
│   ├── child.py
│   ├── subject.py
│   ├── lesson.py
│   ├── game.py
│   ├── question.py
│   ├── attempt.py
│   ├── progress.py
│   ├── reward.py
│   ├── session.py
│   └── sync.py
├── routes/                   # API endpoints (thin controllers)
│   ├── __init__.py
│   ├── auth.py
│   ├── parent.py
│   ├── children.py
│   ├── lessons.py
│   ├── games.py
│   ├── progress.py
│   ├── rewards.py
│   ├── sync.py
│   └── admin.py
├── schemas/                  # Pydantic request/response models
│   ├── __init__.py
│   ├── auth.py
│   ├── parent.py
│   ├── child.py
│   ├── lesson.py
│   ├── game.py
│   ├── progress.py
│   ├── reward.py
│   ├── sync.py
│   └── admin.py
├── services/                 # Business logic
│   ├── auth_service.py
│   ├── lesson_service.py
│   ├── progress_service.py
│   ├── mastery_service.py
│   ├── adaptive_service.py
│   ├── reward_service.py
│   └── sync_service.py
├── middleware/
│   └── rate_limit.py
└── utils/
    ├── security.py
    └── content_validator.py
```

### 3.2 Database Schema

See `docs/database-schema.md` for full schema. Key tables:

| Table | Purpose |
|---|---|
| `users` | Parent + admin accounts |
| `parent_profiles` | Parent settings, PIN |
| `child_profiles` | Child accounts (no sensitive data) |
| `subjects` | Learning areas |
| `lessons` | Lesson metadata + content JSON |
| `games` | Game definitions |
| `questions` | Question bank |
| `attempts` | Per-question attempt records |
| `progress` | Per-lesson progress per child |
| `rewards` | Reward definitions |
| `child_rewards` | Unlocked rewards |
| `daily_sessions` | Daily usage aggregation |
| `content_versions` | Content versioning |
| `sync_queue` | Server-side sync tracking |
| `skill_mastery` | Per-skill mastery per child |
| `adaptive_state` | Per-child adaptive difficulty |
| `audit_log` | Security audit events |

---

## 4. API Contracts

### 4.1 Shared Contracts (Flutter ↔ Backend ↔ Game)

#### MiGameLaunchRequest

```dart
class MiGameLaunchRequest {
  final String childProfileId;
  final String gameId;
  final String levelId;
  final String language;
  final String ageGroup;
  final AccessibilityPreferences accessibility;
  final AudioPreferences audioPreferences;
  final Map<String, dynamic> levelContent;
  final Map<String, dynamic>? restoredState;
}

class AccessibilityPreferences {
  final bool highContrast;
  final bool largeText;
  final bool reduceMotion;
  final bool screenReader;
  final double fontSize;
}

class AudioPreferences {
  final double musicVolume;    // 0.0 - 1.0
  final double sfxVolume;     // 0.0 - 1.0
  final bool speechEnabled;
}
```

#### MiGameResult

```dart
class MiGameResult {
  final String attemptId;          // UUID — idempotency key
  final String childProfileId;
  final String gameId;
  final String levelId;
  final DateTime startedAt;
  final DateTime completedAt;
  final int attemptCount;
  final int correctCount;
  final int incorrectCount;
  final int hintCount;
  final int durationSeconds;
  final bool completed;
  final double masteryEvidence;    // 0.0 - 1.0
  final Map<String, dynamic> skillEvidence;
  final Map<String, dynamic> metadata;
}
```

#### MiGameSnapshot

```dart
class MiGameSnapshot {
  final int schemaVersion;       // Must be 1
  final String gameId;
  final String levelId;
  final String childProfileId;
  final DateTime savedAt;
  final Map<String, dynamic> state;
}
```

#### MiProgressGateway (Interface)

```dart
abstract interface class MiProgressGateway {
  /// Saves a game result. Idempotent by attemptId.
  Future<void> saveGameResult(MiGameResult result);

  /// Saves a game state snapshot for resume.
  Future<void> saveSnapshot(MiGameSnapshot snapshot);

  /// Loads a snapshot for the given child/game/level.
  Future<MiGameSnapshot?> loadSnapshot({
    required String childProfileId,
    required String gameId,
    required String levelId,
  });
}
```

### 4.2 API Endpoints

#### Authentication

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/v1/auth/register` | Register parent account |
| POST | `/api/v1/auth/login` | Login, returns tokens |
| POST | `/api/v1/auth/logout` | Client-side token discard |
| POST | `/api/v1/auth/refresh` | Rotate tokens |

#### Parent

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/v1/parent/profile` | Get profile |
| PUT | `/api/v1/parent/profile` | Update profile |
| PUT | `/api/v1/parent/pin` | Set/change PIN |
| POST | `/api/v1/parent/pin/verify` | Verify PIN, get parent session |
| GET | `/api/v1/parent/reports` | Today's summary |
| GET | `/api/v1/parent/reports/weekly` | Weekly per-child report |
| POST | `/api/v1/parent/children` | Create child profile |
| GET | `/api/v1/parent/children` | List children |
| DELETE | `/api/v1/parent/children/{id}` | Delete child + data |
| GET | `/api/v1/parent/export` | Export privacy-safe parent/child data JSON |

#### Children

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/v1/children/{id}` | Child details |
| PUT | `/api/v1/children/{id}` | Update child |
| GET | `/api/v1/children/{id}/daily-plan` | Today's plan |

#### Lessons

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/v1/lessons` | Catalog (filter by age_group, subject) |
| GET | `/api/v1/lessons/{id}` | Lesson detail + content |
| GET | `/api/v1/lessons/{id}/levels` | Game levels for lesson |

#### Games

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/v1/games` | All available games |
| GET | `/api/v1/games/{id}/levels` | Levels for a game |

#### Progress

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/v1/progress/children/{id}/progress` | Per-lesson progress |
| GET | `/api/v1/progress/children/{id}/skills` | Skill mastery report |
| POST | `/api/v1/progress/game-result` | Save `MiGameResult` |
| GET | `/api/v1/progress/children/{id}/daily-plan` | Adaptive recommendations |

#### Rewards

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/v1/rewards/children/{id}` | Child's unlocked rewards |
| POST | `/api/v1/rewards/children/{id}/check` | Check and unlock new rewards |

#### Sync

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/v1/sync/status` | Content version info |
| GET | `/api/v1/sync/content` | Content delta by type |
| POST | `/api/v1/sync/progress` | Bulk upsert progress |
| POST | `/api/v1/sync/attempts` | Bulk insert attempts |

#### Admin

| Method | Endpoint | Description |
|---|---|---|
| POST | `/admin/api/v1/auth/login` | Admin login |
| GET | `/admin/api/v1/lessons` | List lessons |
| POST | `/admin/api/v1/lessons` | Create lesson |
| PUT | `/admin/api/v1/lessons/{id}` | Update lesson |
| POST | `/admin/api/v1/lessons/{id}/publish` | Publish lesson |
| POST | `/admin/api/v1/lessons/{id}/rollback` | Rollback version |
| GET | `/admin/api/v1/questions` | List questions |
| POST | `/admin/api/v1/questions` | Create question |
| PUT | `/admin/api/v1/questions/{id}` | Update question |
| GET | `/admin/api/v1/games` | List games |
| PUT | `/admin/api/v1/games/{id}` | Update game config |
| GET | `/admin/api/v1/content/versions` | Content versions |
| POST | `/admin/api/v1/content/versions/{id}/rollback` | Rollback content |
| GET | `/admin/api/v1/analytics` | Basic usage analytics |

---

## 5. Adaptive Learning Engine

### 5.1 Data Model

```python
class SkillMastery(Base):
    __tablename__ = "skill_mastery"
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    child_id: Mapped[str] = mapped_column(String(36), ForeignKey("child_profiles.id"))
    skill_key: Mapped[str] = mapped_column(String(50))  # e.g., "math.addition.2digit"
    current_difficulty: Mapped[int] = mapped_column(Integer, default=1)  # 1-5
    mastery_score: Mapped[float] = mapped_column(Float, default=0.0)   # 0.0-1.0
    correct_streak: Mapped[int] = mapped_column(Integer, default=0)
    review_due_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    last_played_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    total_attempts: Mapped[int] = mapped_column(Integer, default=0)
    total_correct: Mapped[int] = mapped_column(Integer, default=0)


class AdaptiveState(Base):
    __tablename__ = "adaptive_state"
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    child_id: Mapped[str] = mapped_column(String(36), ForeignKey("child_profiles.id"))
    subject_id: Mapped[str] = mapped_column(String(36))
    recent_difficulty: Mapped[int] = mapped_column(Integer, default=2)
    confidence: Mapped[float] = mapped_column(Float, default=0.5)  # 0-1
    last_updated: Mapped[datetime] = mapped_column(DateTime)
```

### 5.2 Algorithm

```
adjust_difficulty(mastery_record):
  attempts = mastery_record.total_attempts
  correct = mastery_record.total_correct
  hints = mastery_record.hint_count
  correct_rate = correct / max(attempts, 1)
  difficulty = mastery_record.current_difficulty

  if correct_rate >= 0.85 and attempts >= 3:
    difficulty = min(difficulty + 1, 5)
  elif correct_rate <= 0.5 and attempts >= 2:
    difficulty = max(difficulty - 1, 1)  # silent

  mastery_record.current_difficulty = difficulty
  update_review_due(mastery_record)  # spaced repetition
  return difficulty
```

### 5.3 Principles

- **No negative messaging** — child never sees "you went down a level"
- **Confidence-weighted** — slow, correct > fast, correct
- **Spaced repetition** — `review_due_at` uses exponential backoff
- **Hint penalty** — hints reduce mastery evidence but don't fail the child
- **No speed ranking** — duration tracked but not compared across children

---

## 6. Offline Sync Architecture

### 6.1 Sync Queue Item

```dart
class SyncQueueItem {
  final String id;               // UUID
  final String childProfileId;
  final String type;             // "attempt" | "progress" | "snapshot"
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;
}
```

### 6.2 Sync Flow

```
ONLINE:
1. BackgroundSyncService checks connectivity
2. Drain sync_queue in order (oldest first)
3. For each item:
   a. POST to appropriate /sync/* endpoint
   b. If 
