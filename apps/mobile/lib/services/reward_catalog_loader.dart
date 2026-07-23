import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mi_game_progress/mi_game_progress.dart';

const rewardCatalogAsset = 'assets/rewards/reward_catalog.json';

/// Loads the bundled reward catalog content pack -- same "content pack,
/// not hardcoded" pattern as `loadGameLevels` in `game_levels.dart`, just
/// for rewards instead of levels.
Future<RewardCatalog> loadRewardCatalog({AssetBundle? bundle}) async {
  final json = await (bundle ?? rootBundle).loadString(rewardCatalogAsset);
  final data = jsonDecode(json) as Map<String, dynamic>;
  return RewardCatalog.fromJson(data['rewards'] as List);
}
