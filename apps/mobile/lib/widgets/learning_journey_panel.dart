import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:mi_game_content/mi_game_content.dart';

import '../services/level_selector.dart';
import '../services/world_progression_service.dart';

/// "Where am I, why does this lesson appear, what does it teach, what
/// unlocks next, how long will it take, what do I get" -- the Learning
/// Journey detail sheet shown when a child (or a parent, browsing
/// alongside) taps a [JourneyNode] on the world map.
///
/// Every field is resolved from real data already computed by
/// [WorldProgressionService]/[LevelSelector]/the canonical
/// [ActivityMappingResolver] -- nothing here is invented copy. The one
/// deliberately generic line is the reward preview: predicting exactly
/// which badge a specific level completion would unlock requires
/// simulating the reward catalog against full attempt history per node,
/// which is out of scope for this panel -- it states the real, universal
/// mechanic (stars + journey progress) rather than a fabricated specific
/// prediction.
class LearningJourneyPanel extends StatelessWidget {
  const LearningJourneyPanel({
    super.key,
    required this.node,
    required this.subjectName,
    required this.taxonomy,
    required this.locale,
    required this.onPlay,
  });

  final JourneyNode node;
  final Map<String, String> subjectName;
  final SkillTaxonomy taxonomy;
  final String locale;

  /// Null when [node.state] is [LevelProgressState.locked] -- not
  /// playable yet, so no action is offered rather than a button that
  /// would silently fail.
  final VoidCallback? onPlay;

  String _name(Map<String, String> name) => name[locale] ?? name.values.first;

  String _skillName(String skillId) {
    final skill = taxonomy.skill(skillId);
    return skill != null ? _name(skill.name) : skillId;
  }

  String _reasonCopy(String code) {
    const copy = {
      'NEW_SKILL_EASY_START': {
        'vi': 'Bài học dễ để con bắt đầu tự tin.',
        'en': 'An easy start to build confidence.',
      },
      'DIFFICULTY_MATCH': {
        'vi': 'Vừa đúng trình độ hiện tại của con.',
        'en': 'Matches your current skill level.',
      },
      'REVIEW_DUE': {
        'vi': 'Đã đến lúc ôn lại kỹ năng này.',
        'en': 'Time to review this skill.',
      },
      'PREREQUISITES_MET': {
        'vi': 'Con đã sẵn sàng học bài này.',
        'en': "You're ready for this lesson.",
      },
      'AVOID_IMMEDIATE_REPEAT': {
        'vi': 'Một bài mới để đổi không khí.',
        'en': 'A fresh lesson for variety.',
      },
    };
    return copy[code]?[locale] ?? copy[code]?['en'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final skillName = _skillName(node.mapping.primarySkillId);
    final prerequisiteNames =
        node.mapping.prerequisites.map(_skillName).toList();
    final estimatedMinutes = (node.level.estimatedSeconds / 60).ceil();
    final reasonLines = node.reasonCodes
        .map(_reasonCopy)
        .where((line) => line.isNotEmpty)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(MiTokens.space4),
        decoration: const BoxDecoration(
          color: MiColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(MiTokens.radiusLg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JourneyStateBadge(state: node.state, locale: locale),
            const SizedBox(height: MiTokens.space3),
            Text(
              skillName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: MiTokens.space1),
            Text(
              _name(subjectName),
              style: const TextStyle(color: MiColors.textSecondary),
            ),
            const SizedBox(height: MiTokens.space4),
            _InfoRow(
              icon: Icons.speed_rounded,
              label: locale == 'en' ? 'Difficulty' : 'Độ khó',
              value: '${node.level.difficulty}',
            ),
            _InfoRow(
              icon: Icons.child_care_rounded,
              label: locale == 'en' ? 'Age band' : 'Độ tuổi',
              value: node.level.ageBand ?? '-',
            ),
            _InfoRow(
              icon: Icons.timer_outlined,
              label: locale == 'en' ? 'Estimated time' : 'Thời gian dự kiến',
              value: locale == 'en' ? '$estimatedMinutes min' : '$estimatedMinutes phút',
            ),
            if (prerequisiteNames.isNotEmpty)
              _InfoRow(
                icon: Icons.link_rounded,
                label: locale == 'en' ? 'Builds on' : 'Cần học trước',
                value: prerequisiteNames.join(', '),
              ),
            if (reasonLines.isNotEmpty) ...[
              const SizedBox(height: MiTokens.space3),
              Container(
                padding: const EdgeInsets.all(MiTokens.space3),
                decoration: BoxDecoration(
                  color: MiColors.primarySoft,
                  borderRadius: BorderRadius.circular(MiTokens.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in reasonLines)
                      Text(line, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: MiTokens.space3),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: MiColors.warning, size: MiTokens.iconSm),
                const SizedBox(width: MiTokens.space2),
                Expanded(
                  child: Text(
                    locale == 'en'
                        ? 'Earn stars and journey progress by completing this.'
                        : 'Hoàn thành để nhận sao và tiến bộ trong hành trình học tập.',
                    style: const TextStyle(color: MiColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MiTokens.space4),
            MiPrimaryButton(
              label: onPlay == null
                  ? (locale == 'en' ? 'Locked' : 'Đã khoá')
                  : (locale == 'en' ? 'Play' : 'Chơi ngay'),
              onPressed: onPlay,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MiTokens.space1),
      child: Row(
        children: [
          Icon(icon, size: MiTokens.iconSm, color: MiColors.textSecondary),
          const SizedBox(width: MiTokens.space2),
          Text(label, style: const TextStyle(color: MiColors.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Icon + label for one [LevelProgressState] -- shared by the world map
/// node grid and this panel so the two never drift out of sync. State is
/// never color-only: every state pairs a distinct icon with its color.
class JourneyStateBadge extends StatelessWidget {
  const JourneyStateBadge({super.key, required this.state, required this.locale});

  final LevelProgressState state;
  final String locale;

  static const _iconByState = {
    LevelProgressState.locked: Icons.lock_rounded,
    LevelProgressState.available: Icons.circle_outlined,
    LevelProgressState.recommended: Icons.star_rounded,
    LevelProgressState.mastered: Icons.check_circle_rounded,
    LevelProgressState.review: Icons.history_rounded,
    LevelProgressState.challenge: Icons.emoji_events_rounded,
    LevelProgressState.bonus: Icons.card_giftcard_rounded,
  };

  static const _colorByState = {
    LevelProgressState.locked: MiColors.textSecondary,
    LevelProgressState.available: MiColors.textSecondary,
    LevelProgressState.recommended: MiColors.primary,
    LevelProgressState.mastered: MiColors.success,
    LevelProgressState.review: MiColors.info,
    LevelProgressState.challenge: MiColors.accent,
    LevelProgressState.bonus: MiColors.creative,
  };

  static const _labelByState = {
    LevelProgressState.locked: {'vi': 'Đã khoá', 'en': 'Locked'},
    LevelProgressState.available: {'vi': 'Có thể học', 'en': 'Available'},
    LevelProgressState.recommended: {'vi': 'Gợi ý cho con', 'en': 'Recommended'},
    LevelProgressState.mastered: {'vi': 'Đã thành thạo', 'en': 'Mastered'},
    LevelProgressState.review: {'vi': 'Cần ôn tập', 'en': 'Review'},
    LevelProgressState.challenge: {'vi': 'Thử thách', 'en': 'Challenge'},
    LevelProgressState.bonus: {'vi': 'Phần thưởng thêm', 'en': 'Bonus'},
  };

  /// Shared with `_JourneyNodeTile` on the world map, so the map and this
  /// panel never show a different icon/color for the same state.
  static IconData iconFor(LevelProgressState state) => _iconByState[state]!;
  static Color colorFor(LevelProgressState state) => _colorByState[state]!;

  @override
  Widget build(BuildContext context) {
    final color = _colorByState[state]!;
    final label = _labelByState[state]![locale] ?? _labelByState[state]!['en']!;
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: MiTokens.space3, vertical: MiTokens.space1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(MiTokens.radiusFull),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconByState[state], size: MiTokens.iconSm, color: color),
            const SizedBox(width: MiTokens.space1),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
