import 'package:flutter/material.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_engines/mi_game_engines.dart';

import '../placement_games/placement_game_adapter.dart';
import '../placement_games/placement_game_localization.dart';
import '../snapshot_lifecycle_mixin.dart';

/// Game 11 -- Shape Builder. Reuses the shared Placement Engine
/// (`packages/mi_game_engines`) directly rather than a game-specific drag
/// controller: this screen's only job is converting between the
/// repository-wide [MiLevel]/[MiCompletionResult]/[MiGameSnapshot]
/// contract and the engine's own [PlacementContent]/[PlacementResult]
/// shapes (see `placement_game_adapter.dart`), and supplying locale text
/// (see `placement_game_localization.dart` for shared engine chrome, and
/// this file for Shape-Builder-specific title/description).
class ShapeBuilderScreen extends StatefulWidget {
  const ShapeBuilderScreen({
    super.key,
    required this.level,
    required this.allLevels,
    this.onExit,
    this.onComplete,
    this.initialSnapshot,
    this.onSaveSnapshot,
    this.reduceMotion = false,
    this.locale = 'vi',
    this.childProfileId = 'offline-child',
  });

  final MiLevel level;
  final List<MiLevel> allLevels;
  final VoidCallback? onExit;
  final void Function(MiCompletionResult)? onComplete;
  final MiGameSnapshot? initialSnapshot;
  final void Function(MiGameSnapshot)? onSaveSnapshot;
  final bool reduceMotion;
  final String locale;
  final String childProfileId;

  static String titleFor(String locale) =>
      locale == 'en' ? 'Shape Builder' : 'Xây hình khối';

  @override
  State<ShapeBuilderScreen> createState() => _ShapeBuilderScreenState();
}

class _ShapeBuilderScreenState extends State<ShapeBuilderScreen>
    with WidgetsBindingObserver, SnapshotLifecycleMixin<ShapeBuilderScreen> {
  int _lastAttempts = 0;
  bool _completed = false;

  @override
  void Function(MiGameSnapshot)? get onSaveSnapshot => widget.onSaveSnapshot;

  @override
  MiGameSnapshot? captureSnapshot() {
    if (_completed || _lastAttempts == 0) return null;
    // Placement Engine does not yet expose per-placement state for
    // mid-level resume (see docs/game-engine-architecture.md's Placement
    // section) -- this records that a level is "in progress" (attempt
    // count survives a background/relaunch) without restoring exact
    // piece positions. Documented limitation, not a silent gap.
    return MiGameSnapshot(
      gameId: widget.level.gameId,
      levelId: widget.level.id,
      childProfileId: widget.childProfileId,
      state: const {},
      createdAt: DateTime.now(),
      attemptsUsed: _lastAttempts,
      itemsCompleted: 0,
      totalItems: 1,
    );
  }

  @override
  void dispose() {
    disposeSnapshotLifecycle();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlacementScreen(
      rawContent: buildPlacementRawContent(widget.level, widget.locale),
      localization: buildPlacementLocalization(widget.locale),
      reducedMotion: widget.reduceMotion,
      onExit: widget.onExit ?? () {},
      onSaveProgress: (attempts) => _lastAttempts = attempts,
      onComplete: (result) {
        _completed = true;
        widget.onComplete?.call(
          placementResultToCompletion(
            result: result,
            level: widget.level,
            childProfileId: widget.childProfileId,
          ),
        );
      },
    );
  }
}
