import 'package:hive/hive.dart';

part 'sync_queue.g.dart';

/// Types of items that can be queued for sync.
enum SyncItemType {
  attempt,
  progress,
  snapshot,
  rewardUnlock,
  sessionEnd,
}

/// Status of a sync queue item.
enum SyncItemStatus {
  pending,
  syncing,
  completed,
  failed,
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

  SyncQueueItem({
    required this.id,
    required this.childProfileId,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
    this.status = 'pending',
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
      default:
        return SyncItemStatus.pending;
    }
  }

  void markSyncing() {
    status = 'syncing';
  }

  void markCompleted() {
    status = 'completed';
  }

  void markFailed(String error) {
    status = 'failed';
    lastError = error;
    retryCount += 1;
  }

  /// Should this item be retried? Max 5 retries.
  bool get shouldRetry => retryCount < 5 && status == 'failed';

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
