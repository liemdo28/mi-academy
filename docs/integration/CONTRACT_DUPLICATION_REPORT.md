# MI Academy — Contract Duplication Report

**Date:** 2026-07-17  
**Owner:** Dev 7  
**Status:** Wave 0 — Audit

---

## 1. Summary

Found **12 distinct model duplication clusters** across Dart and Python. Each cluster represents a concept modeled independently in multiple places with inconsistent field naming, types, and serialization. This is the primary integration risk.

---

## 2. Duplication Clusters

### Cluster 1: Child Profile
| Location | Class/File | Fields |
|----------|-----------|--------|
| **Dart** | `ChildProfile` (shared_models.dart:68-112) | id, parentId, nickname, birthYear, ageGroup (enum), gradeLevel, avatarId, preferredLanguage, dailyTimeLimitMinutes, createdAt |
| **Python** | `ChildResponse` (schemas/child.py) | id |
| **Python** | `CreateChildRequest` (schemas/child.py) | nickname |
| **Python** | `UpdateChildRequest` (schemas/child.py) | nickname |
| **Python** | ORM `Child` (models.py) | id, parent_id, nickname, age_group, language, avatar_id, daily_time_limit_minutes, created_at, birth_year, grade_level |

**Risk:** HIGH — field naming (camelCase vs snake_case), missing fields in API schemas, enum representation differs.

**Resolution:** OpenAPI spec + generated Dart/Python clients. Source of truth: `contracts/child_profile.yaml`.

---

### Cluster 2: Parent Profile
| Location | Class/File | Fields |
|----------|-----------|--------|
| **Dart** | `ParentProfile` (shared_models.dart:23-36) | id, displayName, language, timezone, hasPin |
| **Python** | `ParentProfileResponse` (schemas/__init__.py) | id, display_name, language, timezone, has_pin, created_at, children |
| **Python** | ORM `ParentProfile` (models.py) | id, user_id, display_name, timezone, language, has_pin, created_at |
| **Python** | `ParentProfileUpdate` (schemas/__init__.py) | display_name |

**Risk:** MEDIUM — naming convention, extra `created_at` in API response, `children` nested array not in Dart.

**Resolution:** Source of truth: `contracts/parent_profile.yaml`. Generated clients handle naming.

---

### Cluster 3: Game Result
| Location | Class/File | Fields |
|----------|-----------|--------|
| **Dart** | `MiGameResult` (shared_models.dart:428-503) | schemaVersion, attemptId, childProfileId, gameId, levelId, startedAt, completedAt, attemptCount, correctCount, incorrectCount, hintCount, durationSeconds, completed, masteryEvidence, skillEvidence, metadata |
| **Python** | `SaveGameResultRequest` (schemas/progress.py) | **EMPTY** — only has comment |
| **Python** | `GameCompleteRequest` (schemas/__init__.py) | child_id, total_stars, badges_unlocked, rewards_unlocked |
| **Python** | `GameAttemptRequest` (schemas/__init__.py) | child_id, answer_json, response_time_ms, hint_count |
| **Python** | ORM `Attempt` (models.py) | id, child_id, game_id, lesson_id, question_id, answer_json, is_correct, response_time_ms, hint_count, created_at |

**Risk:** CRITICAL — `SaveGameResultRequest` is empty. `MiGameResult` has no corresponding Python Pydantic model. Games cannot send results to the platform via the API.

**Resolution:** `SaveGameResultRequest` must be implemented as a full Pydantic model matching `MiGameResult`. Source of truth: `contracts/game_result.yaml`.

---

### Cluster 4: Game Launch
| Location | Class/File | Fields |
|----------|-----------|--------|
| **Dart** | `MiGameLaunchRequest` (shared_models.dart:369-424) | schemaVersion, childProfileId, gameId, levelId, language, ageGroup, accessibility, audioPreferences, levelContent, restoredState |
| **Python** | `GameStartRequest` (schemas/__init__.py) | child_id |
| **Python** | `GameDetail` (schemas/__init__.py) | id, name, game_type, age_min, age_max, config_json, is_active |

**Risk:** HIGH — `GameStartRequest` is missing all game-launch fields. The API has no endpoint to launch a game with full content. The `/api/v1/games/{game_id}/start` endpoint only accepts `child_id`.

**Resolution:** Create `GameLaunchRequest` Pydantic model. Update endpoint. Source of truth: `contracts/game_launch.yaml`.

---

### Cluster 5: Game Snapshot
| Location | Class/File | Fields |
|----------|-----------|--------|
| **Dart** | `MiGameSnapshot` (shared_models.dart:507-542) | schemaVersion, gameId, levelId, childProfileId, savedAt, state |
| **Python** | None | — |

**Risk:** HIGH — No backend support for game snapshots. No API endpoint to save/load snapshots. No persistence.

**Resolution:** Create snapshot API. Source of truth: `contracts/game_snapshot.yaml`.

---

### Cluster 6: Accessibility Preferences
| Location | Class/File | Fields |
|----------|-----------|--------|
| **Dart** | `AccessibilityPreferences` (shared_models.dart:309-340) | highContrast, largeText, reduceMotion, screenReader, fontSize |
| **Dart** | `AccessibilitySettings` (shared_models.dart:272-286) | highContrast, largeText, reduceMotion, screenReader, fontSize |
| **Python** | `AccessibilityPreferencesSchema` (schemas/progress.py) | high_contrast |

**Risk:** MEDIUM — TWO Dart classes for the same concept. Python schema only has one field. `largeText` missing in Python.

**Resolution:** Consolidate Dart `AccessibilitySettings` and `AccessibilityPreferences` into one class. Extend Python schema. Source of truth: `contracts/accessibility_preferences.yaml`.

---

### Cluster 7: Audio Preferences
| Location | Class/File | Fields |
|----------|-----------|--------|
| **Dart** | `AudioPreferences` (shared_models.dart:342-365) | musicVolume, sfxVolume, speechEnabled |
| **Dart** | `AudioSettings` (shared_models.dart:288-298) | musicVolume, sfxVolume, speechEnabled |
| **Python** | `AudioPreferencesSchema` (schemas/progress.py) | music_volume, sfx_volume, speech_enabled |

**Risk:** MEDIUM — Same duplication as Cluster 6. Two Dart classes, one partial Python class.

**Resolution:** Same as Cluster 6.

---

### Cluster 8: Progress / Mastery
| Location | Class/File | Fields |
|----------|-----------|--------|
| **Dart** | `LessonProgress` (shared_models.dart:198-214) | id, lessonId, status (LessonStatus enum), masteryScore, totalAttempts, lastPlayedAt |
| **Dart** | `LessonStatus` enum (shared_models.dart:162-196) | notStarted, learning, completed, needsPractice, mastered |
| **Python** | `ProgressResponse` (schemas/progress.py) | id, lesson_id, status, mastery_score, total_attempts, last_played_at |
| **Python** | `SyncProgressItem` (schemas/sync.py) | id, child_id, lesson_id, status, mastery_score, total_attempts, last_played_at |
| **Python** | ORM `Progress` (models.py) | id, child_id, lesson_id, status, mastery_score, total_attempts, last_played_at |

**Risk:** MEDIUM — Enum values differ: Dart uses `notStarted`, Python uses `not_started`. Naming convention differs.

**Resolution:** Enum adapter + OpenAPI spec. Source of truth: `contracts/progress.yaml`.

---

### Cluster 9: Lesson
| Location | Class/File | Fields |
|----------|-----------|--------|
| **Dart** | `Lesson` (shared_models.dart:134-158) | id, subjectId, title, description, ageGroup, difficulty, language, estimatedMinutes, contentJson, isActive |
| **Dart** | `Subject` (shared_models.dart:116-130) | id, name, code, icon, orderIndex |
| **Python** | `LessonResponse` (schemas/lesson.py) | id, title |
| **Python** | `LessonListResponse` (schemas/lesson.py) | items |
| **Python** | `DailyPlanItem` (schemas/progress.py) | lesson_id, title, subject, estimated_minutes, type, is_required |
| **Python** | ORM `Lesson` (models.py) | id, title, subject_id, age_group, difficulty, estimated_minutes, content_json, is_active, language |

**Risk:** MEDIUM — `LessonResponse` in Python is severely incomplete (only id + title). `DailyPlanItem` is a different shape.

**Resolution:** Extend `LessonResponse` and `DailyPlanItem`. Source of truth: `content/schemas/lesson.schema.json` → OpenAPI.

---

### Cluster 10: Skill / Mastery Evidence
| Location | Class/File | Fields |
|----------|-----------|--------|
| **Dart** | `MiGameResult.skillEvidence` | `Map<String, dynamic>` (arbitrary) |
| **Dart** | `SkillMastery` (mi_game_progress) | skillId, attempts, correctCount, accuracy, masteryLevel |
| **Dart** | `MasteryState` (mastery_core) | skillStates, sessionStats, overallMastery, nextReviewAt |
| **Python** | `SkillReport` (schemas/progress.py) | subject_id, skill_name, correct_count, total_attempts, accuracy_pct, strength |
| **Python** | ORM (models.py) | subject_id via Lesson join |

**Risk:** MEDIUM — `skillEvidence` in `MiGameResult` is a free-form `Map`. No schema. `SkillReport` uses `subject_id` not `skill_id`. No shared skill taxonomy.

**Resolution:** Define skill evidence schema. Source of truth: `contracts/skill_evidence.yaml`.

---

### Cluster 11: Authentication
| Location | Class/File | Fields |
|----------|-----------|--------|
| **Dart** | `AuthTokens` (shared_models.dart:12-19) | accessToken, refreshToken |
| **Python** | `TokenResponse` (schemas/__init__.py) | access_token, refresh_token, token_type |
| **Python** | `AuthResponse` (schemas/__init__.py) | user, parent_profile, access_token, refresh_token |

**Risk:** LOW — naming convention difference, `token_type` extra field in Python.

**Resolution:** OpenAPI spec handles this. Source of truth: `contracts/auth.yaml`.

---

### Cluster 12: Reward / Daily Session
| Location | Class/File | Fields |
|----------|-----------|--------|
| **Dart** | `Reward`, `ChildReward` (shared_models.dart:220-248) | id, type, name, description, assetUrl / id, rewardId, reward, unlockedAt |
| **Dart** | `DailySession` (shared_models.dart:252-268) | id, childId, sessionDate, durationSeconds, lessonsCompleted, gamesCompleted |
| **Python** | `RewardResponse`, `ChildRewardResponse` (schemas/reward.py) | id, name, type, description, asset_url |
| **Python** | `SyncSessionItem` (schemas/sync.py) | id, child_id, session_date, duration_seconds, lessons_completed, games_completed |
| **Python** | ORM `DailySession` (models.py) | id, child_id, session_date, duration_seconds, lessons_completed, games_completed |
| **Python** | `GameCompleteRequest` (schemas/__init__.py) | badges_unlocked, rewards_unlocked |

**Risk:** LOW-MEDIUM — `Reward`