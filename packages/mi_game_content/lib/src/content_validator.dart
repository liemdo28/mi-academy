/// Validates game content JSON against required structure.
///
/// Runs in dev mode, CI, admin publishing, and mobile content import.
/// Invalid levels must never reach production.
class ContentValidator {
  const ContentValidator();

  /// Validate a single level JSON.
  ///
  /// Returns a list of errors (empty = valid).
  List<String> validateLevel(Map<String, dynamic> data) {
    final errors = <String>[];

    // Required fields
    if (!data.containsKey('id')) {
      errors.add('Field "id" is required and must not be empty');
    } else if (data['id'] is! String || (data['id'] as String).isEmpty) {
      errors.add('Field "id" is required and must not be empty');
    }
    if (!data.containsKey('levelNumber')) {
      errors.add('Field "levelNumber" is required');
    } else if (data['levelNumber'] is! int || data['levelNumber'] < 1) {
      errors.add('Field "levelNumber" must be a positive integer');
    }
    if (!data.containsKey('difficulty')) {
      errors.add('Field "difficulty" is required');
    } else {
      final d = data['difficulty'];
      if (d is! int || d < 1 || d > 5) {
        errors.add('Field "difficulty" must be an integer between 1 and 5');
      }
    }

    // Localized content
    if (!data.containsKey('localizedContent')) {
      errors.add('Field "localizedContent" is required');
    } else {
      final content = data['localizedContent'];
      if (content is! Map) {
        errors.add('Field "localizedContent" must be a Map');
      } else {
        if (!content.containsKey('vi')) {
          errors.add('Vietnamese (vi) localization is required');
        }
      }
    }

    // publicationState (docs/content-schema.md) -- optional, but must be a
    // known value if present; ContentLoader defaults it to 'published'.
    if (data.containsKey('publicationState')) {
      const validStates = {'draft', 'published', 'archived'};
      if (!validStates.contains(data['publicationState'])) {
        errors.add(
          'Field "publicationState" must be one of $validStates, '
          'got ${data['publicationState']}',
        );
      }
    }

    // estimatedSeconds -- optional, but must be a positive duration if
    // present (a level authored with 0 or a negative estimate is a content
    // bug, not a valid "no estimate" state -- omit the field for that).
    if (data.containsKey('estimatedSeconds')) {
      final seconds = data['estimatedSeconds'];
      if (seconds is! int || seconds < 1) {
        errors.add('Field "estimatedSeconds" must be a positive integer');
      }
    }

    // contentVersion -- optional, but must be a positive integer if present.
    if (data.containsKey('contentVersion')) {
      final version = data['contentVersion'];
      if (version is! int || version < 1) {
        errors.add('Field "contentVersion" must be a positive integer');
      }
    }

    // Hints
    if (data.containsKey('hints')) {
      final hints = data['hints'];
      if (hints is! List) {
        errors.add('Field "hints" must be a list');
      } else {
        for (int i = 0; i < hints.length; i++) {
          final hint = hints[i];
          if (hint is! Map) {
            errors.add('Hint[$i] must be a map');
          } else if (!hint.containsKey('text') ||
              (hint['text'] as String?)?.isEmpty == true) {
            errors.add('Hint[$i] must have a non-empty "text" field');
          }
        }
      }
    }

    return errors;
  }

  /// Validate all levels for a game.
  ValidationResult validateGameLevels(List<Map<String, dynamic>> levelData) {
    final allErrors = <String>[];
    final validLevels = <Map<String, dynamic>>[];

    for (int i = 0; i < levelData.length; i++) {
      final errors = validateLevel(levelData[i]);
      if (errors.isEmpty) {
        validLevels.add(levelData[i]);
      } else {
        for (final err in errors) {
          allErrors.add('Level ${i + 1}: $err');
        }
      }
    }

    // Check for duplicate IDs
    final seen = <String>{};
    final ids = levelData
        .map((d) => d['id'])
        .whereType<String>()
        .where((id) => id.isNotEmpty);
    for (final id in ids) {
      if (!seen.add(id)) {
        allErrors.add('Duplicate level ID: $id');
      }
    }

    return ValidationResult(
      isValid: allErrors.isEmpty,
      errors: allErrors,
      validLevelCount: validLevels.length,
      totalLevelCount: levelData.length,
    );
  }
}

class ValidationResult {
  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.validLevelCount,
    required this.totalLevelCount,
  });

  final bool isValid;
  final List<String> errors;
  final int validLevelCount;
  final int totalLevelCount;

  @override
  String toString() {
    if (isValid) return 'Valid ($validLevelCount/$totalLevelCount levels)';
    return 'Invalid: ${errors.join("; ")}';
  }
}
