import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/services/api_sync_processor.dart';
import 'package:offline_sync/offline_sync.dart';

void main() {
  test('routes progress queue items to backend progress sync', () async {
    final client = _FakeSyncApiClient();
    final processor = ApiSyncProcessor(client);
    final item = _item(
      id: 'progress-1',
      type: SyncItemType.progress,
      payload: {
        'id': 'progress-1',
        'child_id': 'child-1',
        'lesson_id': 'lesson-1',
        'status': 'completed',
        'mastery_score': 0.8,
        'total_attempts': 3,
      },
    );

    await processor(item);

    expect(client.progressCalls, [
      [item.payload],
    ]);
    expect(client.attemptCalls, isEmpty);
  });

  test('routes attempt queue items to backend attempt sync', () async {
    final client = _FakeSyncApiClient();
    final processor = ApiSyncProcessor(client);
    final item = _item(
      id: 'attempt-1',
      type: SyncItemType.attempt,
      payload: {
        'id': 'attempt-1',
        'child_id': 'child-1',
        'game_id': 'math_race',
        'is_correct': true,
        'response_time_ms': 1200,
        'hint_count': 0,
      },
    );

    await processor(item);

    expect(client.attemptCalls, [
      [item.payload],
    ]);
    expect(client.progressCalls, isEmpty);
  });

  test('keeps local snapshots local until server contract exists', () async {
    final client = _FakeSyncApiClient();
    final processor = ApiSyncProcessor(client);

    await processor(
      _item(
        id: 'snapshot-1',
        type: SyncItemType.snapshot,
        payload: {'game_id': 'memory_cards'},
      ),
    );

    expect(client.progressCalls, isEmpty);
    expect(client.attemptCalls, isEmpty);
    expect(client.rewardChecks, isEmpty);
  });

  test('routes session-end queue items to backend session sync', () async {
    final client = _FakeSyncApiClient();
    final processor = ApiSyncProcessor(client);
    final item = _item(
      id: 'session-1',
      type: SyncItemType.sessionEnd,
      payload: {
        'id': 'session-1',
        'child_id': 'child-1',
        'session_date': '2026-07-17',
        'duration_seconds': 900,
        'lessons_completed': 1,
        'games_completed': 2,
      },
    );

    await processor(item);

    expect(client.sessionCalls, [
      [item.payload],
    ]);
  });
}

SyncQueueItem _item({
  required String id,
  required SyncItemType type,
  required Map<String, dynamic> payload,
}) {
  return SyncQueueItem(
    id: id,
    childProfileId: 'child-1',
    type: SyncQueueItem.typeToWireValue(type),
    payload: payload,
    createdAt: DateTime.utc(2026, 7, 17),
  );
}

class _FakeSyncApiClient implements SyncApiClient {
  final progressCalls = <List<dynamic>>[];
  final attemptCalls = <List<dynamic>>[];
  final sessionCalls = <List<dynamic>>[];
  final rewardChecks = <String>[];

  @override
  Future<Map<String, dynamic>> syncProgress(List<dynamic> items) async {
    progressCalls.add(items);
    return {'accepted': items.length};
  }

  @override
  Future<Map<String, dynamic>> syncAttempts(List<dynamic> items) async {
    attemptCalls.add(items);
    return {'accepted': items.length, 'total': items.length};
  }

  @override
  Future<Map<String, dynamic>> syncSessions(List<dynamic> items) async {
    sessionCalls.add(items);
    return {'accepted': items.length};
  }

  @override
  Future<Map<String, dynamic>> checkRewards(String childId) async {
    rewardChecks.add(childId);
    return {'unlocked': []};
  }
}
