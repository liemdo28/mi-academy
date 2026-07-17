import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:offline_sync/offline_sync.dart';

class _HttpFailure implements Exception {
  const _HttpFailure(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'HTTP $statusCode';
}

void main() {
  late Directory tempDir;
  late Box<SyncQueueItem> queueBox;
  late Box progressBox;
  late Box attemptBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mi-offline-sync-test-');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SyncQueueItemAdapter());
    }
    queueBox = await Hive.openBox<SyncQueueItem>('sync_queue');
    progressBox = await Hive.openBox('progress');
    attemptBox = await Hive.openBox('attempts');
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('enqueue persists privacy-safe progress and attempt items', () async {
    final service = SyncService(
      queueBox: queueBox,
      progressBox: progressBox,
      attemptBox: attemptBox,
      connectivityChecker: () async => false,
      processor: (_) async {},
    );

    await service.enqueue(
      id: 'progress-1',
      childProfileId: 'child-local',
      type: SyncItemType.progress,
      payload: {
        'gameId': 'math_race',
        'levelId': 'mr-1',
        'skillId': 'math.addition.basic',
        'mastery': 0.62,
      },
    );
    await service.enqueue(
      id: 'attempt-1',
      childProfileId: 'child-local',
      type: SyncItemType.attempt,
      payload: {
        'gameId': 'word_builder',
        'levelId': 'wb-1',
        'score': 90,
        'hintsUsed': 1,
      },
    );

    expect(service.pendingCount, 2);
    expect(queueBox.get('progress-1')!.itemType, SyncItemType.progress);
    expect(queueBox.get('attempt-1')!.itemType, SyncItemType.attempt);

    final encoded = queueBox.values.map((i) => i.toJson()).toList().toString();
    expect(encoded, isNot(contains('parent')));
    expect(encoded, isNot(contains('email')));
    expect(encoded, isNot(contains('token')));
    expect(encoded, isNot(contains('rawAnswer')));
  });

  test('offline sync keeps queued items pending without processing', () async {
    final processed = <String>[];
    final service = SyncService(
      queueBox: queueBox,
      progressBox: progressBox,
      attemptBox: attemptBox,
      connectivityChecker: () async => false,
      processor: (item) async => processed.add(item.id),
    );

    await service.enqueue(
      id: 'attempt-1',
      childProfileId: 'child-local',
      type: SyncItemType.attempt,
      payload: {'score': 10},
    );

    final result = await service.sync();

    expect(result.offline, isTrue);
    expect(result.processed, 0);
    expect(result.succeeded, 0);
    expect(processed, isEmpty);
    expect(queueBox.get('attempt-1')!.itemStatus, SyncItemStatus.pending);
    expect(service.pendingCount, 1);
  });

  test('enqueue with duplicate id replaces the queued payload once', () async {
    final service = SyncService(
      queueBox: queueBox,
      progressBox: progressBox,
      attemptBox: attemptBox,
      connectivityChecker: () async => false,
      processor: (_) async {},
    );

    await service.enqueue(
      id: 'attempt-1',
      childProfileId: 'child-local',
      type: SyncItemType.gameResult,
      payload: {'attemptId': 'attempt-1', 'score': 50},
    );
    await service.enqueue(
      id: 'attempt-1',
      childProfileId: 'child-local',
      type: SyncItemType.gameResult,
      payload: {'attemptId': 'attempt-1', 'score': 90},
    );

    expect(queueBox.length, 1);
    expect(service.pendingCount, 1);
    expect(queueBox.get('attempt-1')!.payload['score'], 90);
  });

  test('queued items survive Hive close and reopen process restart', () async {
    final service = SyncService(
      queueBox: queueBox,
      progressBox: progressBox,
      attemptBox: attemptBox,
      connectivityChecker: () async => false,
      processor: (_) async {},
    );

    await service.enqueue(
      id: 'restart-attempt',
      childProfileId: 'child-local',
      type: SyncItemType.gameResult,
      payload: {'attemptId': 'restart-attempt'},
    );
    await queueBox.close();

    queueBox = await Hive.openBox<SyncQueueItem>('sync_queue');

    expect(queueBox.get('restart-attempt'), isNotNull);
    expect(queueBox.get('restart-attempt')!.itemStatus, SyncItemStatus.pending);
  });

  test('online sync drains pending items FIFO after server confirmation',
      () async {
    final processed = <String>[];
    final service = SyncService(
      queueBox: queueBox,
      progressBox: progressBox,
      attemptBox: attemptBox,
      connectivityChecker: () async => true,
      processor: (item) async => processed.add(item.id),
    );

    await queueBox.put(
      'newer',
      SyncQueueItem(
        id: 'newer',
        childProfileId: 'child-local',
        type: SyncQueueItem.typeToWireValue(SyncItemType.progress),
        payload: {'mastery': 0.6},
        createdAt: DateTime(2026, 7, 17, 9),
      ),
    );
    await queueBox.put(
      'older',
      SyncQueueItem(
        id: 'older',
        childProfileId: 'child-local',
        type: SyncQueueItem.typeToWireValue(SyncItemType.attempt),
        payload: {'score': 80},
        createdAt: DateTime(2026, 7, 17, 8),
      ),
    );

    final result = await service.sync();

    expect(result.offline, isFalse);
    expect(result.processed, 2);
    expect(result.succeeded, 2);
    expect(processed, ['older', 'newer']);
    expect(queueBox.get('older')!.itemStatus, SyncItemStatus.completed);
    expect(queueBox.get('newer')!.itemStatus, SyncItemStatus.completed);
    expect(service.pendingCount, 0);
  });

  test('failed items are retained and retried without deleting local data',
      () async {
    final service = SyncService(
      queueBox: queueBox,
      progressBox: progressBox,
      attemptBox: attemptBox,
      connectivityChecker: () async => true,
      processor: (item) async {
        if (item.id == 'attempt-1') {
          throw StateError('temporary backend outage');
        }
      },
    );

    await attemptBox.put('attempt-1', {'score': 70});
    await service.enqueue(
      id: 'attempt-1',
      childProfileId: 'child-local',
      type: SyncItemType.attempt,
      payload: {'score': 70},
    );

    final result = await service.sync();

    expect(result.processed, 1);
    expect(result.succeeded, 0);
    final item = queueBox.get('attempt-1')!;
    expect(item.itemStatus, SyncItemStatus.failed);
    expect(item.retryCount, 1);
    expect(item.shouldRetry, isTrue);
    expect(item.lastError, contains('temporary backend outage'));
    expect(attemptBox.get('attempt-1'), {'score': 70});
    expect(service.failedCount, 1);
    expect(service.localAttemptCount, 1);
  });

  test('timeout and 500 failures remain retryable', () async {
    final service = SyncService(
      queueBox: queueBox,
      progressBox: progressBox,
      attemptBox: attemptBox,
      connectivityChecker: () async => true,
      processor: (item) async {
        if (item.id == 'timeout') {
          throw TimeoutException('upload timed out');
        }
        throw const _HttpFailure(500);
      },
      isPermanentFailure: (error, _) =>
          error is _HttpFailure && error.statusCode >= 400 && error.statusCode < 500,
    );

    await service.enqueue(
      id: 'timeout',
      childProfileId: 'child-local',
      type: SyncItemType.attempt,
      payload: {'score': 70},
    );
    await service.enqueue(
      id: 'server-500',
      childProfileId: 'child-local',
      type: SyncItemType.progress,
      payload: {'mastery': 0.4},
    );

    final result = await service.sync();

    expect(result.processed, 2);
    expect(result.succeeded, 0);
    expect(queueBox.get('timeout')!.shouldRetry, isTrue);
    expect(queueBox.get('server-500')!.shouldRetry, isTrue);
    expect(service.quarantinedCount, 0);
  });

  test('401 and malformed game result items are quarantined', () async {
    final service = SyncService(
      queueBox: queueBox,
      progressBox: progressBox,
      attemptBox: attemptBox,
      connectivityChecker: () async => true,
      processor: (item) async {
        throw const _HttpFailure(401);
      },
      isPermanentFailure: (error, _) =>
          error is _HttpFailure && error.statusCode == 401,
    );

    await service.enqueue(
      id: 'bad-auth',
      childProfileId: 'child-local',
      type: SyncItemType.progress,
      payload: {'mastery': 0.4},
    );
    await service.enqueue(
      id: 'malformed-result',
      childProfileId: 'child-local',
      type: SyncItemType.gameResult,
      payload: {'attempt_id': 'missing-game-id'},
    );

    final result = await service.sync();

    expect(result.processed, 2);
    expect(result.succeeded, 0);
    expect(queueBox.get('bad-auth')!.itemStatus, SyncItemStatus.quarantined);
    expect(queueBox.get('malformed-result')!.itemStatus, SyncItemStatus.quarantined);
    expect(service.quarantinedCount, 2);
    expect(service.failedCount, 0);
  });

  test('partial success keeps failed item and completes accepted items',
      () async {
    final service = SyncService(
      queueBox: queueBox,
      progressBox: progressBox,
      attemptBox: attemptBox,
      connectivityChecker: () async => true,
      processor: (item) async {
        if (item.id == 'fails') {
          throw const _HttpFailure(500);
        }
      },
    );

    await service.enqueue(
      id: 'succeeds',
      childProfileId: 'child-local',
      type: SyncItemType.progress,
      payload: {'mastery': 0.7},
    );
    await service.enqueue(
      id: 'fails',
      childProfileId: 'child-local',
      type: SyncItemType.attempt,
      payload: {'score': 20},
    );

    final result = await service.sync();

    expect(result.processed, 2);
    expect(result.succeeded, 1);
    expect(queueBox.get('succeeds')!.itemStatus, SyncItemStatus.completed);
    expect(queueBox.get('fails')!.itemStatus, SyncItemStatus.failed);
  });

  test('oldest pending visibility ignores completed and quarantined items',
      () async {
    await queueBox.put(
      'completed',
      SyncQueueItem(
        id: 'completed',
        childProfileId: 'child-local',
        type: SyncQueueItem.typeToWireValue(SyncItemType.progress),
        payload: const {},
        createdAt: DateTime(2026, 7, 17, 7),
        status: 'completed',
      ),
    );
    await queueBox.put(
      'older',
      SyncQueueItem(
        id: 'older',
        childProfileId: 'child-local',
        type: SyncQueueItem.typeToWireValue(SyncItemType.progress),
        payload: const {},
        createdAt: DateTime(2026, 7, 17, 8),
      ),
    );
    await queueBox.put(
      'newer',
      SyncQueueItem(
        id: 'newer',
        childProfileId: 'child-local',
        type: SyncQueueItem.typeToWireValue(SyncItemType.progress),
        payload: const {},
        createdAt: DateTime(2026, 7, 17, 9),
      ),
    );
    await queueBox.put(
      'quarantined',
      SyncQueueItem(
        id: 'quarantined',
        childProfileId: 'child-local',
        type: SyncQueueItem.typeToWireValue(SyncItemType.progress),
        payload: const {},
        createdAt: DateTime(2026, 7, 17, 6),
        status: 'quarantined',
      ),
    );
    final service = SyncService(
      queueBox: queueBox,
      progressBox: progressBox,
      attemptBox: attemptBox,
      connectivityChecker: () async => false,
    );

    expect(service.oldestPending!.id, 'older');
  });

  test('child switching and logout clear profile-scoped queue entries',
      () async {
    final service = SyncService(
      queueBox: queueBox,
      progressBox: progressBox,
      attemptBox: attemptBox,
      connectivityChecker: () async => false,
    );

    await service.enqueue(
      id: 'child-a-1',
      childProfileId: 'child-a',
      type: SyncItemType.progress,
      payload: const {},
    );
    await service.enqueue(
      id: 'child-b-1',
      childProfileId: 'child-b',
      type: SyncItemType.progress,
      payload: const {},
    );

    expect(await service.clearForChild('child-a'), 1);
    expect(queueBox.containsKey('child-a-1'), isFalse);
    expect(queueBox.containsKey('child-b-1'), isTrue);
    expect(await service.clearForLogout(), 1);
    expect(queueBox.isEmpty, isTrue);
  });

  test('wire values round-trip for every sync item type', () {
    for (final type in SyncItemType.values) {
      final item = SyncQueueItem(
        id: type.name,
        childProfileId: 'child-local',
        type: SyncQueueItem.typeToWireValue(type),
        payload: const {},
        createdAt: DateTime(2026, 7, 17),
      );
      expect(item.itemType, type);
    }
  });
}
