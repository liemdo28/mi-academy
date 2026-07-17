# MI Academy — Game Repository Audit

> **Audit date:** 2026-07-17
> **Auditor:** Game & Experience Lead
> **Scope:** Full repository for game development readiness

---

## 1. Repository Overview

| Property | Value |
|----------|-------|
| Repository | https://github.com/liemdo28/mi-academy |
| Latest commit | 2b0210d (2026-07-17) |
| Package manager | Melos workspace |
| Flutter version | >=3.22.0 (Dart >=3.4.0) |
| Mobile target | iOS 15+, Android API 24+ |
| Architecture | Monorepo (packages/ + apps/) |

---

## 2. Package Inventory

### 2.1 Game Packages (Game & Experience Lead ownership)

| Package | Status | Notes |
|---------|--------|-------|
| `mi_game_core` | ✅ Implemented | MiGame interface, lifecycle, models, BaseGame |
| `mi_game_ui` | ⚠️ Shell only | Export file exists, no components |
| `mi_game_audio` | ⚠️ Shell only | Export file exists, no service |
| `mi_game_accessibility` | ⚠️ Shell only | Export file exists, no service |
| `mi_game_testing` | ⚠️ Shell only | Export file exists, no harness |
| `mi_blocks` | ⚠️ Partial | Block/Program models exist, no interpreter/editor |

### 2.2 Other Packages (Dev 1 or shared)

| Package | Owner | Status |
|---------|-------|--------|
| `mi_game_content` | Shared | Shell only |
| `mi_game_progress` | Dev 1 | Shell only |
| `learning_core` | Reference | Python, empty |
| `game_core` | Reference | Python, server-side |

### 2.3 Apps

| App | Status |
|-----|--------|
| `apps/mobile` | ✅ Flutter shell with stub games |
| `apps/api` | ✅ FastAPI backend (Dev 1) |

---

## 3. Flutter SDK & Dependencies Audit

### 3.1 Flutter Version Check

- **Required:** Flutter >=3.22.0, Dart >=3.4.0
- **melos.yaml:** Confirms SDK constraint `>=3.4.0 <4.0.0`
- **Status:** ✅ Version constraint is consistent across all packages

### 3.2 Key Dependencies

| Dependency | Version | Purpose | License | Status |
|------------|---------|---------|---------|--------|
| `equatable` | ^2.0.5 | Value equality | BSD-3 | ✅ OK |
| `uuid` | ^4.4.0 | ID generation | MIT | ✅ OK |
| `flutter_lints` | ^4.0.0 | Lint rules | MIT | ✅ OK |
| `mocktail` | ^1.0.3 | Test mocking | BSD-3 | ✅ OK |
| `go_router` | (mobile) | Navigation | Apache-2.0 | ✅ OK |
| `hive` / `hive_flutter` | (mobile) | Local storage | Apache-2.0 | ✅ OK |

### 3.3 Flame Consideration

- **Status:** Not yet in dependencies
- **Decision:** Wave 0-2 do NOT use Flame (card grid, drag-drop, choice engines are Flutter-native)
- **Flame added:** Wave 3 (Math Race, Math Supermarket) via `flame: ^1.18.0`
- **Flame compatibility:** Will be verified in FLAME_TECHNICAL_SPIKE.md

---

## 4. Rendering Architecture

### 4.1 Mobile App

| Layer | Technology | Status |
|-------|-----------|--------|
| UI | Flutter Widgets | ✅ Working |
| Game screens | StatelessWidget / ConsumerWidget | ⚠️ Stub |
| Navigation | go_router | ✅ Configured |
| State | Riverpod | ✅ Configured |

### 4.2 Game Rendering Strategy

| Wave | Game | Rendering | Reason |
|------|------|-----------|--------|
| Wave 1 | Memory Cards | Flutter GridView + AnimatedSwitcher | Simple card grid, no physics |
| Wave 2 | Word Builder | Flutter Stack + GestureDetector | Drag-drop without physics |
| Wave 2 | Sound Match | Flutter ListView + AudioPlayer | Simple choice grid |
| Wave 3 | Math Race | Flame | Vehicle animation along path |
| Wave 3 | Math Supermarket | Flutter + Flame overlay | Product shelf simulation |
| Wave 4 | Robot Commands | Flutter + Canvas | Grid map with block editor |

**Decision:** Waves 1-2 use Flutter-native rendering (no game engine dependency). Waves 3-4 add Flame progressively.

---

## 5. Audio Architecture

### 5.1 Requirements

- Offline audio (bundled assets)
- Voice narration
- Word pronunciation
- Sound effects
- Background music
- Slow playback support
- Volume groups (voice, music, effects)

### 5.2 Existing Audio

- None currently bundled

### 5.3 Implementation Plan

- Use `audioplayers: ^6.0.0` (Apache-2.0) for audio playback
- Bundle audio as assets in `assets/audio/` per game
- `mi_game_audio` package provides `MiAudioService` as Flutter service locator
- Fallback: visual feedback when audio unavailable

---

## 6. Input Handling

### 6.1 Game Input Types

| Input | Use Case | Implementation |
|-------|----------|----------------|
| Tap | All games | GestureDetector.onTap |
| Long press | Robot Commands blocks | GestureDetector.onLongPress |
| Drag | Word Builder letter drag | Draggable/DragTarget |
| Horizontal swipe | Card deck scroll | PageView / Horizontal drag |
| Keyboard | Web fallback | RawKeyboardListener / KeyboardListener |

### 6.2 Accessibility Input

- All tap interactions must have keyboard equivalents
- Drag-drop must have tap-to-place alternative
- No time-pressure input mechanics

---

## 7. Tablet Landscape Support

### 7.1 Target Devices

| Device | Orientation | Screen Width |
|--------|-------------|--------------|
| Phone portrait | Portrait | 360-428dp |
| Phone landscape | Landscape | 640-926dp |
| Tablet portrait | Portrait | 600-840dp |
| Tablet landscape | Landscape | 960-1280dp |

### 7.2 Layout Strategy

- All game UIs use `Center` + `ConstrainedBox(maxWidth: 600)` for phone
- Tablet: use full width with centered game area
- Landscape: prefer wider card grids, smaller margins
- No hard-coded pixel dimensions

---

## 8. Web Compatibility

### 8.1 Target

- Flutter Web (CanvasKit renderer)
- Keyboard + mouse input
- No touch-specific gestures

### 8.2 Compatibility Considerations

| Feature | Web Support | Notes |
|---------|-------------|-------|
| Drag-drop | ✅ | Mouse drag supported |
| Tap | ✅ | Click |
| Audio | ⚠️ | AudioContext requires user gesture |
| Offline | ✅ | ServiceWorker + cached assets |
| Flame web | ✅ | via `flame_web` package |

---

## 9. Performance on Low-End Devices

### 9.1 Target Devices

- Android API 24 (Android 7.0) — 2GB RAM, Mali-400 GPU
- iPhone 6s equivalent

### 9.2 Performance Requirements

| Metric | Target |
|--------|--------|
| Initial load | < 3s on 4G |
| Game start | < 1s after assets loaded |
| Frame rate | 60fps (30fps acceptable on reduced motion) |
| Memory | < 150MB per game |
| Storage | < 50MB per game |

### 9.3 Optimizations Planned

- Asset preloading via `mi_game_core`
- Image caching with `CachedNetworkImage` for avatars only
- Dispose Flame components properly
- Use `RepaintBoundary` for static UI elements
- Lazy load level content

---

## 10. License & Security Audit

### 10.1 Repository License

- **License file:** ✅ Present
- **License type:** Not specified — needs clarification (default GitHub proprietary until changed)

### 10.2 Dependency Licenses

| License | Allowed? | Used by |
|---------|----------|---------|
| MIT | ✅ | uuid, flutter_lints |
| BSD-3 | ✅ | equatable, mocktail |
| Apache-2.0 | ✅ | go_router, hive, audioplayers |
| GPL | ❌ | Not in use |
| AGPL | ❌ | Not in use |
| Unknown | ❌ | None found |

### 10.3 Third-Party Assets

- **None currently bundled**
- Policy: Only MIT/BSD/Apache-2.0/CC0 assets
- Full inventory tracked in `docs/GAME_OPEN_SOURCE_INVENTORY.md`

---

## 11. Security Considerations

### 11.1 Data Exposure

| Data | Received by Game? | Allowed? |
|------|-------------------|----------|
| Child profile ID | ✅ | ✅ |
| Age group | ✅ | ✅ |
| Language | ✅ | ✅ |
| Accessibility prefs | ✅ | ✅ |
| Level content | ✅ | ✅ |
| Parent password | ❌ | ✅ (never sent) |
| Auth tokens | ❌ | ✅ (never sent) |
| Payment info | ❌ | ✅ (never sent) |
| GPS/contacts | ❌ | ✅ (never sent) |

### 11.2 External Access

- No external API calls from game
- All content bundled locally
- No trackers or analytics SDK in game packages
- No ads or in-app purchases

---

## 12. Content Schemas

| Schema | Location | Status |
|--------|----------|--------|
| Level schema | `schemas/level.schema.json` | ⚠️ Needs creation |
| Game result schema | `schemas/game_result.schema.json` | ⚠️ Needs creation |
| Snapshot schema | `schemas/snapshot.schema.json` | ⚠️ Needs creation |

---

## 13. Existing Game Code

### 13.1 Memory Cards (stub)

- **Location:** `apps/mobile/lib/src/games/memory_cards/memory_cards_game.dart`
- **Status:** 334-line implementation with game logic, no Flutter UI
- **Quality:** Basic implementation, needs Flutter widget integration, animations, accessibility

### 13.2 Game Screen (stub)

- **Location:** `apps/mobile/lib/screens/game_screen.dart`
- **Status:** Shell with game type switch, needs real game integration

---

## 14. Gap Summary

| Category | Gap | Priority |
|----------|-----|----------|
| Documentation | GAME_REPOSITORY_AUDIT.md | ✅ Done |
| Documentation | FLAME_TECHNICAL_SPIKE.md | ⬜ |
| Documentation | GAME_PLATFORM_ARCHITECTURE.md | ⬜ |
| Documentation | GAME_OPEN_SOURCE_INVENTORY.md | ⬜ |
| Documentation | THIRD_PARTY_NOTICES.md | ⬜ |
| Package | mi_game_ui components | ⬜ |
| Package | mi_game_audio service | ⬜ |
| Package | mi_game_accessibility service | ⬜ |
| Package | mi_game_testing harness | ⬜ |
| Package | mi_blocks interpreter + editor | ⬜ |
| Contracts | MiGameLaunchRequest model | ⬜ |
| Contracts | MockGameLauncher | ⬜ |
| Schema | Level JSON schema | ⬜ |
| Schema | Game result schema | ⬜ |
| Game | Memory Cards (enhanced) | ⬜ |
| Game | Word Builder | ⬜ |
| Game | Sound Match | ⬜ |
| Game | Math Race | ⬜ |
| Game | Math Supermarket | ⬜ |
| Game | Robot Commands | ⬜ |

---

## 15. Recommended Actions

1. **Immediate:** Create all documentation files (Wave 0)
2. **Immediate:** Build mi_game_ui components (Wave 0)
3. **Immediate:** Build mi_game_audio service (Wave 0)
4. **Immediate:** Build mi_game_accessibility service (Wave 0)
5. **Immediate:** Build mi_game_testing harness (Wave 0)
6. **Immediate:** Create contracts (MiGameLaunchRequest, MockGameLauncher)
7. **Wave 1:** Enhanced Memory Cards with full UI, accessibility, 10 levels
8. **Wave 2:** Word Builder, Sound Match
9. **Wave 3:** Math Race, Math Supermarket (with Flame)
10. **Wave 4:** Robot Commands with MI Blocks editor
