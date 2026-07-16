# MI Academy — User Flows (MVP)

> **Công cụ vẽ:** Mermaid (hỗ trợ trong VS Code, GitHub, Notion)  
> **Độ tuổi mục tiêu:** 5–12 tuổi  
> **Nguyên tắc:** Không áp lực, không trừ sao, MI luôn khuyến khích  

---

## 1. First Launch Flow (Lần đầu mở app)

```mermaid
flowchart TD
    A[Splash Screen: Logo MI Academy] --> B[Chọn ngôn ngữ: Tiếng Việt / English]
    B --> C{Đã có profile?}
    C -->|Chưa| D[Tạo hồ sơ trẻ đầu tiên]
    C -->|Có| E[Profile Selection]
    D --> D1[Nhập tên - tối đa 20 ký tự]
    D1 --> D2[Chọn avatar - 8 lựa chọn]
    D2 --> D3[Chọn độ tuổi: Junior/Explorer/Master]
    D3 --> F[Thiết lập mã PIN phụ huynh - 4 số]
    F --> G[Onboarding: MI giới thiệu thế giới]
    G --> H[World Map - Màn hình chính]
    D2 -.->|Quay lại| D1
```

**Ghi chú:**
- Không yêu cầu email, số điện thoại, hay tài khoản mạng xã hội
- PIN dùng cho khu vực phụ huynh; có thể đặt sau nếu bỏ qua
- Onboarding: MI nói "Chào em! Mình là MI, cùng khám phá nhé!"

---

## 2. Daily Learning Loop (Vòng lặp học tập 15–25 phút)

```mermaid
flowchart TD
    A[World Map] --> B[MI chào: 'Chào em! Hôm nay học gì?']
    B --> C{Chọn}
    C -->|Nhiệm vụ hằng ngày| D[Mini-Lesson 3-5 phút]
    C -->|Tự chọn game| E[Area Detail → Chọn game]
    E --> D
    D --> D1[MI giải thích khái niệm]
    D1 --> D2[Ví dụ tương tác: kéo, chạm]
    D2 --> D3[Kiểm tra nhanh]
    D3 --> F[Game áp dụng 5-8 phút]
    F --> G[Thử thách tư duy 3-5 phút]
    G --> H[Reward Screen: Sao + Huy hiệu]
    H --> I[MI tóm tắt: 'Em vừa học về...']
    I --> J[Quay lại World Map hoặc Tiếp tục]
```

**Ghi chú:**
- Nếu trẻ chọn sai: MI giải thích nhẹ + cho thử lại (không trừ sao)
- Trẻ có thể dừng bất cứ lúc nào (nút home góc trái)

---

## 3. Map Exploration Flow (Khám phá bản đồ)

```mermaid
flowchart TD
    A[World Map] --> B[Tap khu vực]
    B --> C{Kó nội dung?}
    C -->|Chưa mở khóa| D[Dialog: 'Khu vực này mở sau nhé!']
    C -->|Đã mở| E[Area Detail Screen]
    E --> F[Danh sách game có sẵn]
    F --> G{Game đã hoàn thành?}
    G -->|Chưa| H[Game Lobby: Giới thiệu + Bắt đầu]
    G -->|Rồi| I[Xem sao đã đạt + Chơi lại]
    H --> J[Gameplay]
    I --> J
    J --> K[Results → Reward]
```

**Khu vực MVP:**
- ✅ Thành phố chữ cái (Ghép chữ, Nghe âm)
- ✅ Vương quốc toán học (Đường đua, Siêu thị)
- ✅ Đảo tư duy (Ghi nhớ, Robot)
- 🔒 Ngôi nhà sáng tạo (GĐ2)
- 🔒 Phòng thí nghiệm (GĐ2)

---

## 4. Game Flow (Chung cho 6 game MVP)

```mermaid
flowchart TD
    A[Game Lobby] --> B[MI hướng dẫn luật chơi]
    B --> C[Gameplay level 1]
    C --> D{Câu hỏi/Thử thách}
    D -->|Đúng| E[Cộng sao + TIến tiếp]
    D -->|Sai| F[MI giải thích hình ảnh]
    F --> G{Hết lượt thử?}
    G -->|Chưa| D
    G -->|Rồi| H[MI gợi ý + cho qua nhẹ nhàng]
    E --> I{Hết level?}
    H --> I
    I -->|Chưa| C
    I -->|Rồi| J[Score Screen]
    J --> K[Star Animation + Badge popup]
    K --> L[Continue → Map hoặc Replay]
```

**Quy tắc:**
- Tối đa 3 lần thử mỗi câu
- Lần 1 đúng: 3 sao; lần 2: 2 sao; lần 3: 1 sao
- Không đồng hồ đếm ngược gây áp lực

---

## 5. Parent Access Flow (Khu vực phụ huynh)

```mermaid
flowchart TD
    A[World Map / Settings] --> B[Tap 'Khu vực phụ huynh']
    B --> C[PIN Challenge: 4 số]
    C --> D{PIN đúng?}
    D -->|Sai 3 lần| E[Khóa 30s + Gợi ý quên PIN]
    D -->|Đúng| F[Dashboard]
    E -->|Quên PIN| G[Phép tính bảo mật]
    G --> H{Đúng?}
    H -->|Có| I[Đặt lại PIN]
    H -->|Không| E
    F --> J[Tabs: Tổng quan / Tiến độ / Kỹ năng / Cài đặt]
    J --> K[Xem báo cáo + Chỉnh giới hạn]
```

**Bảo mật:**
- PIN không lưu plaintext (bcrypt)
- Sau 3 lần sai → lockout tạm thời
- Không hiện PIN trên màn hình (dạng dots)

---

## 6. Profile Switch Flow (Chuyển hồ sơ)

```mermaid
flowchart TD
    A[Profile Button - góc phải] --> B[Profile Selection Screen]
    B --> C{Chọn hành động}
    C -->|Chọn hồ sơ| D[Tải progress của trẻ]
    C -->|Thêm mới| E[Tạo profile - max 5]
    C -->|Phụ huynh| F[PIN Challenge]
    D --> G[World Map - hồ sơ mới]
    E --> G
    F --> H[Parent Dashboard]
```

---

## 7. Offline Download Flow (Tải nội dung)

```mermaid
flowchart TD
    A[Settings] --> B[Quản lý nội dung]
    B --> C[Danh sách gói: Lite/Full]
    C --> D{Chọn gói}
    D --> E[Hiển thị dung lượng cần tải]
    E --> F[Xác nhận tải]
    F --> G[Download Progress Bar]
    G --> H{Thành công?}
    H -->|Có| I[Đánh dấu 'Sẵn sàng offline']
    H -->|Lỗi| J[Thử lại / Hủy]
    I --> K[Sử dụng offline]
```

**Ghi chú:**
- Có thể tải từng gói (toán, chữ, logic) riêng
- Tự động resume nếu mạng mất

---

## 8. Error / Recovery Flow (Khi trẻ gặp khó)

```mermaid
flowchart TD
    A[Trẻ trả lời sai] --> B[MI: 'Không sao, thử lại nhé!']
    B --> C[Hiển thị giải thích hình ảnh]
    C --> D{Lần thử thứ mấy?}
    D -->|1| E[Cho thử lại không gợi ý]
    D -->|2| F[MI highlight gợi ý nhẹ]
    D -->|3| G[MI chỉ đáp án + Khen nỗ lực]
    E --> H[Tiếp tục level]
    F --> H
    G --> H
    H --> I[Không trừ sao - vẫn nhận 1 sao tối thiểu]
```

**Nguyên tắc MI:**
- "Em làm tốt rồi!" / "Cố gắng một chút nữa nhé!"
- Không bao giờ: "Sai rồi", "Chậm quá", "Em kém hơn bạn"

---

## 9. Time Limit Flow (Giới hạn thời gian)

```mermaid
flowchart TD
    A[Timer chạy ngầm] --> B{Còn 5 phút?}
    B -->|Có| A
    B -->|Sắp hết| C[MI: 'Sắp đến giờ nghỉ rồi, em chơi nốt trò này nhé']
    C --> D{Trẻ hoàn thành trò?}
    D -->|Có| E[Reward + 'Hẹn gặp lại mai']
    D -->|Không| F[MI: 'Mình nghỉ ngơi, mai chơi tiếp']
    E --> G[Về Map / Đóng app nhẹ nhàng]
    F --> G
```

**Khác biệt với app khác:**
- MI "mời" nghỉ thay vì "buộc thoát"
- Không có màn hình khóa cứng gây khóc

---

*Tài liệu này là phần của PRD MI Academy v1.0 MVP.*
