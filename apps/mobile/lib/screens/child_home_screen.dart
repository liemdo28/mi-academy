import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import '../providers/providers.dart';

/// Child home screen — main learning interface.
///
/// Shows daily plan, subjects, games, and quick actions.
/// Accessible after selecting a child profile.
class ChildHomeScreen extends ConsumerWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(activeChildProvider);
    final planAsync = ref.watch(dailyPlanProvider);

    final nickname = child.child?['nickname'] ?? 'Bạn';

    return Scaffold(
      appBar: AppBar(
        title: Text('Chào $nickname! 👋'),
        automaticallyImplyLeading: false,
        actions: [
          // Settings button (tap 1 of 3 to reach parent dashboard)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/parent'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyPlanProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(MiTokens.space4),
          children: [
            // ─── Today's Plan ──────────────────────────────────────────
            Text(
              '📚 Kế hoạch hôm nay',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: MiTokens.space3),
            planAsync.when(
              loading: () => const MiLoading(),
              error: (e, _) => MiErrorState(
                title: 'Không thể tải kế hoạch',
                onRetry: () => ref.invalidate(dailyPlanProvider),
              ),
              data: (plan) {
                if (plan.isEmpty) {
                  return MiEmptyState(
                    title: 'Chưa có bài học',
                    subtitle: 'Hãy bắt đầu học ngay!',
                    emoji: '✨',
                    action: MiButton(
                      label: 'Bắt đầu',
                      onPressed: () {},
                    ),
                  );
                }
                return Column(
                  children: plan.map((item) =>
                      _buildPlanItem(context, item)).toList(),
                );
              },
            ),

            const SizedBox(height: MiTokens.space8),

            // ─── Subject Grid ──────────────────────────────────────────
            Text(
              '🎮 Chọn chủ đề',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: MiTokens.space3),
            _buildSubjectGrid(context),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Sao'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Huy hiệu'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Phụ huynh'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Already home
              break;
            case 1:
              // TODO: Show rewards/stars
              break;
            case 2:
              // TODO: Show badges
              break;
            case 3:
              context.push('/parent');
              break;
          }
        },
      ),
    );
  }

  Widget _buildPlanItem(BuildContext context, Map<String, dynamic> item) {
    final title = item['title'] ?? 'Bài học';
    final subject = item['subject'] as String? ?? '';
    final minutes = item['estimated_minutes'] ?? 5;

    return MiCard(
      onTap: () {
        // TODO: Start lesson via lesson provider
      },
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: MiTokens.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MiTokens.radiusMd),
            ),
            child: const Center(
              child: Text('📖', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: MiTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subject.isEmpty ? '$minutes phút' : '$subject - $minutes phút',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.play_circle, color: MiTokens.primaryBlue, size: 32),
        ],
      ),
    );
  }

  Widget _buildSubjectGrid(BuildContext context) {
    final subjects = [
      {'title': 'Chữ cái', 'icon': '📝', 'color': MiTokens.primaryBlue},
      {'title': 'Toán học', 'icon': '🔢', 'color': MiTokens.accentOrange},
      {'title': 'Tư duy', 'icon': '🧠', 'color': MiTokens.accentPurple},
      {'title': 'Khoa học', 'icon': '🔬', 'color': MiTokens.accentGreen},
      {'title': 'Sáng tạo', 'icon': '🎨', 'color': MiTokens.accentPink},
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: MiTokens.space3,
      crossAxisSpacing: MiTokens.space3,
      childAspectRatio: 1.3,
      children: subjects.map((s) {
        return MiCard(
          accentColor: s['color'] as Color?,
          onTap: () {
            // TODO: Navigate to subject lessons
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(s['icon'] as String, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: MiTokens.space2),
              Text(
                s['title'] as String,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
