import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'sync_queue.dart';

typedef ConnectivityChecker = Future<bool> Function();
typedef SyncItemProcessor = Future<void> Function(SyncQueueItem item);
typedef SyncFailureClassifier = bool Function(Object error, SyncQueueItem item);

class PermanentSyncFailure implements Exception {
  const PermanentSyncFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

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
  final SyncFailureClassifier? _isPermanentFailure;
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService({
    required Box queueBox,
    required Box progressBox,
    required Box attemptBox,
    ConnectivityChecker? connectivityChecker,
    SyncItemProcessor? processor,
    SyncFailureClassifier? isPermanentFailure,
  })  : _queueBox = queueBox,
        _progressBox = progressBox,
        _attemptBox = attemptBox,
        _connectivityChecker = connectivityChecker,
        _processor = processor,
        _isPermanentFailure = isPermanentFailure;

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

    // Get all pending items, sorted by createdAt (oldest first). Failed
    // items still in backoff (readyToRetry false) are skipped this pass —
    // they remain `shouldRetry`-eligible and will be picked up once their
    // backoff window elapses on a later sync() call.
    final pending = _queueBox.values
        .cast<SyncQueueItem>()
        .where(
          (i) => i.itemStatus == SyncItemStatus.pending || i.readyToRetry,
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final item in pending) {
      processed++;
      try {
        _validateItem(item);
        item.markSyncing();
        await _processItem(item);
        item.markCompleted();
        succeeded++;
      } catch (e) {
        if (e is PermanentSyncFailure || (_isPermanentFailure?.call(e, item) ?? false)) {
          item.markQuarantined(e.toString());
        } else {
          item.markFailed(e.toString());
        }
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

  /// Permanently deletes every queued item for [childProfileId], including
  /// ones that never synced.
  ///
  /// **Not** for routine child-switching in the UI — switching the active
  /// child must never delete another child's still-pending offline
  /// progress (every [SyncQueueItem] already carries its own
  /// `childProfileId` and syncs independently of whichever child is
  /// currently active). This is for explicit data-deletion requests (e.g.
  /// "delete my child's account/data") where losing unsynced items is the
  /// intended outcome, not an accident.
  Future<int> clearForChild(String childProfileId) async {
    final keys = _queueBox.keys
        .where((key) => _queueBox.get(key)?.childProfileId == childProfileId)
        .toList(growable: false);
    await _queueBox.deleteAll(keys);
    return keys.length;
  }

  /// Permanently deletes the entire queue, for every child.
  ///
  /// **Not** for routine parent logout — "never silently lose queued
  /// learning data" means logout should attempt [sync] first (best-effort;
  /// items that don't sync stay queued, scoped to their child, and will
  /// sync on a future login) rather than delete anything. This exists for
  /// account-level data deletion, same caveat as [clearForChild].
  Future<int> clearForLogout() async {
    final count = _queueBox.length;
    await _queueBox.clear();
    return count;
  }

  SyncQueueItem? get oldestPending {
    final pending = _queueBox.values
        .cast<SyncQueueItem>()
        .where((i) => i.itemStatus == SyncItemStatus.pending || i.shouldRetry)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return pending.isEmpty ? null : pending.first;
  }

  int get quarantinedCount => _queueBox.values
      .cast<SyncQueueItem>()
      .where((i) => i.itemStatus == SyncItemStatus.quarantined)
      .length;

  void _validateItem(SyncQueueItem item) {
    if (item.id.trim().isEmpty) {
      throw const PermanentSyncFailure('Malformed sync item: missing id');
    }
    if (item.childProfileId.trim().isEmpty) {
      throw const PermanentSyncFailure('Malformed sync item: missing childProfileId');
    }
    if (item.itemType == SyncItemType.gameResult && item.payload['game_id'] is! String) {
      throw const PermanentSyncFailure('Malformed game_result sync item: missing game_id');
    }
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
      case SyncItemType.gameResult:
        // No default HTTP mapping here — the mobile app always supplies a
        // custom `processor` (ApiSyncProcessor) that knows the game_id path.
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
    // Reward refresh uses GET /api/v1/rewards/children/{id}/rewards
    // in the mobile API client.
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

  /// Average retry count across items that have failed at least once
  /// (pending, quarantined, or still-retryable) -- an operational signal
  /// for "is the backend/network generally healthy," not just a single
  /// queue-size number.
  double get averageRetryCount {
    final attempted = _queueBox.values
        .cast<SyncQueueItem>()
        .where((i) => i.retryCount > 0)
        .toList();
    if (attempted.isEmpty) return 0;
    final total = attempted.fold<int>(0, (sum, i) => sum + i.retryCount);
    return total / attempted.length;
  }
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
