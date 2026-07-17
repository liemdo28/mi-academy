import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'sync_queue.dart';

typedef ConnectivityChecker = Future<bool> Function();
typedef SyncItemProcessor = Future<void> Function(SyncQueueItem item);

/// Background sync service.
///
/// SyncQueue drains when connectivity is restored.
/// Process order: oldest first (FIFO).
/// Never deletes local data before server confirms.
class SyncService {
  final Box _queueBox;
  final Box _progressBox;
  final Box _attemptBox;
  final Connectivity _connectivity = Connectivity();
  final ConnectivityChecker? _connectivityChecker;
  final SyncItemProcessor? _processor;
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService({
    required Box queueBox,
    required Box progressBox,
    required Box attemptBox,
    ConnectivityChecker? connectivityChecker,
    SyncItemProcessor? processor,
  })  : _queueBox = queueBox,
        _progressBox = progressBox,
        _attemptBox = attemptBox,
        _connectivityChecker = connectivityChecker,
        _processor = processor;

  /// Start listening for connectivity changes and auto-sync.
  void start() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        sync();
      }
    });
  }

  /// Stop listening.
  void stop() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Manually trigger sync.
  Future<SyncResult> sync() async {
    if (_isSyncing) return const SyncResult(processed: 0, succeeded: 0);
    _isSyncing = true;

    final results = await _checkConnectivity();
    if (!results) {
      _isSyncing = false;
      return const SyncResult(processed: 0, succeeded: 0, offline: true);
    }

    var processed = 0;
    var succeeded = 0;

    // Get all pending items, sorted by createdAt (oldest first)
    final pending = _queueBox.values
        .cast<SyncQueueItem>()
        .where(
          (i) => i.itemStatus == SyncItemStatus.pending || i.shouldRetry,
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final item in pending) {
      processed++;
      try {
        item.markSyncing();
        await _processItem(item);
        item.markCompleted();
        succeeded++;
      } catch (e) {
        item.markFailed(e.toString());
      }
      await item.save();
    }

    _isSyncing = false;
    return SyncResult(processed: processed, succeeded: succeeded);
  }

  /// Add an item to the sync queue.
  Future<void> enqueue({
    required String id,
    required String childProfileId,
    required SyncItemType type,
    required Map<String, dynamic> payload,
  }) async {
    final item = SyncQueueItem(
      id: id,
      childProfileId: childProfileId,
      type: SyncQueueItem.typeToWireValue(type),
      payload: payload,
      createdAt: DateTime.now(),
    );
    await _queueBox.put(id, item);
  }

  Future<void> _processItem(SyncQueueItem item) async {
    if (_processor != null) {
      await _processor(item);
      return;
    }

    // Route to appropriate endpoint based on type
    switch (item.itemType) {
      case SyncItemType.attempt:
        await _syncAttempt(item);
        break;
      case SyncItemType.progress:
        await _syncProgress(item);
        break;
      case SyncItemType.snapshot:
        // Snapshots are optional — skip on failure
        break;
      case SyncItemType.rewardUnlock:
        await _syncReward(item);
        break;
      case SyncItemType.sessionEnd:
        await _syncSession(item);
        break;
    }
  }

  Future<void> _syncAttempt(SyncQueueItem item) async {
    // HTTP POST to /api/v1/sync/attempts
    // Implementation uses the Dio client passed in
    // Placeholder: real implementation in mobile app
  }

  Future<void> _syncProgress(SyncQueueItem item) async {
    // HTTP POST to /api/v1/sync/progress
  }

  Future<void> _syncReward(SyncQueueItem item) async {
    // HTTP POST to /api/v1/rewards/children/{id}/check
  }

  Future<void> _syncSession(SyncQueueItem item) async {
    // HTTP POST to record daily session
  }

  Future<bool> _checkConnectivity() async {
    if (_connectivityChecker != null) {
      return _connectivityChecker();
    }
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Get sync queue status for UI.
  int get pendingCount => _queueBox.values
      .cast<SyncQueueItem>()
      .where((i) => i.itemStatus == SyncItemStatus.pending)
      .length;

  int get failedCount => _queueBox.values
      .cast<SyncQueueItem>()
      .where((i) => i.shouldRetry)
      .length;

  /// Number of locally stored progress records awaiting or backing sync.
  int get localProgressCount => _progressBox.length;

  /// Number of locally stored attempt records awaiting or backing sync.
  int get localAttemptCount => _attemptBox.length;
}

class SyncResult {
  final int processed;
  final int succeeded;
  final bool offline;

  const SyncResult({
    required this.processed,
    required this.succeeded,
    this.offline = false,
  });
}
