# MI Academy — Game Open Source Inventory

> **Doc date:** 2026-07-17
> **Owner:** Game & Experience Lead
> **Status:** Active tracking of open source usage in game packages

---

## 1. Policy

### 1.1 Allowed Licenses

| License | Status | Notes |
|---------|--------|-------|
| MIT | ✅ Allowed | Preferred |
| BSD (2-clause, 3-clause) | ✅ Allowed | Preferred |
| Apache-2.0 | ✅ Allowed | Preferred |
| CC0 (public domain) | ✅ Allowed | For assets |
| CC-BY (any version) | ✅ Allowed | Must attribute |
| CC-BY-SA | ⚠️ Conditional | Only if share-alike is acceptable |
| GPL v3 | ❌ Not allowed | Triggers copyleft concerns |
| AGPL | ❌ Not allowed | Strong copyleft |
| Unknown | ❌ Not allowed | Must identify |

### 1.2 Prohibited

- Code with advertising SDK
- Code with telemetry/tracker without user consent
- Code with external data collection
- Assets from commercial games
- Code from repositories without LICENSE file

### 1.3 Review Process

1. Identify source repository
2. Verify LICENSE file exists
3. Check license compatibility
4. Record in this inventory
5. Add to THIRD_PARTY_NOTICES.md
6. Add to ASSET_LICENSE_MANIFEST.json

---

## 2. Flutter/Dart Dependencies

### 2.1 Direct Dependencies (game packages)

| Package | Version | License | Repository | Used By |
|---------|---------|---------|------------|---------|
| `equatable` | ^2.0.5 | BSD-3 | https://github.com/felangel/equatable | All game packages |
| `uuid` | ^4.4.0 | MIT | https://github.com/DaveNot英国/uuid | All game packages |
| `audioplayers` | ^6.0.0 | Apache-2.0 | https://github.com/bluefireteam/audioplayers | mi_game_audio |

### 2.2 Dev Dependencies

| Package | Version | License | Used For |
|---------|---------|---------|----------|
| `flutter_test` | SDK | BSD-3 | Unit/widget tests |
| `flutter_lints` | ^4.0.0 | MIT | Lint rules |
| `mocktail` | ^1.0.3 | BSD-3 | Test mocking |
| `bluff` | (future) | MIT | Golden tests |

### 2.3 Flame Engine (Wave 3+)

| Package | Version | License | Repository | Notes |
|---------|---------|---------|------------|-------|
| `flame` | ^1.18.0 | MIT | https://github.com/flame-engine/flame | Game engine |
| `flame_audio` | ^2.0.0 | MIT | https://github.com/flame-engine/flame_audio | Audio |

---

## 3. Open Source Libraries Under Evaluation

### 3.1 Under Evaluation

| Library | Purpose | License | Status | Decision |
|---------|---------|---------|--------|----------|
| `flame` | Game engine | MIT | ✅ | Approved for Waves 3-4 |
| `flame_audio` | Audio | MIT | ✅ | Approved for Waves 3-4 |
| `flame_tiled` | Tiled map support | MIT | ✅ | Approved for Robot map |
| `flame_forge2d` | Physics | MIT | ❌ | Not needed for MVP |
| `flame_lottie` | Animation | MIT | ❌ | No Lottie assets in MVP |
| `flutter_animate` | Flutter animations | MIT | ✅ | For non-game UI animations |

### 3.2 Rejected Libraries

| Library | Reason |
|---------|--------|
| `google_fonts` | External network call — not offline-safe |
| `firebase_core` | External service, not needed |
| `unity_ads` | Advertising — prohibited |
| `facebook_sdk` | Social/analytics — prohibited |

---

## 4. Asset Inventory

### 4.1 Policy

- All game assets must be: created in-house, licensed CC0, or licensed CC-BY
- No sprites, images, audio, or artwork from commercial games
- No characters from licensed properties
- SVG icons from Material Icons or Phosphor Icons (MIT)

### 4.2 Planned Asset Sources

| Asset Type | Source | License | Status |
|------------|--------|---------|--------|
| Card images (Memory Cards) | Custom SVG | CC0 | Pending |
| Word Builder letters | Custom fonts | OFL (custom) | Pending |
| Sound effects | BFXR / Audacity | CC0 | Pending |
| Background music | Custom / Freesound | CC0 | Pending |
| Voice narration | Custom recording | Proprietary | Pending |
| Icons | Phosphor Icons | MIT | Pending |

### 4.3 Freesound Assets (CC0)

If using Freesound for SFX:
- Must credit author and Freesound
- Must link to source
- Must indicate CC0 license
- Must list in ASSET_LICENSE_MANIFEST.json

---

## 5. Code Generation & Build Tools

| Tool | Version | License | Usage |
|------|---------|---------|-------|
| `build_runner` | SDK | BSD-3 | Code generation |
| `json_serializable` | ^6.7.0 | BSD-3 | JSON serialization |
| `freezed` | ^5.0.0 | MIT | Immutable models |

---

## 6. Contribution Requirements

### 6.1 Adding a New Dependency

1. Verify license (MIT/BSD/Apache-2.0 only)
2. Check repository has LICENSE file
3. Run `大妈 pub add --dry-run` first
4. Document in this inventory
5. Add to `THIRD_PARTY_NOTICES.md`
6. Update `pubspec.yaml`
7. Run license compliance check

### 6.2 Adding a New Asset

1. Verify asset