# MI Academy — UI/UX Design System

> **Version:** 1.0  
> **Ngày:** 16/07/2026  
> **Đối tượng:** UI/UX Designer, AI Design Tool, Front-end / Flutter Engineer  
> **Nền tảng:** iOS / Android / Web (ưu tiên tablet & desktop nhỏ)  
> **Mục tiêu:** Thiết kế hệ thống giao diện "thế giới khám phá" an toàn, vui vẻ, không thi cử, dành cho trẻ 5–12 tuổi.

Tài liệu này là bản thiết kế hệ thống (design system) đầy đủ cho MI Academy, bao quát: triết lý thiết kế, màu sắc, typography, khoảng cách, bo góc/bóng, nhân vật MI, component library, navigation, 18 màn hình, trạng thái hệ thống, accessibility, responsive, animation, âm thanh, microcopy và design tokens.

> **Liên kết:** Wireframe ASCII của 13 màn hình MVP nằm ở [docs/screen-designs.md](./screen-designs.md). Tài liệu này mở rộng thành hệ thống đầy đủ (34 mục) bao gồm cả tablet, landscape, parent dashboard và trạng thái rỗng/lỗi/offline.

---

## Mục lục

1. [Mục tiêu thiết kế](#1-mục-tiêu-thiết-kế)
2. [Phong cách hình ảnh](#2-phong-cách-hình-ảnh)
3. [Hệ thống màu sắc](#3-hệ-thống-màu-sắc)
4. [Màu theo khu vực học tập](#4-màu-theo-khu-vực-học-tập)
5. [Typography](#5-typography)
6. [Hệ thống khoảng cách](#6-hệ-thống-khoảng-cách)
7. [Bo góc và đổ bóng](#7-bo-góc-và-đổ-bóng)
8. [Nhân vật MI](#8-nhân-vật-mi)
9. [Component Library](#9-component-library)
10. [Navigation](#10-navigation)
11–28. [Màn hình 1–18](#11-màn-hình--splash-screen) (bao gồm các trạng thái)
29. [Hệ thống animation](#29-hệ-thống-animation)
30. [Âm thanh](#30-âm-thanh)
31. [Microcopy](#31-microcopy)
32. [Design Tokens](#32-design-tokens)
33. [Yêu cầu bàn giao](#33-yêu-cầu-bàn-giao-từ-uiux-designer)
34. [Prompt cho UI/UX Designer / AI Design Tool](#34-prompt-dành-cho-uiux-designer-hoặc-ai-design-tool)

---

## 1. Mục tiêu thiết kế

MI Academy phải tạo cảm giác như một **thế giới khám phá** dành cho trẻ em, không giống phần mềm học tập truyền thống.

| Mục tiêu | Nguyên tắc thực thi |
|----------|---------------------|
| Trẻ tự sử dụng | Mỗi màn hình chỉ **một hành động chính** rõ ràng |
| Nút bấm lớn, dễ hiểu | Chiều cao nút ≥ 56px, vùng chạm ≥ 48×48px |
| Hình nhiều hơn chữ | Ưu tiên icon, illustration, voice-over thay vì văn bản dài |
| Không thi cử | Không điểm số áp lực, không xếp hạng, không so sánh |
| Không gây nghiện | Không hiệu ứng kích thích quá mức, không confetti dày đặc, không jackpot |
| Độ tuổi 5–12 | Hỗ trợ cả mobile & tablet, portrait & landscape |
| An toàn | Không link ngoài, không chat, không mua hàng, không quảng cáo |

---

## 2. Phong cách hình ảnh

**Chủ đề chính:** *Colorful Learning Adventure*

- Hoạt hình 2D mềm mại, góc bo tròn.
- Màu tươi nhưng **không chói** (dùng tone pastel pha trắng).
- Nhân vật thân thiện, ít chi tiết gây rối.
- Animation nhẹ và **có mục đích** (không chuyển động nền liên tục).
- **Không** hình ảnh đáng sợ, **không** giao diện casino / máy quay thưởng.

**Cảm xúc cần truyền tải:** An toàn · Tò mò · Vui vẻ · Được khuyến khích · Có thể thử lại · Thành công từng bước nhỏ.

---

## 3. Hệ thống màu sắc

### Màu thương hiệu

| Tên | Hex | Dùng cho |
|-----|-----|----------|
| **MI Blue** | `#4A90E2` | Logo, nút chính, header, nhân vật MI |
| **Learning Purple** | `#7B61FF` | Tư duy, lập trình, khoa học |
| **Success Green** | `#4CAF73` | Hoàn thành, đáp án đúng, tiến độ tốt |
| **Sunny Yellow** | `#FFD45A` | Sao, phần thưởng, điểm nhấn |
| **Playful Orange** | `#FF9F43` | Nhiệm vụ mới, hoạt động sáng tạo |
| **Soft Red** | `#F26B6B` | Chỉ cảnh báo nhẹ / lỗi cần chú ý (không phạt) |

### Màu nền

| Tên | Hex | Dùng cho |
|-----|-----|----------|
| Light Sky | `#F4F9FF` | Nền app chung |
| Warm White | `#FFFDF7` | Nền ấm (khu sáng tạo) |
| Card White | `#FFFFFF` | Card, modal, popup |
| Soft Gray | `#E8EDF3` | Border, background phụ, divider |

### Màu chữ

| Tên | Hex | Dùng cho |
|-----|-----|----------|
| Primary Text | `#263238` | Nội dung chính |
| Secondary Text | `#607D8B` | Mô tả phụ |
| Disabled Text | `#AAB5BE` | Trạng thái vô hiệu |

### Quy tắc màu

1. **Không quá 4 màu nổi bật** trên một màn hình.
2. **Không dùng đỏ cho câu sai** — đáp án sai chuyển thành xám nhạt hoặc rung nhẹ (shake).
3. Mỗi môn học có **một màu nhận diện** riêng (xem mục 4).
4. Đảm bảo độ tương phản đủ (WCAG AA) cho trẻ thị lực yếu.

---

## 4. Màu theo khu vực học tập

| Khu vực | Màu chính | Icon | Cảm giác |
|---------|-----------|------|----------|
| **Thành phố chữ cái** | Cam `#FF9F43` + Vàng `#FFD45A` | Sách, chữ cái, bút chì | Ấm áp, sáng tạo |
| **Vương quốc toán học** | Xanh dương `#4A90E2` | Số, hình học, máy tính | Rõ ràng, thông minh |
| **Đảo tư duy** | Tím `#7B61FF` | Mê cung, bóng đèn, khối xếp | Bí ẩn, khám phá |
| **Phòng thí nghiệm** | Xanh lá `#4CAF73` | Kính hiển vi, ống nghiệm, hành tinh | Khoa học, tò mò |
| **Ngôi nhà sáng tạo** | Hồng cam `#FF7BA9`* | Cọ vẽ, âm nhạc, câu chuyện | Tự do, giàu tưởng tượng |
| **Khu vườn thành tích** | Xanh lá nhạt + Vàng | Cây, hoa, huy hiệu, ngôi sao | Phát triển, tự hào |

> *Hồng cam (Soft Pink-Orange) lấy tone dịu `#FF7BA9` để phân biệt với Playful Orange của "Thành phố chữ cái". Designer có thể tham khảo palette trong `screen-designs.md` (Pink `#F472B6`) và đồng bộ trước khi hand-off.

---

## 5. Typography

### Font chính (ưu tiên dễ đọc, chữ tròn, thân thiện)

- **Nunito** — body / nội dung.
- **Baloo 2** — tiêu đề (display).
- **Quicksand** — nhãn, UI nhỏ.
- **Atkinson Hyperlegible** — chế độ hỗ trợ đọc (high legibility mode).

> Flutter: dùng `GoogleFonts.nunito()`, `GoogleFonts.baloo2()`. Đảm bảo subset tiếng Việt.

### Kích thước chữ

| Loại | Mobile | Tablet | Weight |
|------|--------|--------|--------|
| Tiêu đề lớn | 28–32px | 36–44px | 700 |
| Tiêu đề màn hình | 22–26px | 28–34px | 700 |
| Nội dung chính | 17–19px | 20–24px | 500–600 |
| Nhãn nút | 18–20px | 22–26px | 700 |
| Nội dung phụ huynh | ≥14px (nhỏ hơn nhưng không <14px) | — | 400–500 |

### Quy tắc typography

- Không viết hoa toàn bộ cho nội dung dài.
- Không quá **3 dòng chữ** trong một card trẻ em.
- Câu hướng dẫn ngắn, không thuật ngữ khó.
- Kết hợp **icon + giọng nói** để giảm lượng chữ.

---

## 6. Hệ thống khoảng cách

Dùng **grid 8px**.

| Token | px | Dùng cho |
|-------|----|----------|
| xs | 4 | Khoảng cách rất nhỏ |
| sm | 8 | Giữa icon và chữ |
| md | 12 | Giữa các phần tử trong card |
| lg | 16 | Padding card nhỏ |
| xl | 24 | Padding card lớn |
| 2xl | 32 | Khoảng cách giữa các section |
| 3xl | 48 | Khoảng cách lớn giữa nhóm nội dung |

### Nút bấm cho trẻ

- Chiều cao tối thiểu: **56px**.
- Khuyến nghị: **64–72px**.
- Vùng chạm tối thiểu: **48×48px**.

---

## 7. Bo góc và đổ bóng

### Bo góc (radius)

| Thành phần | Radius |
|-----------|--------|
| Nút | 18–24px |
| Card | 20–28px |
| Modal | 28–32px |
| Icon container | Hình tròn (full) hoặc 18px |

### Đổ bóng

Dùng bóng mềm, blur lớn, opacity thấp — **không** tạo cảm giác nặng.

```css
/* Bóng card tiêu chuẩn */
box-shadow: 0 8px 24px rgba(38, 50, 56, 0.10);

/* Bóng nút khi hover / pressed */
box-shadow: 0 4px 12px rgba(74, 144, 226, 0.20);

/* Bóng modal */
box-shadow: 0 16px 48px rgba(38, 50, 56, 0.15);
```

**Không** dùng bóng quá tối hoặc đường viền sắc.

---

## 8. Nhân vật MI

### Ngoại hình

MI là **robot giáo viên nhỏ**, thân thiện:

- Đầu hơi tròn, thân nhỏ.
- Mắt lớn có biểu cảm.
- Hai tai giống bộ thu sóng.
- Màn hình nhỏ trên ngực.
- Tay chân đơn giản.
- **Không** giống robot chiến đấu, **không** cầm vũ khí, **không** chi tiết máy móc đáng sợ.

### Màu sắc

| Phần | Màu |
|------|-----|
| Thân | Trắng |
| Viền | Xanh dương `#4A90E2` |
| Điểm nhấn | Tím `#7B61FF` |
| Mắt | Xanh hoặc vàng |

### Biểu cảm cần có (Asset sheet)

| Biểu cảm | Ghi chú |
|----------|---------|
| Chào | Khi vào app / đổi profile |
| Vui | Khi trả lời đúng |
| Suy nghĩ | Đang chờ trẻ trả lời |
| Khuyến khích | Khi trẻ trả lời sai |
| Gợi ý | Khi MI đưa gợi ý |
| Ăn mừng | Khi hoàn thành bài |
| Ngạc nhiên | Phát hiện thú vị |
| Ngủ | Khi trẻ cần nghỉ |
| Nhắc nghỉ | Hết giới hạn thời gian |
| Xin lỗi | Khi hệ thống lỗi |

### Animation

- Nháy mắt, vẫy tay, bay nhẹ, gật đầu.
- Hiển thị bóng đèn khi đưa gợi ý.
- Xoay nhẹ khi ăn mừng.
- **Không** animation liên tục gây mất tập trung.

---

## 9. Component Library

### 9.1 Primary Button

**Dùng cho:** Bắt đầu · Tiếp tục · Chơi ngay · Hoàn thành

| Thuộc tính | Giá trị |
|-----------|---------|
| Chiều cao | 56–64px |
| Radius | 18–24px |
| Font | Baloo 2 / Nunito Bold, 18–22px |
| Màu nền | MI Blue `#4A90E2` hoặc Success Green `#4CAF73` |
| Màu chữ | White `#FFFFFF` |
| Icon | Bên trái (tùy chọn) |
| Hover / Press | Scale nhẹ (1.02) + bóng đậm hơn |
| Disabled | Nền Soft Gray, chữ Disabled Text |

### 9.2 Secondary Button

**Dùng cho:** Nghe lại · Gợi ý · Quay lại · Xem thêm

| Thuộc tính | Giá trị |
|-----------|---------|
| Nền | Transparent hoặc White |
| Border | 2px Soft Gray `#E8EDF3` |
| Chữ | MI Blue hoặc Primary Text |
| Hover | Nền Soft Gray nhẹ |

### 9.3 Icon Button

**Dùng cho:** Âm thanh · Tạm dừng · Trang chủ · Trợ giúp · Cài đặt

- Kích thước icon: ≥ 24px.
- Vùng chạm: ≥ 48×48px.
- **Phải** có tooltip hoặc voice label.

### 9.4 Lesson Card

| Thành phần | Mô tả |
|-----------|-------|
| Icon môn học | Màu theo khu vực |
| Tên bài | Bold 16–18px |
| Thời lượng | Ví dụ "3 phút" |
| Mức tiến độ | Progress bar tròn hoặc thanh |
| Trạng thái | Mới / Đang học / Hoàn thành |
| Hành động | Nút "Bắt đầu" hoặc "Tiếp tục" |

### 9.5 Game Card

| Thành phần | Mô tả |
|-----------|-------|
| Hình minh họa | 4:3 hoặc 1:1 |
| Tên trò chơi | Bold 18px |
| Độ tuổi phù hợp | Badge nhỏ |
| Số cấp độ | "3/10 cấp độ" |
| Biểu tượng offline | Cloud-check nếu đã tải |

### 9.6 Reward Card

| Thành phần | Mô tả |
|-----------|-------|
| Hình vật phẩm | Vuông, bo tròn |
| Tên vật phẩm | Bold 16px |
| Điều kiện | "Hoàn thành 5 bài Toán" |
| Trạng thái | Đã nhận (color) / Chưa nhận (grayscale) |

### 9.7 Progress Bar

- Hình dạng **tròn** (circle) hoặc **đường đi** (road/rocket thay cho con số).
- Animation nhẹ khi tăng.
- **Không** dùng số % quá nổi bật cho trẻ nhỏ.
- Thay thế: hình cây lớn dần, tên lửa tiến về đích, đường đi dài dần.

### 9.8 Avatar Selector

- Avatar hiển thị dạng **vòng tròn**.
- Mỗi avatar có trạng thái **được chọn** rõ ràng (viền màu + check).
- **Không** cho phép tải ảnh thật của trẻ ở MVP.

### 9.9 Modal

**Dùng cho:** Tạm dừng game · Thông báo hoàn thành · Chọn gợi ý · Xác nhận rời bài.

| Thuộc tính | Giá trị |
|-----------|---------|
| Overlay | `rgba(0,0,0,0.35)` |
| Radius | 28–32px |
| Padding | 24–32px |
| Chiều rộng tối đa | 400px (mobile) / 480px (tablet) |

**Không** dùng modal cho nội dung phức tạp.

---

## 10. Navigation

### Navigation dành cho trẻ

Sử dụng **bottom navigation** hoặc bản đồ trực quan.

| Mục | Icon | Ghi chú |
|-----|------|---------|
| Trang chủ | 🏠 | Bản đồ thế giới |
| Học | 📚 | Danh sách bài học |
| Chơi | 🎮 | Trò chơi tự do |
| Phần thưởng | ⭐ | Khu vườn, sticker, badge |
| Hồ sơ | 👤 | Avatar + tiến độ |

Tối đa **5 mục**.

### Navigation dành cho phụ huynh

Sử dụng **tab bar** hoặc sidebar:

| Mục | Ghi chú |
|-----|---------|
| Tổng quan | Dashboard hôm nay |
| Tiến độ | Biểu đồ theo môn |
| Thời gian | Phân tích thời gian |
| Nội dung | Quản lý bài đã tải |
| Cài đặt | Giới hạn, ngôn ngữ, PIN |

### Quy tắc

- Luôn có **nút quay về trang chủ**.
- Trong game phải có **nút pause**.
- Không để trẻ thoát ứng dụng bằng nhầm thao tác (confirm dialog).
- Khu vực phụ huynh **phải** có khóa PIN.

---

## 11. Màn hình — Splash Screen

### Thành phần

- Logo MI Academy.
- Nhân vật MI (animation xuất hiện).
- Thanh loading.
- Trạng thái tải nội dung.

### Nội dung

> "Chào mừng đến với MI Academy."

### Hành vi

1. Hiển thị tối thiểu **1.5 giây**, MI bounce + blink animation.
2. Nếu chưa có hồ sơ → **Onboarding**.
3. Nếu đã có hồ sơ → **Chọn người học**.
4. Nếu offline → sử dụng dữ liệu cục bộ.
5. Fade out khi chuyển màn.
6. Ẩn status bar.

---

## 12. Màn hình — Onboarding phụ huynh

### Slide 1 — Học qua chơi

> Tiêu đề: "Học qua chơi."  
> Mô tả: "Bài học ngắn, trò chơi vui và phù hợp với từng độ tuổi."

### Slide 2 — An toàn cho trẻ

> Tiêu đề: "An toàn cho trẻ."  
> Mô tả: "Không quảng cáo, không mua hàng và không trò chuyện với người lạ."

### Slide 3 — Phụ huynh luôn kiểm soát

> Tiêu đề: "Phụ huynh luôn kiểm soát."  
> Mô tả: "Theo dõi tiến độ và đặt giới hạn thời gian sử dụng."

### Hành động

- **Bắt đầu** (Primary Button).
- **Đăng nhập** (Secondary Button).
- **Dùng thử offline** (Text Button).

### Spec

- 3 slide swipe ngang.
- Nút Skip.
- Lottie animation cho mỗi slide.
- Dot indicator.

---

## 13. Màn hình — Tạo hồ sơ trẻ

### Flow (5 bước)

| Bước | Nội dung | Thành phần UI |
|------|----------|---------------|
| 1 | Chọn biệt danh | Text input lớn, avatar placeholder |
| 2 | Chọn độ tuổi | 3 nút lớn: "5–7" · "8–10" · "11–12" |
| 3 | Chọn nhân vật | Grid avatar (8–12 lựa chọn) |
| 4 | Chọn môn yêu thích | 5 nút icon: Chữ · Toán · Tư duy · Khoa học · Sáng tạo |
| 5 | Chọn ngôn ngữ | 3 nút: Tiếng Việt · English · Song ngữ |

### Hành vi

- MI đọc hướng dẫn (voice-over).
- Phụ huynh có thể **bỏ qua** bước 4.
- Không yêu cầu ngày sinh đầy đủ.
- Nút "Tiếp" lớn ở cuối mỗi bước.

---

## 14. Màn hình — Chọn người học

### Thành phần

- Danh sách hồ sơ trẻ (grid 2 cột mobile, 3 cột tablet).
- Avatar lớn (hình tròn viền màu theo age group).
- Tên / biệt danh.
- Tiến độ hôm nay (mini badge).
- Nút "+" thêm hồ sơ (hiện khi < 5 hồ sơ).
- Nút phụ huynh góc phải dưới.

### Hành vi

Khi trẻ chọn hồ sơ:
1. MI chào theo tên.
2. Hiển thị "nhiệm vụ hôm nay" brief.
3. Cho phép **tiếp tục bài đang dở**.

---

## 15. Màn hình — Home World Map

> **Đây là màn hình quan trọng nhất.** Xem chi tiết wireframe tại [docs/screen-designs.md § World Map](./screen-designs.md#3-world-map-screen-màn-hình-chính).

### Bố cục

Một bản đồ có thể **cuộn ngang hoặc dọc**, chứa 6 khu vực:

1. Thành phố chữ cái 🏙️
2. Vương quốc toán học 🏰
3. Đảo tư duy 🧩
4. Phòng thí nghiệm 🔬
5. Ngôi nhà sáng tạo 🎨
6. Khu vườn thành tích 🌳

### Thành phần trên cùng

- Avatar nhỏ + biệt danh.
- Sao MI (⭐ tổng).
- Thời gian còn lại trong ngày (nếu phụ huynh đặt giới hạn).
- Nút phụ huynh (icon khóa).

### Hành vi

- Khu vực **chưa mở khóa** vẫn nhìn thấy — dùng **mây / cầu chưa hoàn thành** thay vì ổ khóa quá tiêu cực.
- Khi chạm khu vực → MI giới thiệu bằng âm thanh + animation.
- Bottom navigation: 🏠 📚 🎮 ⭐ 👤.
- Bong bóng "mới" khi có bài học mới.

---

## 16. Màn hình — Nhiệm vụ hôm nay

### Thành phần

Tối đa **4 nhiệm vụ**:

| # | Nhiệm vụ | Ví dụ |
|---|----------|-------|
| 1 | Một bài chữ | Ghép chữ cái |
| 2 | Một bài toán | Phép cộng |
| 3 | Một trò tư duy | Mê cung |
| 4 | Một hoạt động tùy chọn | Vẽ / Nghe nhạc |

### Mỗi nhiệm vụ có

- Icon (màu theo khu vực).
- Tên.
- Thời lượng (ví dụ "3 phút").
- Mức độ (dễ / vừa / khó — hiển thị bằng sao hoặc emoji).
- Phần thưởng (sao, sticker, badge).
- Nút **Bắt đầu**.

### Tiến độ tổng

Dùng hình **con đường** hoặc **tên lửa** thay vì bảng điểm.

### Hành vi

- Trẻ có thể chọn **thứ tự**.
- **Không bắt buộc** hoàn thành toàn bộ.
- Khi hoàn thành **3 hoạt động**, MI đề nghị nghỉ.

---

## 17. Màn hình — Danh sách bài học

### Bộ lọc

- Theo chủ đề.
- Theo độ tuổi.
- Theo mức độ.
- Đã tải offline.
- Đang học.
- Đã hoàn thành.

### Card bài học

| Thành phần | Mô tả |
|-----------|-------|
| Hình minh họa | Vuông bo tròn |
| Tên bài | Bold 16px |
| Thời gian | "3 phút" |
| Số hoạt động | "5 activities" |
| Tiến độ | Bar hoặc dot |
| Trạng thái tải | Cloud-download icon |

### Empty state

> "MI chưa tìm thấy bài phù hợp. Hãy thử một chủ đề khác nhé."

---

## 18. Màn hình — Game chung

> Xem wireframe chi tiết tại [docs/screen-designs.md § Game Screen](./screen-designs.md#6-game-screen-common-layout).

### Header

- Nút pause ⏸.
- Tên bài.
- Tiến độ dạng **chấm** (● ● ○ ○ ○).
- Nút âm thanh 🔊.

### Main area (70% chiều cao)

- Nội dung game.
- Hình minh họa lớn.
- Vùng tương tác.
- Hướng dẫn bằng giọng nói (auto play).

### Footer

- Nút **Gợi ý** 💡.
- Nút **Nghe lại** 🔁.
- Nút **Kiểm tra** ✅ (nếu game cần xác nhận).

### Quy tắc

- **Không** đồng hồ đếm ngược cho nhóm 5–7.
- Nhóm lớn hơn chỉ dùng timer trong chế độ tùy chọn.
- Animation đúng tối đa **2 giây**.
- Sai → MI gợi ý + cho thử lại (**không** trừ điểm, **không** màu đỏ).

---

## 19. Màn hình — Kết quả bài học

### Thành phần

- MI ăn mừng 🎉.
- Kỹ năng vừa học.
- Số hoạt động hoàn thành.
- Vật phẩm nhận được (badge / sticker / sao).
- Nút **Chơi lại**.
- Nút **Về bản đồ**.
- Nút **Tiếp tục bài tiếp theo**.

### Không hiển thị

- Xếp hạng / so sánh với trẻ khác.
- Thông báo thất bại.
- Màu đỏ lớn.
- Điểm số gây áp lực.

### Ví dụ nội dung

> "Hôm nay con đã biết cách ghép âm đầu với vần."

> "Con đã thử ba cách khác nhau để giúp robot tìm đường."

---

## 20. Màn hình — Phần thưởng

### Khu vực phần thưởng

| Khu vực | Ví dụ |
|---------|-------|
| Huy hiệu | "Học trò siêng năng" |
| Sticker | Sticker pack theo chủ đề |
| Quần áo | Trang phục cho avatar |
| Khu vườn | Cây, hoa cho vườn ảo |
| Phòng của MI | Đồ trang trí |
| Truyện mở khóa | Câu chuyện tương tác |

### Hành vi

- Trẻ có thể **trang trí phòng** MI.
- Có **preview** trước khi sử dụng vật phẩm.
- **Không** có phần thưởng ngẫu nhiên.
- **Không** có vật phẩm hiếm để tạo cạnh tranh.

---

## 21. Màn hình — Khu vườn thành tích

Mỗi kỹ năng là một **loại cây**:

| Cây | Kỹ năng |
|-----|---------|
| 🌳 Cây chữ cái | Ngôn ngữ |
| 🌲 Cây phép tính | Toán |
| 🌴 Cây tư duy | Logic |
| 🌱 Cây khoa học | Khoa học |
| 🌺 Cây sáng tạo | Sáng tạo |

- Cây phát triển khi trẻ học đều và tiến bộ.
- **Không** làm cây héo nếu trẻ nghỉ học — cây giữ nguyên trạng thái.

---

## 22. Màn hình — Parent Gate

### Cách mở (bất kỳ phương thức nào dưới đây)

- Nhập **PIN 4 số**.
- Face ID.
- Touch ID.
- Giải **phép tính đơn giản** dành cho người lớn (fallback nếu thiết bị không hỗ trợ biometric).

### Nội dung cảnh báo

> "Phần này dành cho phụ huynh."

### Bảo vệ

- **Không** để trẻ tự thay đổi giới hạn thời gian.
- **Không** hiển thị email hoặc thông tin tài khoản trong child mode.
- **Tự khóa lại** sau thời gian không hoạt động (ví dụ: 60 giây).
- Sau 3 lần nhập sai → lockout 30 giây + nền đỏ nhạt.

---

## 23. Màn hình — Parent Dashboard (Tổng quan)

### Tổng quan

Hiển thị:

| Metric | Mô tả |
|--------|-------|
| Thời gian học hôm nay | Tổng phút |
| Số bài hoàn thành | Đếm |
| Môn trẻ tham gia nhiều | Top 1–2 |
| Kỹ năng đang phát triển | Theo radar |
| Nội dung cần luyện thêm | Gợi ý |
| Hoạt động đề xuất | In-app + offline |

### Biểu đồ

Dùng biểu đồ **đơn giản** — ưu tiên dễ hiểu:

- Số phút học theo ngày (bar chart 7 ngày).
- Tiến độ theo môn (stacked bar / circle).
- Mức độ thành thạo (radar 5 trục).
- Số bài hoàn thành (đếm).

**Không** dùng biểu đồ quá phức tạp (không heatmap nhiều chiều).

### Navigation

Tab bar 4–5 tab: Tổng quan · Tiến độ · Thời gian · Nội dung · Cài đặt.

### Font

14–16sp (khác font trẻ em — dùng Inter / Nunito Sans cho phụ huynh).

---

## 24. Màn hình — Báo cáo tuần

### Nội dung

| Mục | Mô tả |
|-----|-------|
| Tổng thời gian học | Phút / tuần |
| Số buổi học | Đếm |
| Bài học đã hoàn thành | Danh sách |
| Kỹ năng mới | Đạt được tuần này |
| Kỹ năng cần ôn | Dưới ngưỡng |
| Mức độ tương tác | Tương quan thời gian |
| Hoạt động ngoài màn hình | Đề xuất |

### Ví dụ đề xuất hoạt động ngoài màn hình

- Đếm số trái cây trong bếp.
- Tìm năm đồ vật bắt đầu bằng chữ B.
- Đo chiều dài bàn bằng thước.
- Sắp xếp đồ vật theo kích thước.

---

## 25. Màn hình — Cài đặt phụ huynh

### Tài khoản

- Email.
- Đổi mật khẩu.
- Đổi PIN.
- Quản lý thiết bị.

### Trẻ em

- Chỉnh sửa hồ sơ (qua PIN).
- Độ tuổi.
- Lớp.
- Ngôn ngữ.
- Mục tiêu học.

### Thời gian

- Giới hạn mỗi ngày (15/30/45/60 phút).
- Lịch nghỉ (ngày không cho dùng).
- Nhắc nghỉ mắt (sau 20 phút).
- Khoảng thời gian cho phép sử dụng (ví dụ 17:00–19:00).

### Nội dung

- Chọn môn được phép.
- Chọn độ khó.
- Tải nội dung offline.
- Xóa nội dung đã tải.

### Quyền riêng tư

- Xuất dữ liệu.
- Xóa dữ liệu.
- Quyền microphone.
- Quyền camera.
- Chính sách quyền riêng tư.

---

## 26. Trạng thái hệ thống

Mỗi màn hình cần có các trạng thái:

### Loading

> "MI đang chuẩn bị bài học..."

- Animation nhẹ (MI bouncing).
- **Không** để màn hình trắng.

### Empty

> "MI chưa tìm thấy bài phù hợp. Hãy thử một chủ đề khác nhé."

- Thông báo thân thiện.
- Có hành động tiếp theo rõ ràng (CTA).

### Error

> "MI chưa tải được bài này. Con có thể thử lại hoặc chọn một bài khác."

- Nút **Thử lại** (Primary).
- Nút **Chọn bài khác** (Secondary).

### Offline

- Icon offline nhỏ ở góc phải header.
- **Không** làm gián đoạn nếu nội dung đã tải.
- Đồng bộ tự động khi có Internet.

### Syncing

- Trạng thái nhỏ (badge).
- **Không** khóa giao diện.
- **Không** làm mất dữ liệu.

---

## 27. Accessibility

### Hỗ trợ thị giác

- Chế độ **tương phản cao**.
- Chế độ **chữ lớn**.
- **Không** phụ thuộc hoàn toàn vào màu sắc (luôn có icon + text đi cùng).
- Hỗ trợ **screen reader** (TalkBack / VoiceOver).

### Hỗ trợ đọc

- **Giọng đọc hướng dẫn** rõ, chậm.
- **Highlight** từng từ khi đọc.
- Điều chỉnh **tốc độ đọc**.
- Chế độ **font dễ đọc** (Atkinson Hyperlegible).
- **Tắt animation** trong cài đặt.

### Hỗ trợ vận động

- **Vùng chạm lớn** (≥ 48×48px).
- **Không** yêu cầu thao tác quá chính xác.
- Có tùy chọn **chạm thay cho kéo thả**.
- **Không** yêu cầu phản xạ nhanh.

### Hỗ trợ âm thanh

- **Phụ đề** cho mọi voice-over.
- **Rung nhẹ** tùy chọn.
- **Ký hiệu hình ảnh** cho âm thanh (icon 🔊 bên cạnh lời thoại).
- Điều chỉnh **âm lượng giọng nói và hiệu ứng** riêng biệt.

### Tuân thủ

- WCAG 2.1 **AA** làm mục tiêu tối thiểu.
- Đối với nhóm 5–7: voice-over gần như **bắt buộc**.
- Tất cả tương tác quan trọng phải có **text alternative**.

---

## 28. Responsive Design

### Mobile dọc (Portrait)

Phù hợp cho:

- Onboarding.
- Chọn hồ sơ.
- Bài học chữ.
- Dashboard phụ huynh.

### Mobile ngang (Landscape)

Phù hợp cho các game cần không gian ngang:

| Game | Lý do landscape |
|------|-----------------|
| 🏎️ Game đua xe | Đường đua rộng |
| 🤖 Robot command | Bàn lệnh rộng |
| 🌀 Mê cung | Bản đồ rộng |
| 🧱 Xây hình | Lưới rộng |

### Tablet

- Tận dụng nhiều không gian.
- Hiển thị **hướng dẫn và game cùng lúc** (split view).
- **Không** kéo giãn nội dung quá rộng.
- **Giới hạn chiều rộng nội dung chính** (max-width: 720px cho text, 960px cho card game).

### Web

- Tập trung vào **tablet và desktop nhỏ**.
- **Không** thiết kế như dashboard doanh nghiệp.
- Vẫn giữ **trải nghiệm trẻ em** (nút lớn, màu tươi).

### Breakpoints (tham khảo)

| Tên | Width | Thiết bị |
|-----|-------|----------|
| xs | < 600px | Phone portrait |
| sm | 600–840px | Phone landscape / Tablet nhỏ |
| md | 840–1024px | Tablet portrait |
| lg | 1024–1280px | Tablet landscape / Desktop nhỏ |
| xl | > 1280px | Desktop lớn (giới hạn nội dung) |

---

## 29. Hệ thống animation

### Animation được phép

- Nhân vật vẫy tay.
- Nút scale nhẹ (1.0 → 1.02 → 1.0).
- Sao bay nhẹ (lên + xuống).
- Cây lớn lên (scale Y + fade in).
- Xe tiến về phía trước.
- Robot di chuyển.
- Card xuất hiện mềm mại (slide-up + fade).

### Thời lượng

| Loại | Duration |
|------|----------|
| Micro interaction | 150–250ms |
| Chuyển màn hình | 250–400ms |
| Ăn mừng | Tối đa 2 giây |
| Tutorial animation | Tối đa 5 giây, có thể bỏ qua |

### Easing

- `easeOutCubic` cho entrance.
- `easeInOut` cho loop.
- **Tránh** `linear` (gây cảm giác robot).

### Không sử dụng

- Nhấp nháy (flash > 3Hz).
- Rung mạnh (shake quá 4px).
- Zoom liên tục.
- Confetti quá nhiều (> 30 hạt / lần).
- Animation không thể tắt.
- Chuyển động nền liên tục (parallax vô tận).

---

## 30. Âm thanh

### Các lớp âm thanh

| Lớp | Ví dụ |
|------|-------|
| Giọng MI | Đọc hướng dẫn, khen |
| Nhạc nền | Loop nhẹ (tắt được) |
| Hiệu ứng game | Tap, success, drag-drop |
| Âm báo hoàn thành | Melody ngắn |
| Âm báo gợi ý | "Bing" nhẹ |

### Quy tắc

- **Nhạc nền mặc định** nhỏ (volume ≤ 30%).
- **Không** tự phát âm thanh lớn.
- Có thể **tắt từng loại** âm thanh.
- Giọng đọc **rõ và chậm**.
- **Không** dùng giọng gây căng thẳng.
- **Không** dùng âm thanh thất bại.

---

## 31. Microcopy

### Khi bắt đầu

> "Cùng MI khám phá bài mới nhé."

### Khi đúng

- "Chính xác!"
- "Con đã tìm ra rồi."
- "Cách làm rất thông minh."

### Khi sai

- "Gần đúng rồi."
- "Mình thử một cách khác nhé."
- "MI sẽ cho con một gợi ý."

### Khi hoàn thành

- "Con đã hoàn thành nhiệm vụ hôm nay."
- "Con vừa giúp khu vườn lớn thêm một chút."

### Khi cần nghỉ

> "Chúng ta đã học được nhiều rồi. Mắt và cơ thể cũng cần nghỉ nhé."

### Khi mất mạng

> "Không có Internet cũng không sao. MI vẫn còn các bài đã tải."

### Tone & voice

- Xưng "MI" và gọi trẻ là "con".
- Câu ngắn (≤ 12 từ).
- Tránh động từ mạnh ("phải", "bắt buộc").
- Dùng động từ nhẹ ("thử", "cùng", "khám phá").

---

## 32. Design Tokens

### 32.1 Bảng token (JSON — xem file `design-tokens.json` đi kèm)

```json
{
  "colors": {
    "brandPrimary": "#4A90E2",
    "brandSecondary": "#7B61FF",
    "success": "#4CAF73",
    "reward": "#FFD45A",
    "creative": "#FF9F43",
    "softError": "#F26B6B",
    "background": "#F4F9FF",
    "backgroundWarm": "#FFFDF7",
    "surface": "#FFFFFF",
    "border": "#E8EDF3",
    "textPrimary": "#263238",
    "textSecondary": "#607D8B",
    "textDisabled": "#AAB5BE"
  },
  "radius": {
    "small": 12,
    "medium": 20,
    "large": 28,
    "full": 999
  },
    "spacing": {
    "xs": 4,
    "sm": 8,
    "md": 12,
    "lg": 16,
    "xl": 24,
    "xxl": 32,
    "xxxl": 48
  },
  "buttonHeight": {
    "small": 48,
    "medium": 56,
    "large": 64
  },
  "font": {
    "display": "Baloo 2",
    "body": "Nunito",
    "label": "Quicksand",
    "legibility": "Atkinson Hyperlegible"
  },
  "shadow": {
    "card": "0 8px 24px rgba(38, 50, 56, 0.10)",
    "button": "0 4px 12px rgba(74, 144, 226, 0.20)",
    "modal": "0 16px 48px rgba(38, 50, 56, 0.15)"
  }
}
```

### 32.2 Zone màu theo khu vực (area tokens)

| Token | Hex | Khu vực |
|-------|-----|---------|
| `areaLetters` | `#FF9F43` / `#FFD45A` | Thành phố chữ cái |
| `areaMath` | `#4A90E2` | Vương quốc toán học |
| `areaLogic` | `#7B61FF` | Đảo tư duy |
| `areaScience` | `#4CAF73` | Phòng thí nghiệm |
| `areaCreative` | `#FF7BA9` | Ngôi nhà sáng tạo |
| `areaGarden` | `#A8E6A1` / `#FFD45A` | Khu vườn thành tích |

---

## 33. Yêu cầu bàn giao từ UI/UX Designer

Designer phải bàn giao:

1. **Logo MI Academy** — vector (SVG) + favicon.
2. **Nhân vật MI** — 10 biểu cảm + Rive/Lottie source.
3. **Color system** — palette chuẩn + area colors.
4. **Typography system** — font files + scale sheet.
5. **Component library** — Figma components (button, card, modal, toggle...).
6. **Mobile design** — portrait full flow.
7. **Tablet design** — split view.
8. **Landscape game design** — 4 game ngang.
9. **Parent dashboard** — 5 tab.
10. **Empty states** — mọi danh sách rỗng.
11. **Error states** — mọi màn hình.
12. **Offline states** — badge + banner.
13. **Loading states** — skeleton + MI animation.
14. **Animation specifications** — duration, easing, trigger.
15. **Asset export** — @1x/2x/3x, SVG, Lottie.
16. **Design tokens** — file `design-tokens.json`.
17. **Prototype luồng chính** — click-through flow.
18. **Accessibility notes** — contrast report, screen-reader labels.

### Checklist bàn giao (tick-list)

- [ ] Mọi text đều có text-alternative / voice label.
- [ ] Contrast ≥ 4.5:1 (WCAG AA).
- [ ] Tất cả touch target ≥ 48×48px.
- [ ] Dark pattern check: không countdown gây áp lực, không jackpot.
- [ ] Offline mode đã cover mọi màn hình.

---

## 34. Prompt dành cho UI/UX Designer hoặc AI Design Tool

```
Bạn là Senior Product Designer chuyên thiết kế ứng dụng giáo dục an toàn cho trẻ em.

Hãy thiết kế MI Academy, một ứng dụng học qua chơi miễn phí, không quảng cáo,
dành cho trẻ từ 5 đến 12 tuổi.

Ứng dụng gồm:
- Học chữ.
- Toán học.
- Tư duy logic.
- Khoa học.
- Sáng tạo.
- 30 mini-game.
- Nhân vật robot MI.
- Bản đồ thế giới học tập.
- Khu vực phụ huynh.
- Báo cáo tiến độ.
- Chế độ offline.

Phong cách:
- Hoạt hình 2D.
- Màu tươi nhưng dịu.
- Bo góc lớn.
- Nút lớn.
- Ít chữ.
- Hình ảnh thân thiện.
- Không tạo cảm giác thi cử.
- Không dùng giao diện casino.
- Không dùng dark pattern.
- Không quảng cáo.
- Không mua hàng.

Hãy thiết kế đầy đủ các màn hình:
1. Splash screen.
2. Parent onboarding.
3. Create child profile.
4. Select learner.
5. Learning world map.
6. Daily missions.
7. Lesson list.
8. Game screen.
9. Lesson result.
10. Rewards.
11. Achievement garden.
12. Parent gate.
13. Parent dashboard.
14. Weekly report.
15. Parent settings.
16. Offline state.
17. Loading state.
18. Error state.

Yêu cầu:
- Thiết kế mobile và tablet.
- Có phiên bản portrait và landscape.
- Có design system.
- Có component library.
- Có design tokens.
- Có prototype luồng chính.
- Đảm bảo accessibility.
- Không phụ thuộc hoàn toàn vào màu sắc.
- Nút tối thiểu 48 x 48 px.
- Có tùy chọn chữ lớn.
- Có giọng hướng dẫn.
- Có phụ đề.
- Có thể tắt animation.
- Không để trẻ truy cập liên kết ngoài.

Luồng prototype bắt buộc:
1. Phụ huynh tạo hồ sơ trẻ.
2. Trẻ chọn avatar.
3. Trẻ vào bản đồ.
4. Trẻ chọn nhiệm vụ.
5. Trẻ chơi game.
6. Trẻ nhận phần thưởng.
7. Phụ huynh xem báo cáo.

Hãy ưu tiên trải nghiệm đơn giản, an toàn, vui vẻ và có thể sử dụng độc lập bởi trẻ em.
```

---

## Phụ lục — Ánh xạ tài liệu

| Tài liệu | Nội dung |
|----------|----------|
| [README.md](./README.md) | Tổng quan dự án |
| [PRD.md](../PRD.md) | Yêu cầu sản phẩm |
| [docs/screen-designs.md](./screen-designs.md) | Wireframe ASCII 13 màn hình MVP |
| [docs/mvp-games-spec.md](./mvp-games-spec.md) | Spec 6 game MVP |
| [docs/user-flow.md](./user-flow.md) | User flow + wireframe |
| [docs/tech-architecture.md](./tech-architecture.md) | Kiến trúc kỹ thuật (Flutter) |
| **docs/ui-ux-design-system.md** | **Tài liệu thiết kế hệ thống này** |
| **docs/design-tokens.json** | **Token máy đọc được** |

---

## Phụ lục B — Flutter ThemeData (Theme Extension)

> Dùng làm base để implement design tokens vào Flutter. Copy vào `lib/theme/mi_theme.dart`. Token values từ `design-tokens.json`.

```dart
import 'package:flutter/material.dart';

/// MI Academy Design Tokens → Flutter ThemeData
/// Dựa trên docs/design-tokens.json v1.0
class MITokens {
  // ── Colors ────────────────────────────────────────────────────────────────
  static const brandPrimary   = Color(0xFF4A90E2);
  static const brandSecondary = Color(0xFF7B61FF);
  static const success        = Color(0xFF4CAF73);
  static const reward         = Color(0xFFFFD45A);
  static const creative       = Color(0xFFFF9F43);
  static const softError      = Color(0xFFF26B6B);
  static const bgDefault      = Color(0xFFF4F9FF);
  static const bgWarm         = Color(0xFFFFFDF7);
  static const surface        = Color(0xFFFFFFFF);
  static const border         = Color(0xFFE8EDF3);
  static const textPrimary    = Color(0xFF263238);
  static const textSecondary  = Color(0xFF607D8B);
  static const textDisabled   = Color(0xFFAAB5BE);

  // Area colors
  static const areaLetters   = Color(0xFFFF9F43);
  static const areaMath      = Color(0xFF4A90E2);
  static const areaLogic     = Color(0xFF7B61FF);
  static const areaScience   = Color(0xFF4CAF73);
  static const areaCreative  = Color(0xFFFF7BA9);
  static const areaGarden    = Color(0xFFA8E6A1);

  // ── Radius ───────────────────────────────────────────────────────────────
  static const rSmall  = 12.0;
  static const rMedium = 20.0;
  static const rLarge  = 28.0;
  static const rFull   = 999.0;

  // ── Spacing (8px grid) ─────────────────────────────────────────────────
  static const sp = 4.0;   // xs
  static const sm = 8.0;   // sm
  static const md = 12.0;  // md
  static const lg = 16.0;  // lg
  static const xl = 24.0;  // xl
  static const xxl= 32.0;  // xxl
  static const xxxl=48.0;  // xxxl

  // ── Button heights ─────────────────────────────────────────────────────
  static const btnSm = 48.0;
  static const btnMd = 56.0;
  static const btnLg = 64.0;

  // ── Shadows ────────────────────────────────────────────────────────────
  static BoxShadow shadowCard  = BoxShadow(0, 8, 24, Color(0x1A263238));
  static BoxShadow shadowBtn   = BoxShadow(0, 4, 12, Color(0x334A90E2));
  static BoxShadow shadowModal = BoxShadow(0, 16, 48, Color(0x26263238));
}

/// Flutter ThemeData — gắn MITokens vào MaterialApp
ThemeData miLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: MITokens.bgDefault,
    colorScheme: ColorScheme.light(
      primary:   MITokens.brandPrimary,
      secondary: MITokens.brandSecondary,
      surface:   MITokens.surface,
      error:     MITokens.softError,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: MITokens.textPrimary,
    ),
    // Typography — dùng GoogleFonts ( Baloo 2, Nunito, Quicksand )
    textTheme: const TextTheme(
      displayLarge:  TextStyle(fontFamily: 'Baloo 2',   fontWeight: FontWeight.w700, fontSize: 28, color: MITokens.textPrimary),
      displayMedium: TextStyle(fontFamily: 'Baloo 2',   fontWeight: FontWeight.w700, fontSize: 22, color: MITokens.textPrimary),
      bodyLarge:     TextStyle(fontFamily: 'Nunito',     fontWeight: FontWeight.w500, fontSize: 17, color: MITokens.textPrimary),
      bodyMedium:    TextStyle(fontFamily: 'Nunito',     fontWeight: FontWeight.w400, fontSize: 15, color: MITokens.textSecondary),
      labelLarge:    TextStyle(fontFamily: 'Quicksand', fontWeight: FontWeight.w700, fontSize: 18, color: MITokens.textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, MITokens.btnMd),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MITokens.rMedium)),
        backgroundColor: MITokens.brandPrimary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontFamily: 'Baloo 2', fontWeight: FontWeight.w700, fontSize: 18),
      ),
    ),
    cardTheme: CardTheme(
      color: MITokens.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MITokens.rMedium)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: MITokens.surface,
      selectedItemColor: MITokens.brandPrimary,
      unselectedItemColor: MITokens.textSecondary,
      type: BottomNavigationBarType.fixed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: MITokens.bgDefault,
      foregroundColor: MITokens.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
  );
}
```

---

## Phụ lục C — Component State Matrix

Bảng trạng thái cho mỗi component chính.

### C.1 Primary Button

| Trạng thái | Nền | Chữ | Bóng | Scale | Khác |
|-----------|------|------|------|-------|------|
| Default | `#4A90E2` | White | shadowBtn | 1.0 | Icon trái (tùy) |
| Hover | `#3A7FCC` | White | shadowBtn đậm | 1.02 | — |
| Pressed | `#2A6FBB` | White | shadowBtn nhạt | 0.98 | — |
| Disabled | `#E8EDF3` | `#AAB5BE` | none | 1.0 | Pointer-none |
| Loading | `#4A90E2` | White + spinner | shadowBtn | 1.0 | Text ẩn |

### C.2 Lesson Card

| Trạng thái | Border | Opacity | Badge |
|-----------|--------|---------|-------|
| Mới | `#FFD45A` 2px | 1.0 | "Mới" vàng |
| Đang học | `#4A90E2` 2px | 1.0 | Progress bar |
| Hoàn thành | none | 1.0 | ⭐⭐⭐ |
| Khóa (chưa ready) | none | 0.55 | Cloud/silhouette |

### C.3 Progress Bar

| Trạng thái | Màu thanh | Màu nền | Animation |
|-----------|-----------|---------|-----------|
| 0% | — | `#E8EDF3` | none |
| Đang tiến | Gradient area color | `#E8EDF3` | Slide right 300ms |
| 100% | `#4CAF73` | `#E8EDF3` | Scale pulse 1.05→1.0 |

### C.4 Avatar Selector

| Trạng thái | Border | Checkmark | Scale |
|-----------|--------|-----------|-------|
| Default | none | hidden | 1.0 |
| Hover | `#4A90E2` 2px | hidden | 1.03 |
| Selected | `#4A90E2` 3px | ✅ hiện | 1.05 |

### C.5 Modal

| Trạng thái | Overlay | Animation vào | Animation ra |
|-----------|---------|-------------|------------|
| Opening | `rgba(0,0,0,0.35)` | Scale 0.9→1.0 + fade 300ms | Scale 1.0→0.95 + fade 200ms |
| Closing | `rgba(0,0,0,0.35)` | — | Scale 0.95→0.9 + fade 200ms |

---

## Phụ lục D — Responsive Layout Spec

Hướng dẫn layout cụ thể cho từng màn hình theo thiết bị.

### D.1 World Map (Screen 15)

| | Mobile Portrait | Mobile Landscape | Tablet Portrait | Tablet Landscape |
|--|----------------|-----------------|-----------------|-----------------|
| **Layout** | Cuộn dọc, 2 cột khu vực | Cuộn ngang | Grid 3×2 | Grid 3×2 + sidebar MI |
| **Khu vực mỗi ô** | 160×120px | 200×160px | 240×180px | 280×200px |
| **Avatar header** | Trên cùng full-width | Trên cùng compact | Trên cùng | Sidebar trái |
| **Bottom nav** | 5 icon + label | Thu gọn icon | 5 icon + label | Ẩn, dùng sidebar |
| **MI character** | Bên dưới bản đồ | Bên phải | Bên phải bản đồ | Tách sidebar 240px |

### D.2 Game Screen (Screen 18)

| | Mobile Portrait | Mobile Landscape | Tablet Portrait | Tablet Landscape |
|--|----------------|-----------------|-----------------|-----------------|
| **Header** | Sticky, 56px | Sticky, 48px compact | Sticky, 64px | Sticky, 64px |
| **Game area** | 65% chiều cao | 70% chiều cao | 60% chiều cao | 80% chiều rộng |
| **MI hint zone** | Dưới game, 80px | Bên phải, 120px | Dưới game, 100px | Bên phải, 160px |
| **Footer controls** | 2 hàng nút | 1 hàng ngang | 2 hàng nút | 1 hàng dọc |
| **Pause overlay** | Full-screen modal | Full-screen modal | Centered modal 400px | Centered modal 480px |

### D.3 Parent Dashboard (Screen 23)

| | Mobile Portrait | Tablet |
|--|----------------|--------|
| **Navigation** | Tab bar 5 tab cuộn ngang | Sidebar cố định 240px |
| **Metric card** | Full-width stack | Grid 2 cột |
| **Bar chart** | Full-width, 240px cao | 360×240px |
| **Radar chart** | 280×280px center | 360×360px |
| **Font size** | 14–16sp | 16–18sp |

### D.4 Avatar Selector & Profile Creation (Screen 13–14)

| | Mobile Portrait | Tablet |
|--|----------------|--------|
| **Layout** | Cuộn dọc, 1 cột | Cuộn ngang, grid 4×3 |
| **Avatar size** | 80px | 120px |
| **Spacing** | 16px gap | 24px gap |
| **Input height** | 64px | 72px |
| **Age button grid** | 3 nút full-width | 3 nút 200px mỗi |

### D.5 Parent Settings (Screen 25)

| | Mobile Portrait | Tablet |
|--|----------------|--------|
| **Layout** | Full-width list | 2 cột (danh sách + preview) |
| **Row height** | 64px | 72px |
| **Switch toggle** | 48×28px | 56×32px |

---

## Phụ lục E — Nhân vật MI: Proportions Grid & Asset Spec

> Dùng cho designer vẽ và export nhân vật MI. Đơn vị: pixel (px) trên base 512×512.

### E.1 Proportions Grid

```
            ┌────────┐
            │  EARS  │  ← 2 bộ thu sóng (antenna), cao 64px
            ├───┬────┤
            │   │    │
            │ H │    │  ← Đầu: 256×220px, viền xanh #4A90E2
            │ E │    │     Mắt: 64×64px mỗi, đặt ở 1/3 trên
            │ A │    │
            │ D │    │
            ├───┼────┤
            │ BODY │  ← Thân: 200×180px
            │      │    Màn hình ngực: 80×60px, màu #7B61FF
            │(scr)│
            ├──────┤
            │ ARM  │  ← Tay: 48×120px mỗi, đơn giản
            │ L    │  ← Chân: 56×80px mỗi
            │   R  │
            └──────┘
```

| Phần | Width | Height | Color | Ghi chú |
|------|-------|--------|-------|---------|
| Head | 256px | 220px | White + blue border | Góc bo tròn 32px |
| Eyes (mỗi) | 64px | 64px | `#4A90E2` iris | Pupil 32px |
| Ear/antenna (mỗi) | 32px | 64px | `#4A90E2` | Thu sóng nhỏ |
| Body | 200px | 180px | White | Bo tròn 24px |
| Chest screen | 80px | 60px | `#7B61FF` | Hiển thị biểu cảm |
| Arm (mỗi) | 48px | 120px | White | Bo tròn 16px |
| Leg (mỗi) | 56px | 80px | White | Bo tròn 20px |

### E.2 Export Requirements

| Asset | Format | Sizes | Animation |
|-------|--------|-------|-----------|
| Static base | SVG, PNG | @1x/2x/3x (64/128/192px avatar) | none |
| Full body | SVG, PNG | @1x/2x/3x (256/512/768px) | none |
| Rive state machine | .riv | single file | recommended |
| Lottie fallback | .json | single file | for web fallback |
| Expression sprites | PNG sprite sheet | 512×512 per frame | 10 frames |
| Blink animation | Lottie | single loop | 200ms close, 3s open |

### E.3 Character Safety Rules

- **Cấm:** Vũ khí, bộ giáp, chi tiết sắc nhọn, màu đỏ đậm, mắt trống rỗng, vẻ mặt tức giận.
- **Bắt buộc:** Mắt to ≥ 15% diện tích đầu, góc bo tròn toàn bộ, biểu cảm vui ≥ 5/10 frame.

---

## Phụ lục F — Checklist triển khai cho Engineering

Checklist này dùng để review trước khi implement mỗi màn hình.

### F.1 Mỗi màn hình phải có

- [ ] Layout responsive (xs → xl).
- [ ] Nút chính Primary Button ≥ 56px height.
- [ ] Tất cả touch target ≥ 48×48px.
- [ ] Font scale phù hợp device.
- [ ] Trạng thái loading (skeleton + MI animation).
- [ ] Trạng thái empty (copy + CTA).
- [ ] Trạng thái error (retry + fallback).
- [ ] Offline badge/banner (nếu cần).
- [ ] Voice label / accessibility label cho mọi interactive element.
- [ ] Safe area padding (notch, home indicator).
- [ ] Nút pause trong game.
- [ ] Navigation quay về trang chủ.

### F.2 Accessibility checklist

- [ ] Color contrast ≥ 4.5:1 cho text nhỏ.
- [ ] Icon + text đi cùng (không chỉ color).
- [ ] Screen reader label cho button, card, image.
- [ ] Focus order hợp lý (Tab / D-pad).
- [ ] Font Atkinson Hyperlegible khi bật accessibility mode.
- [ ] Tốc độ animation = 0 khi Reduced Motion bật.

### F.3 Game screen checklist

- [ ] Không countdown timer cho age group 5–7.
- [ ] Sai: grayscale hoặc shake (không đỏ).
- [ ] Đúng: success green + scale 2s.
- [ ] Gợi ý xuất hiện sau 3s hoặc khi hesitate >5s.
- [ ] Pause modal có resume + quit + home.
- [ ] Voice-over auto-play ở step đầu tiên.


