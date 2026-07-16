# -*- coding: utf-8 -*-
import json
from pathlib import Path

Q = chr(39)
NL = chr(10)
lines = []
def L(t):
    lines.append(t)

tables = [
    ("users", [
        ("id", "UUID PRIMARY KEY DEFAULT gen_random_uuid()"),
        ("role", "VARCHAR(20) NOT NULL DEFAULT "+Q+"parent"+Q),
        ("email", "VARCHAR(255) NOT NULL UNIQUE"),
        ("password_hash", "VARCHAR(255) NOT NULL"),
        ("created_at", "TIMESTAMPTZ NOT NULL DEFAULT now()"),
        ("updated_at", "TIMESTAMPTZ NOT NULL DEFAULT now()"),
    ], ["users(email)", "users(role)"]),
    ("parent_profiles", [
        ("id", "UUID PRIMARY KEY DEFAULT gen_random_uuid()"),
        ("user_id", "UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE"),
        ("display_name", "VARCHAR(100) NOT NULL"),
        ("language", "VARCHAR(10) NOT NULL DEFAULT "+Q+"vi"+Q),
        ("timezone", "VARCHAR(50) NOT NULL DEFAULT "+Q+"Asia/Ho_Chi_Minh"+Q),
        ("pin_hash", "VARCHAR(255)"),
    ], ["parent_profiles(user_id)"]),
    ("child_profiles", [
        ("id", "UUID PRIMARY KEY DEFAULT gen_random_uuid()"),
        ("parent_id", "UUID NOT NULL REFERENCES parent_profiles(id) ON DELETE CASCADE"),
        ("nickname", "VARCHAR(50) NOT NULL"),
        ("birth_year", "INT"),
        ("age_group", "VARCHAR(20) NOT NULL"),
        ("grade_level", "VARCHAR(20)"),
        ("avatar_id", "VARCHAR(50) NOT NULL DEFAULT "+Q+"avatar_01"+Q),
        ("preferred_language", "VARCHAR(10) NOT NULL DEFAULT "+Q+"vi"+Q),
        ("daily_time_limit", "INT DEFAULT 60"),
        ("created_at", "TIMESTAMPTZ NOT NULL DEFAULT now()"),
    ], ["child_profiles(parent_id)", "child_profiles(age_group)"]),
    ("subjects", [
        ("id", "UUID PRIMARY KEY DEFAULT gen_random_uuid()"),
        ("name", "VARCHAR(100) NOT NULL"),
        ("code", "VARCHAR(50) NOT NULL UNIQUE"),
        ("icon", "VARCHAR(20)"),
        ("order_index", "INT NOT NULL DEFAULT 0"),
    ], ["subjects(code)"]),
    ("lessons", [
        ("id", "UUID PRIMARY KEY DEFAULT gen_random_uuid()"),
        ("subject_id", "UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE"),
        ("title", "VARCHAR(200) NOT NULL"),
        ("description", "TEXT"),
        ("age_group", "VARCHAR(20) NOT NULL"),
        ("difficulty", "INT NOT NULL DEFAULT 1"),
        ("language", "VARCHAR(10) NOT NULL DEFAULT "+Q+"vi"+Q),
        ("estimated_minutes", "INT NOT NULL DEFAULT 5"),
        ("content_json", "JSONB"),
        ("is_active", "BOOLEAN NOT NULL DEFAULT true"),
    ], ["lessons(subject_id)", "lessons(age_group)", "lessons(is_active)"]),
    ("games", [
        ("id", "UUID PRIMARY KEY DEFAULT gen_random_uuid()"),
        ("name", "VARCHAR(100) NOT NULL"),
        ("game_type", "VARCHAR(50) NOT NULL"),
        ("age_min", "INT NOT NULL DEFAULT 5"),
        ("age_max", "INT NOT NULL DEFAULT 12"),
        ("config_json", "JSONB"),
        ("is_active", "BOOLEAN NOT NULL DEFAULT true"),
    ], ["games(game_type)"]),
    ("questions", [
        ("id", "UUID PRIMARY KEY DEFAULT gen_random_uuid()"),
        ("lesson_id", "UUID REFERENCES lessons(id) ON DELETE SET NULL"),
        ("question_type", "VARCHAR(30) NOT NULL"),
        ("prompt", "TEXT NOT NULL"),
        ("options_json", "JSONB"),
        ("correct_answer_json", "JSONB NOT NULL"),
        ("explanation", "TEXT"),
        ("media_url", "VARCHAR(500)"),
        ("difficulty", "INT NOT NULL DEFAULT 1"),
    ], ["questions(lesson_id)", "questions(question_type)", "questions(difficulty)"]),
    ("attempts", [
        ("id", "UUID PRIMARY KEY DEFAULT gen_random_uuid()"),
        ("child_id", "UUID NOT NULL REFERENCES child_profiles(id) ON DELETE CASCADE"),
        ("lesson_id", "UUID REFERENCES lessons(id) ON DELETE SET NULL"),
        ("game_id", "UUID REFERENCES games(id) ON DELETE SET NULL"),
        ("question_id", "UUID REFERENCES questions(id) ON DELETE SET NULL"),
        ("answer_json", "JSONB"),
        ("is_correct", "BOOLEAN"),
        ("response_time_ms", "INT"),
        ("hint_count", "INT NOT NULL DEFAULT 0"),
        ("created_at", "TIMESTAMPTZ NOT NULL DEFAULT now()"),
    ], ["attempts(child_id)", "attempts(lesson_id)", "attempts(created_at)"]),
    ("progress", [
        ("id", "UUID PRIMARY KEY DEFAULT gen_random_uuid()"),
        ("child_id", "UUID NOT NULL REFERENCES child_profiles(id) ON DELETE CASCADE"),
        ("lesson_id", "UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE"),
        ("status", "VARCHAR(20) NOT NULL DEFAULT "+Q+"not_started"+Q),
        ("mastery_score", "FLOAT NOT NULL DEFAULT 0.0"),
        ("total_attempts", "INT NOT NULL DEFAULT 0"),
        ("last_played_at", "TIMESTAMPTZ"),
    ], ["progress(child_id)", "progress(lesson_id)", "progress(status)"], "UNIQUE(child_id, lesson_id)"),
    ("rewards", [
        ("id", "UUID PRIMARY KEY DEFAULT gen_random_uuid()"),
        ("reward_type", "VARCHAR(30) NOT NULL"),
        ("name", "VARCHAR(100) NOT NULL"),
        ("description", "TEXT"),
        ("asset_url", "VARCHAR(500)"),
        ("unlock_requirement_json", "JSONB"),
    ], ["rewards(reward_type)"]),
    ("child_rewards", [
        ("id", "UUID PRIMARY KEY DEFAULT gen_random_uuid()"),
        ("child_id", "UUID NOT NULL REFERENCES child_profiles(id) ON DELETE CASCADE"),
        ("reward_id", "UUID NOT NULL REFERENCES rewards(id) ON DELETE CASCADE"),
        ("unlocked_at", "TIMESTAMPTZ NOT NULL DEFAULT now()"),
    ], ["child_rewards(child_id)", "child_rewards(reward_id)"]),
    ("daily_sessions", [
        ("id", "UUID PRIMARY KEY DEFAULT gen_random_uuid()"),
        ("child_id", "UUID NOT NULL REFERENCES child_profiles(id) ON DELETE CASCADE"),
        ("session_date", "DATE NOT NULL"),
        ("duration_seconds", "INT NOT NULL DEFAULT 0"),
        ("lessons_completed", "INT NOT NULL DEFAULT 0"),
        ("games_completed", "INT NOT NULL DEFAULT 0"),
    ], ["daily_sessions(child_id)", "daily_sessions(session_date)"]),
    ("content_versions", [
        ("id", "UUID PRIMARY KEY DEFAULT gen_random_uuid()"),
        ("content_type", "VARCHAR(50) NOT NULL"),
        ("version", "BIGINT NOT NULL DEFAULT 1"),
        ("checksum", "VARCHAR(128)"),
        ("created_at", "TIMESTAMPTZ NOT NULL DEFAULT now()"),
    ], ["content_versions(content_type)"]),
]

L("-- MI Academy: Initial schema migration")
L("-- Auto-generated - 13 tables + indexes + seed data")
L("")
L("CREATE EXTENSION IF NOT EXISTS "pgcrypto";")
L("")

for entry in tables:
    tname = entry[0]
    cols = entry[1]
    idxs = entry[2]
    constraint = entry[3] if len(entry) > 3 else None
    L("-- ==================== " + tname + " ====================")
    L("CREATE TABLE " + tname + " (")
    for i, (cn, ct) in enumerate(cols):
        comma = "," if i < len(cols)-1 else ""
        L("    " + cn + " " + ct + comma)
    if constraint:
        L("," + constraint)
    L(");")
    L("")
    for idx in idxs:
        L("CREATE INDEX idx_" + idx.replace("(","_").replace(")","").replace(" ","_") + " ON " + idx + ";")
        L("")

# Seed subjects
subjects_seed = [
    ("letters", "Th\u00e0nh ph\u1ed1 ch\u1eef c\u00e1i", "\U0001f4dd", 1),
    ("math", "V\u01b0\u1ee1ng qu\u1ed1c to\u00e1n h\u1ecdc", "\U0001f522", 2),
    ("logic", "\u0110\u1ea3o t\u01b0 duy", "\U0001f9e0", 3),
    ("science", "Ph\u00f2ng th\u00ed nghi\u1ec7m", "\U0001f52c", 4),
    ("creative", "Ng\u00f4i nh\u00e0 s\u00e1ng t\u1ea1o", "\U0001f3a8", 5),
]

L("")
L("-- SEED DATA: Subjects")
L("INSERT INTO subjects (id, name, code, icon, order_index) VALUES")
for i, (code, name, icon, idx) in enumerate(subjects_seed):
    comma = "," if i < len(subjects_seed)-1 else ";"
    L("    (gen_random_uuid(), " + Q + name + Q + ", " + Q + code + Q + ", " + Q + icon + Q + ", " + str(idx) + ")" + comma)

