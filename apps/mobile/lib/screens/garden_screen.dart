import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

/// Achievement Garden — the soft-retention collection screen.
///
/// Shows badges the child has actually earned, sourced from
/// [localRewardsProvider] (local, offline-first — never depends on
/// connectivity). No rank, no comparison, no purchase prompts — see
/// docs/design/MI_DESIGN_SYSTEM.md and §13 of the product brief.
class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(localRewardsProvider);
    final locale = ref.watch(parentSettingsProvider).maybeWhen(
          data: (settings) => settings.language,
          orElse: () => 'vi',
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(locale == 'en' ? 'Achievement Garden' : 'Vườn thành tích'),
      ),
      body: SafeArea(
        child: rewardsAsync.when(
          loading: () => const MiLoading(),
          error: (e, _) => MiErrorState(
            title: locale == 'en'
                ? "Couldn't load the achievement garden"
                : 'Không thể tải vườn thành tích',
            retryLabel: locale == 'en' ? 'Try again' : 'Thử lại',
            onRetry: () => ref.invalidate(localRewardsProvider),
          ),
          data: (rewards) {
            if (rewards.isEmpty) {
              return MiEmptyState(
                title: locale == 'en'
                    ? 'Your garden is still empty'
                    : 'Vườn của con còn trống',
                subtitle: locale == 'en'
                    ? 'Finish missions to grow the first flowers!'
                    : 'Hoàn thành nhiệm vụ để trồng những bông hoa đầu tiên!',
                brandIcon: MiBrandIcon.garden,
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
                final title = reward.name[locale] ?? reward.name['vi'] ?? '';
                return MiCard(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const MiBrandIconView(
                        icon: MiBrandIcon.achievement,
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
