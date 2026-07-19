import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_engines/mi_game_engines.dart';

import '../level_skill_ids.dart';

/// Converts one [MiLevel] (the repository-wide content shape, loaded via
/// [GameContentProvider]) plus a target [locale] into the flat JSON shape
/// [PlacementContent.fromJson] expects.
///
/// Games built on the Placement Engine (Shape Builder, Word Sorter) author
/// their per-locale content as `localizedContent.<locale>.{prompt,hint,
/// items,targets,rule,configuration}` -- `prompt` doubles as the schema's
/// required field and the Placement Engine's `instruction`, so a single
/// level file satisfies both `schemas/level.schema.json` and
/// `PlacementContent.fromJson` without a second parallel content shape.
Map<String, dynamic> buildPlacementRawContent(MiLevel level, String locale) {
  final localeContent = level.contentForLocale(locale);
  return {
    'contentId': level.id,
    'gameId': level.gameId,
    'locale': locale,
    'ageBand': level.ageBand ?? 'junior',
    'difficulty': level.difficulty,
    'instruction': localeContent['prompt'],
    if (localeContent['hint'] != null) 'hint': localeContent['hint'],
    'items': localeContent['items'],
    'targets': localeContent['targets'],
    if (localeContent['rule'] != null) 'rule': localeContent['rule'],
    if (localeContent['configuration'] != null)
      'configuration': localeContent['configuration'],
    'estimatedSeconds': level.estimatedSeconds,
    'schemaVersion': '1.0',
  };
}

/// Converts the Placement Engine's normalized [PlacementResult] into the
/// repository-wide [MiCompletionResult] shape every game reports through
/// (see `apps/mobile/lib/screens/game_screen.dart`'s `_saveResult`). The
/// engine itself never produces this -- it has no concept of a child
/// profile or a backend -- so this conversion happens once, here, at the
/// app layer, not inside `packages/mi_game_engines`.
MiCompletionResult placementResultToCompletion({
  required PlacementResult result,
  required MiLevel level,
  required String childProfileId,
}) {
  return MiCompletionResult(
    gameId: level.gameId,
    levelId: level.id,
    childProfileId: childProfileId,
    completedAt: DateTime.now(),
    score: result.score,
    maxScore: 100,
    attemptsUsed: result.attempts,
    hintsUsed: result.hintCount,
    duration: result.duration,
    perfectRun: result.incorrectCount == 0,
    newSkillsAcquired: skillIdsFor(level, fallback: const []),
  );
}
