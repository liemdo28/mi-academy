import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';

import '../providers/providers.dart';

/// Child home screen — Phase 1 brand reference implementation.
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
    final copy = _HomeCopy(context);
    final isTablet = context.miDeviceClass != MiDeviceClass.phone;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: MiTokens.space4,
        title: const MiAcademyLogo(
          variant: MiLogoVariant.primary,
          size: 44,
          compact: true,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: MiTokens.space3),
            child: GestureDetector(
              onTapDown: (_) => _startParentGateHold(),
              onTapUp: (_) => _cancelParentGateHold(),
              onTapCancel: _cancelParentGateHold,
              child: Semantics(
                label: copy.parentGateLabel,
                button: true,
                child: AnimatedContainer(
                  duration: MiMotion.resolve(context, MiMotion.fast),
                  width: MiTokens.touchTargetChild,
                  height: MiTokens.touchTargetChild,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _parentGateHolding
                        ? MiColors.primarySoft
                        : MiColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: MiShadows.soft,
                  ),
                  child: const MiBrandIconView(
                    icon: MiBrandIcon.parent,
                    color: MiColors.textPrimary,
                    size: 22,
                    decorative: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: MiColors.primary,
        onRefresh: () async => ref.invalidate(dailyPlanProvider),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            isTablet ? MiTokens.space8 : MiTokens.space4,
            MiTokens.space2,
            isTablet ? MiTokens.space8 : MiTokens.space4,
            MiTokens.space8,
          ),
          children: [
            _HomeHero(
              greeting: copy.greeting(nickname),
              subtitle: copy.playLearnGrow,
              mascotLabel: copy.mascotLabel,
              ctaLabel: nextLesson != null
                  ? copy.continueLearning
                  : copy.startLearning,
              isLoading: planAsync.isLoading && !planAsync.hasValue,
              onPressed: child.childId == null
                  ? null
                  : () => _launchLesson(context, child.childId!, nextLesson),
            ),
            const SizedBox(height: MiTokens.space4),
            _HomeProgressRow(planCount: plan.length, copy: copy),
            const SizedBox(height: MiTokens.space8),
            MiSectionHeader(
              title: copy.dailyMission,
              subtitle: copy.dailyMissionSubtitle,
            ),
            const SizedBox(height: MiTokens.space3),
            planAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(MiTokens.space8),
                child: MiLoading(),
              ),
              error: (e, _) => MiErrorState(
                title: copy.planLoadError,
                onRetry: () => ref.invalidate(dailyPlanProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return _HomeEmptyPlan(copy: copy);
                }
                return Column(
                  children: items
                      .map(
                        (item) => _PlanItem(
                          item: item,
                          childId: child.childId,
                          copy: copy,
                          onTap: child.childId == null
                              ? null
                              : () => _launchLesson(
                                    context,
                                    child.childId!,
                                    item,
                                  ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: MiTokens.space8),
            MiSectionHeader(title: copy.gameCategories),
            const SizedBox(height: MiTokens.space3),
            _GameCategoryGrid(
              copy: copy,
              childId: child.childId,
              onLaunchGame: (gameType) {
                if (child.childId == null) return;
                final uri = Uri(
                  path: '/game/$gameType',
                  queryParameters: {'childId': child.childId!},
                );
                context.push(uri.toString());
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: MiBottomNavigation(
        currentIndex: 0,
        destinations: [
          MiBottomNavigationDestination(
            label: copy.home,
            icon: MiBrandIcon.profile,
            activeIcon: MiBrandIcon.profile,
          ),
          MiBottomNavigationDestination(
            label: copy.world,
            icon: MiBrandIcon.world,
            activeIcon: MiBrandIcon.world,
          ),
          MiBottomNavigationDestination(
            label: copy.garden,
            icon: MiBrandIcon.garden,
            activeIcon: MiBrandIcon.garden,
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.push('/world');
            case 2:
              context.push('/garden');
          }
        },
      ),
    );
  }

  void _launchLesson(
    BuildContext context,
    String childId,
    Map<String, dynamic>? lesson,
  ) {
    final lessonId = lesson?['lesson_id'] as String?;
    final gameType = lesson?['game_type'] as String? ?? 'memory_cards';
    final query = {
      'childId': childId,
      if (lessonId != null) 'lessonId': lessonId,
    };
    final uri = Uri(path: '/game/$gameType', queryParameters: query);
    context.push(uri.toString());
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.greeting,
    required this.subtitle,
    required this.mascotLabel,
    required this.ctaLabel,
    required this.isLoading,
    required this.onPressed,
  });

  final String greeting;
  final String subtitle;
  final String mascotLabel;
  final String ctaLabel;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.miDeviceClass != MiDeviceClass.phone;
    return Container(
      padding: EdgeInsets.all(isTablet ? MiTokens.space6 : MiTokens.space4),
      decoration: BoxDecoration(
        color: MiColors.surface,
        borderRadius: BorderRadius.circular(MiTokens.radiusXl),
        boxShadow: MiShadows.raised,
      ),
      child: isTablet
          ? Row(
              children: [
                Expanded(child: _HeroCopy(this)),
                const SizedBox(width: MiTokens.space6),
                MiMascotReaction(
                  emotion: MiMascotEmotion.welcome,
                  size: MiTokens.mascotReactionLg,
                  semanticLabel: mascotLabel,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: MiMascotReaction(
                    emotion: MiMascotEmotion.welcome,
                    size: MiTokens.mascotReactionMd,
                    semanticLabel: mascotLabel,
                  ),
                ),
                _HeroCopy(this),
              ],
            ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy(this.hero);

  final _HomeHero hero;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          hero.greeting,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: MiTokens.space2),
        Text(hero.subtitle, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: MiTokens.space6),
        MiPrimaryButton(
          label: hero.ctaLabel,
          icon: const MiIcon(
            MiIconName.play,
            color: MiColors.textOnPrimary,
            size: MiTokens.iconMd,
          ),
          isLoading: hero.isLoading,
          width: double.infinity,
          onPressed: hero.onPressed,
        ),
      ],
    );
  }
}

class _HomeProgressRow extends StatelessWidget {
  const _HomeProgressRow({required this.planCount, required this.copy});

  final int planCount;
  final _HomeCopy copy;

  @override
  Widget build(BuildContext context) {
    final progress = planCount == 0 ? 0.08 : (planCount / 4).clamp(0.25, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        final progressCard = MiProgressCard(
          title: copy.progressTitle,
          subtitle: planCount == 0
              ? copy.progressEmpty
              : copy.progressWithCount(planCount),
          progress: progress,
        );
        final badges = Row(
          children: [
            Expanded(
              child: MiAchievementBadge(
                label: copy.stars,
                value: '0',
                icon: MiBrandIcon.rewardStar,
              ),
            ),
            const SizedBox(width: MiTokens.space3),
            Expanded(
              child: MiAchievementBadge(
                label: copy.badges,
                value: '0',
                icon: MiBrandIcon.achievement,
                color: MiColors.discovery,
              ),
            ),
          ],
        );

        if (wide) {
          return Row(
            children: [
              Expanded(flex: 3, child: progressCard),
              const SizedBox(width: MiTokens.space3),
              Expanded(flex: 2, child: badges),
            ],
          );
        }
        return Column(
          children: [
            progressCard,
            const SizedBox(height: MiTokens.space3),
            badges,
          ],
        );
      },
    );
  }
}

class _HomeEmptyPlan extends StatelessWidget {
  const _HomeEmptyPlan({required this.copy});

  final _HomeCopy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MiTokens.space6),
      decoration: BoxDecoration(
        color: MiColors.surface,
        borderRadius: BorderRadius.circular(MiTokens.radiusLg),
        boxShadow: MiShadows.soft,
      ),
      child: Row(
        children: [
          const MiMascotReaction(
            emotion: MiMascotEmotion.thinking,
            size: MiTokens.mascotReactionSm,
          ),
          const SizedBox(width: MiTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy.emptyTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: MiTokens.space1),
                Text(copy.emptySubtitle,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanItem extends StatelessWidget {
  const _PlanItem({
    required this.item,
    required this.childId,
    required this.copy,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final String? childId;
  final _HomeCopy copy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String? ?? copy.lessonFallback;
    final subject = item['subject'] as String? ?? '';
    final minutes = item['estimated_minutes'] ?? 5;

    return Padding(
      padding: const EdgeInsets.only(bottom: MiTokens.space3),
      child: MiCard(
        onTap: onTap,
        padding: const EdgeInsets.all(MiTokens.space3),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MiColors.discoverySoft,
                borderRadius: BorderRadius.circular(MiTokens.radiusLg),
              ),
              child: const MiIcon(
                MiIconName.play,
                color: MiColors.discovery,
                size: MiTokens.iconLg,
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
                  const SizedBox(height: MiTokens.space1),
                  Text(
                    subject.isEmpty
                        ? copy.minutes(minutes)
                        : '$subject - ${copy.minutes(minutes)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: MiTokens.space2),
            const MiIcon(MiIconName.play, color: MiColors.primary, size: 28),
          ],
        ),
      ),
    );
  }
}

class _GameCategoryGrid extends StatelessWidget {
  const _GameCategoryGrid({
    required this.copy,
    required this.childId,
    required this.onLaunchGame,
  });

  final _HomeCopy copy;
  final String? childId;
  final ValueChanged<String> onLaunchGame;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _GameCategory(
        title: copy.lettersTitle,
        subtitle: copy.lettersSubtitle,
        icon: MiBrandIcon.alphabet,
        color: MiColors.primary,
        gameType: 'missing_letter',
      ),
      _GameCategory(
        title: copy.numbersTitle,
        subtitle: copy.numbersSubtitle,
        icon: MiBrandIcon.numbers,
        color: MiColors.secondary,
        gameType: 'math_race',
      ),
      _GameCategory(
        title: copy.logicTitle,
        subtitle: copy.logicSubtitle,
        icon: MiBrandIcon.logic,
        color: MiColors.creative,
        gameType: 'robot_commands',
      ),
      _GameCategory(
        title: copy.memoryTitle,
        subtitle: copy.memorySubtitle,
        icon: MiBrandIcon.memory,
        color: MiColors.discovery,
        gameType: 'memory_cards',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: MiTokens.space3,
            mainAxisSpacing: MiTokens.space3,
            childAspectRatio: columns == 4 ? 0.95 : 0.9,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return MiGameCard(
              title: card.title,
              subtitle: card.subtitle,
              icon: card.icon,
              color: card.color,
              onTap: childId == null ? null : () => onLaunchGame(card.gameType),
            );
          },
        );
      },
    );
  }
}

class _GameCategory {
  const _GameCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.gameType,
  });

  final String title;
  final String subtitle;
  final MiBrandIcon icon;
  final Color color;
  final String gameType;
}

class _HomeCopy {
  _HomeCopy(this.context);

  final BuildContext context;

  String t(String key, [Map<String, dynamic>? params]) =>
      context.miT(key, params);

  String greeting(String name) => t('homeGreeting', {'name': name});
  String get mascotLabel => t('homeMascotLabel');
  String get parentGateLabel => t('homeParentGateLabel');
  String get startLearning => t('homeStartLearning');
  String get continueLearning => t('homeContinueLearning');
  String get playLearnGrow => t('homePlayLearnGrow');
  String get progressTitle => t('homeProgressTitle');
  String get progressEmpty => t('homeProgressEmpty');
  String progressWithCount(int count) =>
      t('homeProgressWithCount', {'count': count});
  String get stars => t('homeStars');
  String get badges => t('homeBadges');
  String get dailyMission => t('homeDailyMission');
  String get dailyMissionSubtitle => t('homeDailyMissionSubtitle');
  String get planLoadError => t('homePlanLoadError');
  String get emptyTitle => t('homeEmptyTitle');
  String get emptySubtitle => t('homeEmptySubtitle');
  String minutes(Object count) => t('homeMinutes', {'count': count});
  String get lessonFallback => t('homeLessonFallback');
  String get gameCategories => t('homeGameCategories');
  String get lettersTitle => t('homeLettersTitle');
  String get lettersSubtitle => t('homeLettersSubtitle');
  String get numbersTitle => t('homeNumbersTitle');
  String get numbersSubtitle => t('homeNumbersSubtitle');
  String get logicTitle => t('homeLogicTitle');
  String get logicSubtitle => t('homeLogicSubtitle');
  String get memoryTitle => t('homeMemoryTitle');
  String get memorySubtitle => t('homeMemorySubtitle');
  String get world => t('homeWorld');
  String get garden => t('homeGarden');
  String get home => t('homeHome');
}
