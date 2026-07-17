# MI Academy — License Decision Log

> **Version:** 1.0.0
> **Date:** 2026-07-17
> **Owner:** Dev 3

---

## Policy

MI Academy uses a strict license gate:
- **Allowed:** MIT, BSD-2, BSD-3, Apache-2.0, ISC
- **Case-by-case:** MPL-2.0 (only unmodified), CC-BY
- **Blocked:** GPL, LGPL, AGPL, CC-BY-SA, CC-BY-NC, Unlicensed

## Decision log

| Date | Dependency/Repo | License | Decision | Rationale |
|------|----------------|---------|----------|-----------|
| 2026-07-17 | flame | MIT | APPROVED_FOR_EVALUATION | 2D game engine, no copyleft risk |
| 2026-07-17 | flutter_riverpod | MIT | APPROVED | State management, MIT |
| 2026-07-17 | go_router | BSD-3 | APPROVED | Navigation, permissive |
| 2026-07-17 | audioplayers | MIT | APPROVED | Audio playback |
| 2026-07-17 | hive / hive_flutter | Apache-2 | APPROVED | Offline storage, permissive |
| 2026-07-17 | equatable | MIT | APPROVED | Value equality |
| 2026-07-17 | uuid | MIT | APPROVED | UUID generation |
| 2026-07-17 | intl | BSD-3 | APPROVED | Localization |
| 2026-07-17 | mocktail | MIT | APPROVED | Testing mocks |
| 2026-07-17 | golden_toolkit | MIT | APPROVED | Golden tests |
| 2026-07-17 | melos | MIT | APPROVED | Workspace management |
| 2026-07-17 | json_annotation | BSD-3 | APPROVED | JSON codegen |
| 2026-07-17 | json_serializable | BSD-3 | APPROVED | JSON codegen |
| 2026-07-17 | freezed_annotation | MIT | APPROVED | Immutable models |
| 2026-07-17 | firebase_* | Multiple | REJECTED | Excessive data collection, cloud coupling |
| 2026-07-17 | google_mobile_ads | Google ToS | REJECTED | Advertising SDK, child safety violation |
| 2026-07-17 | sentry_flutter | BSD-2 | REJECTED (deferred) | Only needed after public beta |
| 2026-07-17 | isar | Apache-2 | REJECTED | Uncertain v3 maintenance, use Hive |
| 2026-07-17 | webview_flutter | BSD-3 | REJECTED | Not needed (native Flutter blocks) |
| 2026-07-17 | GCompris | GPL-3 | REFERENCE_ONLY | Copyleft — no code copying |
| 2026-07-17 | Blockly | Apache-2 | APPROVED_WITH_ADAPTATION | Study data model, don't embed |
| 2026-07-17 | Blockly Games | Apache-2 | REFERENCE_ONLY | Study mechanics only |

## Process

1. Before adding any new dependency: check license
2. If approved license → add to `OPEN_SOURCE_AUDIT.md`
3. If uncertain → `REQUIRES_LEGAL_REVIEW` before merge
4. If GPL/AGPL → `REJECTED` with rationale
5. All decisions logged here for audit trail
