import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';

/// Screen for selecting which child profile to use.
///
/// Shown after parent login. Child profiles are loaded from local storage
/// and cached. This screen shows only the nickname and avatar — no PII.
class ChildSelectorScreen extends ConsumerWidget {
  const ChildSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Load child profiles from Hive via ProfileRepository
    // final children = ref.watch(childProfilesProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MiTokens.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: MiTokens.space8),
              Text(
                'Chọn hồ sơ của bạn',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: MiTokens.space2),
              Text(
                'Bạn là ai hôm nay?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: MiTokens.space8),
              // Avatar grid — 2 columns
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: MiTokens.space4,
                  crossAxisSpacing: MiTokens.space4,
                  childAspectRatio: 0.9,
                  children: const [
                    _ChildAvatarCard(
                      avatarId: 'avatar_01',
                      nickname: 'Minh',
                      ageGroup: 'junior',
                    ),
                    _ChildAvatarCard(
                      avatarId: 'avatar_02',
                      nickname: 'Lan',
                      ageGroup: 'explorer',
                    ),
                    _AddChildCard(),
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

  const _ChildAvatarCard({
    required this.avatarId,
    required this.nickname,
    required this.ageGroup,
  });

  @override
  Widget build(BuildContext context) {
    return MiCard(
      onTap: () {
        // TODO: Set active child profile
        context.go('/home');
      },
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
        return MiTokens.juniorBlue;
      case 'explorer':
        return MiTokens.explorerGreen;
      case 'master':
        return MiTokens.masterPurple;
      default:
        return MiTokens.primaryBlue;
    }
  }

  String _ageGroupLabel(String ag) {
    switch (ag) {
      case 'junior':
        return '5-7 tuổi';
      case 'explorer':
        return '8-10 tuổi';
      case 'master':
        return '11-12 tuổi';
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
  const _AddChildCard();

  @override
  Widget build(BuildContext context) {
    return MiCard(
      onTap: () {
        // TODO: Navigate to create child profile
        context.go('/parent');
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: MiTokens.border,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.add,
                size: 36,
                color: MiTokens.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: MiTokens.space3),
          Text(
            'Thêm hồ sơ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: MiTokens.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
