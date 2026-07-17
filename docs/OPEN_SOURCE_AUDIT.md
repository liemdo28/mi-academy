# MI Academy — Open Source Audit

> **Audit date:** 2026-07-17
> **Scope:** Foundation Sprint — Phase A
> **Status:** Complete

---

## 1. Purpose

Document every open-source dependency added during the Foundation Sprint.
For each: name, version, license, purpose, risk assessment, and acceptance decision.

---

## 2. Dependency allowlist (Flutter / Dart)

### Core framework (approved)

| Package                  | Version  | License   | Purpose                          | Decision |
|--------------------------|----------|-----------|----------------------------------|----------|
| `flutter`                | SDK 3.x  | BSD-3     | App framework                    | ✅ APPROVED |
| `flame`                  | ^1.18.0  | MIT       | 2D game engine (evaluated later) | ✅ APPROVED_FOR_EVALUATION |

### State management

| Package         | Version  | License   | Purpose                  | Decision |
|-----------------|----------|-----------|--------------------------|----------|
| `flutter_riverpod` | ^2.5.0 | MIT      | Reactive state / DI      | ✅ APPROVED |
| `riverpod_annotation` | ^2.3.0 | MIT  | Code generation for Riverpod | ✅ APPROVED |

### Navigation

| Package     | Version  | License | Purpose               | Decision |
|-------------|----------|---------|-----------------------|----------|
| `go_router` | ^14.0.0  | BSD-3   | Declarative routing   | ✅ APPROVED |

### Audio

| Package           | Version  | License   | Purpose                     | Decision |
|-------------------|----------|-----------|-----------------------------|----------|
| `audioplayers`    | ^5.2.0   | MIT       | Multi-source audio playback | ✅ APPROVED |

### Storage / offline

| Package     | Version  | License   | Purpose                     | Decision |
|-------------|----------|-----------|-----------------------------|----------|
| `hive`      | ^2.2.3   | Apache-2  | Lightweight key-value store | ✅ APPROVED |
| `hive_flutter` | ^1.1.0 | Apache-2  | Hive Flutter bindings       | ✅ APPROVED |

### JSON / content

| Package           | Version  | License   | Purpose              | Decision |
|-------------------|----------|-----------|----------------------|----------|
| `json_annotation` | ^4.9.0   | BSD-3     | JSON model annotations| ✅ APPROVED |
| `json_serializable` | ^6.8.0 | BSD-3    | JSON code generation  | ✅ APPROVED |
| `freezed_annotation` | ^2.4.0 | MIT    | Immutable model annotations | ✅ APPROVED |

### Networking (deferred — not needed for offline-first MVP)

| Package  | Version  | License | Purpose             | Decision |
|----------|----------|---------|---------------------|----------|
| `dio`    | ^5.4.0   | MIT     | HTTP client         | ⏸ DEFERRED — no network calls in v0.1 |

### Testing

| Package              | Version  | License   | Purpose                  | Decision |
|----------------------|----------|-----------|--------------------------|----------|
| `flutter_test`       | SDK      | BSD-3     | Widget / unit testing    | ✅ APPROVED |
| `mocktail`           | ^1.0.3   | MIT       | Mocking framework        | ✅ APPROVED |
| `golden_toolkit`     | ^0.15.0  | MIT       | Golden test utilities    | ✅ APPROVED |

### Utilities

| Package              | Version  | License   | Purpose                  | Decision |
|----------------------|----------|-----------|--------------------------|----------|
| `equatable`          | ^2.0.5   | MIT       | Value equality for models| ✅ APPROVED |
| `uuid`               | ^4.4.0   | MIT       | UUID generation          | ✅ APPROVED |
| `intl`               | ^0.19.0  | BSD-3     | Date/number formatting   | ✅ APPROVED |

### Melos (workspace management)

| Package | Version | License | Purpose                          | Decision |
|---------|---------|---------|----------------------------------|----------|
| `melos` | ^5.3.0  | MIT     | Monorepo management (dev global) | ✅ APPROVED |

---

## 3. Version pinning policy

- **Melos workspace**: All packages use caret (`^`) constraints for minor+patch.
  Major version pinned in `melos.yaml` overrides.
- **Lock file**: `pubspec.lock` committed to repo, reviewed in PR for unexpected
  changes.
- **Automated check**: CI runs `dart pub outdated --dependency-overrides-only` to
  flag stale or security-vulnerable deps.

---

## 4. Rejected dependencies

| Package          | Reason                                                     |
|------------------|------------------------------------------------------------|
| `firebase_*`     | Excessive data collection; cloud coupling                  |
| `google_mobile_ads` | Advertising SDK — child safety violation               |
| `sentry_flutter` | Only needed after public beta; defer                       |
| `isar`           | Apache-2 but v3 has uncertain maintenance; use Hive instead|
| `webview_flutter`| Not needed; MI Blocks is native Flutter (no Blockly embed) |

---

## 5. License summary

All approved dependencies use **MIT**, **BSD-3**, or **Apache-2** — all permissive
and compatible with commercial use. No copyleft (GPL/LGPL/AGPL) dependencies.

---

## 6. Asset license manifest

Referenced: `assets/ASSET_LICENSE_MANIFEST.json`

All assets used in this sprint are:
- Original MI Academy artwork (created in-house).
- Placeholder SVGs/JSON (no external licensed assets yet).

Any future third-party asset (fonts, sounds, illustrations) must be added to
`assets/ASSET_LICENSE_MANIFEST.json` before merge.
