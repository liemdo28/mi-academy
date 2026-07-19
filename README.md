# MI Academy

> **Học qua chơi, lớn lên qua từng khám phá.**

MI Academy là ứng dụng học tập kết hợp trò chơi dành cho trẻ 5–12 tuổi, tập trung vào toán, ngôn ngữ, tư duy logic, sáng tạo và kỹ năng sống.

## Current verified status (2026-07-19)

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
  (15 of 30 target games exist).

Quick facts, verified directly: 15 playable games with local persistence;
`flutter analyze`, `ruff check .`, `ruff format --check .`, and `mypy .`
are clean; `pytest` 187 passed; `flutter test` 123 passed (6 Linux-only
golden tests skipped on Windows); content schema, malformed-fixture,
content-safety, solvability, and ARB parity checks pass; Android
`applicationId` is `com.liemteam.miacademy`. CI run `29675995855` is green,
including Android emulator integration tests. Games 1-15 engineering is
complete; human educational review, Play release, Games 16-30, and broad
localization cleanup remain pending.

**Shared game engines** (`packages/mi_game_engines/`, see
[docs/game-engine-architecture.md](./docs/game-engine-architecture.md)):
all four Milestone 1 WS5 engines are now real and tested -- Matching,
Sequence, Placement, and Multi-select -- 165 passing tests. Games 9-15
consume those shared engines through the public `mi_game_engines` barrel.

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
