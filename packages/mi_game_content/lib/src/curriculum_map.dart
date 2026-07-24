import 'package:equatable/equatable.dart';

/// One (age band, subject) position in the curriculum -- e.g. "junior
/// letters" -- with the ordered skill list a child at that age/subject is
/// expected to work through. Parsed from `content/curriculum/age_*.json`.
///
/// [nodeId] is derived (`'$ageGroup.$subjectId'`), not invented: it is a
/// stable composite of two fields the curriculum files already declare
/// (top-level `ageGroup`, and each key under `subjects`), not a new ID
/// scheme layered on top of the content.
class CurriculumNode extends Equatable {
  const CurriculumNode({
    required this.ageGroup,
    required this.subjectId,
    required this.skillIds,
    required this.description,
  });

  final String ageGroup;
  final String subjectId;
  final List<String> skillIds;
  final Map<String, String> description;

  String get nodeId => '$ageGroup.$subjectId';

  @override
  List<Object?> get props => [ageGroup, subjectId, skillIds, description];
}

/// Parsed, queryable form of all `content/curriculum/age_*.json` files.
class CurriculumMap {
  CurriculumMap(this.nodes);

  final List<CurriculumNode> nodes;

  /// Parses one age-band curriculum file's already-decoded JSON.
  factory CurriculumMap.fromAgeFiles(List<Map<String, dynamic>> ageFilesJson) {
    final nodes = <CurriculumNode>[];
    for (final json in ageFilesJson) {
      final ageGroup = json['ageGroup'] as String;
      final subjects = json['subjects'] as Map<String, dynamic>;
      for (final entry in subjects.entries) {
        final subjectJson = entry.value as Map<String, dynamic>;
        nodes.add(CurriculumNode(
          ageGroup: ageGroup,
          subjectId: entry.key,
          skillIds:
              (subjectJson['skills'] as List).map((e) => e as String).toList(),
          description: subjectJson['description'] != null
              ? Map<String, String>.from(subjectJson['description'] as Map)
              : const {},
        ));
      }
    }
    return CurriculumMap(nodes);
  }

  late final Map<String, CurriculumNode> _byNodeId = {
    for (final node in nodes) node.nodeId: node,
  };

  CurriculumNode? node(String nodeId) => _byNodeId[nodeId];

  /// The curriculum node an (ageGroup, subjectId) pair resolves to, or
  /// null if that age band doesn't cover that subject yet (e.g. 'junior'
  /// has no 'science' node -- science starts at 'explorer').
  CurriculumNode? nodeFor(
          {required String ageGroup, required String subjectId}) =>
      _byNodeId['$ageGroup.$subjectId'];

  /// The curriculum node(s) that list [skillId] -- normally one, but
  /// reported as a list so [ActivityMappingResolver] can flag it as an
  /// inconsistency if a skill is (incorrectly) claimed by more than one
  /// node for the same age group.
  List<CurriculumNode> nodesContaining(String skillId) =>
      nodes.where((n) => n.skillIds.contains(skillId)).toList();
}
