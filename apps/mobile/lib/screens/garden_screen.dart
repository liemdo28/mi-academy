import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

/// Achievement Garden — placeholder shell.
///
/// Shows earned rewards once `rewardsProvider` returns real collectible
/// data (badges/stickers). No rank, no comparison, no purchase prompts —
/// see docs/design/MI_DESIGN_SYSTEM.md and §13 of the product brief.
class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vườn thành tích')),
      body: SafeArea(
        child: rewardsAsync.when(
          loading: () => const MiLoading(),
          error: (e, _) => MiErrorState(
            title: 'Không thể tải vườn thành tích',
            onRetry: () => ref.invalidate(rewardsProvider),
          ),
          data: (rewards) {
            if (rewards.isEmpty) {
              return const MiEmptyState(
                title: 'Vườn của con còn trống',
                subtitle: 'Hoàn thành nhiệm vụ để trồng những bông hoa đầu tiên!',
                emoji: '🌱',
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(MiTokens.space4),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                mainAxisSpacing: MiTokens.space3,
                crossAxisSpacing: MiTokens.space3,
                childAspectRatio: 0.9,
              ),
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                final reward = rewards[index];
                final title = reward['title'] as String? ?? 'Huy hiệu';
                return MiCard(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const MiIcon(
                        MiIconName.badge,
                        color: MiColors.secondary,
                        size: 40,
                      ),
                      const SizedBox(height: MiTokens.space2),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
