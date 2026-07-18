import 'package:hive/hive.dart';

part 'sync_queue.g.dart';

/// Types of items that can be queued for sync.
enum SyncItemType {
  attempt,
  progress,
  snapshot,
  rewardUnlock,
  sessionEnd,
  gameResult,
}

/// Status of a sync queue item.
enum SyncItemStatus {
  pending,
  syncing,
  completed,
  failed,
  quarantined,
}

/// A single item in the sync queue.
///
/// Stored in the `sync_queue` Hive box.
/// Processed FIFO (oldest first) to maintain data integrity.
@HiveType(typeId: 0)
class SyncQueueItem extends HiveObject {
  @HiveField(0)
  final String id; // UUID

  @HiveField(1)
  final String childProfileId;

  @HiveField(2)
  final String type; // SyncItemType as string

  @HiveField(3)
  final Map<String, dynamic> payload;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  int retryCount;

  @HiveField(6)
  String? lastError;

  @HiveField(7)
  String status; // SyncItemStatus as string

  /// When this item was last attempted (null if never attempted). Used for
  /// exponential backoff -- retrying a failed item immediately on every
  /// `sync()` call (e.g. one triggered per connectivity event) ignores how
  /// recently it just failed.
  @HiveField(8)
  DateTime? lastAttemptAt;

  SyncQueueItem({
    required this.id,
    required this.childProfileId,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
    this.status = 'pending',
    this.lastAttemptAt,
  });

  static String typeToWireValue(SyncItemType type) {
    switch (type) {
      case SyncItemType.attempt:
        return 'attempt';
      case SyncItemType.progress:
        return 'progress';
      case SyncItemType.snapshot:
        return 'snapshot';
      case SyncItemType.rewardUnlock:
        return 'reward_unlock';
      case SyncItemType.sessionEnd:
        return 'session_end';
      case SyncItemType.gameResult:
        return 'game_result';
    }
  }

  SyncItemType get itemType {
    switch (type) {
      case 'attempt':
        return SyncItemType.attempt;
      case 'progress':
        return SyncItemType.progress;
      case 'snapshot':
        return SyncItemType.snapshot;
      case 'reward_unlock':
        return SyncItemType.rewardUnlock;
      case 'session_end':
        return SyncItemType.sessionEnd;
      case 'game_result':
        return SyncItemType.gameResult;
      default:
        return SyncItemType.attempt;
    }
  }

  SyncItemStatus get itemStatus {
    switch (status) {
      case 'pending':
        return SyncItemStatus.pending;
      case 'syncing':
        return SyncItemStatus.syncing;
      case 'completed':
        return SyncItemStatus.completed;
      case 'failed':
        return SyncItemStatus.failed;
      case 'quarantined':
        return SyncItemStatus.quarantined;
      default:
        return SyncItemStatus.pending;
    }
  }

  /// Maximum transient-failure retries before an item is quarantined
  /// instead of retried forever (or, worse, silently stopping being
  /// retried while still showing as "failed" — see [shouldRetry]).
  static const maxRetries = 5;

  void markSyncing() {
    status = 'syncing';
    lastAttemptAt = DateTime.now();
  }

  void markCompleted() {
    status = 'completed';
  }

  /// Records a transient failure. Once [maxRetries] is exhausted, the item
  /// moves to `quarantined` rather than staying `failed` forever: a
  /// `failed` item with no retries left previously vanished from both
  /// `shouldRetry` and `failedCount` (which is defined in terms of
  /// `shouldRetry`) — an item nobody could see, and nobody would ever sync
  /// again.
  void markFailed(String error) {
    lastError = error;
    retryCount += 1;
    status = retryCount >= maxRetries ? 'quarantined' : 'failed';
  }

  void markQuarantined(String error) {
    status = 'quarantined';
    lastError = error;
  }

  /// Exponential backoff: 2^retryCount seconds, capped at 5 minutes, so a
  /// connectivity-restore event doesn't hammer a server that just rejected
  /// this exact item moments ago.
  Duration get _backoff {
    final seconds = (1 << retryCount.clamp(0, 8));
    return Duration(seconds: seconds.clamp(1, 300));
  }

  bool get _backoffElapsed {
    final last = lastAttemptAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= _backoff;
  }

  /// Is this item eligible for another attempt at all (remaining retries,
  /// `failed` status)? Doesn't consider backoff timing -- use [readyToRetry]
  /// to decide whether to actually attempt it in a given `sync()` call.
  bool get shouldRetry => retryCount < maxRetries && status == 'failed';

  /// Should this item be retried right now? [shouldRetry] plus enough time
  /// having passed since the last attempt (see [_backoff]) -- this is what
  /// `sync()` uses to pick items, so a connectivity-restore event doesn't
  /// hammer a server that just rejected this exact item moments ago.
  bool get readyToRetry => shouldRetry && _backoffElapsed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'child_profile_id': childProfileId,
        'type': type,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
        'last_error': lastError,
        'status': status,
      };
}
