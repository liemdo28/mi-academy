import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:offline_sync/offline_sync.dart';

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
