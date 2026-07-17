# Game Performance Report

**Date:** 2026-07-17

## 1. Performance Strategy

### 1.1 Offline-First Architecture
All games load level content from the app bundle. No network required for gameplay. Background sync for progress when online.

### 1.2 Rendering Strategy
- **Waves 1-2 (Memory Cards, Word Builder, Sound Match):** Flutter-native rendering. No game engine dependency. ~60fps on mid-range devices.
- **Waves 3-4 (Math Race, Math Supermarket, Robot Commands):** Flutter-native or Flame ^1.18.0.

### 1.3 Memory Management
- Memory Cards: card grid only renders visible cards. Unmatched cards use minimal state.
- Robot Commands: grid is a fixed-size widget, no dynamic allocation.
- All games: dispose() cancels timers and releases resources.

### 1.4 Snapshot Size
- Memory Cards: ~200 bytes/level (card IDs + states)
- Robot Commands: ~100 bytes/level (robot pos + program)
- Choice games: ~50 bytes/level (selected option)

## 2. Power & Battery

- No background audio loops
- Animations pause when game is paused
- No GPS or network polling during gameplay
- Reduced motion mode disables animation timers

## 3. Offline Guarantees

- All 6 games work fully offline
- Progress saves locally before any network attempt
- MiGameSnapshot ensures state survives app kill

## 4. Startup Performance

- Games use lazy loading via Flutter's widget tree
- No splash/loading screen for individual games (only app-level splash)
- mi_game_core initializes synchronously (no async assets needed at start)

## 5. Accessibility Performance

- Reduced motion disables AnimatedBuilder controllers
- Screen reader mode skips decorative animations
- No high-frequency polling (event-driven architecture)
