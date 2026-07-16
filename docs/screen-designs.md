# MI Academy — Chi tiết thiết kế màn hình (MVP)

> **Nền tảng:** Flutter (iOS / Android / Web)  
> **Phong cách:** Hoạt hình 2D, bo tròn, màu sắc tươi sáng, dễ nhìn  
> **Typography:** Baloo 2 (display), Nunito (body) — hỗ trợ tiếng Việt  
> **Cỡ chữ:** Heading 24sp+, Body 16sp+, Touch target 48x48dp  
> **Phụ trách UI:** Rive animations cho MI, Lottie cho effects  

---

## Bảng màu chủ đạo

| Màu | Hex | Vùng sử dụng |
|-----|-----|--------------|
| Cam nắng | `#FF8C42` | Chữ cái / Ngôn ngữ |
| Xanh biếc | `#4ECDC4` | Toán học |
| Tím nhẹ | `#A78BFA` | Tư duy / Logic |
| Xanh lá | `#10B981` | Khoa học |
| Hồng đào | `#F472B6` | Sáng tạo |
| Nền kem | `#FFF8F0` | Nền chung |
| Xám đậm | `#2D3436` | Text chính |
| Xám nhạt | `#DFE6E9` | Border, background phụ |
| Trắng | `#FFFFFF` | Card, popup |

---

## 1. Splash Screen

```
┌──────────────────────────────────────┐
│                                      │
│         ┌──────────────┐             │
│         │  🤖 MI        │             │
│         │  ACADEMY      │             │
│         └──────────────┘             │
│                                      │
│    "Học qua chơi, lớn lên qua       │
│     từng khám phá"                  │
│                                      │
│         ┌──────────────┐             │
│         │  Đang tải... │             │
│         └──────────────┘             │
└──────────────────────────────────────┘
```

**Spec:** Hiển thị tối thiểu 1.5 giây, MI bounce+blink animation, fade out → Profile Selection, ẩn status bar.

---

## 2. Profile Selection Screen

```
┌──────────────────────────────────────┐
│  Cài đặt ⚙️              Nút cha 👨     │
│         ┌─────────────────┐          │
│         │ Chọn bạn nhỏ    │          │
│   ┌──────┐  ┌──────┐  ┌──────┐      │
│   │  👦  │  │  👧  │  │  +   │      │
│   │ Minh │  │ Lan  │  │Thêm  │      │
│   └──────┘  └──────┘  └──────┘      │
│   ┌──────┐  ┌──────┐                │
│   │  👦  │  │  👦  │                │
│   │ Kiên │  │ Tùng │                │
│   └──────┘  └──────┘                │
└──────────────────────────────────────┘
```

**Spec:** Avatar hình tròn viền màu theo age_group; nút Thêm chỉ hiện khi <5 hồ sơ; nút phụ huynh gọn góc phải dưới; phone 2 cột / tablet 3 cột.

---

## 3. World Map Screen (Màn hình chính)

```
┌──────────────────────────────────────┐
│  Sao: ⭐145  [Minh ▾]      🏠       │
│   ☁️        ☁️         ☁️            │
│  ┌────────┐         ┌────────┐      │
│  │ 🏙️     │  🏰     │ 🧩     │      │
│  │Thành   │  MI     │Đảo    │      │
│  │phố chữ │ (robot) │Tư duy │      │
│  └────────┘         └────────┘      │
│      ┌────────┐         ┌────────┐  │
│      │ 🔢    │         │🔒     │  │
│      │Vương  │         │Sáng   │  │
│      │quốc   │         │tạo    │  │
│      └────────┘         └────────┘  │
│  [🏠] [🗺️] [👤] [⭐]              │
└──────────────────────────────────────┘
```

**Spec:** 3 khu vực MVP sáng màu; 2 khu vực khóa grayed + ổ khóa + tooltip MI; MI idle animation; bottom nav 4 icon; bong bóng "mới" khi có bài học.

---

## 4. Area Detail Screen

```
┌──────────────────────────────────────┐
│  ← Quay lại    Thành phố chữ cái 🏙️ │
│  "Nơi học về chữ cái, từ ngữ..."    │
│  ┌──────────────────────────────────┐│
│  │ ⭐ Ghép chữ tạo từ  Lvl 5/15 ▶   ││
│  │ ████████░░░░░░░░ 33%            ││
│  └──────────────────────────────────┘│
│  ┌──────────────────────────────────┐│
│  │ ⭐ Nghe âm tìm chữ  Lvl 3/12 ▶   ││
│  │ ████████████░░░░ 75%            ││
│  └──────────────────────────────────┘│
│  ┌──────────────────────────────────┐│
│  │ 🔒 Đọc truyện tương tác - Sắp ra ││
│  └──────────────────────────────────┘│
└──────────────────────────────────────┘
```

**Spec:** Card bo tròn + progress bar; game khóa grayed; game hoàn thành hiện sao ⭐⭐⭐; gap 16dp; swipe down xem thêm.

---

## 5. Mini-Lesson Screen

```
┌──────────────────────────────────────┐
│  ← Quay lại     2/5    ✕ Thoát      │
│  ┌──────────────────────────────────┐│
│  │     🤖 MI (animation)            ││
│  │     "Chữ M giống hai ngọn núi!" ││
│  └──────────────────────────────────┘│
│  ┌──────────────────────────────────┐│
│  │       ┌──────┐                   ││
│  │       │  M   │                   ││
│  │       └──────┘                   ││
│  │  "MẸ"   "MẶT"   "MŨI"          ││
│  └──────────────────────────────────┘│
│  ◀ Qua lại   ────────── ✦ ✦ ✦      │
│           Tiến tới ▶                 │
└──────────────────────────────────────┘
```

**Spec:** MI audio VI/EN; progress dots ● ● ○ ○ ○; chạm hình minh họa → animation; nút Thoát nhỏ góc phải, xác nhận; KHÔNG timer.

---

## 6. Game Screen (Common Layout)

```
┌──────────────────────────────────────┐
│  ← Quay lại   ⭐ 3/3   ⏸ Tạm dừng  │
│  ┌──────────────────────────────────┐│
│  │      KHU VỰC GAME (70% cao)     ││
│  └──────────────────────────────────┘│
│  ┌──────────────────────────────────┐│
│  │  🤖 "Em sắp tìm ra rồi!"        ││
│  │  [Gợi ý 💡]                      ││
│  └──────────────────────────────────┘│
└──────────────────────────────────────┘
```

**Spec:** Header back + star counter + pause; game area responsive center; MI hint zone hiện khi hesitate >5s; nút Gợi ý hiện sau 3s; background gradient nhẹ tránh mỏi mắt.

---

## 7. Reward Screen

```
┌──────────────────────────────────────┐
│          ✨ CHÚC MỪNG! ✨            │
│       ⭐ ⭐ ⭐ (3→2→1 anim)          │
│   🌟  HOÀN THÀNH RỒI!                │
│  ┌──────────────────────────────┐   │
│  │  "Em vừa học về chữ M!"       │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │ 🏅 Huy hiệu mới (nếu có)      │   │
│  │  [Badge anim] "Học trò siêng" │   │
│  └──────────────────────────────┘   │
│        ┌──────────────────┐         │
│        │  Tiếp tục nhé ▶  │         │
│        └──────────────────┘         │
└──────────────────────────────────────┘
```

**Spec:** Sao pop-up scale + halo; huy hiệu trượt từ dưới, MI vỗ tay; 3–4 giây; haptic rung nhẹ; nút lớn, MI "Em bấm khi sẵn sàng nhé".

---

## 8. Child Profile Screen

```
┌───────────────────────────────────────┐
│  ← Quay lại          Hồ sơ của bé     │
│      ┌───────────┐                    │
│      │   👦  Minh │                    │
│      └───────────┘   6 tuổi - Lớp 1  │
│       ⭐ 145 sao                      │
│  ╭─ 🏅 Huy hiệu (4/9) ─────────────╮  │
│  │  ✨ Sao đầu tiên  ✓              │  │
│  │  📚 Học trò siêng năng  ✓       │  │
│  │  🔤 Chuyên gia chữ cái   🔒      │  │
│  │  🏆 Nhà vô địch tuần   🔒        │  │
│  ╰─────────────────────────────────╯  │
│  ╭─ 📊 Tiến độ ────────────────────╮  │
│  │  Chữ   ████████░░ 80%           │  │
│  │  Toán  ██████░░░░ 60%           │  │
│  │  Logic ████░░░░░░ 40%           │  │
│  ╰─────────────────────────────────╯  │
└───────────────────────────────────────┘
```

**Spec:** Huy hiệu đạt màu đầy + sparkle; chưa đạt silhouette + tooltip; progress bar theo chủ đề; tap avatar chỉnh tên; nút khóa tránh trẻ đổi lung tung.

---

## 9. Parent PIN Screen

```
┌───────────────────────────────────────┐
│          Khu vực phụ huynh             │
│        🔒 (icon khóa lớn)             │
│   "Nhập mã PIN 4 số để mở nhé"      │
│        ┌─┐ ┌─┐ ┌─┐ ┌─┐               │
│        │·│ │·│ │ │ │ │               │
│        └─┘ └─┘ └─┘ └─┘               │
│   ┌─────┼─────┼─────┼─────┐         │
│   │  1  │  2  │  3  │  ⌫  │         │
│   │  4  │  5  │  6  │     │         │
│   │  7  │  8  │  9  │     │         │
│   │     │  0  │     │     │         │
│   └─────┴─────┴─────┴─────┘         │
│       [Quên PIN?]                      │
└───────────────────────────────────────┘
```

**Spec:** PIN dots rỗng/đầy/✓; 3 lần sai → lockout 30s + nền đỏ nhạt; hỗ trợ accessibility; "Quên PIN?" → phép tính bảo mật.

---

## 10. Parent Dashboard — Tổng quan

```
┌───────────────────────────────────────┐
│  [Tổng quan] [Tiến độ] [Kỹ năng] [Cài]│
│─────────────────────────────────────│
│   Xin chào! Hôm nay con học 18 phút  │
│  ╭─ Thời gian 7 ngày ──────────────╮  │
│  │  25 █                          │  │
│  │  20 █ █                        │  │
│  │  15 █ █   █                    │  │
│  │  10 █ █ █ █ █ █              │  │
│  │   5 █ █ █ █ █ █ █              │  │
│  │    T2 T3 T4 T5 T6 T7 CN        │  │
│  ╰─────────────────────────────────╯  │
│  ╭─ Đề xuất ngoài trời ─────────────╮ │
│  │ • Đếm đồ vật trong nhà cùng bé │  │
│  │ • Tìm chữ M trên biển hiệu     │  │
│  ╰─────────────────────────────────╯  │
└───────────────────────────────────────┘
```

**Spec:** Tab bar 4 tab; bar chart ngày vượt giới hạn đỏ; đề xuất theo độ tuổi/kỹ năng; font 14–16sp (khác font trẻ em).

---

## 11. Parent Dashboard — Kỹ năng

```
┌───────────────────────────────────────┐
│  [Tổng quan] [Tiến độ] [Kỹ năng] [Cài]│
│         ┌─ Radar chart ─┐            │
│         │       *        │  Chữ 88   │
│         │   *       *    │  Toán 75  │
│         │ *           *  │  Logic 60 │
│         │   *       *    │  Nhớ 82   │
│         │       *        │  Quan sát70│
│         └────────────────┘            │
│  ╭─ Mạnh ───────╮ ╭─ Cần luyện ───╮  │
│  │ ✨ Chữ 88%   │ │ 💡 Cộng 60%   │  │
│  │ ✨ Nhớ 82%   │ │ 💡 Nhân 45%   │  │
│  ╰──────────────╯ ╰──────────────╯  │
└───────────────────────────────────────┘
```

**Spec:** Radar 5 trục anim 1s; màu xanh mạnh / cam cần luyện; nút "Xem bài luyện tập" gợi ý game cụ thể.

---

## 12. Parent Settings

```
┌───────────────────────────────────────┐
│  [Tổng quan] [Tiến độ] [Kỹ năng] [Cài]│
│  ⏱  Giới hạn thời gian                │
│  [15][30][45][60]  ← selected 30     │
│  🌐  Ngôn ngữ  [Tiếng Việt][English] │
│  🔊  Âm thanh  [Bật ███████░░░]      │
│  📦  Offline   Gói cơ bản ✅ / Đầy ⬇ │
│  👶  Hồ sơ     [Minh][Lan][+Thêm]    │
│  🔐  Đổi mã PIN                        │
│  ⚠️  Xóa toàn bộ dữ liệu [Yêu cầu PIN]│
└───────────────────────────────────────┘
```

---

## 13. Onboarding Screens

```
Screen 1: 🤖 "Chào em! Mình là MI" [▶ Tiếp] [•]
Screen 2: 🗺️ "Khám phá 5 khu vực"    [▶ Tiếp] [• •]
Screen 3: 🏆 "Nhận sao, huy hiệu"     [Bắt đầu ▶] [• • •]
```

**Spec:** 3 màn hình swipe ngang; nút Skip; Lottie anim