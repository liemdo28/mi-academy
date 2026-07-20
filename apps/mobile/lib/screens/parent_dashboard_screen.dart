import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:localization/localization.dart';
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
        title: const Text(MiMobileStrings.m088),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/parent/settings'),
          ),
        ],
      ),
      body: reportsAsync.when(
        loading: () => const MiLoading(message: MiMobileStrings.m089),
        error: (e, _) => MiErrorState(
          title: MiMobileStrings.m090,
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
                MiMobileStrings.m091,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: MiTokens.space3),
              if (children.children.isEmpty)
                MiEmptyState(
                  title: MiMobileStrings.m092,
                  subtitle: MiMobileStrings.m093,
                  emoji: '👶',
                  action: MiButton(
                    label: MiMobileStrings.m094,
                    onPressed: () => _showCreateChildDialog(context, ref),
                  ),
                )
              else
                ...children.children.map(
                  (child) => _buildChildCard(context, child),
                ),
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
            MiMobileStrings.m095,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: MiTokens.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(context, '⭐', '$stars', 'Sao'),
              _buildStatItem(context, '📚', '$lessons', MiMobileStrings.m057),
              _buildStatItem(context, '🎮', '$games', MiMobileStrings.m096),
              _buildStatItem(context, '⏱️', '$minutes', MiMobileStrings.m097),
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
            MiMobileStrings.m095,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: MiTokens.space4),
          const MiEmptyState(
            title: MiMobileStrings.m098,
            subtitle: MiMobileStrings.m099,
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
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
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
              child: Text('🧒', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: MiTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child['nickname'] ?? MiMobileStrings.m100,
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
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showDialog<({String nickname, String ageGroup})>(
      context: context,
      builder: (context) => const AddChildDialog(),
    );
    if (result == null) return;

    final ok = await ref
        .read(activeChildProvider.notifier)
        .createChild(nickname: result.nickname, ageGroup: result.ageGroup);
    if (!context.mounted) return;
    if (!ok) {
      final error = ref.read(activeChildProvider).error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error ?? MiMobileStrings.m060)));
    }
  }
}
