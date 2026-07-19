import 'package:flutter/material.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_engines/mi_game_engines.dart';

import '../placement_games/placement_game_adapter.dart';
import '../placement_games/placement_game_localization.dart';
import '../snapshot_lifecycle_mixin.dart';

/// Game 12 -- Word Sorter. Sorts words/picture-supported items into 2-4
/// labeled groups using the shared Placement Engine's many-to-one
/// placement support (one target per group, `capacity` > 1) -- not an
/// independent drag-and-drop implementation. See
/// `placement_game_adapter.dart` for the MiLevel<->PlacementContent
/// conversion shared with Shape Builder.
class WordSorterScreen extends StatefulWidget {
  const WordSorterScreen({
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
      locale == 'en' ? 'Word Sorter' : 'Phân loại từ';

  @override
  State<WordSorterScreen> createState() => _WordSorterScreenState();
}

class _WordSorterScreenState extends State<WordSorterScreen>
    with WidgetsBindingObserver, SnapshotLifecycleMixin<WordSorterScreen> {
  int _lastAttempts = 0;
  bool _completed = false;

  @override
  void Function(MiGameSnapshot)? get onSaveSnapshot => widget.onSaveSnapshot;

  @override
  MiGameSnapshot? captureSnapshot() {
    if (_completed || _lastAttempts == 0) return null;
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
