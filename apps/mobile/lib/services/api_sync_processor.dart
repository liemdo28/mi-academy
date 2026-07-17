import 'package:offline_sync/offline_sync.dart';

import 'api_service.dart';

abstract class SyncApiClient {
  Future<Map<String, dynamic>> syncProgress(List<dynamic> items);
  Future<Map<String, dynamic>> syncAttempts(List<dynamic> items);
  Future<Map<String, dynamic>> syncSessions(List<dynamic> items);
  Future<Map<String, dynamic>> checkRewards(String childId);
}

class ApiServiceSyncClient implements SyncApiClient {
  ApiServiceSyncClient(this._api);

  final ApiService _api;

  @override
  Future<Map<String, dynamic>> syncProgress(List<dynamic> items) {
    return _api.syncProgress(items);
  }

  @override
  Future<Map<String, dynamic>> syncAttempts(List<dynamic> items) {
    return _api.syncAttempts(items);
  }

  @override
  Future<Map<String, dynamic>> syncSessions(List<dynamic> items) {
    return _api.syncSessions(items);
  }

  @override
  Future<Map<String, dynamic>> checkRewards(String childId) {
    return _api.checkRewards(childId);
  }
}

class ApiSyncProcessor {
  const ApiSyncProcessor(this._client);

  final SyncApiClient _client;

  Future<void> call(SyncQueueItem item) async {
    switch (item.itemType) {
      case SyncItemType.progress:
        await _client.syncProgress([item.payload]);
        break;
      case SyncItemType.attempt:
        await _client.syncAttempts([item.payload]);
        break;
      case SyncItemType.rewardUnlock:
        await _client.checkRewards(item.childProfileId);
        break;
      case SyncItemType.snapshot:
        // Snapshots are local recovery state; backend sync is intentionally
        // skipped until a dedicated server contract exists.
        break;
      case SyncItemType.sessionEnd:
        await _client.syncSessions([item.payload]);
        break;
    }
  }
}
