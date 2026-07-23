import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mi_game_content/mi_game_content.dart';

/// The canonical knowledge-graph/curriculum source of truth. These files
/// live at the repo root (`content/`), not copied into
/// `apps/mobile/assets/` -- see the `assets:` comment in pubspec.yaml for
/// why. Loading them here, rather than duplicating their contents, is what
/// makes `content/skills/skill_taxonomy.json` genuinely the *one* source
/// of truth instead of a design document nothing at runtime reads.
const skillTaxonomyAsset = '../../content/skills/skill_taxonomy.json';
const curriculumAssets = [
  '../../content/curriculum/age_5_7.json',
  '../../content/curriculum/age_8_10.json',
  '../../content/curriculum/age_11_12.json',
];

/// Loads the taxonomy + curriculum and builds the resolver every
/// [GameScreen] completion resolves canonical mappings through. Construct
/// once per app session ([activityMappingResolverProvider] does this) --
/// [SkillTaxonomy] and [CurriculumMap] cache their own lookups internally.
Future<ActivityMappingResolver> loadActivityMappingResolver({
  AssetBundle? bundle,
}) async {
  final bundleToUse = bundle ?? rootBundle;

  final taxonomyJson = await bundleToUse.loadString(skillTaxonomyAsset);
  final taxonomy = SkillTaxonomy.fromJson(
    jsonDecode(taxonomyJson) as Map<String, dynamic>,
  );

  final curriculumJsons = <Map<String, dynamic>>[];
  for (final asset in curriculumAssets) {
    final raw = await bundleToUse.loadString(asset);
    curriculumJsons.add(jsonDecode(raw) as Map<String, dynamic>);
  }
  final curriculum = CurriculumMap.fromAgeFiles(curriculumJsons);

  return ActivityMappingResolver(taxonomy: taxonomy, curriculum: curriculum);
}
