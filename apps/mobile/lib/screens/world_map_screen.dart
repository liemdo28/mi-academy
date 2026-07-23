import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_game_content/mi_game_content.dart';

import '../providers/providers.dart';
import '../services/level_selector.dart';
import '../services/world_progression_service.dart';
import '../widgets/learning_journey_panel.dart';

/// World map — a child's real learning journey, not a placeholder.
///
/// One zone per real taxonomy subject ([WorldProgress], sourced from
/// [worldProgressProvider], which is itself built from the already
/// canonical [ActivityMappingResolver]/[LevelSelector] pipeline -- see
/// `world_progression_service.dart`). A subject with zero registered
/// games (e.g. science/creative today) still gets a zone card, honestly
/// showing 0% and no nodes rather than fabricated content.
class WorldMapScreen extends ConsumerStatefulWidget {
  const WorldMapScreen({super.key});

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen> {
  String? _selectedSubjectId;

  static const _subjectIcons = <String, MiBrandIcon>{
    'letters': MiBrandIcon.alphabet,
    'math': MiBrandIcon.numbers,
    'logic': MiBrandIcon.logic,
    'science': MiBrandIcon.exploration,
    'creative': MiBrandIcon.writing,
  };

  @override
  Widget build(BuildContext context) {
    final worldsAsync = ref.watch(worldProgressProvider);
    final settingsAsync = ref.watch(parentSettingsProvider);
    final locale = settingsAsync.value?.language ?? 'vi';

    return Scaffold(
      appBar: AppBar(
        leading: _selectedSubjectId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _selectedSubjectId = null),
              )
            : null,
        title: Text(
          _selectedSubjectId == null
              ? (locale == 'en' ? 'World Map' : 'Bản đồ thế giới')
              : _worldName(worldsAsync.value, _selectedSubjectId!, locale),
        ),
      ),
      body: worldsAsync.when(
        loading: () => MiLoading(message: locale == 'en' ? 'Loading...' : 'Đang tải...'),
        error: (e, _) => MiErrorState(
          title: locale == 'en' ? "Couldn't load the world map" : 'Không thể tải bản đồ',
          onRetry: () => ref.invalidate(worldProgressProvider),
        ),
        data: (worlds) {
          final subjectId = _selectedSubjectId;
          if (subjectId == null) {
            return _buildZoneGrid(context, worlds, locale);
          }
          final world = worlds.firstWhere(
            (w) => w.subjectId == subjectId,
            orElse: () => WorldProgress(subjectId: subjectId, name: const {}, nodes: const []),
          );
          return _buildNodeList(context, world, locale);
        },
      ),
    );
  }

  String _worldName(List<WorldProgress>? worlds, String subjectId, String locale) {
    final world = worlds?.where((w) => w.subjectId == subjectId).firstOrNull;
    if (world == null) return subjectId;
    return world.name[locale] ?? world.name.values.firstOrNull ?? subjectId;
  }

  Widget _buildZoneGrid(BuildContext context, List<WorldProgress> worlds, String locale) {
    if (worlds.isEmpty) {
      return MiEmptyState(
        title: locale == 'en' ? 'No worlds yet' : 'Chưa có thế giới nào',
        brandIcon: MiBrandIcon.world,
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(MiTokens.space4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: MiTokens.space3,
        crossAxisSpacing: MiTokens.space3,
        childAspectRatio: 0.95,
      ),
      itemCount: worlds.length,
      itemBuilder: (context, index) {
        final world = worlds[index];
        return _ZoneCard(
          world: world,
          locale: locale,
          icon: _subjectIcons[world.subjectId] ?? MiBrandIcon.world,
          onTap: () => setState(() => _selectedSubjectId = world.subjectId),
        );
      },
    );
  }

  Widget _buildNodeList(BuildContext context, WorldProgress world, String locale) {
    if (world.nodes.isEmpty) {
      return MiEmptyState(
        title: locale == 'en' ? 'Coming soon' : 'Sắp ra mắt',
        subtitle: locale == 'en'
            ? 'No activities are built for this world yet.'
            : 'Chưa có hoạt động nào cho thế giới này.',
        brandIcon: _subjectIcons[world.subjectId] ?? MiBrandIcon.world,
      );
    }

    final resolverAsync = ref.watch(activityMappingResolverProvider);
    final taxonomy = resolverAsync.value?.taxonomy;
    final childId = ref.watch(activeChildProvider).childId ?? 'offline-child';

    return ListView.builder(
      padding: const EdgeInsets.all(MiTokens.space4),
      itemCount: world.nodes.length,
      itemBuilder: (context, index) {
        final node = world.nodes[index];
        return _JourneyNodeTile(
          node: node,
          locale: locale,
          onTap: taxonomy == null
              ? null
              : () => _openJourneyPanel(context, node, world.name, taxonomy, locale, childId),
        );
      },
    );
  }

  void _openJourneyPanel(
    BuildContext context,
    JourneyNode node,
    Map<String, String> subjectName,
    SkillTaxonomy taxonomy,
    String locale,
    String childId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => LearningJourneyPanel(
        node: node,
        subjectName: subjectName,
        taxonomy: taxonomy,
        locale: locale,
        onPlay: node.state == LevelProgressState.locked
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                context.push(
                  Uri(path: '/game/${node.game.gameId}', queryParameters: {'childId': childId})
                      .toString(),
                );
              },
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    required this.world,
    required this.locale,
    required this.icon,
    required this.onTap,
  });

  final WorldProgress world;
  final String locale;
  final MiBrandIcon icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasContent = world.totalNodes > 0;
    return MiCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MiBrandIconView(icon: icon, size: MiTokens.iconXl, decorative: true),
          const SizedBox(height: MiTokens.space2),
          Text(
            world.name[locale] ?? world.name.values.firstOrNull ?? world.subjectId,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: MiTokens.space2),
          if (hasContent) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(MiTokens.radiusFull),
              child: LinearProgressIndicator(
                value: world.completionPercent,
                minHeight: 6,
                backgroundColor: MiColors.border,
                valueColor: const AlwaysStoppedAnimation(MiColors.success),
              ),
            ),
            const SizedBox(height: MiTokens.space1),
            Text(
              '${world.masteredCount}/${world.totalNodes}',
              style: const TextStyle(color: MiColors.textSecondary, fontSize: MiTokens.fontXs),
            ),
          ] else
            Text(
              locale == 'en' ? 'Coming soon' : 'Sắp ra mắt',
              style: const TextStyle(color: MiColors.textSecondary, fontSize: MiTokens.fontXs),
            ),
        ],
      ),
    );
  }
}

/// One node tile on a world's map. The recommended node gently pulses
/// (respecting reduced motion via [MiMotion.resolve]); every other state
/// is a static icon+color pair -- never color alone (see
/// [JourneyStateBadge]'s icon-per-state table, reused here for
/// consistency between the map and the detail panel).
class _JourneyNodeTile extends StatefulWidget {
  const _JourneyNodeTile({required this.node, required this.locale, required this.onTap});

  final JourneyNode node;
  final String locale;
  final VoidCallback? onTap;

  @override
  State<_JourneyNodeTile> createState() => _JourneyNodeTileState();
}

class _JourneyNodeTileState extends State<_JourneyNodeTile> with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    if (widget.node.state == LevelProgressState.recommended) {
      _pulse = AnimationController(vsync: this, duration: MiMotion.celebration)
        ..repeat(reverse: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pulse != null && MediaQuery.of(context).disableAnimations) {
      _pulse!
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final isLocked = node.state == LevelProgressState.locked;
    final color = JourneyStateBadge.colorFor(node.state);
    final icon = JourneyStateBadge.iconFor(node.state);

    Widget avatar = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, color: color),
    );
    if (_pulse != null) {
      avatar = AnimatedBuilder(
        animation: _pulse!,
        builder: (context, child) =>
            Transform.scale(scale: 1.0 + (_pulse!.value * 0.08), child: child),
        child: avatar,
      );
    }

    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: MiCard(
        onTap: widget.onTap,
        child: Row(
          children: [
            avatar,
            const SizedBox(width: MiTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.locale == 'en'
                        ? 'Level ${node.level.levelNumber}'
                        : 'Bài ${node.level.levelNumber}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    node.game.localizedName[widget.locale] ??
                        node.game.localizedName.values.firstOrNull ??
                        node.game.gameId,
                    style: const TextStyle(color: MiColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (isLocked) const Icon(Icons.lock_rounded, color: MiColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
