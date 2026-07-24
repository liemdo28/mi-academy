/// Game contract registry with metadata and forbidden-field enforcement.
/// Single source of truth for all game-related contract definitions.
library;

/// Metadata for a single game contract.
class GameContractMeta {
  final String contractId;
  final int schemaVersion;
  final String semanticVersion;
  final String owner;
  final String compatibility;
  final String description;

  const GameContractMeta({
    required this.contractId,
    required this.schemaVersion,
    required this.semanticVersion,
    required this.owner,
    required this.compatibility,
    required this.description,
  });
}

/// Central registry of all game contracts.
class GameContracts {
  GameContracts._();

  /// All registered game contracts with version metadata.
  static const List<GameContractMeta> all = [
    GameContractMeta(
      contractId: 'mi.game.launch-request',
      schemaVersion: 2,
      semanticVersion: '1.2.0',
      owner: 'Dev7-Integration',
      compatibility: 'backward',
      description:
          'Request to launch a game session with accessibility and audio config.',
    ),
    GameContractMeta(
      contractId: 'mi.game.result',
      schemaVersion: 2,
      semanticVersion: '1.2.0',
      owner: 'Dev7-Integration',
      compatibility: 'backward',
      description: 'Result of a completed game session with mastery evidence.',
    ),
    GameContractMeta(
      contractId: 'mi.game.snapshot',
      schemaVersion: 2,
      semanticVersion: '1.1.0',
      owner: 'Dev7-Integration',
      compatibility: 'backward',
      description: 'Snapshot of game state for save/resume.',
    ),
    GameContractMeta(
      contractId: 'mi.game.accessibility-config',
      schemaVersion: 1,
      semanticVersion: '1.0.0',
      owner: 'Dev7-Integration',
      compatibility: 'backward',
      description: 'Accessibility configuration for game sessions.',
    ),
    GameContractMeta(
      contractId: 'mi.game.audio-preferences',
      schemaVersion: 1,
      semanticVersion: '1.0.0',
      owner: 'Dev7-Integration',
      compatibility: 'backward',
      description: 'Audio preferences for game sessions.',
    ),
    GameContractMeta(
      contractId: 'mi.game.skill-evidence',
      schemaVersion: 1,
      semanticVersion: '1.0.0',
      owner: 'Dev7-Integration',
      compatibility: 'backward',
      description: 'Evidence of skill mastery from game play.',
    ),
  ];

  /// Fields that are NEVER allowed on game contracts (security).
  static const List<String> forbiddenFields = [
    'accessToken',
    'refreshToken',
    'password',
    'token',
    'apiKey',
    'secret',
    'privateKey',
    'sessionId',
    'creditCard',
    'ssn',
    'email',
    'phoneNumber',
  ];

  /// Checks a map for forbidden fields. Returns list of violations.
  static List<String> checkForbiddenFields(Map<String, dynamic> data) {
    final violations = <String>[];
    for (final key in data.keys) {
      if (forbiddenFields.contains(key)) {
        violations.add(key);
      }
    }
    return violations;
  }

  /// Looks up contract metadata by ID.
  static GameContractMeta? lookup(String contractId) {
    for (final c in all) {
      if (c.contractId == contractId) return c;
    }
    return null;
  }
}
