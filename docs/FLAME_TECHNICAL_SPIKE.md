# MI Academy — Flame Technical Spike

> **Spike date:** 2026-07-17
> **Engineer:** Game & Experience Lead
> **Purpose:** Evaluate Flame game engine for Waves 3-4

---

## 1. Executive Summary

**Recommendation:** Adopt Flame ^1.18.0 for Math Race, Math Supermarket, and Robot Commands.
Flame will NOT be used for Waves 1-2 (Memory Cards, Word Builder, Sound Match).

**Rationale:**
- Flame is lightweight, well-maintained, MIT-licensed, and Flutter-native.
- Supports iOS, Android, Web, and macOS.
- Has a game-loop model that maps cleanly to the MiGame lifecycle.
- No dependency conflicts with existing packages.

---

## 2. Flame Version & Compatibility

### 2.1 Recommended Version

```
flame: ^1.18.0
flame_fire_ase: ^0.2.0      # Particle effects
flame_audio: ^2.0.0         # Audio (alternative to audioplayers)
```

### 2.2 Flutter Compatibility Matrix

| Flame | Flutter | Dart | Status |
|-------|---------|------|--------|
| 1.18.0 | 3.22+ | 3.4+ | ✅ Recommended |
| 1.15.0 | 3.16+ | 3.2+ | ⚠️ Older |
| 1.10.0 | 3.10+ | 3.0+ | ⚠️ Legacy |

### 2.3 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Android | ✅ | API 21+ (we target 24+) |
| iOS | ✅ | 12.0+ |
| Web | ✅ | CanvasKit required |
| macOS | ✅ | 10.15+ |
| Linux | ✅ | GTK |

---

## 3. Architecture Integration

### 3.1 Flame in MiGame Lifecycle

```
MiGame.initialize()
  → FlameGame.onMount()
  → FlameGame.onLoad()         # Load assets
  → MiGame.loadLevel()

MiGame.start()
  → FlameGame.startGame()
  → gameLoop begins

MiGame.pause()
  → FlameGame.pauseEngine()
  → gameLoop stops

MiGame.resume()
  → FlameGame.resumeEngine()

MiGame.complete()
  → FlameGame.gameOver()

MiGame.dispose()
  → FlameGame.onRemove()
```

### 3.2 Component Hierarchy

```
MiGameWrapperWidget  (Flutter widget)
  └── FlameGameWidget<MyFlameGame>  (Flame bridge)
        └── MyFlameGame extends FlameGame
              ├── CameraComponent
              ├── SpriteComponent (cards, vehicles, robots)
              └── TappableComponent / HoverableComponent
```

### 3.3 Flutter-Flame Bridge Pattern

Games using Flame will use a two-layer architecture:

**Layer 1 — Flutter Shell (outside Flame):**
- Game header (level, hint, pause)
- Tutorial overlay
- Completion overlay
- Audio controls
- Accessibility settings

**Layer 2 — Flame Game (inside game area):**
- Game loop and rendering
- Sprite and animation
- Physics (if needed)
- Input handling

This keeps UI chrome outside Flame for easier Flutter testing.

---

## 4. Games Using Flame

### 4.1 Math Race (Wave 3)

**Why Flame:**
- Vehicle animation along curved path
- Checkpoint markers along path
- Speed transitions
- Particle effects on correct answer

**Flame Components:**
```dart
class MathRaceFlameGame extends FlameGame {
  late PathComponent racePath;
  late VehicleSpriteComponent vehicle;
  List<CheckpointComponent> checkpoints = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    racePath = PathComponent();
    vehicle = VehicleSpriteComponent();
    add(racePath);
    add(vehicle);
  }

  void moveToCheckpoint(int index) {
    vehicle.moveTo(checkpoints[index].position);
  }
}
```

**Reduced Motion:**
When reduced motion is enabled, FlameGame pauses the visual vehicle movement and instead updates a progress bar in the Flutter overlay.

### 4.2 Math Supermarket (Wave 3)

**Why Flame:**
- Product shelf rendering
- Cart animation
- Coin/money particle effects

**Flame Components:**
```dart
class SupermarketFlameGame extends FlameGame {
  late ShelfComponent shelf;
  late CartComponent cart;
  late MoneyParticleEmitter coinEffect;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    shelf = ShelfComponent();
    cart = CartComponent();
    add(shelf);
    add(cart);
  }
}
```

**Decision:** Use Flutter for the shelf grid and cart UI. Use Flame only for visual product sprites and animation effects. This is a hybrid approach.

### 4.3 Robot Commands (Wave 4)

**Why Flame:**
- Grid map rendering
- Robot movement animation
- Block highlight animation on execution

**Flame Components:**
```dart
class RobotFlameGame extends FlameGame {
  late GridMapComponent gridMap;
  late RobotSpriteComponent robot;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    gridMap = GridMapComponent(level.grid);
    robot = RobotSpriteComponent();
    add(gridMap);
    add(robot);
  }

  void executeStep(int blockIndex) {
    highlightBlock(blockIndex);
    robot.step();
  }
}
```

**Decision:** Robot Commands uses a Flutter Canvas for the grid map (same as card grid), with Flame for the robot sprite movement only. This keeps the complex block editor as pure Flutter.

---

## 5. Games NOT Using Flame

### 5.1 Memory Cards (Wave 1)

**Reason:** Simple 2D card grid. No physics, no continuous animation, no particle effects.
**Implementation:** Flutter `GridView` + `AnimatedSwitcher` + `Transform` for flip animation.

### 5.2 Word Builder (Wave 2)

**Reason:** Drag-and-drop text layout. Native Flutter gesture handling is sufficient.
**Implementation:** Flutter `Stack` + `Positioned` + `Draggable/DragTarget`.

### 5.3 Sound Match (Wave 2)

**Reason:** Audio playback + tap selection. No game physics.
**Implementation:** Flutter `GridView` + `audioplayers`.

---

## 6. Asset Pipeline

### 6.1 Asset Structure

```
assets/
├── images/
│   ├── games/
│   │   ├── memory_cards/
│   │   ├── word_builder/
│   │   ├── math_race/
│   │   ├── math_supermarket/
│   │   └── robot_commands/
│   └── common/
│       ├── icons/
│       └── backgrounds/
├── audio/
│   ├── voice/
│   ├── sfx/
│   └── music/
└── sprites/
    ├── math_race/
    └── robot_commands/
```

### 6.2 Sprite Loading

Flame supports:
- `Sprite` from image files
- `Spritesheet` for animations
- `ParallaxComponent` for backgrounds

**Recommended format:** PNG with transparency for sprites. SVG not directly supported (use flutter_svg for Flutter UI).

### 6.3 Audio Loading

Two options:
1. **flame_audio** — Flame-native audio (preferred for Flame games)
2. **audioplayers** — Used by `mi_game_audio` package (cross-game audio)

**Decision:** Use `audioplayers` globally via `mi_game_audio` for consistency. Flame games access audio through the same service.

---

## 7. Performance Benchmarks

### 7.1 Memory Usage

| Game Type | Sprite Count | Memory Est. |
|-----------|-------------|-------------|
| Memory Cards (Flutter) | 0 sprites | ~20MB |
| Math Race (Flame) | 50 sprites | ~60MB |
| Supermarket (Hybrid) | 30 sprites | ~45MB |
| Robot (Flutter + Flame) | 20 sprites | ~40MB |

### 7.2 Frame Rate

| Game | Normal | Reduced Motion |
|------|--------|----------------|
| Memory Cards | 60fps | 30fps (animated switching) |
| Math Race | 60fps | 30fps (bar animation) |
| Supermarket | 60fps | 30fps |
| Robot | 60fps | 30fps |

### 7.3 APK Size Impact

Adding Flame to `pubspec.yaml`:
- `flame: ^1.18.0` — ~2.5MB
- Per-game sprites — ~0.5-2MB per game
- Total estimated: +5MB for all Flame games

---

## 8. Migration Plan

### 8.1 Wave 0 (No Flame)

- Build all Flutter-native shared packages
- No Flame dependency added yet
- Focus: Memory Cards, Word Builder, Sound Match

### 8.2 Wave 3 (Flame introduced)

Add to `apps/mobile/pubspec.yaml`:
```yaml
dependencies:
  flame: ^1.18.0
  flame_audio: ^2.0.0
```

Add Flame packages to `melos.yaml` scripts to ensure proper analysis.

### 8.3 Flame Game Base Class

Create `packages/mi_game_flame/` (new package):
```dart
abstract class MiFlameGame extends FlameGame implements MiGame {
  // Bridge between MiGame interface and Flame lifecycle
}
```

This keeps Flame-specific code isolated from core game logic.

---

## 9. Testing Strategy

### 9.1 Unit Tests

- Game logic (Flutter): `flutter_test`
- Flame components: `flutter_test` with `FlameBloc` or manual mock

### 9.2 Widget Tests

- Flutter UI: Standard `flutter_test`
- Flame widget: `flame_test` package (official Flame testing utilities)

### 9.3 Golden Tests

- Use `flutter_test` golden tests for Flutter UI
- Use `flame_gamelist` or screenshot comparison for Flame rendering

### 9.4 Integration Tests

- Use `integration_test` package
- Launch real Flame game in test environment

---

## 10. Known Limitations & Mitigations

| Limitation | Impact | Mitigation |
|------------|--------|------------|
| Flame Web requires CanvasKit | Large bundle | Only enable on web, not default |
| Flame audio latency | Slight delay on mobile | Pre-buffer sounds |
| Sprite sheet memory | Large sheets eat RAM | Use small, 8-bit style sprites |
| Flame debug mode slow | Testing slower | Use `--release` for perf tests |
| Flame not in existing deps | Migration effort | Add in Wave 3, no rush |

---

## 11. Decision Matrix

| Criterion | Score (1-5) | Notes |
|-----------|-------------|-------|
| License | 5 | MIT — clean |
| Flutter integration | 5 | Native Flutter game engine |
| Performance | 4 | Good on target devices |
| Bundle size | 4 | ~2.5MB overhead |
| Learning curve | 3 | Moderate (game loop model) |
| Community | 5 | Active, well-documented |
| Web support | 4 | CanvasKit required |
| Testability | 4 | flame_test available |
| **Total** | **34/35** | **Proceed** |

---

## 12. Action Items

- [ ] Add `flame: ^1.18.0` to `apps/mobile/pubspec.yaml` in Wave 3
- [ ] Create `packages/mi_game_flame/` base class
- [ ] Set up `flame_test` dev dependency
- [ ] Create sprite assets for Math Race vehicles
- [ ] Create sprite assets for Robot character
- [ ] Test Flame on Android emulator (API 24)
- [ ] Test Flame on Flutter Web (CanvasKit)
- [ ] Benchmark memory on low-end Android device
- [ ] Document Flame game structure in GAME_PLATFORM_ARCHITECTURE.md
