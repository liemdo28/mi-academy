import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import '../providers/providers.dart';
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
                  emoji: '👶',
                  action: MiButton(
                    label: 'Tạo hồ sơ',
                    onPressed: () => _showCreateChildDialog(context, ref),
                  ),
                )
              else
                ...children.children.map((child) =>
                    _buildChildCard(context, child)),
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
          Text(
            '📊 Tổng quan hôm nay',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: MiTokens.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(context, '⭐', '$stars', 'Sao'),
              _buildStatItem(context, '📚', '$lessons', 'Bài học'),
              _buildStatItem(context, '🎮', '$games', 'Trò chơi'),
              _buildStatItem(context, '⏱️', '$minutes', 'Phút'),
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
          Text(
            '📊 Tổng quan hôm nay',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: MiTokens.space4),
          const MiEmptyState(
            title: 'Chưa có hoạt động',
            subtitle: 'Con bạn chưa học hôm nay',
            emoji: '📚',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String emoji,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
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
    return MiCard(
      onTap: () {
        // TODO: Navigate to child detail/progress view
      },
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
              child: Text('🧒', style: TextStyle(fontSize: 24)),
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
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  Future<void> _showCreateChildDialog(BuildContext context, WidgetRef ref) async {
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
