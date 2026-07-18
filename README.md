# MI Academy

> **Học qua chơi, lớn lên qua từng khám phá.**

MI Academy là ứng dụng học tập kết hợp trò chơi dành cho trẻ 5–12 tuổi, tập trung vào toán, ngôn ngữ, tư duy logic, sáng tạo và kỹ năng sống.

## Current verified status (2026-07-18)

Do not treat the phased plan below as a completion claim — it is the
original design roadmap. For what is actually built, tested, and verified
in the current codebase, see:

- [docs/release-audit.md](./docs/release-audit.md) — the full findings
  ledger (what's fixed, what's open, with evidence and verification
  commands for each).
- [docs/milestone-1-completion.md](./docs/milestone-1-completion.md) —
  Milestone 1's delivered scope, architecture, test coverage, and honest
  remaining limitations.
- [docs/game-catalog.md](./docs/game-catalog.md) — real per-game status
  (6 of 30 target games exist).

Quick facts, verified directly: 6 playable games with local persistence;
`flutter analyze`/`ruff check .`/`mypy .` all clean; `pytest` 170 passed;
`flutter test` 92 passed (6 Linux-only golden tests skipped elsewhere);
a real Android-emulator integration-test suite passing in CI; Android
`applicationId` is `com.liemteam.miacademy` (no longer the
`com.example.*` scaffold default); unsigned APK/AAB builds succeed
locally, signed builds succeed in CI given configured secrets.

## Tài liệu phát triển

| Tài liệu | Mô tả |
|-----------|--------|
| [PRD.md](./PRD.md) | Product Requirements Document chính |
| [docs/api-specification.md](./docs/api-specification.md) | REST API specification (FastAPI) |
| [docs/database-schema.md](./docs/database-schema.md) | Thiết kế cơ sở dữ liệu (PostgreSQL) |
| [docs/tech-architecture.md](./docs/tech-architecture.md) | Kiến trúc kỹ thuật tổng quan |
| [docs/user-flow.md](./docs/user-flow.md) | User flow với Mermaid diagrams |
| [docs/screen-designs.md](./docs/screen-designs.md) | Chi tiết thiết kế 13 màn hình |
| [docs/mvp-games-spec.md](./docs/mvp-games-spec.md) | Spec chi tiết 6 game MVP (Flame) |
| [docs/localization.md](./docs/localization.md) | Hướng dẫn đa ngôn ngữ VI/EN |
| [docs/security.md](./docs/security.md) | Bảo mật, quyền riêng tư, COPPA/GDPR/NĐ13 |
| [docs/ui-ux-design-system.md](./docs/ui-ux-design-system.md) | Design system đầy đủ |

## Triển khai theo giai đoạn

### Giai đoạn 1 — MVP (Ưu tiên cao nhất)
- Hồ sơ trẻ & nhân vật MI
- Bản đồ học tập tương tác
- **6 trò chơi MVP**: Ghép chữ tạo từ, Nghe âm tìm chữ, Đường đua cộng trừ, Siêu thị toán học, Ghi nhớ vị trí, Robot làm theo lệnh
- Hệ thống sao & huy hiệu
- Báo cáo phụ huynh (PIN-protected)
- Chế độ offline
- Tiếng Việt & tiếng Anh

### Giai đoạn 2
- Mở rộng lên 15 trò chơi
- Đọc truyện, bảng nhân, đo lường, hình học, mê cung, khoa học

### Giai đoạn 3
- Hoàn thiện 30 trò chơi
- Hệ thống cá nhân hóa
- Thư viện bài học mở rộng
