# MI Academy — Product Requirements Document (PRD)

> **Version:** 1.0 — MVP  
> **Ngày:** 16/07/2026  
> **Trạng thái:** Draft  

---

## 1. Tổng quan sản phẩm

### 1.1 Tầm nhìn

MI Academy tạo ra một không gian an toàn, vui vẻ và hoàn toàn miễn phí, nơi trẻ từ 5–12 tuổi có thể học toán, học chữ, luyện tư duy và khám phá thế giới theo tốc độ riêng của mình.

### 1.2 Giá trị cốt lõi

| Nguyên tắc | Mô tả |
|------------|-------|
| **Miễn phí hoàn toàn** | Không phí, không IAP, không subscription |
| **Không quảng cáo** | Zero ads, không liên kết bên ngoài |
| **Không gây áp lực** | Không trừ sao, không xếp hạng, không deadline |
| **Offline-first** | Hoạt động đầy đủ sau khi tải nội dung |
| **Bảo vệ trẻ em** | Không mạng xã hội, không chat, không chia sẻ dữ liệu cá nhân |
| **Học qua chơi** | Gameplay-driven learning, không bài tập khô khan |

### 1.3 Đối tượng người dùng

| Nhóm | Độ tuổi | Mô tả |
|------|----------|-------|
| **MI Junior** | 5–7 tuổi | Nhận biết chữ cái, đếm số, hình dạng, màu sắc, trí nhớ |
| **MI Explorer** | 8–10 tuổi | Đọc hiểu, chính tả, bốn phép tính, đo lường, logic |
| **MI Master** | 11–12 tuổi | Toán nâng cao, phân số, viết, lập trình, chiến lược |

### 1.4 Người dùng phụ

- **Phụ huynh/người giám hộ**: Theo dõi tiến độ, thiết lập giới hạn, quản lý hồ sơ
- **Quản trị viên nội dung**: Tạo bài học, câu hỏi, quản lý media qua CMS
- **Quản trị viên hệ thống**: Xem báo cáo, quản lý lỗi, kiểm tra độ khó

---

## 2. Phạm vi MVP (Giai đoạn 1)

### 2.1 Tính năng bắt buộc (Must Have)

| # | Tính năng | Mức ưu tiên |
|---|-----------|-------------|
| 1 | **Hệ thống hồ sơ trẻ** — Tạo/xem/sửa hồ sơ, avatar, tên | P0 |
| 2 | **Nhân vật MI** — Robot hướng dẫn với animation (Rive/Lottie) | P0 |
| 3 | **Bản đồ học tập** — Thế giới khám phá tương tác (5 khu vực) | P0 |
| 4 | **Game 1: Ghép chữ tạo từ** | P0 |
| 5 | **Game 2: Nghe âm tìm chữ** | P0 |
| 6 | **Game 3: Đường đua cộng trừ** | P0 |
| 7 | **Game 4: Siêu thị toán học** | P0 |
| 8 | **Game 5: Ghi nhớ vị trí** | P0 |
| 9 | **Game 6: Robot làm theo lệnh** | P0 |
| 10 | **Hệ thống sao & huy hiệu** | P0 |
| 11 | **Khu vực phụ huynh** (PIN-protected) | P0 |
| 12 | **Chế độ offline** | P0 |
| 13 | **Đa ngôn ngữ** (Tiếng Việt + English) | P0 |
| 14 | **Bài học ngắn 3–5 phút** trước mỗi game | P0 |
| 15 | **Vòng lặp học tập 15–25 phút** | P0 |

### 2.2 Tính năng nên có (Should Have)

| # | Tính năng | Ghi chú |
|---|-----------|---------|
| 1 | Nhiệm vụ hằng ngày | Cập nhật mỗi ngày |
| 2 | Trang trí hồ sơ cá nhân | Quần áo, phụ kiện cho avatar |
| 3 | Vườn cây ảo | Phần thưởng hình thành cây |
| 4 | Đồng bộ dữ liệu đa thiết bị | Khi có Internet |
| 5 | Onboarding flow | Hướng dẫn lần đầu sử dụng |

### 2.3 Tính năng tốt nếu có (Nice to Have)

| # | Tính năng | Ghi chú |
|---|-----------|---------|
| 1 | Chế độ tối | Giảm ánh sáng ban đêm |
| 2 | Font chữ điều chỉnh | Cho trẻ khiếm thị nhẹ |
| 3 | Chia sẻ chứng nhận | QR code hoặc PDF (không qua mạng xã hội) |

---

## 3. User Stories

### 3.1 Trẻ em

```
US-001: [Trẻ] Tôi muốn chọn nhân vật và tên để hồ sơ thuộc về tôi
  AC: Trẻ có thể nhập tên (max 20 ký tự), chọn 1 avatar trong 8 lựa chọn
  AC: Hệ thống không yêu cầu email hay số điện thoại

US-002: [Trẻ] Tôi muốn MI chào tôi và gợi ý việc cần làm hôm nay
  AC: MI xuất hiện với animation + giọng nói
  AC: MI gợi ý 1 nhiệm vụ hằng ngày + 1 trò chơi tự chọn
  AC: MI không nhắc lại nếu trẻ đã hoàn thành

US-003: [Trẻ] Tôi muốn khám phá bản đồ bằng cách chạm vào khu vực
  AC: Bản đồ hiển thị 5 khu vực với animation sống động
  AC: Khu vực có khóa nếu chưa đạt độ tuổi phù hợp
  AC: Khu vực sáng lên khi có nội dung mới

US-004: [Trẻ] Tôi muốn chơi trò "Ghép chữ tạo từ"
  AC: Trẻ kéo thả chữ cái vào vị trí trống để tạo từ
  AC: Trẻ có 3 lần thử cho mỗi từ
  AC: MI gợi ý nhẹ sau lần thử thứ 2 (highlight chữ cái đúng)
  AC: Trẻ nhận sao khi hoàn thành (không bị trừ khi sai)

US-005: [Trẻ] Tôi muốn chơi trò "Nghe âm tìm chữ"
  AC: Ứng dụng phát âm thanh rõ ràng
  AC: Trẻ chọn từ 4 lựa chọn (tăng lên 6 ở level cao)
  AC: MI khen ngợi khi đúng, gợi ý khi sai

US-006: [Trẻ] Tôi muốn chơi trò "Đường đua cộng trừ"
  AC: Màn hình hiển thị phép tính + 3 đáp án
  AC: Chọn đúng → xe tiến về đích
  AC: Chọn sai → MI giải thích bằng hình ảnh + cho thử lại
  AC: Không có đồng hồ đếm ngược

US-007: [Trẻ] Tôi muốn chơi trò "Siêu thị toán học"
  AC: Trẻ chọn 2–3 sản phẩm từ kệ
  AC: Trẻ tính tổng tiền và nhập tiền thừa
  AC: Có hỗ trợ vật lý ảo (đếm xu, tờ tiền)
  AC: Độ khó tăng dần: cộng → trừ → nhân

US-008: [Trẻ] Tôi muốn chơi trò "Ghi nhớ vị trí"
  AC: Hiển thị 4–12 thẻ (tùy level)
  AC: Trẻ có 3 giây để ghi nhớ vị trí
  AC: Lật thẻ tìm cặp giống nhau
  AC: Thời gian ghi nhớ tăng ở level cao

US-009: [Trẻ] Tôi muốn chơi trò "Robot làm theo lệnh"
  AC: Trẻ sắp xếp lệnh tiến, lùi, trái, phải
  AC: Robot di chuyển theo lệnh
  AC: Mục tiêu: đưa robot đến ngôi sao
  AC: Số lệnh tối đa giới hạn tùy level

US-010: [Trẻ] Tôi muốn xem sao và huy hiệu tôi đạt được
  AC: Màn hình hồ sơ hiển thị tổng sao, huy hiệu, thành tích mới
  AC: Mỗi huy hiệu có icon + tên + điều kiện đạt được
  AC: Huy hiệu chưa đạt hiển thị "???" với gợi ý
```

### 3.2 Phụ huynh

```
US-101: [Phụ huynh] Tôi muốn bảo vệ khu vực của mình bằng PIN
  AC: Khu vực phụ huynh yêu cầu nhập 4-digit PIN
  AC: Lần đầu tạo PIN khi setup hồ sơ
  AC: Có tùy chọn "quên PIN" (câu hỏi bảo mật dạng phép tính)

US-102: [Phụ huynh] Tôi muốn xem thời gian sử dụng mỗi ngày
  AC: Biểu đồ bar chart 7 ngày gần nhất
  AC: Hiển thị tổng thời gian + trung bình
  AC: Đánh dấu ngày vượt giới hạn (nếu có)

US-103: [Phụ huynh] Tôi muốn xem bài học đã hoàn thành
  AC: Danh sách bài học + % hoàn thành
  AC: Lọc theo chủ đề (toán, chữ, logic)
  AC: Hiển thị kỹ năng mạnh + kỹ năng cần luyện

US-104: [Phụ huynh] Tôi muốn đặt giới hạn thời gian
  AC: Cài đặt: 15/30/45/60 phút mỗi ngày
  AC: MI tự động thông báo khi sắp hết giờ
  AC: MI mời trẻ "nghỉ ngơi" thay vì "buộc thoát"

US-105: [Phụ huynh] Tôi muốn tải bài học để dùng offline
  AC: Hiển thị dung lượng cần tải
  AC: Tải theo gói (toán, chữ, logic riêng)
  AC: Hiển thị tiến độ tải + dung lượng đã tải

US-106: [Phụ huynh] Tôi muốn tạo nhiều hồ sơ trẻ
  AC: Tối đa 5 hồ sơ trên 1 thiết bị
  AC: Chuyển đổi hồ sơ qua màn hình chính
  AC: Mỗi hồ sơ có tiến độ riêng
```

---

## 4. Yêu cầu phi chức năng

### 4.1 Hiệu năng

| Yêu cầu | Giá trị |
|----------|---------|
| Thời gian tải game đầu tiên | ≤ 3 giây (offline) |
| Thời gian phản hồi animation | ≤ 100ms |
| Khung hình animation | 60 FPS |
| Dung lượng app cài đặt | ≤ 150 MB (không có nội dung) |
| Dung lượng nội dung offline | ≤ 500 MB |

### 4.2 Khả năng truy cập

| Yêu cầu | Mô tả |
|----------|---------|
| Font size tối thiểu | 16sp cho text, 24sp cho heading |
| Color contrast | WCAG AA (4.5:1 cho text) |
| Voice-over/Screen reader | Hỗ trợ iOS VoiceOver + Android TalkBack |
| Touch target tối thiểu | 48x48 dp |
| Nút bấm rõ ràng | Viền bo tròn + icon + label text |

### 4.3 Bảo mật & Quyền riêng tư

| Yêu cầu | Mô tả |
|----------|---------|
| Dữ liệu thu thập | Không thu thập PII của trẻ em |
| Analytics | Ẩn danh, không tracking cross-app |
| Mã hóa | AES-256 cho dữ liệu local, TLS 1.3 cho network |
| PIN phụ huynh | Bcrypt hash, không lưu plaintext |
| Tuân thủ | COPPA (US), GDPR-K (EU), Nghị định 13 (VN) |

### 4.4 Nền tảng

| Nền tảng | Phiên bản tối thiểu |
|-----------|---------------------|
| iOS | 15.0+ (iPhone 8+, iPad 5th gen+) |
| Android | API 24+ (Android 7.0+) |
| Web | Chrome 90+, Safari 15+, Firefox 90+ |
| Màn hình | 320dp–1280dp width |

---

## 5. Hệ thống phần thưởng MVP

### 5.1 Loại phần thưởng

| Loại | Cách nhận | MVP? |
|------|-----------|------|
| ⭐ Sao MI | Hoàn thành bài học/trò chơi | ✅ |
| 🏅 Huy hiệu | Đạt cột mốc (5 bài, 10 bài, hoàn chủ đề) | ✅ |
| 👕 Quần áo avatar | Hoàn thành bộ bài học | ❌ Giai đoạn 2 |
| 🌱 Vườn cây | Hoàn thành bài hàng ngày | ❌ Giai đoạn 2 |
| 📖 Truyện mới | Hoàn thành 3 game | ❌ Giai đoạn 2 |

### 5.2 Huy hiệu MVP

| Huy hiệu | Điều kiện |
|----------|-----------|
| 🌟 Sao đầu tiên | Hoàn thành bài học đầu tiên |
| 📚 Học trò siêng năng | Hoàn thành 5 bài học |
| 🧠 Bộ não nhạy bén | Hoàn thành 10 bài học |
| 🔤 Chuyên gia chữ cái | Hoàn thành tất cả bài Nhóm A |
| 🔢 Phù thủy toán | Hoàn thành tất cả bài Nhóm B |
| 💡 Thần đồng tư duy | Hoàn thành tất cả bài Nhóm C |
| 🏆 Nhà vô địch tuần | Hoàn thành 7 ngày liên tiếp |
| 🎯 Hoàn thành thử thách | Hoàn thành thử thách tư duy 5 lần |
| 🌈 Khám phá gia | Chơi ít nhất 1 game ở mỗi khu vực |

### 5.3 Quy tắc phần thưởng

- **KHÔNG BAO GIỜ** trừ sao khi trả lời sai
- Trẻ nhận tối thiểu 1 sao mỗi khi hoàn thành bài học (dù có trả lời sai)
- Trả lời đúng lần đầu → 3 sao, lần 2 → 2 sao, lần 3 → 1 sao
- Huy hiệu được MI trao với animation đặc biệt
- Không có "hộp quà ngẫu nhiên" hay "luck-based" reward

---

## 6. Kiến trúc khu vực trên bản đồ

```
┌─────────────────────────────────────────────────────────┐
│                    MI ACADEMY MAP                        │
│                                                         │
│   ┌──────────┐    🏰 Nhân vật MI (trung tâm)            │
│   │ Thành phố │                                          │
│   │ Chữ cái  │    ┌──────────┐    ┌──────────┐          │
│   │ (Nhóm A) │    │ Vương    │    │ Đảo      │          │
│   └──────────┘    │ Quốc     │    │ Tư duy   │          │
│                   │ Toán     │    │ (Nhóm C) │          │
│   ┌──────────┐    │ (Nhóm B) │    └──────────┘          │
│   │ Ngôi nhà │    └──────────┘                          │
│   │ Sáng tạo │                                          │
│   │          │    ┌──────────┐                          │
│   └──────────┘    │ Phòng    │                          │
│                   │ Thí nghiệm│                         │
│   ┌──────────┐    └──────────┘                          │
│   │ Hồ sơ   │                                          │
│   │ của bé  │                                          │
│   └──────────┘                                          │
└─────────────────────────────────────────────────────────┘
```

**Khu vực MVP (có nội dung):**
- ✅ Thành phố chữ cái (2 game: Ghép chữ, Nghe âm)
- ✅ Vương quốc toán học (2 game: Đường đua, Siêu thị)
- ✅ Đảo tư duy (2 game: Ghi nhớ vị trí, Robot)
- 🔒 Ngôi nhà sáng tạo (Giai đoạn 2)
- 🔒 Phòng thí nghiệm (Giai đoạn 2)

---

## 7. Vòng lặp học tập chi tiết

```
┌──────────────────────────────────────────┐
│  MI chào trẻ (giọng nói + animation)      │
│  "Chào em! Hôm nay mình học gì nhé?"     │
└──────────────────┬───────────────────────┘
                   ▼
┌──────────────────────────────────────────┐
│  Trẻ chọn nhiệm vụ hằng ngày HOẶC        │
│  tự chọn trò chơi từ bản đồ              │
└──────────────────┬───────────────────────┘
                   ▼
┌──────────────────────────────────────────┐
│  Bài học ngắn (3–5 phút)                 │
│  MI giải thích khái niệm                  │
│  Ví dụ tương tác (kéo, chạm)              │
└──────────────────┬───────────────────────┘
                   ▼
┌──────────────────────────────────────────┐
│  Trò chơi áp dụng (5–8 phút)             │
│  Áp dụng kiến thức vừa học               │
│  Mức độ: dễ → vừa → khó                  │
└──────────────────┬───────────────────────┘
                   ▼
┌──────────────────────────────────────────┐
│  Thử thách tư duy (3–5 phút)             │
│  Bài tập logic liên quan chủ đề          │
│  Không bắt buộc hoàn thành ngay           │
└──────────────────┬───────────────────────┘
                   ▼
┌──────────────────────────────────────────┐
│  Nhận thưởng                              │
│  Sao + huy hiệu (nếu đạt)                │
│  Animation MI ăn mừng                    │
└──────────────────┬───────────────────────┘
                   ▼
┌──────────────────────────────────────────┐
│  MI tóm tắt                               │
│  "Em vừa học về [chủ đề].                │
│   Em giỏi lắm! Mai mình học tiếp nhé!"   │
└──────────────────────────────────────────┘
  → Lưu tiến độ → Về bản đồ học tập
