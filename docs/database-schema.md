# MI Academy — Database Schema

> **Engine:** PostgreSQL 16+  
> **Backend:** FastAPI (Python 3.11+) — SQLAlchemy + Alembic  
> **Last updated:** 16/07/2026 — MVP v1.0  

---

## Sơ đồ quan hệ tổng quan

```
┌────────────────────┐         ┌────────────────────┐
│     parent         │ 1     n │      child         │
└────────────────────┘ ─────── └────────────────────┘
                                      │ 1
                                      │
                                      │ n
                                      ▼
┌────────────────────┐    ┌────────────────────┐    ┌────────────────────┐
│     game_session   │ n  │      game          │ 1  │     subject        │
└────────────────────┘ ─── └────────────────────┘ ─── └────────────────────┘

┌────────────────────┐
│  lesson_completion │ n─1 child
└────────────────────┘
┌────────────────────┐
│     star_earning   │ n─1 child
└────────────────────┘
┌────────────────────┐
│   badge_earning    │ n─1 child
└────────────────────┘
┌────────────────────┐
│     daily_task     │ n─1 child
└────────────────────┘
┌────────────────────┐
│    usage_time      │ n─1 child  (date bucket)
└────────────────────┘
```

---

## 1. Profile Module

### 1.1 `parent`

Tài khoản phụ huynh/người giám hộ. Một `parent` có thể có tới 5 `child`. PIN là 4 chữ số, hash bcrypt.

```sql
CREATE TABLE parent (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id         TEXT NOT NULL,           -- UUID thiết bị (không phải PII)
    pin_hash          TEXT NOT NULL,           -- bcrypt(12 rounds)
    recovery_answer   TEXT,                     -- hash đáp án phép tính
    language          CHAR(2) NOT NULL DEFAULT 'vi' CHECK (language IN ('vi','en')),
    daily_time_limit  SMALLINT NOT NULL DEFAULT 30 CHECK (daily_time_limit BETWEEN 15 AND 180),
    sound_enabled     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_parent_device ON parent(device_id);
```

### 1.2 `child`

```sql
CREATE TYPE age_group AS ENUM ('junior', 'explorer', 'master');

CREATE TABLE child (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id    UUID NOT NULL REFERENCES parent(id) ON DELETE CASCADE,
    name         VARCHAR(20) NOT NULL,
    avatar_id    SMALLINT NOT NULL CHECK (avatar_id BETWEEN 1 AND 8),
    age_group    age_group NOT NULL,
    birth_year   SMALLINT,                    -- optional, for age calculation
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- mỗi parent tối đa 5 child
    CONSTRAINT uniq_child_per_parent UNIQUE (parent_id, name)
);

CREATE INDEX idx_child_parent ON child(parent_id) WHERE is_active = TRUE;

-- Trigger chặn quá 5 child/parent
CREATE OR REPLACE FUNCTION enforce_child_limit()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM child WHERE parent_id = NEW.parent_id AND is_active) >= 5 THEN
        RAISE EXCEPTION 'Maximum 5 children per parent';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_child_limit
BEFORE INSERT ON child
FOR EACH ROW EXECUTE FUNCTION enforce_child_limit();
```

---

## 2. Content Module

### 2.1 `subject`

Nhóm chủ đề (Toán, Chữ, Logic, Khoa học, Sáng tạo).

```sql
CREATE TABLE subject (
    id          SMALLSERIAL PRIMARY KEY,
    code        VARCHAR(20) UNIQUE NOT NULL,    -- 'language','math','logic','science','creative'
    icon        TEXT NOT NULL,                  -- đường dẫn asset
    color_hex   CHAR(7) NOT NULL,
    sort_order  SMALLINT NOT NULL
);

INSERT INTO subject (code, icon, color_hex, sort_order) VALUES
  ('language', 'icons/alphabet.svg',  '#FF8C42', 1),
  ('math',     'icons/calculator.svg','#4ECDC4', 2),
  ('logic',    'icons/brain.svg',      '#A78BFA', 3),
  ('science',  'icons/flask.svg',      '#10B981', 4),
  ('creative', 'icons/palette.svg',    '#F472B6', 5);
```

### 2.2 `lesson`

```sql
CREATE TABLE lesson (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_id      SMALLINT NOT NULL REFERENCES subject(id),
    game_id         UUID REFERENCES game(id),      -- liên kết 1-1 với game (nếu có)
    age_group_min   age_group NOT NULL,
    age_group_max   age_group NOT NULL,
    sort_order      SMALLINT NOT NULL,
    duration_sec    SMALLINT NOT NULL CHECK (duration_sec BETWEEN 60 AND 600),
    thumbnail       TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    CONSTRAINT chk_age_range CHECK (age_group_min <= age_group_max)
);

CREATE INDEX idx_lesson_subject ON lesson(subject_id, sort_order);
CREATE INDEX idx_lesson_game ON lesson(game_id);
```

### 2.3 `lesson_i18n`

Tách các field đa ngôn ngữ: title, intro_text, summary, mi_speech.

```sql
CREATE TABLE lesson_i18n (
    lesson_id     UUID NOT NULL REFERENCES lesson(id) ON DELETE CASCADE,
    language      CHAR(2) NOT NULL,
    title         VARCHAR(120) NOT NULL,
    intro_text    TEXT NOT NULL,        -- cho mini-lesson intro screen
    summary       TEXT NOT NULL,        -- MI nói khi kết thúc
    audio_url     TEXT,                 -- optional file mp3 cho intro
    PRIMARY KEY (lesson_id, language)
);
```

### 2.4 `game`

```sql
CREATE TABLE game (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code          VARCHAR(30) UNIQUE NOT NULL,   -- 'word_builder','sound_match',...
    subject_id    SMALLINT NOT NULL REFERENCES subject(id),
    age_group_min age_group NOT NULL,
    age_group_max age_group NOT NULL,
    config_json   JSONB NOT NULL,                -- cấu hình game (max levels, ...)
    icon          TEXT NOT NULL,
    is_published  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO game (code, subject_id, age_group_min, age_group_max, icon, config_json, is_published) VALUES
  ('word_builder',  1, 'junior',   'explorer', 'icons/word.svg',    '{"max_levels":15,"letters_per_word_max":6}', TRUE),
  ('sound_match',   1, 'junior',   'master',   'icons/ear.svg',     '{"max_levels":12,"max_options":6}',            TRUE),
  ('math_race',     2, 'junior',   'master',   'icons/race.svg',    '{"max_levels":20,"tracks":[10,15,25]}',       TRUE),
  ('math_market',   2, 'explorer', 'master',   'icons/cart.svg',    '{"max_levels":12,"catalog_size":30}',          TRUE),
  ('memory_match',  3, 'junior',   'master',   'icons/cards.svg',   '{"max_grids":[[2,2],[3,2],[4,3],[4,4],[5,4]],"themes":["animals","fruits","shapes"]}', TRUE),
  ('robot_cmd',     3, 'explorer', 'master',   'icons/robot.svg',   '{"max_levels":20,"max_commands":[5,6,7,8,10,12]}', TRUE);
```

### 2.5 `game_level`

Mỗi game có nhiều level, mỗi level có data riêng.

```sql
CREATE TABLE game_level (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id       UUID NOT NULL REFERENCES game(id) ON DELETE CASCADE,
    level_index   SMALLINT NOT NULL,
    difficulty    SMALLINT NOT NULL CHECK (difficulty BETWEEN 1 AND 5),
    data_json     JSONB NOT NULL,
    PRIMARY KEY (game_id, level_index)
);

-- Ví dụ data_json cho 'word_builder' level 1:
-- {
--   "target_word": "MẸ",
--   "letters": ["M", "Ẹ", "B", "L"],
--   "hint": "Người nuôi em khôn lớn"
-- }
```

### 2.6 `question` (chung cho các game dạng hỏi-đáp)

```sql
CREATE TABLE question (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id     UUID NOT NULL REFERENCES game(id) ON DELETE CASCADE,
    level_index SMALLINT NOT NULL,
    prompt_i18n JSONB NOT NULL,    -- {"vi":"...","en":"..."}
    audio_url   TEXT,
    image_url   TEXT,
    correct_id  UUID,              -- FK tới question_option
    points      SMALLINT NOT NULL DEFAULT 1,
    FOREIGN KEY (game_id, level_index) REFERENCES game_level(game_id, level_index),
    FOREIGN KEY (correct_id) REFERENCES question_option(id)
);
```

### 2.7 `question_option`

```sql
CREATE TABLE question_option (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES question(id) ON DELETE CASCADE,
    label_i18n  JSONB NOT NULL,    -- {"vi":"...","en":"..."}
    image_url   TEXT,
    sort_order  SMALLINT NOT NULL
);
```

### 2.8 `daily_task`

Nhiệm vụ hằng ngày (rotation theo ngày).

```sql
CREATE TABLE daily_task (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    active_date     DATE NOT NULL UNIQUE,
    age_groups      age_group[] NOT NULL,
    lesson_ids      UUID[] NOT NULL,
    bonus_text_i18n JSONB NOT NULL,    -- text MI nói kèm
    bonus_stars     SMALLINT NOT NULL DEFAULT 5
);
```

### 2.9 `content_package` (gói nội dung offline)

```sql
CREATE TABLE content_package (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code          VARCHAR(30) UNIQUE NOT NULL,    -- 'pkg_lite','pkg_full'
    name_i18n     JSONB NOT NULL,
    size_mb       SMALLINT NOT NULL,
    lesson_ids    UUID[] NOT NULL,
    version       SMALLINT NOT NULL,
    published_at  TIMESTAMPTZ
);
```

---

## 3. Progress Module

### 3.1 `lesson_completion`

```sql
CREATE TABLE lesson_completion (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id        UUID NOT NULL REFERENCES child(id) ON DELETE CASCADE,
    lesson_id       UUID NOT NULL REFERENCES lesson(id),
    stars_earned    SMALLINT NOT NULL DEFAULT 1 CHECK (stars_earned BETWEEN 1 AND 3),
    duration_sec    SMALLINT NOT NULL,
    completed_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    language        CHAR(2) NOT NULL,
    
    UNIQUE (child_id, lesson_id)
);

CREATE INDEX idx_lesson_comp_child ON lesson_completion(child_id, completed_at DESC);
```

### 3.2 `game_session`

Mỗi phiên chơi game là 1 row.

```sql
CREATE TABLE game_session (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id        UUID NOT NULL REFERENCES child(id) ON DELETE CASCADE,
    game_id         UUID NOT NULL REFERENCES game(id),
    level_index     SMALLINT NOT NULL,
    score           SMALLINT NOT NULL DEFAULT 0,
    correct_count   SMALLINT NOT NULL DEFAULT 0,
    wrong_count     SMALLINT NOT NULL DEFAULT 0,
    hint_used       SMALLINT NOT NULL DEFAULT 0,
    stars_earned    SMALLINT NOT NULL DEFAULT 0,
    finished        BOOLEAN NOT NULL DEFAULT FALSE,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    finished_at     TIMESTAMPTZ,
    
    FOREIGN KEY (game_id, level_index) REFERENCES game_level(game_id, level_index)
);

CREATE INDEX idx_session_child ON game_session(child_id, started_at DESC);
```

### 3.3 `attempt`

Từng lần trả lời một câu (để phân tích kỹ năng).

```sql
CREATE TABLE attempt (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id    UUID NOT NULL REFERENCES game_session(id) ON DELETE CASCADE,
    question_id   UUID NOT NULL REFERENCES question(id),
    selected_id   UUID REFERENCES question_option(id),
    is_correct    BOOLEAN NOT NULL,
    time_spent_ms SMALLINT NOT NULL,
    attempt_no    SMALLINT NOT NULL,         -- lần thứ mấy trong câu (1..3)
    answered_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_attempt_session ON attempt(session_id);
CREATE INDEX idx_attempt_question ON attempt(question_id) WHERE is_correct = FALSE;
```

### 3.4 `usage_time`

Bucket theo ngày để dashboard.

```sql
CREATE TABLE usage_time (
    child_id      UUID NOT NULL REFERENCES child(id) ON DELETE CASCADE,
    local_date    DATE NOT NULL,
    total_sec     INTEGER NOT NULL DEFAULT 0,
    session_count SMALLINT NOT NULL DEFAULT 0,
    PRIMARY KEY (child_id, local_date)
);

CREATE INDEX idx_usage_date ON usage_time(local_date DESC);
```

### 3.5 `skill_progress`

```sql
CREATE TYPE skill_level AS ENUM ('beginner','developing','proficient');

CREATE TABLE skill_progress (
    child_id      UUID NOT NULL REFERENCES child(id) ON DELETE CASCADE,
    skill_code    VARCHAR(30) NOT NULL,   -- 'letter_recognition','addition','memory'
    level         skill_level NOT NULL DEFAULT 'beginner',
    accuracy_pct  SMALLINT NOT NULL DEFAULT 0 CHECK (accuracy_pct BETWEEN 0 AND 100),
    attempts      INTEGER NOT NULL DEFAULT 0,
    last_practiced TIMESTAMPTZ,
    PRIMARY KEY (child_id, skill_code)
);
```

---

## 4. Reward Module

### 4.1 `star_earning` (ledger — double-entry style)

```sql
CREATE TABLE star_earning (
    id            BIGSERIAL PRIMARY KEY,
    child_id      UUID NOT NULL REFERENCES child(id) ON DELETE CASCADE,
    source_type   VARCHAR(20) NOT NULL,      -- 'lesson','game','daily_task','streak_bonus'
    source_id     UUID,
    amount        SMALLINT NOT NULL,         -- luôn dương, không cho trừ
    earned_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_star_child ON star_earning(child_id, earned_at DESC);

-- Materialized view: tổng sao hiện tại
CREATE MATERIALIZED VIEW mv_child_star_total AS
SELECT child_id, COALESCE(SUM(amount),0)::INTEGER AS total_stars
FROM star_earning
GROUP BY child_id;

CREATE UNIQUE INDEX ON mv_child_star_total(child_id);
```

### 4.2 `badge`

```sql
CREATE TABLE badge (
    id            SMALLSERIAL PRIMARY KEY,
    code          VARCHAR(40) UNIQUE NOT NULL,
    name_i18n     JSONB NOT NULL,
    description_i18n JSONB NOT NULL,
    icon          TEXT NOT NULL,
    condition_json JSONB NOT NULL    -- {'type':'lessons_completed','value':5}
);

INSERT INTO badge (code, name_i18n, description_i18n, icon, condition_json) VALUES
  ('first_star',     '{"vi":"Sao đầu tiên","en":"First Star"}',
                      '{"vi":"Hoàn thành bài học đầu tiên","en":"Complete your first lesson"}',
                      'badges/first_star.svg',
                      '{"type":"lessons_completed","value":1}'),
  ('diligent',       '{"vi":"Học trò siêng năng","en":"Diligent Student"}',
                      '{"vi":"Hoàn thành 5 bài học","en":"Complete 5 lessons"}',
                      'badges/diligent.svg',
                      '{"type":"lessons_completed","value":5}'),
  ('sharp_mind',     '{"vi":"Bộ não nhạy bén","en":"Sharp Mind"}',
                      '{"vi":"Hoàn thành 10 bài học","en":"Complete 10 lessons"}',
                      'badges/sharp_mind.svg',
                      '{"type":"lessons_completed","value":10}'),
  ('alphabet_pro',   '{"vi":"Chuyên gia chữ cái","en":"Alphabet Pro"}',
                      '{"vi":"Hoàn thành bài Nhóm A","en":"Complete all Group A lessons"}',
                      'badges/alphabet_pro.svg',
                      '{"type":"subject_completed","value":"language"}'),
  ('math_wizard',    '{"vi":"Phù thủy toán","en":"Math Wizard"}',
                      '{"vi":"Hoàn thành bài Nhóm B","en":"Complete all Group B lessons"}',
                      'badges/math_wizard.svg',
                      '{"type":"subject_completed","value":"math"}'),
  ('logic_genius',   '{"vi":"Thần đồng tư duy","en":"Logic Genius"}',
                      '{"vi":"Hoàn thành bài Nhóm C","en":"Complete all Group C lessons"}',
                      'badges/logic_genius.svg',
                      '{"type":"subject_completed","value":"logic"}'),
  ('weekly_champ',   '{"vi":"Nhà vô địch tuần","en":"Weekly Champion"}',
                      '{"vi":"Hoàn thành 7 ngày liên tiếp","en":"Complete 7 days in a row"}',
                      'badges/weekly_champ.svg',
                      '{"type":"streak","value":7}'),
  ('explorer',       '{"vi":"Khám phá gia","en":"Little Explorer"}',
                      '{"vi":"Chơi 1 game ở mỗi khu vực","en":"Play 1 game in each area"}',
                      'badges/explorer.svg',
                      '{"type":"areas_visited","value":3}');
```

### 4.3 `badge_earning`

```sql
CREATE TABLE badge_earning (
    id           BIGSERIAL PRIMARY KEY,
    child_id     UUID NOT NULL REFERENCES child(id) ON DELETE CASCADE,
    badge_id     SMALLINT NOT NULL REFERENCES badge(id),
    earned_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    announced    BOOLEAN NOT NULL DEFAULT FALSE,    -- đã hiển thị animation cho trẻ
    UNIQUE (child_id, badge_id)
);

CREATE INDEX idx_badge_child ON badge_earning(child_id, earned_at DESC);
```

---

## 5. Sync Module (Offline)

### 5.1 `sync_queue`

Hàng đợi các thay đổi local cần đẩy lên server khi có mạng.

```sql
CREATE TYPE sync_op AS ENUM ('insert','update','delete');

CREATE TABLE sync_queue (
    id            BIGSERIAL PRIMARY KEY,
    child_id      UUID NOT NULL REFERENCES child(id) ON DELETE CASCADE,
    entity        VARCHAR(40) NOT NULL,        -- 'lesson_completion','attempt'...
    op            sync_op NOT NULL,
    payload       JSONB NOT NULL,              -- dữ liệu đầy đủ
    local_uuid    UUID NOT NULL,               -- id cục bộ để dedupe
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    synced_at     TIMESTAMPTZ,
    UNIQUE (local_uuid)
);

CREATE INDEX idx_sync_pending ON sync_queue(synced_at) WHERE synced_at IS NULL;
```

### 5.2 `content_download`

Theo dõi trạng thái tải nội dung trên từng thiết bị.

```sql
CREATE TYPE download_status AS ENUM ('pending','downloading','completed','failed');

CREATE TABLE content_download (
    child_id         UUID NOT NULL REFERENCES child(id) ON DELETE CASCADE,
    package_code     VARCHAR(30) NOT NULL,
    status           download_status NOT NULL DEFAULT 'pending',
    downloaded_mb    SMALLINT NOT NULL DEFAULT 0,
    total_mb         SMALLINT NOT NULL,
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (child_id, package_code)
);
```

---

## 6. Admin Module (CMS)

### 6.1 `admin_user`

```sql
CREATE TABLE admin_user (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email        VARCHAR(120) UNIQUE NOT NULL,       -- PII chỉ của admin, không của trẻ
    password_hash TEXT NOT NULL,                      -- bcrypt
    role         VARCHAR(20) NOT NULL DEFAULT 'editor',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- role: 'editor' (quản lý nội dung), 'viewer' (chỉ xem report), 'super' (toàn quyền)
```

### 6.2 `error_log` (ẩn danh)

```sql
CREATE TABLE error_log (
    id            BIGSERIAL PRIMARY KEY,
    app_version   VARCHAR(20) NOT NULL,
    platform      VARCHAR(10) NOT NULL,              -- 'ios','android','web'
    error_type    VARCHAR(40) NOT NULL,
    stack_hash    CHAR(40) NOT NULL,                 -- SHA1 của stack trace (ẩn danh)
    count         INTEGER NOT NULL DEFAULT 1,
    first_seen    TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- KHÔNG lưu device_id, user_id, hay bất kỳ PII nào
CREATE INDEX idx_err_hash ON error_log(stack_hash, last_seen DESC);
```

---

## 7. Indexes & Performance Notes

| Bảng | Index | Lý do |
|------|-------|-------|
| `star_earning` | `(child_id, earned_at DESC)` | Dashboard feed |
| `game_session` | `(child_id, started_at DESC)` | Lịch sử nhanh |
| `attempt` | partial `(question_id)` WHERE wrong | Tìm câu khó |
| `usage_time` | `(local_date DESC)` | Weekly report |
| `mv_child_star_total` | unique `(child_id)` | Tổng sao O(1) |

**Partitioning suggestion:** `usage_time` và `attempt` nên partition theo tháng nếu > 10M rows.

---

## 8. Seed Data — Game Levels (Ví dụ)

### Word Builder (levels 1–3)

```json
[
  {"level_index":1,"difficulty":1,"data_json":{"target_word":"MẸ","letters":["M","Ẹ","T","B"],"hint":"Người nuôi em khôn lớn"}},
  {"level_index":2,"difficulty":1,"data_json":{"target_word":"CHA","letters":["C","H","A","O","E"],"hint":"Bố của em"}},
  {"level_index":3,"difficulty":2,"data_json":{"target_word":"CÁT","letters":["C","Á","T","S","M"],"hint":"Hạt nhỏ trên bờ biển"}}
]
```

### Math Race (difficulty curve)

```json
[
  {"level_index":1,"difficulty":1,"data_json":{"op":"add","max_operand":5,"track_length":10}},
  {"level_index":5,"difficulty":2,"data_json":{"op":"add","max_operand":10,"track_length":15}},
  {"level_index":10,"difficulty":3,"data_json":{"op":"sub","max_operand":20,"track_length":20}},
  {"level_index":20,"difficulty":5,"data_json":{"op":"mixed","max_operand":50,"track_length":25}}
]
```

---

## 9. Migration Strategy

- Sử dụng **Alembic** cho schema migration.
- Mỗi migration có `down_revision`.
- Seed data qua `scripts/seed_mvp.py` (chạy idempotent).
- Backup:每日 PostgreSQL `pg_dump` → object storage (mã hóa AES-256).

---

*Tài liệu này là phần của PRD MI Academy v1.0 MVP.*

