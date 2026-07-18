import 'package:flutter/material.dart';
import 'package:mi_game_core/mi_game_core.dart';

/// Shared wiring for the "save on backgrounding, save on exit" half of
/// Phase 10's save policy, so each game screen doesn't hand-roll its own
/// [WidgetsBindingObserver]. The game screen still owns *when* a snapshot
/// is capturable (via [captureSnapshot]) and *what's* in it (each session's
/// own `saveSnapshot()`); this mixin only calls the platform-supplied
/// `onSaveSnapshot` callback at the right moments. The screen never writes
/// to Hive or calls the backend itself — see [onSaveSnapshot]'s doc on the
/// widget classes that use this.
mixin SnapshotLifecycleMixin<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  /// Returns the current in-progress snapshot, or null if there's nothing
  /// worth saving right now (e.g. the level already completed).
  MiGameSnapshot? captureSnapshot();

  /// Called with the captured snapshot when the app backgrounds or this
  /// screen is disposed. May be null if the platform isn't tracking
  /// snapshots for this launch (e.g. `childId == 'offline-child'`).
  void Function(MiGameSnapshot)? get onSaveSnapshot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _save();
    }
  }

  void _save() {
    final snapshot = captureSnapshot();
    if (snapshot != null) onSaveSnapshot?.call(snapshot);
  }

  @mustCallSuper
  void disposeSnapshotLifecycle() {
    _save();
    WidgetsBinding.instance.removeObserver(this);
  }
}
