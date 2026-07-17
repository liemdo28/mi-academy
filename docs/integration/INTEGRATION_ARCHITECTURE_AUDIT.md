# MI Academy — Integration Architecture Audit

**Date:** 2026-07-17  
**Owner:** Dev 7 (Integration, SDK & Automation Lead)  
**Status:** Wave 0 — Foundation Audit

---

## 1. Executive Summary

MI Academy is a Flutter (mobile) + FastAPI (backend) application with a modular Dart package structure. Games are Flutter-based. Content is JSON-defined. The system has a strong shared_models foundation but lacks systematic contract enforcement, generated API clients, mock parity, and unified tooling.

**Key Finding:** The shared_models package (542 lines, 15+ classes) is the de facto contract source of truth for the mobile/game layer, but the backend uses independent Pydantic models with different field names and structure. No OpenAPI spec exists. No JSON Schema registry. No shared fixtures. No generated code. These are the root causes of integration risk.

---

## 2. Repository Structure Inventory

### 2.1 Packages (Dart/Flutter)

| Package | Purpose | Has lib/ | Files |
|---------|---------|----------|-------|
| shared_models | Cross-app data models | ✅ | shared_models.dart, mi_progress_gateway.dart |
| mi_game_progress | Attempt/skill/mastery tracking | ✅ | 6 files |
| mi_game_core | Game contracts + lifecycle | ✅ | stub |
| mi_game_content | Content loading + validation | ✅ | 4 files |
| mi_game_accessibility | Accessibility helpers | ✅ | 5 files |
| mi_game_audio | Audio manager | ✅ | stub |
| learning_core | Lesson engine + phases | ✅ | 3 files |
| mastery_core | Mastery evaluation engine | ✅ | 5 files |
| progress_core | Progress storage | ✅ | stub |
| offline_sync | Sync service | ✅ | 5 files |
| recommendation_core | Recommendation engine | ✅ | stub |
| learning_analytics | Analytics SDK | ✅ | stub |
| localization | i18n (ARB files) | ✅ | ✅ |
| design_system | Theme + widgets | ✅ | ✅ |
| mi_game_ui | Game UI components | ✅ | stub |
| mi_game_testing | Test utilities | ✅ | stub |
| mi_blocks | Robot command blocks | ✅ | ✅ |
| spaced_repetition | Spaced repetition | ✅ | ✅ |
| ai_safety | AI safety | ✅ | ✅ |
| game_core | Game core (alias) | ✅ | stub |
| game-core | Game core (alias) | ✅ | stub |

### 2.2 Backend (Python/FastAPI)

| Path | Purpose |
|------|---------|
| apps/api/main.py | FastAPI app entry |
| apps/api/routes/ | API routes (auth, children, lessons, games, progress, rewards, sync, parent, admin) |
| apps/api/schemas/ | Pydantic request/response models |
| apps/api/models.py | SQLAlchemy ORM models |
| apps/api/dependencies.py | Auth dependencies |
| apps/admin/ | Admin interface |
| middleware/ | Auth middleware |
| routes/ | Legacy routes |

### 2.3 Content (JSON)

| Path | Purpose |
|------|---------|
| content/schemas/ | lesson.schema.json, question.schema.json |
| schemas/level.schema.json | Game level schema |
| content/manifests/ | Content package manifests |
| content/curriculum/ | Curriculum definitions |
| content/skills/ | Skill definitions |
| content/en/, content/vi/ | Localized content |

### 2.4 Assets

| Path | Purpose |
|------|---------|
| assets/manifests/ | Asset manifest files |
| assets/ASSET_LICENSE_MANIFEST.json | License manifest |
| apps/mobile/assets/ | Mobile asset files |

### 2.5 Docs

| Path | Count |
|------|-------|
| docs/ | 35+ markdown files |
| docs/integration/ | **Missing** — needs creation |
| docs/contracts/ | **Missing** — needs creation |
| docs/sdk/ | **Missing** — needs creation |
| docs/developer-tools/ | **Missing** — needs creation |
| docs/compatibility/ | **Missing** — needs creation |

---

## 3. Contract Inventory

### 3.1 Game Contracts (Dart — shared_models.dart, v1)

| Contract | File | Fields | Version |
|----------|------|--------|---------|
| MiGameLaunchRequest | shared_models.dart:369-424 | schemaVersion, childProfileId, gameId, levelId, language, ageGroup, accessibility, audioPreferences, levelContent, restoredState | 1 |
| MiGameResult | shared_models.dart:428-503 | schemaVersion, attemptId, childProfileId, gameId, levelId, startedAt, completedAt, attemptCount, correctCount, incorrectCount, hintCount, durationSeconds, completed, masteryEvidence, skillEvidence, metadata | 1 |
| MiGameSnapshot | shared_models.dart:507-542 | schemaVersion, gameId, levelId, childProfileId, savedAt, state | 1 |
| AccessibilityPreferences | shared_models.dart:309-340 | highContrast, largeText, reduceMotion, screenReader, fontSize | 1 |
| AudioPreferences | shared_models.dart:342-365 | musicVolume, sfxVolume, speechEnabled | 1 |
| MiProgressGateway | mi_progress_gateway.dart | saveGameResult, saveSnapshot, loadSnapshot | N/A (interface) |

### 3.2 Backend API Contracts (Python Pydantic)

| Contract | File | Key Fields | Gap vs Dart |
|----------|------|------------|-------------|
| RegisterRequest | schemas/__init__.py | email, password, display_name, language | Different naming (snake_case), extra fields |
| LoginRequest | schemas/__init__.py | email, password | Missing in Dart |
| TokenResponse | schemas/__init__.py | access_token, refresh_token, token_type | Partial in Dart AuthTokens |
| ParentProfileResponse | schemas/__init__.py | id, display_name, language, timezone, has_pin, created_at | Naming mismatch |
| ChildResponse | schemas/child.py | id | Partial in Dart ChildProfile |
| CreateChildRequest | schemas/child.py | nickname | Missing ageGroup, language in request |
| LessonResponse | schemas/lesson.py | id, title | Partial in Dart Lesson |
| GameListItem | schemas/__init__.py | id, name, game_type, age_min, age_max, is_active | Naming mismatch |
| GameDetail | schemas/__init__.py | id, name, game_type, age_min, age_max, config_json, is_active | Naming mismatch |
| GameStartRequest | schemas/__init__.py | child_id | Different from MiGameLaunchRequest |
| GameAttemptRequest | schemas/__init__.py | child_id, answer_json, response_time_ms, hint_count | Not in Dart shared_models |
| GameCompleteRequest | schemas/__init__.py | child_id, total_stars, badges_unlocked, rewards_unlocked | Different from MiGameResult |
| ProgressResponse | schemas/progress.py | id, lesson_id, status, mastery_score, total_attempts, last_played_at | Naming + enum mismatch |
| SkillReport | schemas/progress.py | subject_id, skill_name, correct_count, total_attempts, accuracy_pct, strength | Not in Dart shared_models |
| DailyPlanItem | schemas/progress.py | lesson_id, title, subject, estimated_minutes, type, is_required | Not in Dart shared_models |
| SyncProgressItem | schemas/sync.py | id, child_id, lesson_id, status, mastery_score, total_attempts, last_played_at | Naming mismatch |
| SyncAttemptItem | schemas/sync.py | id, child_id, lesson_id, game_id, question_id, answer_json, is_correct, response_time_ms, hint_count, created_at | Not in Dart |
| SyncSessionItem | schemas/sync.py | id, child_id, session_date, duration_seconds, lessons_completed, games_completed | Partial in Dart DailySession |
| SyncContentResponse | schemas/sync.py | content_type, version, items, deleted_ids | Not in Dart |
| SyncStatusResponse | schemas/sync.py | lessons_version, questions_version, games_version, server_time | Not in Dart |
| AccessibilityPreferencesSchema | schemas/progress.py | high_contrast | Partial vs Dart AccessibilityPreferences |
| AudioPreferencesSchema | schemas/progress.py | music_volume, sfx_volume, speech_enabled | Naming mismatch vs Dart AudioPreferences |
| ParentReportSummary | schemas/reports.py | total_children | Not in Dart |
| AttemptExportSummary | schemas/reports.py | child_id, total, correct, accuracy_pct | Not in Dart |
| SaveGameResultRequest | schemas/progress.py | **Comment**: "Platform receives MiGameResult from the game layer" — model is EMPTY | **CRITICAL GAP** |

### 3.3 Content Schemas (JSON)

| Schema | File | Key Fields | Status |
|--------|------|------------|--------|
| Lesson | content/schemas/lesson.schema.json | id, title, age_group, subject_id, difficulty, phases, skills, game_type, estimated_minutes | ✅ |
| Question | content/schemas/question.schema.json | id, prompt, question_type, options, correct_answer, explanation, media_url, skills, difficulty | ✅ |
| Level | schemas/level.schema.json | id, gameId, levelNumber, difficulty, localizedContent, learningObjective, hints, metadata, assetRefs, accessibilityOverrides | ✅ |

---

## 4. Model Duplication Analysis

### 4.1 Critical Duplications

| Domain | Dart Location | Backend Location | Status |
|--------|---------------|------------------|--------