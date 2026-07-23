import 'package:equatable/equatable.dart';

/// How a [RewardDefinition] is earned, evaluated purely against locally
/// tracked [AttemptRecord]s -- no network required, so rewards unlock the
/// instant a child earns them, offline or not.
enum RewardRuleType {
  /// At least one level ever completed, across any game.
  firstCompletion,

  /// At least [RewardRule.count] levels completed, across any game.
  completionCount,

  /// Every game in [RewardRule.category] (a [GameRegistryEntry.category]
  /// value like 'letters', 'math', 'logic') has been completed at least
  /// once. Reads the category list from whatever games exist at
  /// evaluation time, so a new game added to that category is
  /// automatically required -- no reward catalog edit needed.
  categoryCompleted,

  /// At least one level completed on each of [RewardRule.count]
  /// consecutive calendar days.
  streakDays,

  /// At least one level completed in every known category.
  allCategoriesExplored,
}

/// A single unlock condition. Data, not code -- new rewards are added by
/// appending catalog entries (see `reward_catalog.json`), never by editing
/// [RewardEngine].
class RewardRule extends Equatable {
  const RewardRule._(this.type, {this.count, this.category});

  const RewardRule.firstCompletion() : this._(RewardRuleType.firstCompletion);

  const RewardRule.completionCount(int count)
      : this._(RewardRuleType.completionCount, count: count);

  const RewardRule.categoryCompleted(String category)
      : this._(RewardRuleType.categoryCompleted, category: category);

  const RewardRule.streakDays(int days)
      : this._(RewardRuleType.streakDays, count: days);

  const RewardRule.allCategoriesExplored()
      : this._(RewardRuleType.allCategoriesExplored);

  final RewardRuleType type;
  final int? count;
  final String? category;

  factory RewardRule.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'first_completion':
        return const RewardRule.firstCompletion();
      case 'completion_count':
        return RewardRule.completionCount(json['count'] as int);
      case 'category_completed':
        return RewardRule.categoryCompleted(json['category'] as String);
      case 'streak_days':
        return RewardRule.streakDays(json['count'] as int);
      case 'all_categories_explored':
        return const RewardRule.allCategoriesExplored();
      default:
        throw ArgumentError('Unknown reward rule type: $type');
    }
  }

  Map<String, dynamic> toJson() => {
        'type': switch (type) {
          RewardRuleType.firstCompletion => 'first_completion',
          RewardRuleType.completionCount => 'completion_count',
          RewardRuleType.categoryCompleted => 'category_completed',
          RewardRuleType.streakDays => 'streak_days',
          RewardRuleType.allCategoriesExplored => 'all_categories_explored',
        },
        if (count != null) 'count': count,
        if (category != null) 'category': category,
      };

  @override
  List<Object?> get props => [type, count, category];
}
