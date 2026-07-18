import 'package:equatable/equatable.dart';
import 'dart:convert';

/// Serializable snapshot of game state for save/restore.
///
/// Every game must be able to save its state to this format
/// and restore from it — enabling offline play and interruption recovery.
class MiGameSnapshot extends Equatable {
  const MiGameSnapshot({
    this.schemaVersion = 2,
    this.gameVersion = '1.0.0',
    required this.gameId,
    required this.levelId,
    required this.childProfileId,
    required this.state,
    required this.createdAt,
    this.score = 0,
    this.attemptsUsed = 0,
    this.hintsUsed = 0,
    this.itemsCompleted = 0,
    this.totalItems = 0,
    this.metadata = const {},
    this.checksum,
  });

  /// Schema version for forward/backward compatibility.
  final int schemaVersion;

  /// Game implementation/content version that produced this snapshot.
  final String gameVersion;

  final String gameId;
  final String levelId;
  final String childProfileId;

  /// Full game-specific state map.
  /// Each game defines its own schema within this map.
  final Map<String, dynamic> state;

  /// Current score.
  final int score;

  /// Number of attempts used so far.
  final int attemptsUsed;

  /// Number of hints used so far.
  final int hintsUsed;

  /// Items completed (e.g., matched pairs, answered questions).
  final int itemsCompleted;

  /// Total items required to complete the level.
  final int totalItems;

  /// When this snapshot was created.
  final DateTime createdAt;

  /// Contract alias for [createdAt].
  DateTime get savedAt => createdAt;

  /// Additional game-specific snapshot data.
  final Map<String, dynamic> metadata;

  /// Deterministic FNV-1a checksum over the stable snapshot payload.
  final String? checksum;

  /// Create a unique key for storage.
  String get storageKey => '${gameId}_${levelId}_$childProfileId';

  /// Whether the level is considered in-progress (some items done).
  bool get inProgress => itemsCompleted > 0 && itemsCompleted < totalItems;

  /// Progress ratio (0.0 to 1.0).
  double get progress => totalItems > 0 ? itemsCompleted / totalItems : 0.0;

  /// True when the stored checksum is absent (legacy v1) or matches payload.
  bool get hasValidIntegrity {
    if (checksum == null) return true;
    return checksum == computeChecksum();
  }

  bool canRestoreFor({
    required String childProfileId,
    required String gameId,
    required String levelId,
    int maxSupportedSchemaVersion = 2,
  }) {
    return this.childProfileId == childProfileId &&
        this.gameId == gameId &&
        this.levelId == levelId &&
        schemaVersion <= maxSupportedSchemaVersion &&
        hasValidIntegrity;
  }

  /// Convert to JSON map for persistence.
  Map<String, dynamic> toJson() {
    final payload = _stablePayload();
    return {
      ...payload,
      'checksum': checksum ?? _checksumForPayload(payload),
    };
  }

  Map<String, dynamic> _stablePayload() => {
        'schema_version': schemaVersion,
        'game_version': gameVersion,
        'game_id': gameId,
        'level_id': levelId,
        'child_profile_id': childProfileId,
        'saved_at': createdAt.toIso8601String(),
        'state': state,
        'score': score,
        'attempts_used': attemptsUsed,
        'hints_used': hintsUsed,
        'items_completed': itemsCompleted,
        'total_items': totalItems,
        'created_at': createdAt.toIso8601String(),
        'metadata': metadata,
      };

  String computeChecksum() => _checksumForPayload(_stablePayload());

  static String _checksumForPayload(Map<String, dynamic> payload) {
    final encoded = _canonicalJson(payload);
    var hash = 0x811c9dc5;
    for (final codeUnit in encoded.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static String _canonicalJson(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((e) => e.toString()).toList()..sort();
      return '{${keys.map((key) => '${jsonEncode(key)}:${_canonicalJson(value[key])}').join(',')}}';
    }
    if (value is Iterable) {
      return '[${value.map(_canonicalJson).join(',')}]';
    }
    return jsonEncode(value);
  }

  /// Reconstruct from JSON map.
  factory MiGameSnapshot.fromJson(Map<String, dynamic> json) {
    return MiGameSnapshot(
      schemaVersion: json['schema_version'] as int? ?? 1,
      gameVersion:
          (json['game_version'] ?? json['gameVersion'] ?? '1.0.0') as String,
      gameId: (json['game_id'] ?? json['gameId']) as String,
      levelId: (json['level_id'] ?? json['levelId']) as String,
      childProfileId:
          (json['child_profile_id'] ?? json['childProfileId']) as String,
      state: Map<String, dynamic>.from(json['state'] as Map),
      createdAt: DateTime.parse(
        (json['saved_at'] ?? json['created_at'] ?? json['createdAt']) as String,
      ),
      score: json['score'] as int? ?? 0,
      attemptsUsed:
          (json['attempts_used'] ?? json['attemptsUsed']) as int? ?? 0,
      hintsUsed: (json['hints_used'] ?? json['hintsUsed']) as int? ?? 0,
      itemsCompleted:
          (json['items_completed'] ?? json['itemsCompleted']) as int? ?? 0,
      totalItems: (json['total_items'] ?? json['totalItems']) as int? ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      checksum: json['checksum'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        gameId,
        levelId,
        childProfileId,
        schemaVersion,
        gameVersion,
        state,
        score,
        attemptsUsed,
        hintsUsed,
        itemsCompleted,
        totalItems,
        createdAt,
        metadata,
      ];
}
