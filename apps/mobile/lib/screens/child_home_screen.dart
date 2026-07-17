import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import '../providers/providers.dart';

/// Child home screen — main learning interface.
///
/// One dominant CTA ("Tiếp tục học"), a daily mission list, and entry
/// points to the world map and achievement garden. See
/// design/screens/CHILD_HOME_WIREFRAME.md for the full spec.
///
/// "Chơi gần đây" from the wireframe is intentionally omitted until a
/// recent-games data provider exists (Dev 1) — no fabricated placeholder
/// data is shown in its place.
class ChildHomeScreen extends ConsumerStatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  ConsumerState<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends ConsumerState<ChildHomeScreen> {
  Timer? _parentGateTimer;
  bool _parentGateHolding = false;

  @override
  void initState() {
    super.initState();
    // Refresh on open instead of relying on pull-to-refresh, which children
    // rarely discover (docs/design/CHILD_USABILITY_RISK_REPORT.md R6).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(dailyPlanProvider);
    });
  }

  @override
  void dispose() {
    _parentGateTimer?.cancel();
    super.dispose();
  }

  void _startParentGateHold() {
    setState(() => _parentGateHolding = true);
    _parentGateTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _parentGateHolding = false);
        context.push('/parent-pin');
      }
    });
  }

  void _cancelParentGateHold() {
    _parentGateTimer?.cancel();
    if (mounted) setState(() => _parentGateHolding = false);
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(activeChildProvider);
    final planAsync = ref.watch(dailyPlanProvider);
    final nickname = child.child?['nickname'] as String? ?? 'Bạn';
    final plan = planAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final nextLesson = plan.isNotEmpty ? plan.first : null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: MiTokens.space2,
        title: Row(
          children: [
            const MiCharacter(
              expression: MiExpression.welcome,
              size: 36,
              semanticLabel: 'MI',
            ),
            const SizedBox(width: MiTokens.space3),
            Expanded(
              child: Text(
                'Chào $nickname!',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: MiTokens.space2),
            child: GestureDetector(
              onTapDown: (_) => _startParentGateHold(),
              onTapUp: (_) => _cancelParentGateHold(),
              onTapCancel: _cancelParentGateHold,
              child: Semantics(
                label: 'Khu vực phụ huynh, giữ 3 giây để mở',
                button: true,
                child: Container(
                  width: MiTokens.touchTargetChild,
                  height: MiTokens.touchTargetChild,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        _parentGateHolding ? MiColors.primarySoft : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: const MiIcon(
                    MiIconName.parent,
                    color: MiColors.textSecondary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dailyPlanProvider),
        child: ListView(
          padding: const EdgeInsets.all(MiTokens.space4),
          children: [
            // ─── Hero CTA ────────────────────────────────────────────
            MiButton(
              label: nextLesson != null ? 'Tiếp tục học' : 'Bắt đầu học',
              icon: Icons.play_arrow_rounded,
              width: double.infinity,
              isLoading: planAsync.isLoading && !planAsync.hasValue,
              onPressed: () {
                // TODO(dev1): route to the lesson launcher once a
                // dedicated lesson-start route exists.
              },
            ),
            if (nextLesson != null) ...[
              const SizedBox(height: MiTokens.space2),
              Text(
                _planSubtitle(nextLesson),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: MiTokens.space8),

            // ─── Daily mission ───────────────────────────────────────
            Text(
              'Nhiệm vụ hôm nay',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: MiTokens.space3),
            planAsync.when(
              loading: () => const MiLoading(),
              error: (e, _) => MiErrorState(
                title: 'Không thể tải kế hoạch',
                onRetry: () => ref.invalidate(dailyPlanProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const MiEmptyState(
                    title: 'Chưa có nhiệm vụ hôm nay',
                    subtitle: 'MI sẽ gợi ý bài học mới sớm thôi!',
                    emoji: '✨',
                  );
                }
                return Column(
                  children:
                      items.map((item) => _buildPlanItem(context, item)).toList(),
                );
              },
            ),

            const SizedBox(height: MiTokens.space8),

            // ─── World map / Garden entries ─────────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildDestinationCard(
                    context,
                    icon: MiIconName.world,
                    color: MiColors.primary,
                    label: 'Bản đồ\nthế giới',
                    onTap: () => context.push('/world'),
                  ),
                ),
                const SizedBox(width: MiTokens.space3),
                Expanded(
                  child: _buildDestinationCard(
                    context,
                    icon: MiIconName.garden,
                    color: MiColors.secondary,
                    label: 'Vườn\nthành tích',
                    onTap: () => context.push('/garden'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: MiColors.primary,
        unselectedItemColor: MiColors.textSecondary,
        onTap: (index) {
          switch (index) {
            case 0:
              break; // already home
            case 1:
              context.push('/world');
            case 2:
              context.push('/garden');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: MiIcon(MiIconName.home, color: MiColors.textSecondary),
            activeIcon:
                MiIcon(MiIconName.home, filled: true, color: MiColors.primary),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: MiIcon(MiIconName.world, color: MiColors.textSecondary),
            activeIcon:
                MiIcon(MiIconName.world, filled: true, color: MiColors.primary),
            label: 'Bản đồ',
          ),
          BottomNavigationBarItem(
            icon: MiIcon(MiIconName.garden, color: MiColors.textSecondary),
            activeIcon:
                MiIcon(MiIconName.garden, filled: true, color: MiColors.primary),
            label: 'Vườn',
          ),
        ],
      ),
    );
  }

  String _planSubtitle(Map<String, dynamic> item) {
    final title = item['title'] as String? ?? 'Bài học';
    final subject = item['subject'] as String? ?? '';
    final minutes = item['estimated_minutes'] ?? 5;
    final detail = subject.isEmpty ? '$minutes phút' : '$subject · $minutes phút';
    return '$title — $detail';
  }

  Widget _buildPlanItem(BuildContext context, Map<String, dynamic> item) {
    final title = item['title'] as String? ?? 'Bài học';
    final subject = item['subject'] as String? ?? '';
    final minutes = item['estimated_minutes'] ?? 5;

    return Padding(
      padding: const EdgeInsets.only(bottom: MiTokens.space3),
      child: MiCard(
        onTap: () {
          // TODO(dev1): start lesson via lesson provider
        },
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: MiColors.primarySoft,
                borderRadius: BorderRadius.circular(MiTokens.radiusMd),
              ),
              child: const Center(
                child: Icon(Icons.menu_book_rounded, color: MiColors.primary),
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
            const MiIcon(MiIconName.play, color: MiColors.primary, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationCard(
    BuildContext context, {
    required MiIconName icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return MiCard(
      accentColor: color.withValues(alpha: 0.3),
      onTap: onTap,
      child: SizedBox(
        height: 96,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MiIcon(icon, filled: true, color: color, size: 32),
            const SizedBox(height: MiTokens.space2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
