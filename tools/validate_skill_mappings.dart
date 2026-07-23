import 'dart:convert';
import 'dart:io';

/// Validates the canonical (gameId, levelId) -> skillId mapping across all
/// real MI Academy content -- content/skills/skill_taxonomy.json,
/// content/curriculum/age_*.json, and every apps/mobile/assets/levels/*.json
/// file. This is the CI-runnable counterpart to
/// packages/mi_game_content's ActivityMappingResolver (which runs inside
/// the app at completion time): same rules, checked in bulk against every
/// level up front instead of one completion at a time.
///
/// Deliberately stdlib-only (dart:io + dart:convert, no package imports),
/// same as tools/validate_brand_assets.dart -- runnable via
/// `dart run tools/validate_skill_mappings.dart` without needing the
/// Flutter SDK or `flutter pub get` to have run first.
const _stableIdPattern = r'^[a-z][a-z0-9_.]*$';
final _stableId = RegExp(_stableIdPattern);

const _taxonomyPath = 'content/skills/skill_taxonomy.json';
const _curriculumPaths = [
  'content/curriculum/age_5_7.json',
  'content/curriculum/age_8_10.json',
  'content/curriculum/age_11_12.json',
];
const _levelsDir = 'apps/mobile/assets/levels';

void main(List<String> args) {
  final strict = args.contains('--strict');
  // Dev mode: an unknown skillId is demoted from a fatal error to a
  // warning. Meant for local runs while another workstream is actively
  // authoring content for skills not yet added to skill_taxonomy.json --
  // e.g. new benchmark-inspired games -- without needing to bypass this
  // validator entirely. Every other check (duplicate activity IDs, missing
  // vi/en content, taxonomy self-consistency, display-name-as-ID) stays
  // fatal in both modes; only "not in the taxonomy yet" is treated
  // differently. Production CI never passes --dev.
  final dev = args.contains('--dev');
  final result = _ValidationResult();

  final taxonomyFile = File(_taxonomyPath);
  if (!taxonomyFile.existsSync()) {
    result.fatal.add('Missing taxonomy file: $_taxonomyPath');
    stdout.writeln(result.toReport());
    if (strict) exitCode = 1;
    return;
  }
  final taxonomy =
      jsonDecode(taxonomyFile.readAsStringSync()) as Map<String, dynamic>;
  final skills = <String, Map<String, dynamic>>{};
  for (final subject in taxonomy['subjects'] as List) {
    for (final skill in (subject as Map<String, dynamic>)['skills'] as List) {
      skills[(skill as Map<String, dynamic>)['skillId'] as String] = skill;
    }
  }

  _validateTaxonomySelfConsistency(skills, result);

  final curriculumNodes = <String>{};
  for (final path in _curriculumPaths) {
    final file = File(path);
    if (!file.existsSync()) {
      result.fatal.add('Missing curriculum file: $path');
      continue;
    }
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final ageGroup = json['ageGroup'] as String;
    for (final subjectId in (json['subjects'] as Map<String, dynamic>).keys) {
      curriculumNodes.add('$ageGroup.$subjectId');
    }
  }

  final levelsDir = Directory(_levelsDir);
  if (!levelsDir.existsSync()) {
    result.fatal.add('Missing levels directory: $_levelsDir');
    stdout.writeln(result.toReport());
    if (strict) exitCode = 1;
    return;
  }

  final coveredSkills = <String>{};
  final activityIdOwners = <String, String>{}; // activityId -> gameId

  for (final entity in levelsDir.listSync()) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    final fileGameId =
        entity.uri.pathSegments.last.replaceAll('.json', '');
    final json = jsonDecode(entity.readAsStringSync()) as Map<String, dynamic>;
    final levels = json['levels'] as List;

    for (final rawLevel in levels) {
      final level = rawLevel as Map<String, dynamic>;
      final levelId = level['id'] as String;
      final declaredGameId = level['gameId'] as String? ?? fileGameId;
      if (declaredGameId != fileGameId) {
        result.fatal.add(
          '$fileGameId/$levelId: level.gameId ("$declaredGameId") does not '
          'match its containing file ("$fileGameId.json") -- content pack '
          'references an unknown/mismatched game.',
        );
      }

      final metadata = level['metadata'] as Map<String, dynamic>? ?? const {};
      final skillIds = (metadata['skillIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];

      if (skillIds.isEmpty) {
        result.warnings.add(
          '$fileGameId/$levelId: orphan level -- no metadata.skillIds, no '
          'canonical mapping possible.',
        );
        continue;
      }

      for (final skillId in skillIds) {
        if (!_stableId.hasMatch(skillId)) {
          result.fatal.add(
            '$fileGameId/$levelId: skillId "$skillId" does not look like a '
            'stable machine ID (localized display name used as an ID?).',
          );
          continue;
        }
        if (!skills.containsKey(skillId)) {
          final message = '$fileGameId/$levelId: skillId "$skillId" is not '
              'defined in $_taxonomyPath.';
          if (dev) {
            result.warnings.add('[unknown future skill] $message');
          } else {
            result.fatal.add(message);
          }
          continue;
        }
        coveredSkills.add(skillId);
      }

      final localizedContent =
          level['localizedContent'] as Map<String, dynamic>? ?? const {};
      for (final requiredLocale in const ['vi', 'en']) {
        if (!localizedContent.containsKey(requiredLocale)) {
          result.fatal.add(
            '$fileGameId/$levelId: missing required "$requiredLocale" '
            'localized content.',
          );
        }
      }

      // activityId == levelId today (see CanonicalActivityMapping's doc
      // comment in mi_game_content) -- must be globally unique across every
      // game, not just within one file.
      final existingOwner = activityIdOwners[levelId];
      if (existingOwner != null && existingOwner != fileGameId) {
        result.fatal.add(
          'activityId "$levelId" is shared by both $existingOwner and '
          '$fileGameId -- two incompatible activities cannot share one ID.',
        );
      } else {
        activityIdOwners[levelId] = fileGameId;
      }
    }
  }

  final orphanSkills = skills.keys.toSet().difference(coveredSkills).toList()
    ..sort();
  for (final skillId in orphanSkills) {
    result.warnings.add(
      'taxonomy skill "$skillId" has no activity coverage yet.',
    );
  }

  stdout.writeln('Mode: ${dev ? 'dev (unknown skills are warnings)' : 'production'}');
  stdout.writeln(result.toReport());
  if (strict && result.fatal.isNotEmpty) {
    exitCode = 1;
  }
}

void _validateTaxonomySelfConsistency(
  Map<String, Map<String, dynamic>> skills,
  _ValidationResult result,
) {
  final seen = <String>{};
  for (final entry in skills.entries) {
    if (!seen.add(entry.key)) {
      result.fatal.add('Duplicate skillId in taxonomy: ${entry.key}');
    }
    final prerequisites =
        (entry.value['prerequisites'] as List).map((e) => e as String);
    for (final prereq in prerequisites) {
      if (!skills.containsKey(prereq)) {
        result.fatal.add(
          'Skill ${entry.key} references missing prerequisite: $prereq',
        );
      }
    }
  }
}

class _ValidationResult {
  final fatal = <String>[];
  final warnings = <String>[];

  String toReport() {
    final buffer = StringBuffer()
      ..writeln('MI Academy canonical skill mapping validation')
      ..writeln('Status: ${fatal.isEmpty ? 'PASS' : 'FAIL'}')
      ..writeln();
    _writeSection(buffer, 'Fatal errors', fatal);
    _writeSection(buffer, 'Warnings (non-blocking)', warnings);
    return buffer.toString();
  }

  void _writeSection(StringBuffer buffer, String title, List<String> items) {
    buffer.writeln('$title (${items.length})');
    if (items.isEmpty) {
      buffer.writeln('- none');
    } else {
      for (final item in items) {
        buffer.writeln('- $item');
      }
    }
    buffer.writeln();
  }
}
