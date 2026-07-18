import 'package:mi_game_core/mi_game_core.dart';

/// Real per-level skill taxonomy IDs (e.g. `letters.word_building`,
/// `math.addition.within_10` — matching `content/skills/skill_taxonomy.json`)
/// authored in each game's level content
/// (`metadata.skillIds` in `assets/levels/*.json`), instead of a single
/// hardcoded tag that was the same for every level of a game regardless
/// of what that level actually taught.
///
/// [fallback] preserves the old single-tag behavior for levels that don't
/// declare `skillIds` (e.g. Memory Cards' level content has none today --
/// that game already reports its own real tags directly, not via this
/// helper).
List<String> skillIdsFor(MiLevel level, {required List<String> fallback}) {
  final raw = level.metadata['skillIds'];
  if (raw is List && raw.isNotEmpty) {
    return raw.map((e) => e.toString()).toList();
  }
  return fallback;
}
