# MI Academy — Chi tiết kỹ thuật 6 Game MVP

> **Nền tảng:** Flutter 3.x + Flame Engine 1.x  
> **Độ tuổi:** 5–12 tuổi  
> **Ngày:** 16/07/2026 | **Trạng thái:** Draft  

---

## Quy tắc chung cho tất cả game

| Quy tắc | Giá trị |
|----------|---------|
| Thử đúng lần 1 | ⭐⭐⭐ (3 sao) |
| Thử đúng lần 2 | ⭐⭐ (2 sao) |
| Thử đúng lần 3 | ⭐ (1 sao) |
| Sai → gợi ý MI | KHÔNG trừ sao |
| Thời gian gợi ý | Sau 3–5s không tương tác |
| Timer | KHÔNG có đồng hồ đếm ngược |
| Haptic feedback | Rung nhẹ khi nhận thưởng |

---

## Game 1: Ghép chữ tạo từ — Word Builder

**Chủ đề:** Ngôn ngữ | **Tuổi:** 5–9 | **Engine:** Flame `SpriteComponent`

### Mục tiêu
Kéo chữ cái vào vị trí trống để tạo từ có nghĩa.

### Giao diện (ASCII)

```
┌─────────────────────────────────────┐
│  ← Quay lại  ⭐ 1/5   💡 Gợi ý  │
│                                     │
│      TỪ CẦN TẠO: "MẸ"            │
│      ┌─┐ ┌─┐ ┌─┐                  │
│      │_│ │_│ │_│                  │
│      └─┘ └─┘ └─┘                  │
│                                     │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐            │
│  │ M│ │ Ẹ│ │ T│ │ B│            │
│  └──┘ └──┘ └──┘ └──┘            │
│                                     │
│  🤖 "Kéo chữ M vào ô đầu tiên!"  │
└─────────────────────────────────────┘
```

### Cấu hình level (JSON)

```json
{
  "game_code": "word_builder",
  "max_levels": 15,
  "letters_per_word": {"min": 2, "max": 5},
  "distractors_count": {"min": 1, "max": 3},
  "themes": ["family", "animals", "food", "nature"]
}
```

### Tiến trình level

| Level | Độ khó | Từ/LV | Loại từ | Ví dụ |
|-------|--------|--------|----------|-------|
| 1–3 | Dễ | 5 | 2 chữ cái | MẸ, CHA, BÀ |
| 4–6 | TB | 10 | 2–3 chữ | CÁ, SÔ, HOA |
| 7–9 | TB+ | 10 | 3 chữ | MEO, CÁ, BÀ |
| 10–12 | Khó | 10 | 3–4 chữ | GẤU, BƯỚM |
| 13–15 | Rất khó | 10 | 4–5 chữ | CHUỘT, GÀ, VỊT |

### Dữ liệu mẫu level 1

```json
{
  "level_index": 1,
  "difficulty": 1,
  "words": [
    {
      "id": "w1",
      "word": "MẸ",
      "hint": "Người nuôi em khôn lớn",
      "distractors": ["T", "B", "L"]
    }
  ]
}
```

### Âm thanh

| Sự kiện | File | Mô tả |
|----------|------|--------|
| Đúng | `correct.mp3` | Tiếng chuông vui |
| Gần đúng | `close.mp3` | Tiếng "sai nhẹ" |
| Hoàn thành | `complete.mp3` | Fanfare nhẹ |
| Thu thập sao | `star.mp3` | Tiếng "bling" |

---

## Game 2: Nghe âm tìm chữ — Sound Match

**Chủ đề:** Ngôn ngữ | **Tuổi:** 5–12 | **Engine:** Flame + `audioplayers`

### Mục tiêu
Nghe âm thanh/phát âm, chọn từ viết đúng.

### Giao diện (ASCII)

```
┌─────────────────────────────────────┐
│  ← Quay lại  ⭐ 2/5   🔊 Phát lại │
│                                     │
│      NGHE VÀ CHỌN TỪ ĐÚNG:        │
│                                     │
│        🔊 [Nút phát to]           │
│                                     │
│  ┌─────────┐ ┌─────────┐          │
│  │   MẸ   │ │   CHA   │          │
│  └─────────┘ └─────────┘          │
│  ┌─────────┐ ┌─────────┐          │
│  │   MÈ   │ │   BÀ   │          │
│  └─────────┘ └─────────┘          │
│                                     │
│  🤖 "Nghe kỹ rồi chọn đáp án!"  │
└─────────────────────────────────────┘
```

### Tiến trình level

| Level | Độ khó | Số lựa chọn | Nội dung |
|-------|--------|-------------|----------|
| 1–3 | Dễ | 4 | Âm đơn: a, o, e, i |
| 4–6 | TB | 4 | Âm ghép: an, en, on |
| 7–9 | TB+ | 4–6 | Từ đơn: mẹ, bà, cha |
| 10–12 | Khó | 6 | Từ kép: nhà, bông |

### Dữ liệu mẫu level 1

```json
{
  "level_index": 1,
  "difficulty": 1,
  "questions": [
    {
      "id": "q1",
      "prompt_audio": "me.mp3",
      "prompt_text": "Chọn từ: mẹ",
      "options": [
        {"id": "o1", "label": "MẸ", "is_correct": true},
        {"id": "o2", "label": "BÀ", "is_correct": false},
        {"id": "o3", "label": "CHA", "is_correct": false},
        {"id": "o4", "label": "MÈ", "is_correct": false}
      ]
    }
  ]
}
```

---

## Game 3: Đường đua cộng trừ — Math Race

**Chủ đề:** Toán học | **Tuổi:** 5–12 | **Engine:** Flame `ParallaxComponent`

### Mục tiêu
Trả lời phép tính đúng để xe đua tiến về đích.

### Giao diện (ASCII)

```
┌─────────────────────────────────────┐
│  ← Quay lại  ⭐ 3/5   🏁 Đích    │
│  ┌─────────────────────────────────┐│
│  │ 🚗 ════════════════ 🏁         ││
│  │    ══════════════               ││
│  │         ══════                  ││
│  └─────────────────────────────────┘│
│                                     │
│          3 + 4 = ?                  │
│   ┌───────┐ ┌───────┐ ┌───────┐   │
│   │   6   │ │   7   │ │   8   │   │
│   └───────┘ └───────┘ └───────┘   │
│                                     │
│  🤖 "Tính nhẩm nào, đáp án nào?" │
└─────────────────────────────────────┘
```

### Tiến trình level

| Level | Phép tính | Số hạng max | Đích |
|-------|-----------|-------------|------|
| 1–5 | Cộng | 5 | 10 vòng |
| 6–10 | Cộng | 10 | 15 vòng |
| 11–15 | Trừ | 10 | 15 vòng |
| 16–20 | Trừ | 20 | 20 vòng |

### Dữ liệu mẫu level 1

```json
{
  "level_index": 1,
  "difficulty": 1,
  "operation": "add",
  "max_operand": 5,
  "track_length": 10,
  "problems": [
    {"a": 1, "b": 2, "correct": 3, "options": [3, 4, 2]},
    {"a": 2, "b": 3, "correct": 5, "options": [4, 5, 6]}
  ]
}
```

### Flame Components

```dart
// Main game class
class MathRaceGame extends FlameGame with HasCollisionDetection {
  late CarComponent car;
  late TrackComponent track;
  int currentProblem = 0;
  int carPosition = 0; // 0..trackLength
}

// Car moves forward each correct answer
car.moveForward(int steps) {
  carPosition += steps;
  // animate along track path
}
```

---

## Game 4: Siêu thị toán học — Math Supermarket

**Chủ đề:** Toán học | **Tuổi:** 8–12 | **Engine:** Flame

### Mục tiêu
Chọn sản phẩm, tính tổng, nhập tiền thừa.

### Giao diện (ASCII)

```
┌─────────────────────────────────────┐
│  ← Quay lại  ⭐ 2/4               │
│                                     │
│  ┌───────┐ ┌───────┐ ┌───────┐   │
│  │ 🍎    │ │ 🍞    │ │ 🥛    │   │
│  │ 3.000đ│ │ 8.000đ│ │12.000đ│   │
│  └───────┘ └───────┘ └───────┘   │
│  ┌───────┐ ┌───────┐ ┌───────┐   │
│  │ 🍌    │ │ 🧀    │ │ 🥚    │   │
│  │ 5.000đ│ │15.000đ│ │ 7.000đ│   │
│  └───────┘ └───────┘ └───────┘   │
│                                     │
│  Đã chọn: 🍎 + 🧀 = 18.000đ       │
│  Khách đưa: 20.000đ               │
│  Tiền thừa: [______] đ            │
└─────────────────────────────────────┘
```

### Tiến trình level

| Level | Sản phẩm | Phép tính | Tiền |
|-------|-----------|-----------|------|
| 1–3 | 2 | Cộng | Tiền lẻ chẵn |
| 4–6 | 2–3 | Cộng | Tiền lẻ |
| 7–9 | 2–3 | Cộng+Trừ | Tiền thừa |
| 10–12 | 3–4 | Cộng+Trừ+Ngẫu nhiên | Phức tạp |

---

## Game 5: Ghi nhớ vị trí — Memory Match

**Chủ đề:** Tư duy | **Tuổi:** 5–12 | **Engine:** Flame `TappableComponent`

### Mục tiêu
Lật thẻ tìm cặp giống nhau trong thời gian giới hạn.

### Giao diện (ASCII)

```
┌─────────────────────────────────────┐
│  ← Quay lại  ⭐ 3/6   ⏱ 2:00    │
│                                     │
│  ┌──────┐ ┌──────┐ ┌──────┐      │
│  │  ?   │ │  ?   │ │  ?   │      │
│  └──────┘ └──────┘ └──────┘      │
│  ┌──────┐ ┌──────┐ ┌──────┐      │
│  │  ?   │ │  ?   │ │  ?   │      │
│  └──────┘ └──────┘ └──────┘      │
│                                     │
│  Cặp đã tìm: 🐱 + 🐱 ✓           │
│                                     │
│  🤖 "Nhớ vị trí các thẻ nhé!"   │
└─────────────────────────────────────┘
```

### Tiến trình level

| Level | Grid | Số thẻ | Chủ đề | Thời gian |
|-------|------|---------|--------|-----------|
| 1–2 | 2×2 | 4 | Động vật | 30s |
| 3–4 | 3×2 | 6 | Trái cây | 45s |
| 5–6 | 3×4 | 12 | Hình dạng | 60s |
| 7–8 | 4×4 | 16 | Hình dạng | 90s |
| 9–10 | 5×4 | 20 | Hình dạng | 120s |

### Dữ liệu mẫu level 1

```json
{
  "level_index": 1,
  "difficulty": 1,
  "grid": [2, 2],
  "theme": "animals",
  "pairs": [
    {"id": "p1", "image": "cat.svg", "label": "Mèo"},
    {"id": "p2", "image": "dog.svg", "label": "Chó"}
  ],
  "time_limit_sec": 30
}
```

---

## Game 6: Robot làm theo lệnh — Robot Commands

**Chủ đề:** Tư duy | **Tuổi:** 8–12 | **Engine:** Flame

### Mục tiêu
Sắp xếp lệnh để robot đến ngôi sao.

### Giao diện (ASCII)

```
┌─────────────────────────────────────┐
│  ← Quay lại  ⭐ 1/3   📋 Lệnh    │
│                                     │
│  5 × 5 Grid:                       │
│  ┌─┬─┬─┬─┬─┐                      │
│  │R│ │ │ │ │  ← Robot             │
│  ├─┼─┼─┼─┼─┤                      │
│  │ │ │ │ │ │                      │
│  ├─┼─┼─┼─┼─┤                      │
│  │ │ │ │★│ │  ← Sao              │
│  ├─┼─┼─┼─┼─┤                      │
│  │ │ │ │ │ │                      │
│  └─┴─┴─┴─┴─┘                      │
│                                     │
│  Lệnh: [↑] [→] [←] [↓]            │
│  Đã chọn: [↑] [→] [→]             │
│                                     │
│  🤖 "Robot cần 3 bước đến sao!"  │
└─────────────────────────────────────┘
```

### Tiến trình level

| Level | Max lệnh | Grid | Ràng buộc |
|-------|---------|------|-----------|
| 1–5 | 5 | 4×4 | Đường thẳng |
| 6–10 | 6 | 5×5 | 1 góc |
| 11–15 | 8 | 5×5 | 2 góc |
| 16–20 | 10–12 | 6×6 | Nhiều chướng ngại |

### Dữ liệu mẫu level 1

```json
{
  "level_index": 1,
  "difficulty": 1,
  "grid_size": [4, 4],
  "robot_pos": [0, 0],
  "goal_pos": [1, 2],
  "max_commands": 5,
  "solution": ["right", "down", "down"],
  "obstacles": []
}
```

### Flame Implementation

```dart
class RobotCommandsGame extends FlameGame {
  late GridComponent grid;
  late RobotComponent robot;
  final List<String> commandQueue = [];

  void executeCommands() async {
    for (final cmd in commandQueue) {
      await robot.animateMove(cmd);
      await Future.delayed(Duration(milliseconds: 500));
    }
    if (robot.position == goal.position) {
      onSuccess();
    } else {
      onFailure();
    }
  }
}
```

---

## Tổng hợp Sound Effects

| Game | Sự kiện | File |
|------|----------|------|
| Tất cả | Hoàn thành game | `fanfare.mp3` |
| Tất cả | Nhận sao | `star.mp3` |
| Tất cả | Nhận huy hiệu | `badge.mp3` |
| Tất cả | MI động viên | `mi_encourage.mp3` |
| Tất cả | Gợi ý hiện | `hint.mp3` |
| Word Builder | Kéo thả | `drag.mp3` / `drop.mp3` |
| Sound Match | Phát âm | `{word}.mp3` |
| Math Race | Động cơ xe | `engine_loop.mp3` |
| Math Market | Tiền rơi | `coin.mp3` |
| Memory Match | Lật thẻ | `flip.mp3` |
| Robot | Di chuyển | `step.mp3` |

---

## Flutter pubspec.yaml — Game Dependencies

```yaml
dependencies:
  flame: ^1.15.0
  flame_audio: ^2.10.2
  flame_forge2d: ^0.17.0  # optional physics
  google_fonts: ^6.1.0
  hive: ^2.2.3
  audioplayers: ^5.2.1
  flutter_animate: ^4.5.0
```

---

*Tài liệu này là phần của PRD MI Academy v1.0 MVP.*
