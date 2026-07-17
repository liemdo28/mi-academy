/// Progress gateway interface — the contract between platform and games.
///
/// Games (Dev 2) depend on this abstract interface only.
/// The platform provides the real implementation.
/// A mock (InMemoryProgressGateway) is provided for game development.
library mi_progress_gateway;

import 'shared_models.dart';

/// Abstract interface for saving/loading game progress.
///
/// Rules:
/// - No access tokens
/// - No parent passwords or emails
/// - No child PII beyond profile ID
/// - All operations must be idempotent-safe
/// - Serialize-safe for offline queuing
abstract interface class MiProgressGateway {
  /// Save a completed game result.
  /// Idempotent: duplicate attemptIds are silently ignored.
  Future<void> saveGameResult(MiGameResult result);

  /// Save or update an in-progress game snapshot.
  Future<void> saveSnapshot(MiGameSnapshot snapshot);

  /// Load the most recent snapshot for a child+game+level combo.
  /// Returns null if no snapshot exists.
  Future<MiGameSnapshot?> loadSnapshot({
    required String childProfileId,
    required String gameId,
    required String levelId,
  });
}
