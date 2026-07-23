import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import '../providers/providers.dart';
import '../services/world_progression_service.dart';
import '../widgets/add_child_dialog.dart';

/// Parent dashboard — today overview, weekly report, child progress.
///
/// Access is locked behind PIN/biometric (see parent_pin_screen.dart).
/// Accessible in max 3 taps from child home: Settings → PIN → Dashboard.
class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsProvider);
    final children = ref.watch(activeChildProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển phụ huynh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/parent/settings'),
          ),
        ],
      ),
      body: reportsAsync.when(
        loading: () => const MiLoading(message: 'Đang tải...'),
        error: (e, _) => MiErrorState(
          title: 'Không thể tải dữ liệu',
          onRetry: () => ref.invalidate(reportsProvider),
        ),
        data: (reports) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(reportsProvider),
          child: ListView(
            padding: const EdgeInsets.all(MiTokens.space4),
            children: [
              // ─── Today's Summary ─────────────────────────────────────────
              if (reports.isNotEmpty)
                _buildTodaySummary(context, reports.first)
              else
                _buildTodaySummaryPlaceholder(context),

              const SizedBox(height: MiTokens.space6),

              // ─── Learning Journey (local-first, real data) ──────────────
              Text(
                'Hành trình học tập',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: MiTokens.space3),
              _buildLearningInsights(context, ref),

              const SizedBox(height: MiTokens.space6),

              // ─── Children section ────────────────────────────────────────
              Text(
                'Hồ sơ trẻ em',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: MiTokens.space3),
              if (children.children.isEmpty)
                MiEmptyState(
                  title: 'Chưa có hồ sơ',
                  subtitle: 'Tạo hồ sơ cho con bạn',
                  brandIcon: MiBrandIcon.profile,
                  action: MiButton(
                    label: 'Tạo hồ sơ',
                    onPressed: () => _showCreateChildDialog(context, ref),
                  ),
                )
              else
                ...children.children
                    .map((child) => _buildChildCard(context, child)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySummary(BuildContext context, Map<String, dynamic> report) {
    final lessons = report['total_lessons_today'] ?? 0;
    final games = report['total_games_today'] ?? 0;
    final minutes = report['total_time_minutes_today'] ?? 0;
    final stars = report['total_stars_today'] ?? 0;

    return MiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MiBrandIconView(
                icon: MiBrandIcon.report,
                size: MiTokens.iconMd,
                decorative: true,
              ),
              const SizedBox(width: MiTokens.space2),
              Text(
                'Tổng quan hôm nay',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: MiTokens.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(context, MiBrandIcon.rewardStar, '$stars', 'Sao'),
              _buildStatItem(
                  context, MiBrandIcon.progress, '$lessons', 'Bài học'),
              _buildStatItem(context, MiBrandIcon.logic, '$games', 'Trò chơi'),
              _buildStatItem(context, MiBrandIcon.report, '$minutes', 'Phút'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummaryPlaceholder(BuildContext context) {
    return MiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MiBrandIconView(
                icon: MiBrandIcon.report,
                size: MiTokens.iconMd,
                decorative: true,
              ),
              const SizedBox(width: MiTokens.space2),
              Text(
                'Tổng quan hôm nay',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: MiTokens.space4),
          const MiEmptyState(
            title: 'Chưa có hoạt động',
            subtitle: 'Con bạn chưa học hôm nay',
            brandIcon: MiBrandIcon.progress,
          ),
        ],
      ),
    );
  }

  /// Local-first learning summary -- built from mastery/attempt/reward
  /// data already on-device (see [WorldProgressionService.buildInsights]),
  /// never the backend shadow-mode `reportsProvider` above. Every number
  /// here is real: no XP/coins, no fabricated "recent" ordering for
  /// achievements (the local reward store has no unlock timestamp) -- see
  /// `LearningInsights`'s own doc comment for exactly what's honest vs.
  /// deliberately left out.
  Widget _buildLearningInsights(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(learningInsightsProvider);
    final worldsAsync = ref.watch(worldProgressProvider);

    return insightsAsync.when(
      loading: () => const MiCard(child: MiLoading(message: 'Đang tải...')),
      error: (e, _) => MiCard(
        child: MiErrorState(
          title: 'Không thể tải hành trình học tập',
          onRetry: () => ref.invalidate(learningInsightsProvider),
        ),
      ),
      data: (insights) {
        final worldNames = <String, Map<String, String>>{
          for (final world in worldsAsync.value ?? const <WorldProgress>[])
            world.subjectId: world.name,
        };
        final minutes = insights.totalTimeSpent.inMinutes;

        return MiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceAround,
                runSpacing: MiTokens.space3,
                children: [
                  _buildStatItem(context, MiBrandIcon.achievement,
                      '${insights.masteredSkills.length}', 'Đã thành thạo'),
                  _buildStatItem(context, MiBrandIcon.progress,
                      '${insights.skillsNeedingReview.length}', 'Cần ôn tập'),
                  _buildStatItem(context, MiBrandIcon.rewardStar,
                      '${insights.streakDays}', 'Ngày liên tiếp'),
                  _buildStatItem(
                    context,
                    MiBrandIcon.report,
                    '${(insights.overallAccuracy * 100).round()}%',
                    'Độ chính xác',
                  ),
                  _buildStatItem(context, MiBrandIcon.world, '$minutes', 'Phút học'),
                ],
              ),
              if (insights.weakSkills.isNotEmpty) ...[
                const SizedBox(height: MiTokens.space4),
                Text(
                  'Kỹ năng cần luyện thêm',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: MiTokens.space2),
                Wrap(
                  spacing: MiTokens.space2,
                  runSpacing: MiTokens.space2,
                  children: [
                    for (final skill in insights.weakSkills)
                      Chip(
                        label: Text(skill.name['vi'] ?? skill.name.values.first),
                        backgroundColor: MiColors.errorHc.withValues(alpha: 0.1),
                        side: BorderSide.none,
                      ),
                  ],
                ),
              ],
              if (insights.curriculumCompletionBySubject.values.any((v) => v != null)) ...[
                const SizedBox(height: MiTokens.space4),
                Text(
                  'Tiến độ chương trình học',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: MiTokens.space2),
                for (final entry in insights.curriculumCompletionBySubject.entries)
                  if (entry.value != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: MiTokens.space2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            worldNames[entry.key]?['vi'] ?? entry.key,
                            style: const TextStyle(fontSize: MiTokens.fontSm),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(MiTokens.radiusFull),
                            child: LinearProgressIndicator(
                              value: entry.value,
                              minHeight: 6,
                              backgroundColor: MiColors.border,
                              valueColor: const AlwaysStoppedAnimation(MiColors.success),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
              if (insights.unlockedRewards.isNotEmpty) ...[
                const SizedBox(height: MiTokens.space4),
                Text(
                  'Huy hiệu đã đạt được',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: MiTokens.space2),
                Wrap(
                  spacing: MiTokens.space2,
                  runSpacing: MiTokens.space2,
                  children: [
                    for (final reward in insights.unlockedRewards)
                      Chip(
                        avatar: const MiBrandIconView(
                          icon: MiBrandIcon.achievement,
                          size: MiTokens.iconSm,
                          decorative: true,
                        ),
                        label: Text(reward.name['vi'] ?? reward.name.values.first),
                        backgroundColor: MiColors.primarySoft,
                        side: BorderSide.none,
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    MiBrandIcon icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        MiBrandIconView(icon: icon, size: MiTokens.iconMd, decorative: true),
        const SizedBox(height: MiTokens.space1),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildChildCard(BuildContext context, Map<String, dynamic> child) {
    // No per-child detail/progress screen exists yet (no route for it) --
    // showing a chevron and an onTap that silently does nothing would
    // mislead a parent into thinking this card is interactive. A plain,
    // non-tappable summary card is honest about what's actually here today.
    return MiCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: MiColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: MiBrandIconView(
                icon: MiBrandIcon.profile,
                size: MiTokens.iconMd,
                decorative: true,
              ),
            ),
          ),
          const SizedBox(width: MiTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child['nickname'] ?? 'Trẻ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  child['age_group'] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateChildDialog(
      BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String nickname, String ageGroup})>(
      context: context,
      builder: (context) => const AddChildDialog(),
    );
    if (result == null) return;

    final ok = await ref.read(activeChildProvider.notifier).createChild(
          nickname: result.nickname,
          ageGroup: result.ageGroup,
        );
    if (!context.mounted) return;
    if (!ok) {
      final error = ref.read(activeChildProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Không thể tạo hồ sơ, thử lại nhé')),
      );
    }
  }
}
