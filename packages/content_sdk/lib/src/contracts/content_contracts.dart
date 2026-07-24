/// Content contract registry with metadata.
/// Single source of truth for all content-related contract definitions.
library;

/// Metadata for a single content contract.
class ContentContractMeta {
  final String contractId;
  final int schemaVersion;
  final String semanticVersion;
  final String owner;
  final String compatibility;
  final String description;

  const ContentContractMeta({
    required this.contractId,
    required this.schemaVersion,
    required this.semanticVersion,
    required this.owner,
    required this.compatibility,
    required this.description,
  });
}

/// Central registry of all content contracts.
class ContentContracts {
  ContentContracts._();

  static const List<ContentContractMeta> all = [
    ContentContractMeta(
      contractId: 'mi.content.lesson',
      schemaVersion: 1,
      semanticVersion: '1.0.0',
      owner: 'Dev7-Integration',
      compatibility: 'backward',
      description: 'A lesson in the curriculum with skills and levels.',
    ),
    ContentContractMeta(
      contractId: 'mi.content.level',
      schemaVersion: 1,
      semanticVersion: '1.0.0',
      owner: 'Dev7-Integration',
      compatibility: 'backward',
      description:
          'A game level within a lesson with difficulty and prerequisites.',
    ),
    ContentContractMeta(
      contractId: 'mi.content.curriculum',
      schemaVersion: 1,
      semanticVersion: '1.0.0',
      owner: 'Dev7-Integration',
      compatibility: 'backward',
      description: 'A curriculum for an age group with lessons.',
    ),
    ContentContractMeta(
      contractId: 'mi.content.localization',
      schemaVersion: 1,
      semanticVersion: '1.0.0',
      owner: 'Dev7-Integration',
      compatibility: 'backward',
      description: 'Localized string entry with language context.',
    ),
    ContentContractMeta(
      contractId: 'mi.content.lesson-progress',
      schemaVersion: 1,
      semanticVersion: '1.0.0',
      owner: 'Dev7-Integration',
      compatibility: 'backward',
      description: 'Child progress through a lesson.',
    ),
  ];

  static ContentContractMeta? lookup(String contractId) {
    for (final c in all) {
      if (c.contractId == contractId) return c;
    }
    return null;
  }
}
