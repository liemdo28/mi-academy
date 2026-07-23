import 'package:equatable/equatable.dart';

import 'reward_rule.dart';

/// One catalog entry: a badge plus the rule that unlocks it. Bilingual
/// name/description are required, not optional -- see CLAUDE.md's
/// localization-first rule.
class RewardDefinition extends Equatable {
  const RewardDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.rule,
  });

  /// Stable slug (e.g. `first_completion`), not a database UUID -- shared
  /// between the bundled offline catalog and the backend `Reward.id` so
  /// the two stay reconcilable without a network round trip.
  final String id;
  final Map<String, String> name;
  final Map<String, String> description;
  final RewardRule rule;

  factory RewardDefinition.fromJson(Map<String, dynamic> json) {
    return RewardDefinition(
      id: json['id'] as String,
      name: Map<String, String>.from(json['name'] as Map),
      description: Map<String, String>.from(json['description'] as Map),
      rule: RewardRule.fromJson(json['rule'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'rule': rule.toJson(),
      };

  @override
  List<Object?> get props => [id, name, description, rule];
}

/// The full set of rewards a child can earn. Loaded from a bundled content
/// pack (see `apps/mobile/assets/rewards/reward_catalog.json`) the same
/// way level content is loaded -- adding a reward means adding a JSON
/// entry, not writing code.
class RewardCatalog extends Equatable {
  const RewardCatalog(this.rewards);

  final List<RewardDefinition> rewards;

  factory RewardCatalog.fromJson(List<dynamic> json) {
    return RewardCatalog(
      json
          .map((entry) =>
              RewardDefinition.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [rewards];
}
