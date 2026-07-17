"""Generate the complete MI Academy OpenAPI spec from source."""
import json
import textwrap

SPEC = {
    "openapi": "3.1.0",
    "info": {
        "title": "MI Academy API",
        "version": "1.0.0",
        "description": "MI Academy backend API — parent dashboard, child progress, games, and sync. "
                      "All contracts are versioned. Breaking changes increment the major version.",
        "contact": {"name": "MI Academy Platform Team"},
        "license": {"name": "Proprietary"},
    },
    "servers": [{"url": "/api/v1", "description": "Current production"}],
    "security": [{"BearerAuth": []}],
    "tags": [
        {"name": "auth", "description": "Authentication and token management"},
        {"name": "parent", "description": "Parent profile management"},
        {"name": "children", "description": "Child profile management"},
        {"name": "lessons", "description": "Lesson catalog and content"},
        {"name": "games", "description": "Game catalog and sessions"},
        {"name": "progress", "description": "Progress tracking and mastery"},
        {"name": "sync", "description": "Offline sync"},
        {"name": "rewards", "description": "Rewards and achievements"},
        {"name": "admin", "description": "Admin content management"},
    ],
    "components": {
        "securitySchemes": {
            "BearerAuth": {"type": "http", "scheme": "bearer", "bearerFormat": "JWT"}
        },
        "schemas": {
            "Error": {
                "type": "object", "required": ["error"],
                "properties": {
                    "error": {
                        "type": "object", "required": ["code", "message"],
                        "properties": {
                            "code": {"type": "string", "example": "CONTENT_VERSION_UNSUPPORTED"},
                            "message": {"type": "string", "example": "This content is not available right now."},
                            "requestId": {"type": "string"},
                            "retryable": {"type": "boolean", "default": False},
                            "details": {"type": "object", "additionalProperties": True},
                            "schemaVersion": {"type": "integer", "default": 1},
                        },
                    }
                },
            },
            "RegisterRequest": {
                "type": "object", "required": ["email", "password", "display_name"],
                "properties": {
                    "email": {"type": "string", "format": "email", "maxLength": 255},
                    "password": {"type": "string", "minLength": 8, "maxLength": 128},
                    "display_name": {"type": "string", "minLength": 1, "maxLength": 100},
                    "language": {"type": "string", "enum": ["vi", "en"], "default": "vi"},
                },
            },
            "LoginRequest": {
                "type": "object", "required": ["email", "password"],
                "properties": {
                    "email": {"type": "string", "format": "email"},
                    "password": {"type": "string"},
                },
            },
            "RefreshRequest": {
                "type": "object", "required": ["refresh_token"],
                "properties": {"refresh_token": {"type": "string"}},
            },
            "TokenResponse": {
                "type": "object", "required": ["access_token", "refresh_token", "token_type"],
                "properties": {
                    "access_token": {"type": "string"},
                    "refresh_token": {"type": "string"},
                    "token_type": {"type": "string", "enum": ["bearer"], "default": "bearer"},
                },
            },
            "AuthResponse": {
                "type": "object", "required": ["user", "access_token", "refresh_token"],
                "properties": {
                    "user": {"$ref": "#/components/schemas/UserResponse"},
                    "parent_profile": {"$ref": "#/components/schemas/ParentProfileResponse"},
                    "access_token": {"type": "string"},
                    "refresh_token": {"type": "string"},
                },
            },
            "UserResponse": {
                "type": "object", "required": ["id", "role", "email", "created_at"],
                "properties": {
                    "id": {"type": "string", "format": "uuid"},
                    "role": {"type": "string", "enum": ["parent", "admin"]},
                    "email": {"type": "string", "format": "email"},
                    "created_at": {"type": "string", "format": "date-time"},
                },
            },
            "ParentProfileResponse": {
                "type": "object", "required": ["id", "display_name", "language", "timezone", "has_pin", "created_at"],
                "properties": {
                    "id": {"type": "string", "format": "uuid"},
                    "display_name": {"type": "string"},
                    "language": {"type": "string", "enum": ["vi", "en"]},
                    "timezone": {"type": "string"},
                    "has_pin": {"type": "boolean"},
                    "created_at": {"type": "string", "format": "date-time"},
                    "children": {"type": "array", "items": {"$ref": "#/components/schemas/ChildResponse"}},
                },
            },
            "ParentProfileUpdate": {
                "type": "object",
                "properties": {"display_name": {"type": "string", "minLength": 1, "maxLength": 100}},
            },
            "SetPinRequest": {
                "type": "object", "required": ["pin"],
                "properties": {"pin": {"type": "string", "pattern": "^[0-9]{4,6}$"}},
            },
            "VerifyPinRequest": {
                "type": "object", "required": ["pin"],
                "properties": {"pin": {"type": "string", "pattern": "^[0-9]{4,6}$"}},
            },
            "VerifyPinResponse": {
                "type": "object", "required": ["verified"],
                "properties": {"verified": {"type": "boolean"}},
            },
            "ChildResponse": {
                "type": "object", "required": ["id", "nickname", "age_group", "preferred_language", "created_at"],
                "properties": {
                    "id": {"type": "string", "format": "uuid"},
                    "nickname": {"type": "string", "maxLength": 50},
                    "birth_year": {"type": "integer"},
                    "age_group": {"$ref": "#/components/schemas/AgeGroup"},
                    "grade_level": {"type": "string"},
                    "avatar_id": {"type": "string"},
                    "preferred_language": {"type": "string", "enum": ["vi", "en"]},
                    "daily_time_limit_minutes": {"type": "integer"},
                    "created_at": {"type": "string", "format": "date-time"},
                },
            },
            "CreateChildRequest": {
                "type": "object", "required": ["nickname", "age_group", "preferred_language"],
                "properties": {
                    "nickname": {"type": "string", "minLength": 1, "maxLength": 50},
                    "birth_year": {"type": "integer"},
                    "age_group": {"$ref": "#/components/schemas/AgeGroup"},
                    "grade_level": {"type": "string"},
                    "avatar_id": {"type": "string", "default": "avatar_default"},
                    "preferred_language": {"type": "string", "enum": ["vi", "en"], "default": "vi"},
                    "daily_time_limit_minutes": {"type": "integer"},
                },
            },
            "UpdateChildRequest": {
                "type": "object",
                "properties": {
                    "nickname": {"type": "string", "minLength": 1, "maxLength": 50},
                    "avatar_id": {"type": "string"},
                    "preferred_language": {"type": "string", "enum": ["vi", "en"]},
                    "daily_time_limit_minutes": {"type": "integer"},
                },
            },
            "AgeGroup": {"type": "string", "enum": ["junior", "explorer", "master"]},
            "AccessibilityPreferencesSchema": {
                "type": "object",
                "properties": {
                    "high_contrast": {"type": "boolean", "default": False},
                    "large_text": {"type": "boolean", "default": False},
                    "reduce_motion": {"type": "boolean", "default": False},
                    "screen_reader": {"type": "boolean", "default": False},
                    "font_size": {"type": "number", "minimum": 0.8, "maximum": 2.0, "default": 1.0},
                },
            },
            "AudioPreferencesSchema": {
                "type": "object",
                "properties": {
                    "music_volume": {"type": "number", "minimum": 0.0, "maximum": 1.0, "default": 0.8},
                    "sfx_volume": {"type": "number", "minimum": 0.0, "maximum": 1.0, "default": 1.0},
                    "speech_enabled": {"type": "boolean", "default": True},
                },
            },
            "LessonResponse": {
                "type": "object", "required": ["id", "title", "subject_id", "age_group", "difficulty", "estimated_minutes", "language", "is_active"],
                "properties": {
                    "id": {"type": "string", "format": "uuid"},
                    "title": {"type": "object", "additionalProperties": {"type": "string"}},
                    "description": {"type": "string"},
                    "subject_id": {"type": "string"},
                    "age_group": {"$ref": "#/components/schemas/AgeGroup"},
                    "difficulty": {"type": "integer", "minimum": 1, "maximum": 5},
                    "language": {"type": "string", "enum": ["vi", "en"]},
                    "estimated_minutes": {"type": "integer"},
                    "content_version": {"type": "integer", "default": 1},
                    "is_active": {"type": "boolean"},
                },
            },
            "LessonListResponse": {
                "type": "object", "required": ["items"],
                "properties": {
                    "items": {"type": "array", "items": {"$ref": "#/components/schemas/LessonResponse"}},
                    "total": {"type": "integer"},
                },
            },
            "GameLevelResponse": {
                "type": "object", "required": ["id"],
                "properties": {
                    "id": {"type": "string", "format": "uuid"},
                    "game_id": {"type": "string", "format": "uuid"},
                    "level_number": {"type": "integer", "minimum": 1},
                    "difficulty": {"type": "integer", "minimum": 1, "maximum": 5},
                },
            },
            "GameListItem": {
                "type": "object", "required": ["id", "name", "game_type", "is_active"],
                "properties": {
                    "id": {"type": "string", "format": "uuid"},
                    "name": {"type": "string"},
                    "game_type": {"type": "string", "enum": ["memory", "word_builder", "sound_match", "math_race", "math_supermarket", "robot_commands"]},
                    "age_min": {"type": "integer"},
                    "age_max": {"type": "integer"},
                    "is_active": {"type": "boolean"},
                },
            },
            "GameDetail": {
                "type": "object", "required": ["id", "name", "game_type", "is_active"],
                "properties": {
                    "id": {"type": "string", "format": "uuid"},
                    "name": {"type": "string"},
                    "game_type": {"type": "string", "enum": ["memory", "word_builder", "sound_match", "math_race", "math_supermarket", "robot_commands"]},
                    "age_min": {"type": "integer"},
                    "age_max": {"type": "integer"},
                    "config_json": {"type": "object", "additionalProperties": True},
                    "is_active": {"type": "boolean"},
                },
            },
            "GameStartRequest": {
                "type": "object", "required": ["child_id"],
                "properties": {"child_id": {"type": "string", "format": "uuid"}},
            },
            "GameAttemptRequest": {
                "type": "object", "required": ["child_id", "answer_json", "response_time_ms", "hint_count"],
                "properties": {
                    "child_id": {"type": "string", "format": "uuid"},
                    "answer_json": {"type": "object", "additionalProperties": True},
                    "response_time_ms": {"type": "integer"},
                    "hint_count": {"type": "integer", "minimum": 0},
                },
            },
            "GameCompleteRequest": {
                "type": "object", "required": ["child_id", "total_stars"],
                "properties": {
                    "child_id": {"type": "string", "format": "uuid"},
                    "total_stars": {"type": "integer", "minimum": 0, "maximum": 3},
                    "badges_unlocked": {"type": "array", "items": {"type": "string"}, "default": []},
                    "rewards_unlocked": {"type": "array", "items": {"type": "string"}, "default": []},
                },
            },
            "MiGameLaunchRequest": {
                "type": "object",
                "description": "Full game launch request from platform to game. NEVER contains tokens or PII.",
                "required": ["schema_version", "child_profile_id", "game_id", "level_id", "language", "age_group", "accessibility", "audio_preferences", "level_content"],
                "properties": {
                    "schema_version": {"type": "integer", "default": 1},
                    "child_profile_id": {"type": "string", "format": "uuid"},
                    "game_id": {"type": "string", "format": "uuid"},
                    "level_id": {"type": "string", "format": "uuid"},
                    "language": {"type": "string", "enum": ["vi", "en"]},
                    "age_group": {"$ref": "#/components/schemas/AgeGroup"},
                    "accessibility": {"$ref": "#/components/schemas/AccessibilityPreferencesSchema"},
                    "audio_preferences": {"$ref": "#/components/schemas/AudioPreferencesSchema"},
                    "level_content": {"type": "object", "additionalProperties": True},
                    "restored_state": {"type": "object", "additionalProperties": True},
                },
            },
            "MiGameResult": {
                "type": "object",
                "description": "Game result from game to platform. NEVER contains tokens or PII.",
                "required": ["schema_version", "attempt_id", "child_profile_id", "game_id", "level_id", "started_at", "completed_at", "attempt_count", "correct