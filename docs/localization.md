# MI Academy — Localization Guide (i18n)

> **Ngày:** 16/07/2026 | **Ngôn ngữ MVP:** Tiếng Việt (vi), English (en)  
> **Framework:** Flutter `intl` + ARB files | Backend: Python `Babel`

---

## 1. Kiến trúc i18n tổng quan

```
Flutter App                    Backend (FastAPI)              CMS
┌──────────────┐            ┌──────────────┐           ┌──────────────┐
│  ARB files   │            │ Babel/JSONB  │           │  Admin UI    │
│  app_vi.arb  │            │ vi/en JSONB  │           │  Song ngữ    │
│  app_en.arb  │            │ columns      │           │  nhập liệu  │
└──────┬───────┘            └──────┬───────┘           └──────┬───────┘
       │                           │                          │
       │  Hive cache              │  Accept-Language header   │
       └──────────────────────────┴──────────────────────────┘
                    API response → Flutter cache
```

---

## 2. Cấu trúc ARB (Flutter)

### 2.1 File: `lib/l10n/app_vi.arb`

```json
{
  "@@locale": "vi",
  "appTitle": "MI Academy",
  "greetingMorning": "Chào buổi sáng!",
  "greetingAfternoon": "Chào buổi chiều!",
  "greetingEvening": "Chào buổi tối!",
  "miWelcome": "Chào em! Mình là MI, cùng khám phá nhé!",
  "miGreatJob": "Em làm tốt lắm!",
  "miTryAgain": "Không sao, thử lại nhé!",
  "miHint": "Gợi ý nhé: {hint}",
  "@miHint": {
    "placeholders": {
      "hint": { "type": "String" }
    }
  },
  "starEarned": "{count} sao",
  "@starEarned": {
    "placeholders": {
      "count": { "type": "int" }
    }
  },
  "starEarnedPlural": "{count, plural, =1{1 sao} =2{2 sao} other{{count} sao}}",
  "gameComplete": "Hoàn thành!",
  "badgeEarned": "Huy hiệu mới: {name}",
  "@badgeEarned": {
    "placeholders": {
      "name": { "type": "String" }
    }
  },
  "buttonContinue": "Tiếp tục",
  "buttonBack": "Quay lại",
  "buttonHint": "Gợi ý",
  "buttonExit": "Thoát",
  "buttonPlay": "Chơi ngay",
  "buttonReplay": "Chơi lại",
  "lessonTitle": "Bài học {number}",
  "@lessonTitle": {
    "placeholders": {
      "number": { "type": "int" }
    }
  },
  "progressPercent": "{percent}% hoàn thành",
  "timeRemaining": "Còn {minutes} phút",
  "parentArea": "Khu vực phụ huynh",
  "dailyTask": "Nhiệm vụ hằng ngày",
  "noInternetOffline": "Đang offline — dữ liệu sẽ đồng bộ sau",
  "errorPinInvalid": "Mã PIN không đúng",
  "errorNetworkError": "Lỗi kết nối, thử lại sau",
  "settingsLanguage": "Ngôn ngữ",
  "settingsTimeLimit": "Giới hạn thời gian",
  "settingsSound": "Âm thanh",
  "profileNameHint": "Nhập tên của bé"
}
```

### 2.2 File: `app_en.arb`

```json
{
  "@@locale": "en",
  "appTitle": "MI Academy",
  "greetingMorning": "Good morning!",
  "greetingAfternoon": "Good afternoon!",
  "greetingEvening": "Good evening!",
  "miWelcome": "Hi there! I'm MI, let's explore together!",
  "miGreatJob": "You're doing great!",
  "miTryAgain": "No worries, try again!",
  "miHint": "Hint: {hint}",
  "starEarnedPlural": "{count, plural, =1{1 star} other{{count} stars}}",
  "gameComplete": "Complete!",
  "badgeEarned": "New badge: {name}",
  "buttonContinue": "Continue",
  "buttonBack": "Back",
  "buttonHint": "Hint",
  "buttonExit": "Exit",
  "buttonPlay": "Play Now",
  "buttonReplay": "Play Again",
  "lessonTitle": "Lesson {number}",
  "progressPercent": "{percent}% complete",
  "timeRemaining": "{minutes} minutes left",
  "parentArea": "Parent Zone",
  "dailyTask": "Daily Challenge",
  "noInternetOffline": "Offline — data will sync later",
  "errorPinInvalid": "Incorrect PIN",
  "errorNetworkError": "Connection error, try again",
  "settingsLanguage": "Language",
  "settingsTimeLimit": "Time Limit",
  "settingsSound": "Sound",
  "profileNameHint": "Enter child's name"
}
```

---

## 3. Bảng thuật ngữ game (VI ↔ EN)

| VI | EN | Ghi chú |
|----|----|---------|
| Ghép chữ tạo từ | Word Builder | Game 1 |
| Nghe âm tìm chữ | Sound Match | Game 2 |
| Đường đua cộng trừ | Math Race | Game 3 |
| Siêu thị toán học | Math Supermarket | Game 4 |
| Ghi nhớ vị trí | Memory Match | Game 5 |
| Robot làm theo lệnh | Robot Commands | Game 6 |
| Thành phố chữ cái | Alphabet City | Khu vực A |
| Vương quốc toán học | Math Kingdom | Khu vực B |
| Đảo tư duy | Logic Island | Khu vực C |
| Sao đầu tiên | First Star | Huy hiệu |
| Học trò siêng năng | Diligent Student | Huy hiệu |
| Phù thủy toán | Math Wizard | Huy hiệu |
| Thần đồng tư duy | Logic Genius | Huy hiệu |
| Nhà vô địch tuần | Weekly Champion | Huy hiệu |
| Khu vực phụ huynh | Parent Zone | |
| Khu vực khóa | Locked area | |

---

## 4. Audio path structure

```
assets/
└── audio/
    ├── vi/
    │   ├── mi/
    │   │   ├── welcome.mp3
    │   │   ├── hint.mp3
    │   │   ├── great_job.mp3
    │   │   └── try_again.mp3
    │   ├── letters/
    │   │   ├── a.mp3, ă.mp3, â.mp3, b.mp3...
    │   │   └── me.mp3, cha.mp3...
    │   ├── sounds/
    │   │   ├── correct.mp3
    │   │   ├── wrong.mp3
    │   │   ├── star.mp3
    │   │   └── fanfare.mp3
    │   └── games/
    │       ├── word_builder/
    │       ├── math_race/
    │       └── memory_match/
    └── en/
        └── (tương tự cấu trúc vi/)
```

---

## 5. ICU MessageFormat — Plural & Gender

```dart
// Flutter ARB plural syntax
"youHaveStars": "{count, plural, =0{Bạn chưa có sao nào} =1{Bạn có 1 sao} other{Bạn có {count} sao}}",

// Number formatting
"yourProgress": "Tiến độ: {percent}%",  // percent auto-localized

// Date formatting (dùng Intl)
final now = DateTime.now();
formatDate(now, 'vi') → "16/07/2026"
formatDate(now, 'en') → "07/16/2026"
```

---

## 6. Number & Currency formatting

```dart
import 'package:intl/intl.dart';

String formatNumber(int n, String locale) {
  return NumberFormat.decimalPattern(locale).format(n);
  // vi: 1.234 | en: 1,234
}

String formatCurrency(int dong, String locale) {
  if (locale == 'vi') {
    return '${NumberFormat.decimalPattern('vi').format(dong)} đ';
  } else {
    return '\$${NumberFormat.decimalPattern('en').format(dong)}';
  }
  // vi: 15.000 đ | en: $15,000
}
```

---

## 7. Backend i18n (FastAPI + Pydantic)

```python
from pydantic import BaseModel
from typing import Literal

class LessonContent(BaseModel):
    title: dict[str, str]  # {"vi": "Nhận biết chữ M", "en": "Letter M recognition"}
    intro_text: dict[str, str]
    summary: dict[str, str]
    audio_url_vi: str | None
    audio_url_en: str | None

class GameData(BaseModel):
    prompt_i18n: dict[str, str]
    options_i18n: list[dict[str, str]]
    hint_i18n: dict[str, str]
```

**Accept-Language routing:**

```python
from fastapi import Header

async def get_lessons(language: str = Header(default="vi", alias="Accept-Language")):
    lang = language[:2] if language else "vi"
    # lang ∈ {"vi", "en"}
    return await fetch_lessons(localized=lang)
```

---

## 8. Font & Rendering

| Ngôn ngữ | Font | Fallback |
|----------|------|---------|
| Tiếng Việt | **Baloo 2** (display) | Nunito |
| Tiếng Việt | **Nunito** (body) | system-ui |
| Tiếng Anh | **Baloo 2** | Nunito |
| Emoji | System emoji font | |

**pubspec.yaml:**
```yaml
dependencies:
  google_fonts: ^6.1.0

flutter:
  fonts:
    - family: Baloo2
      fonts:
        - asset: assets/fonts/Baloo2-Regular.ttf
        - asset: assets/fonts/Baloo2-Bold.ttf
          weight: 700
```

---

## 9. QA Test Matrix

| # | Test Case | VI | EN | Pass Criteria |
|---|-----------|----|----|---------------|
| 1 | Plural sao (1, 2, 5) | ✅ | ✅ | Đúng số ít/dạng |
| 2 | Tiếng Việt có dấu hiển thị | ✅ | N/A | Không bị mất dấu |
| 3 | Câu dài vừa màn hình | ✅ | ✅ | Không tràn |
| 4 | Emoji hiển thị | ✅ | ✅ | Không bị □ |
| 5 | Số định dạng đúng | ✅ | ✅ | VD: 1.234 vs 1,234 |
| 6 | Ngày định dạng đúng | ✅ | ✅ | VN: dd/MM, EN: MM/dd |
| 7 | RTL margin (tương lai) | N/A | N/A | Chuẩn bị sẵn |

---

## 10. Verified implementation status (Milestone 1, 2026-07-18)

The sections above are the design/PRD target. This section records what
was directly verified against the current codebase — some of section 9's
QA matrix checkmarks predate that verification and should not be trusted
without re-confirming; this section supersedes them where they conflict.

- **`.arb` key parity**: real, verified 57/57 keys matching between
  `app_en.arb` and `app_vi.arb`. Now enforced in CI (`tools/localization_audit.py`,
  wired into `.github/workflows/ci.yml`'s `content-and-safety` job) —
  previously only true by coincidence, not gated.
- **Hardcoded-string scan**: `tools/localization_audit.py` (no `--fail-on-hardcoded`)
  reports, as of this pass, **245 hardcoded Vietnamese string literals
  across 39 files** in `apps/mobile/lib`. This is report-only in CI, not
  blocking — retrofitting all 39 files to use `AppLocalizations`/`L10nService`
  instead of literals is tracked as open work (`docs/release-audit.md`
  RA-05), not something this pass silently fixed or hid.
- **Game content locale** (prompts, target words, hints, per-question
  feedback from JSON level content): real, verified — every game session
  class reads a `locale` parameter instead of a hardcoded `'vi'` (see
  `docs/game-catalog.md` and the locale-wiring commits on this branch).
- **App-shell locale** (`MaterialApp.locale`): real, reads from
  `ParentSettingsSnapshot.language` via a reactive provider, verified.
- **First-launch language selection**: real, exists (`LocaleSelectionScreen`),
  with 8 passing tests covering fresh install, VI selection, EN selection,
  persistence, later change in Parent Settings, and local-data-reset
  returning to selection.
- **Section 9's QA matrix**: not re-verified item-by-item this pass (no
  device/emulator run was performed for these specific checks — see
  `docs/testing.md`'s integration-test gap). Do not treat those checkmarks
  as current verification.

*Tài liệu này là phần của PRD MI Academy v1.0 MVP.*
