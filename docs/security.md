# MI Academy — Security & Privacy Policy

> **Ngày:** 16/07/2026 | **Trạng thái:** Draft  
> **Liên hệ bảo mật:** security@miacademy.app

---

## 1. Nguyên tắc cốt lõi

| Nguyên tắc | Mô tả |
|------------|--------|
| **Privacy-by-design** | Không thu thập PII của trẻ em |
| **Encryption everywhere** | Mã hóa at-rest + in-transit |
| **Least privilege** | Chỉ cấp quyền tối thiểu cần thiết |
| **No ads/trackers** | Zero third-party analytics trên child interactions |
| **Defense in depth** | Nhiều lớp bảo vệ |
| **Open communication** | Báo cáo lỗi bảo mật → security@miacademy.app |

---

## 2. Tuân thủ pháp lý

### 2.1 COPPA (Hoa Kỳ — Children's Online Privacy Protection Act)

| Yêu cầu COPPA | Triển khai |
|----------------|------------|
| Không thu thập PII trẻ dưới 13 | ✅ Chỉ thu: nickname, age_group, device_id |
| Phụ huynh kiểm soát dữ liệu | ✅ Xem, sửa, xóa qua Parent Zone |
| Xóa dữ liệu khi yêu cầu | ✅ DELETE endpoint + CASCADE DB |
| Không có hồ sơ mặc định | ✅ Không tạo account không có parent consent |
| Biên nhận hướng dẫn quyền riêng tư | ✅ Privacy policy trong app + website |

### 2.2 GDPR-K / Article 8 (Liên minh Châu Âu)

| Yêu cầu | Triển khai |
|----------|------------|
| Cơ sở pháp lý cho xử lý dữ liệu | Parent consent (tự nguyện khi setup) |
| Quyền xóa dữ liệu (Art. 17) | ✅ `DELETE /children/{id}` + cascade |
| Quyền tiếp cận (Art. 15) | ✅ Parent dashboard xem tiến độ |
| Data portability (Art. 20) | ✅ Export JSON trong Parent Settings |
| DPO requirement | Xem xét nếu mở rộng sang EU |
| 72h breach notification | ✅ Incident response plan |

### 2.3 Nghị định 13/2023/NĐ-CP (Việt Nam)

| Yêu cầu | Triển khai |
|----------|------------|
| Thu thập có consent | ✅ Parent consent khi tạo hồ sơ |
| Mục đích rõ ràng | ✅ Chỉ để học tập, không mục đích khác |
| Xóa dữ liệu theo yêu cầu | ✅ Delete cascade trong DB |
| Thông báo vi phạm | ✅ security@miacademy.app |
| Bảo mật thông tin | ✅ AES-256, TLS 1.3 |

### 2.4 Apple App Store / Google Play (Kids Category)

| Yêu cầu | Triển khai |
|----------|------------|
| Designed for Families | ✅ Designed for Families declaration |
| Không có IAP | ✅ Không IAP, hoàn toàn miễn phí |
| Không có quảng cáo | ✅ Zero ads SDK |
| Parental gate | ✅ PIN challenge trước parent zone |
| Age-appropriate design | ✅ UI test với trẻ em thật |

---

## 3. Dữ liệu được phép thu thập vs. KHÔNG

### ✅ Thu thập (không phải PII)

| Dữ liệu | Mục đích | Lưu trữ |
|---------|---------|---------|
| `device_id` (UUID) | Xác định thiết bị | Local encrypted + server |
| `nickname` (tên trẻ, local) | Gọi tên trong app | Local only (không server) |
| `age_group` | Chọn nội dung phù hợp | Server (UUID link) |
| `learning_progress` | Lưu tiến độ | Server (UUID link) |
| `anonymous_error_log` | Cải thiện app | Server (no PII) |

### ❌ KHÔNG BAO GIỜ thu thập

- Họ tên thật, địa chỉ, số điện thoại
- Email của phụ huynh (không yêu cầu)
- Ảnh chụp của trẻ
- Vị trí GPS
- Danh sách bạn bè / mạng xã hội
- Dữ liệu tài chính
- Thông tin nhà trường

---

## 4. Mã hóa

### 4.1 Local Storage (Flutter)

| Dữ liệu | Phương thức | Key storage |
|----------|------------|-------------|
| Progress data | **Hive** với `encryptionCipher` | **flutter_secure_storage** (AES-256 key) |
| PIN hash | bcrypt(cost=12) | flutter_secure_storage |
| Auth tokens | JWT access + refresh | flutter_secure_storage |
| Content cache | AES-256-GCM | Per-package key |

```dart
// Flutter: mã hóa Hive box
final encryptionKey = await getEncryptionKey(); // from flutter_secure_storage
final encryptedBox = await Hive.openBox(
  'progress',
  encryptionCipher: HiveAesCipher(encryptionKey),
);
```

### 4.2 Network (TLS 1.3)

```yaml
# Production HTTPS only
# TLS 1.3 minimum (no TLS 1.1/1.2)
# HSTS preload list
# Certificate pinning via package:dio with SecurityContext
```

### 4.3 Database (PostgreSQL)

```sql
-- PIN hash: bcrypt
UPDATE parent SET pin_hash = crypt('1234', gen_salt('bf', 12));

-- Sensitive fields có thể dùng pgcrypto:
-- CREATE EXTENSION pgcrypto;
```

---

## 5. Quyền của phụ huynh

| Quyền | Endpoint | Mô tả |
|--------|----------|--------|
| Xem tiến độ | `GET /parent/usage-time` | Bar chart 7 ngày |
| Xem kỹ năng | `GET /parent/skill-analysis` | Radar chart |
| Xóa toàn bộ dữ liệu | `DELETE /children/{id}` | GDPR/NĐ13 compliant |
| Đặt giới hạn thời gian | `PUT /settings` | 15/30/45/60 phút |
| Export dữ liệu | `GET /parent/export` | JSON file download |
| Đổi PIN | `POST /auth/change-pin` | Yêu cầu PIN cũ |

---

## 6. Checklist bảo mật cho dev team

- [ ] **Secrets management**: Tất cả API key/token trong `.env`, KHÔNG commit
- [ ] **Input validation**: Pydantic models + SQLAlchemy parameterized queries (no SQL injection)
- [ ] **Rate limiting**: Implement ở tất cả endpoint (5.1.3)
- [ ] **Constant-time PIN compare**: Dùng `secrets.compare_digest()` thay vì `==`
- [ ] **No stack trace in prod**: `debug=False`, custom error handler
- [ ] **HTTPS only**: Redirect HTTP → HTTPS, HSTS header
- [ ] **CORS strict**: Chỉ domain app được phép
- [ ] **Audit log**: Ghi lại admin actions trong CMS
- [ ] **Error log ẩn danh**: Stack hash, không có device_id/user_id
- [ ] **Dependency scan**: `pip-audit` + `flutter pub outdated` mỗi sprint
- [ ] **SAST**: Code scanning trong CI pipeline
- [ ] **No hardcoded URLs**: Dùng config environment
- [ ] **Secure random**: `secrets.token_urlsafe(32)` cho UUID
- [ ] **Session timeout**: Access token 1h, refresh 7 days
- [ ] **Parent PIN lockout**: 3 sai → 30s lockout

---

## 7. Third-party dependencies

| Loại | Được phép | KHÔNG được phép |
|------|-----------|----------------|
| Error tracking | Self-hosted GlitchTip | Sentry (có tracking), Bugsnag |
| Analytics | Ẩn danh, server-side | Firebase Analytics, Amplitude |
| Ads | ❌ HOÀN TOÀN KHÔNG | Google Ads, Facebook Ads, AdMob |
| Social | ❌ KHÔNG CÓ | Facebook SDK, Firebase Auth |
| A/B testing | ❌ KHÔNG | Remote config cho nội dung OK |
| CDN | ✅ Dùng CDN cho static | Không dùng cho data API |
| Push notification | ❌ KHÔNG | Không cần push notification |

---

## 8. Incident Response Plan

```
Phát hiện lỗi bảo mật
        │
        ▼
1. Xác nhận và phân loại (Critical/High/Medium/Low)
        │
        ▼
2. Cô lập hệ thống bị ảnh hưởng
        │
        ▼
3. Thông báo nội bộ (trong 4h)
        │
        ▼
4. Điều tra nguyên nhân (trong 24h)
        │
        ▼
5. GDPR: Thông báo supervisory authority trong 72h
        COPPA: Đánh giá FTC reporting requirement
        NĐ13: Thông báo C03 (nếu cần) trong 72h
        │
        ▼
6. Khắc phục và verify
        │
        ▼
7. Post-mortem + security review
```

---

## 9. Bảo vệ trẻ khỏi nội dung xấu

| Biện pháp | Triển khai |
|-----------|------------|
| Không có UGC | Ứng dụng đọc, không cho trẻ tạo nội dung |
| Không chat | Zero messaging functionality |
| Không liên kết bên ngoài | `allowNavigation` = false; external links = parent PIN required |
| Content moderation | Tất cả nội dung do CMS tạo, có approval workflow |
| Age gate | Parent PIN trước mọi nội dung do người lớn tạo |

---

## 10. Security contact

```
Email: security@miacademy.app
PGP Key: (published on miacademy.app/security)
Response time: 48h business days
Disclosure: coordinated disclosure via HackerOne/GCSC
```

---

*Tài liệu này là phần của PRD MI Academy v1.0 MVP.*
