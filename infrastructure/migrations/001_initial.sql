-- MI Academy — Initial schema migration
-- SUPERSEDED: kept only as historical reference. The source of truth for
-- schema migrations is now Alembic (apps/api/alembic/versions/), which is
-- generated from and stays in sync with apps/api/models. Do not run this
-- file against a new database — use `alembic upgrade head` instead
-- (see docs/infrastructure/ENVIRONMENT_STRATEGY.md and the Makefile's
-- `make migrate` target).
-- Original usage: psql $DATABASE_URL -f infrastructure/migrations/001_initial.sql

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role VARCHAR(20) NOT NULL,
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Parent profiles
CREATE TABLE IF NOT EXISTS parent_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    display_name VARCHAR(100) NOT NULL,
    language VARCHAR(10) DEFAULT 'vi',
    timezone VARCHAR(50) DEFAULT 'Asia/Ho_Chi_Minh',
    pin_hash VARCHAR(255)
);

-- Child profiles
CREATE TABLE IF NOT EXISTS child_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID NOT NULL REFERENCES parent_profiles(id) ON DELETE CASCADE,
    nickname VARCHAR(50) NOT NULL,
    birth_year INT,
    age_group VARCHAR(20) NOT NULL,
    grade_level VARCHAR(50),
    avatar_id VARCHAR(50) DEFAULT 'avatar_01',
    preferred_language VARCHAR(10) DEFAULT 'vi',
    daily_time_limit INT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Subjects
CREATE TABLE IF NOT EXISTS subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    icon VARCHAR(100),
    order_index INT DEFAULT 0
);

-- Lessons
CREATE TABLE IF NOT EXISTS lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_id UUID NOT NULL REFERENCES subjects(id),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    age_group VARCHAR(20) NOT NULL,
    difficulty INT DEFAULT 1,
    language VARCHAR(10) DEFAULT 'vi',
    estimated_minutes INT DEFAULT 5,
    content_json JSONB,
    is_active BOOLEAN DEFAULT TRUE
);

-- Games
CREATE TABLE IF NOT EXISTS games (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    game_type VARCHAR(50) NOT NULL,
    age_min INT DEFAULT 5,
    age_max INT DEFAULT 12,
    config_json JSONB,
    is_active BOOLEAN DEFAULT TRUE
);

-- Questions
CREATE TABLE IF NOT EXISTS questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    question_type VARCHAR(50) NOT NULL,
    prompt TEXT NOT NULL,
    options_json JSONB,
    correct_answer_json JSONB,
    explanation TEXT,
    media_url VARCHAR(500),
    difficulty INT DEFAULT 1
);

-- Attempts
CREATE TABLE IF NOT EXISTS attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL REFERENCES child_profiles(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    question_id UUID REFERENCES questions(id) ON DELETE CASCADE,
    answer_json JSONB,
    is_correct BOOLEAN DEFAULT FALSE,
    response_time_ms INT DEFAULT 0,
    hint_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_attempts_child_created ON attempts(child_id, created_at);

-- Progress
CREATE TABLE IF NOT EXISTS progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL REFERENCES child_profiles(id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    status VARCHAR(30) DEFAULT 'not_started',
    mastery_score FLOAT DEFAULT 0.0,
    total_attempts INT DEFAULT 0,
    last_played_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_progress_child ON progress(child_id);

-- Rewards
CREATE TABLE IF NOT EXISTS rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reward_type VARCHAR(30) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    asset_url VARCHAR(500),
    unlock_requirement_json JSONB
);

-- Child rewards
CREATE TABLE IF NOT EXISTS child_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL REFERENCES child_profiles(id) ON DELETE CASCADE,
    reward_id UUID NOT NULL REFERENCES rewards(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMPTZ DEFAULT now()
);

-- Daily sessions
CREATE TABLE IF NOT EXISTS daily_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL REFERENCES child_profiles(id) ON DELETE CASCADE,
    session_date DATE NOT NULL,
    duration_seconds INT DEFAULT 0,
    lessons_completed INT DEFAULT 0,
    games_completed INT DEFAULT 0,
    UNIQUE(child_id, session_date)
);

-- Content versions
CREATE TABLE IF NOT EXISTS content_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_type VARCHAR(30) NOT NULL,
    version BIGINT DEFAULT 1,
    checksum VARCHAR(64),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Seed data: Subjects
INSERT INTO subjects (id, name, code, icon, order_index) VALUES
    (gen_random_uuid(), 'Thành phố chữ cái', 'letters', '📝', 1),
    (gen_random_uuid(), 'Vương quốc toán học', 'math', '🔢', 2),
    (gen_random_uuid(), 'Đảo tư duy', 'logic', '🧠', 3),
    (gen_random_uuid(), 'Phòng thí nghiệm', 'science', '🔬', 4),
    (gen_random_uuid(), 'Ngôi nhà sáng tạo', 'creative', '🎨', 5);

-- Seed data: Games
INSERT INTO games (id, name, game_type, age_min, age_max, config_json, is_active) VALUES
    (gen_random_uuid(), 'Ghép chữ tạo từ', 'word_builder', 5, 10, '{"max_level": 8}', true),
    (gen_random_uuid(), 'Nghe âm tìm chữ', 'sound_match', 5, 10, '{"max_level": 8}', true),
    (gen_random_uuid(), 'Đường đua cộng trừ', 'math_race', 5, 12, '{"questions_per_race": 10}', true),
    (gen_random_uuid(), 'Siêu thị toán học', 'math_supermarket', 8, 12, '{"currency": "VND"}', true),
    (gen_random_uuid(), 'Ghi nhớ vị trí', 'memory_cards', 5, 12, '{"grid_sizes": ["2x2","2x3","2x4","3x4","4x4"]}', true),
    (gen_random_uuid(), 'Robot làm theo lệnh', 'robot_commands', 8, 12, '{"max_grid_size": 8}', true);

-- Seed data: Rewards (MVP badges)
INSERT INTO rewards (id, reward_type, name, description, unlock_requirement_json) VALUES
    (gen_random_uuid(), 'badge', 'Sao đầu tiên', 'Hoàn thành bài học đầu tiên', '{"type": "lessons_completed", "count": 1}'),
    (gen_random_uuid(), 'badge', 'Học trò siêng năng', 'Hoàn thành 5 bài học', '{"type": "lessons_completed", "count": 5}'),
    (gen_random_uuid(), 'badge', 'Bộ não nhạy bén', 'Hoàn thành 10 bài học', '{"type": "lessons_completed", "count": 10}'),
    (gen_random_uuid(), 'badge', 'Chuyên gia chữ cái', 'Hoàn thành tất cả bài chữ cái', '{"type": "subject_complete", "subject": "letters"}'),
    (gen_random_uuid(), 'badge', 'Phù thủy toán', 'Hoàn thành tất cả bài toán', '{"type": "subject_complete", "subject": "math"}'),
    (gen_random_uuid(), 'badge', 'Thần đồng tư duy', 'Hoàn thành tất cả bài tư duy', '{"type": "subject_complete", "subject": "logic"}'),
    (gen_random_uuid(), 'badge', 'Nhà vô địch tuần', 'Hoàn thành 7 ngày liên tiếp', '{"type": "consecutive_days", "count": 7}'),
    (gen_random_uuid(), 'badge', 'Hoàn thành thử thách', 'Hoàn thành thử thách tư duy 5 lần', '{"type": "game_complete", "count": 5}'),
    (gen_random_uuid(), 'badge', 'Khám phá gia', 'Chơi ít nhất 1 game ở mỗi khu vực', '{"type": "all_games_tried", "count": 1}'),
    (gen_random_uuid(), 'star', '⭐ Sao MI', 'Sao thưởng cho bài học', '{"type": "auto"}');
