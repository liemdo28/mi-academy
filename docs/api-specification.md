# MI Academy — API Specification

> **Framework:** FastAPI (Python 3.11+)  
> **Base URL:** `https://api.miacademy.app/v1`  
> **Auth:** Bearer JWT (refresh + access token)  
> **Format:** JSON, UTF-8 (hỗ trợ tiếng Việt có dấu)  
> **Last updated:** 16/07/2026 — MVP v1.0  

---

## 1. Conventions

| Mục | Quy định |
|-----|----------|
| HTTP verbs | GET (read), POST (create/action), PUT (update), DELETE (remove) |
| Timestamps | ISO 8601 UTC, ví dụ `2026-07-16T10:30:00Z` |
| IDs | UUID v4 (string) |
| Locale | Header `Accept-Language: vi` hoặc `en` |
| Pagination | `?page=1&per_page=20` → `total`, `page`, `per_page`, `items` |
| Errors | `{ "error": { "code": "PIN_INVALID", "message": "..." , "details": {} } }` |

### Error codes

| Code | HTTP | Mô tả |
|------|------|-------|
| `UNAUTHORIZED` | 401 | Token thiếu/hết hạn |
| `PIN_INVALID` | 401 | PIN phụ huynh sai |
| `PAYLOAD_INVALID` | 422 | Validation fail |
| `NOT_FOUND` | 404 | Resource không tồn tại |
| `CHILD_LIMIT` | 409 | Quá 5 child/parent |
| `RATE_LIMITED` | 429 | Quá nhiều request |
| `SERVER_ERROR` | 500 | Lỗi server |

---

## 2. Authentication & Parent PIN

### POST /auth/setup-pin

Thiết lập PIN lần đầu (khi tạo hồ sơ đầu).

**Request:**
```json
{
  "device_id": "a1b2c3d4-...",
  "pin": "1234"
}
```

**Response 200:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "expires_in": 3600,
  "parent_id": "uuid"
}
```

### POST /auth/verify-pin

Xác thực PIN để vào khu vực phụ huynh (chỉ local verify, không gửi PIN lên server).

> **Lưu ý bảo mật:** App verify PIN local bằng bcrypt so sánh với `pin_hash` đã lưu. Endpoint này chỉ dùng khi cần xác thực server-side cho đồng bộ.

**Request:**
```json
{ "parent_id": "uuid", "pin": "1234" }
```

**Response 200:** `{ "valid": true, "access_token": "eyJ..." }`

### POST /auth/forgot-pin

Dùng câu hỏi bảo mật (phép tính dạng người lớn).

**Request:**
```json
{ "parent_id": "uuid", "answer": "42" }
```

**Response 200:** `{ "reset_token": "eyJ...", "valid": true }`  
**Response 401:** `{ "error": { "code": "PIN_INVALID", "message": "Đáp án không đúng" } }`

### POST /auth/refresh

```json
{ "refresh_token": "eyJ..." }
```
→ 200 `{ "access_token": "eyJ...", "expires_in": 3600 }`

---

## 3. Child Profiles

### GET /children

Danh sách hồ sơ trẻ (có progress summary).

**Response 200:**
```json
{
  "items": [
    {
      "id": "uuid",
      "name": "Minh",
      "avatar_id": 3,
      "age_group": "junior",
      "total_stars": 145,
      "badges_earned": 4,
      "lessons_completed": 12,
      "last_active": "2026-07-16T09:00:00Z"
    }
  ],
  "total": 1
}
```

### POST /children

Tạo hồ sơ mới (max 5).

**Request:**
```json
{
  "name": "Minh",
  "avatar_id": 3,
  "age_group": "junior",
  "birth_year": 2020
}
```

**Response 201:** `{ "id": "uuid", "name": "Minh", ... }`  
**Response 409:** `{ "error": { "code": "CHILD_LIMIT", "message": "Tối đa 5 hồ sơ" } }`

### GET /children/{child_id}

**Response 200:** profile đầy đủ + `progress_summary`, `badges`, `skills`.

### PUT /children/{child_id}

Cập nhật tên/avatar (không đổi age_group sau khi có progress).

### DELETE /children/{child_id}

Xóa toàn bộ dữ liệu (GDPR/Nghị định 13 compliant). Yêu cầu PIN verify.

---

## 4. Lessons & Games (Content)

### GET /lessons

```http
GET /lessons?age_group=junior&subject=language&page=1&per_page=20
```

**Response 200:**
```json
{
  "items": [
    {
      "id": "uuid",
      "title": "Nhận biết chữ M",
      "subject": "language",
      "duration_sec": 180,
      "thumbnail": "lessons/l1.svg",
      "completed": false,
      "stars": 0
    }
  ],
  "total": 15
}
```

### GET /lessons/{lesson_id}

Trả về nội dung bài học đầy đủ (i18n theo Accept-Language).

**Response 200:**
```json
{
  "id": "uuid",
  "title": "Nhận biết chữ M",
  "intro_text": "Chữ M giống như hai ngọn núi...",
  "summary": "Em vừa học về chữ M! Tuyệt vời!",
  "audio_url": "https://.../m.mp3",
  "game_id": "uuid",
  "steps": [
    { "type": "show_letter", "letter": "M", "sound": "m.mp3" },
    { "type": "trace", "letter": "M" },
    { "type": "quiz", "question_id": "uuid" }
  ]
}
```

### GET /games/{game_id}/config

```json
{ "max_levels": 15, "letters_per_word_max": 6, "themes_available": ["animals"] }
```

### POST /games/{game_id}/start

Bắt đầu phiên chơi, server trả về level data.

**Request:**
```json
{ "child_id": "uuid", "level_index": 1 }
```

**Response 200:**
```json
{
  "session_id": "uuid",
  "level": {
    "level_index": 1,
    "difficulty": 1,
    "data": { "target_word": "MẸ", "letters": ["M","Ẹ","T","B"], "hint": "..." }
  }
}
```

### POST /games/{game_id}/submit-answer

Gửi từng câu trả lời (cho analytics + scoring).

**Request:**
```json
{
  "session_id": "uuid",
  "question_id": "uuid",
  "selected_id": "uuid",
  "time_spent_ms": 3200,
  "attempt_no": 1
}
```

**Response 200:**
```json
{
  "is_correct": true,
  "correct_answer": "MẸ",
  "hint": null,
  "stars_earned": 3,
  "next_question": "uuid"   // hoặc null nếu hết
}
```

### POST /games/{game_id}/finish

Kết thúc phiên, tính tổng sao.

**Request:** `{ "session_id": "uuid", "stars_earned": 3 }`  
**Response 200:** `{ "badges_new": ["first_star"], "total_stars": 148 }`

---

## 5. Progress

### GET /progress/{child_id}/summary

```json
{
  "total_stars": 148,
  "lessons_completed": 12,
  "games_played": 8,
  "streak_days": 3,
  "subjects": {
    "language": { "completed": 5, "total": 10, "accuracy": 92 },
    "math": { "completed": 4, "total": 10, "accuracy": 85 },
    "logic": { "completed": 3, "total": 10, "accuracy": 78 }
  }
}
```

### POST /progress/complete-lesson

```json
{
  "child_id": "uuid",
  "lesson_id": "uuid",
  "stars_earned": 2,
  "duration_sec": 175,
  "language": "vi"
}
```
→ 201 `{ "badges_new": [], "total_stars": 150 }`

### GET /progress/{child_id}/skills

```json
{
  "skills": [
    { "code": "letter_recognition", "level": "proficient", "accuracy_pct": 95 },
    { "code": "addition", "level": "developing", "accuracy_pct": 70 },
    { "code": "memory", "level": "beginner", "accuracy_pct": 55 }
  ]
}
```

---

## 6. Rewards

### GET /rewards/{child_id}/stars

```json
{ "total": 150, "today": 5, "this_week": 42, "history": [ {"date":"2026-07-16","amount":5}, ... ] }
```

### GET /rewards/{child_id}/badges

```json
{
  "earned": [
    { "code": "first_star", "name": "Sao đầu tiên", "icon": "badges/first_star.svg", "earned_at": "..." }
  ],
  "locked": [
    { "code": "weekly_champ", "name": "Nhà vô địch tuần", "icon": "...", "hint": "Hoàn thành 7 ngày liên tiếp" }
  ]
}
```

### POST /rewards/check-badge

Trigger kiểm tra điều kiện huy hiệu (sau mỗi hoàn thành).

```json
{ "child_id": "uuid", "event": "lesson_completed" }
```
→ 200 `{ "new_badges": ["diligent"] }`

---

## 7. Parent Dashboard

### GET /parent/usage-time?child_id=uuid&days=7

```json
{
  "data": [
    { "date": "2026-07-16", "total_min": 18, "sessions": 2, "limit_exceeded": false },
    { "date": "2026-07-15", "total_min": 25, "sessions": 3, "limit_exceeded": false }
  ],
  "average_min": 21,
  "daily_limit": 30
}
```

### GET /parent/weekly-report?child_id=uuid

```json
{
  "week_start": "2026-07-10",
  "lessons_completed": 7,
  "stars_earned": 42,
  "strongest_skill": "letter_recognition",
  "needs_practice": "addition",
  "real_world_suggestions": [
    "Đếm số lượng đồ chơi cùng bé",
    "Tìm chữ cái M trên biển báo đường phố"
  ]
}
```

### GET /parent/skill-analysis?child_id=uuid

```json
{
  "radar": {
    "labels": ["Chữ", "Toán", "Logic", "Ghi nhớ", "Quan sát"],
    "values": [92, 85, 78, 70, 88]
  },
  "recommendations": ["Tăng cường bài tập cộng trừ"]
}
```

---

## 8. Settings

### GET /settings

```json
{
  "daily_time_limit": 30,
  "language": "vi",
  "sound_enabled": true,
  "offline_packages": [
    { "code": "pkg_lite", "size_mb": 120, "downloaded": true },
    { "code": "pkg_full", "size_mb": 480, "downloaded": false }
  ]
}
```

### PUT /settings

```json
{ "daily_time_limit": 45, "sound_enabled": false }
```
→ 200 updated

---

## 9. Offline Sync

### GET /sync/content-packages

Danh sách gói nội dung có thể tải.

```json
{
  "packages": [
    { "code": "pkg_lite", "name": "Gói cơ bản", "size_mb": 120, "version": 3, "lessons": 30 },
    { "code": "pkg_full", "name": "Gói đầy đủ", "size_mb": 480, "version": 3, "lessons": 120 }
  ]
}
```

### POST /sync/upload-progress

Đẩy hàng đợi local lên server (batch).

**Request:**
```json
{
  "items": [
    { "local_uuid": "uuid", "entity": "lesson_completion", "payload": { ... } },
    { "local_uuid": "uuid2", "entity": "attempt", "payload": { ... } }
  ]
}
```

**Response 200:**
```json
{ "accepted": ["uuid", "uuid2"], "rejected": [] }
```

### GET /sync/delta?since=2026-07-15T00:00:00Z

Lấy nội dung mới/cập nhật từ server (CMS thay đổi).

```json
{
  "lessons_new": [],
  "lessons_updated": ["uuid"],
  "games_updated": ["uuid"],
  "badges_new": []
}
```

---

## 10. Admin CMS (Role-protected)

### POST /admin/lessons

Tạo/chỉnh sửa bài học (role: editor, super).

### POST /admin/questions

Tạo câu hỏi + options.

### GET /admin/reports/anonymous

Xuất báo cáo sử dụng ẩn danh (role: viewer, super).

### GET /admin/errors

Danh sách lỗi ứng dụng (từ `error_log`).

---

## 11. Rate Limiting

| Endpoint group | Limit |
|----------------|-------|
| Auth | 5 req/min/IP |
| Content read | 60 req/min |
| Progress write | 30 req/min |
| Admin | 100 req/min |

---

*Tài liệu này là phần của PRD MI Academy v1.0 MVP.*
