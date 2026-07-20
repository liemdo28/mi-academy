import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:localization/localization.dart';
import '../providers/providers.dart';
import '../widgets/add_child_dialog.dart';

/// Screen for selecting which child profile to use.
///
/// Shown after parent login. Child profiles are loaded from the backend
/// (via [activeChildProvider]) — no PII beyond nickname/avatar is shown.
class ChildSelectorScreen extends ConsumerStatefulWidget {
  const ChildSelectorScreen({super.key});

  @override
  ConsumerState<ChildSelectorScreen> createState() =>
      _ChildSelectorScreenState();
}

class _ChildSelectorScreenState extends ConsumerState<ChildSelectorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(activeChildProvider.notifier).loadChildren();
    });
  }

  Future<void> _openAddChildDialog() async {
    final result = await showDialog<({String nickname, String ageGroup})>(
      context: context,
      builder: (context) => const AddChildDialog(),
    );
    if (result == null || !mounted) return;

    final ok = await ref
        .read(activeChildProvider.notifier)
        .createChild(nickname: result.nickname, ageGroup: result.ageGroup);
    if (ok && mounted) {
      context.go('/home');
    } else if (mounted) {
      final error = ref.read(activeChildProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? MiMobileStrings.m060)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeChildProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MiTokens.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: MiTokens.space8),
              Text(
                MiMobileStrings.m061,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: MiTokens.space2),
              Text(
                MiMobileStrings.m062,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: MiTokens.space8),
              Expanded(
                child: state.isLoading && state.children.isEmpty
                    ? const MiLoading()
                    : state.error != null && state.children.isEmpty
                        ? MiErrorState(
                            title: MiMobileStrings.m063,
                            onRetry: () => ref
                                .read(activeChildProvider.notifier)
                                .loadChildren(),
                          )
                        : GridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: MiTokens.space4,
                            crossAxisSpacing: MiTokens.space4,
                            childAspectRatio: 0.9,
                            children: [
                              for (final child in state.children)
                                _ChildAvatarCard(
                                  avatarId: child['avatar_id'] as String? ??
                                      'avatar_01',
                                  nickname: child['nickname'] as String? ?? '',
                                  ageGroup:
                                      child['age_group'] as String? ?? 'junior',
                                  onTap: () async {
                                    await ref
                                        .read(activeChildProvider.notifier)
                                        .selectChild(child);
                                    if (context.mounted) context.go('/home');
                                  },
                                ),
                              _AddChildCard(onTap: _openAddChildDialog),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildAvatarCard extends StatelessWidget {
  final String avatarId;
  final String nickname;
  final String ageGroup;
  final VoidCallback onTap;

  const _ChildAvatarCard({
    required this.avatarId,
    required this.nickname,
    required this.ageGroup,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MiCard(
      onTap: onTap,
      accentColor: _ageGroupColor(ageGroup),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _ageGroupColor(ageGroup).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _avatarEmoji(avatarId),
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(height: MiTokens.space3),
          Text(
            nickname,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MiTokens.space1),
          Text(
            _ageGroupLabel(ageGroup),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Color _ageGroupColor(String ag) {
    switch (ag) {
      case 'junior':
        return MiColors.primary;
      case 'explorer':
        return MiColors.success;
      case 'master':
        return MiColors.secondary;
      default:
        return MiColors.primary;
    }
  }

  String _ageGroupLabel(String ag) {
    switch (ag) {
      case 'junior':
        return MiMobileStrings.m064;
      case 'explorer':
        return MiMobileStrings.m065;
      case 'master':
        return MiMobileStrings.m066;
      default:
        return '';
    }
  }

  String _avatarEmoji(String avatarId) {
    switch (avatarId) {
      case 'avatar_01':
        return '🐻';
      case 'avatar_02':
        return '🐰';
      case 'avatar_03':
        return '🦊';
      case 'avatar_04':
        return '🐱';
      default:
        return '🧒';
    }
  }
}

class _AddChildCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddChildCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MiCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: MiColors.border,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.add, size: 36, color: MiColors.textSecondary),
            ),
          ),
          const SizedBox(height: MiTokens.space3),
          Text(
            MiMobileStrings.m067,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: MiColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
