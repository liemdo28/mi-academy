import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// First-launch language selection, shown by SplashScreen before the normal
/// auth/child flow whenever `ParentSettingsSnapshot.localeConfirmed` is
/// false (fresh install, or after a full local-data reset via
/// ParentSettingsStore.deleteChildData). Bilingual by design -- a family
/// choosing this screen may not yet read either language fluently, so both
/// labels are always shown together rather than relying on a single
/// language's wording.
class LocaleSelectionScreen extends ConsumerStatefulWidget {
  const LocaleSelectionScreen({super.key});

  @override
  ConsumerState<LocaleSelectionScreen> createState() =>
      _LocaleSelectionScreenState();
}

class _LocaleSelectionScreenState extends ConsumerState<LocaleSelectionScreen> {
  bool _saving = false;

  Future<void> _choose(String language) async {
    if (_saving) return;
    setState(() => _saving = true);

    final store = ref.read(parentSettingsStoreProvider);
    final current = await store.load();
    await store.save(
      current.copyWith(language: language, localeConfirmed: true),
    );
    // parentSettingsProvider has no way to observe the store directly, so
    // MiAcademyApp's locale would otherwise stay stale until the next full
    // app restart -- see ParentSettingsScreen for the same pattern.
    ref.invalidate(parentSettingsProvider);

    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiColors.primary,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chọn ngôn ngữ / Choose your language',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _LanguageOption(
                    label: 'Tiếng Việt',
                    semanticLabel: 'Chọn Tiếng Việt',
                    enabled: !_saving,
                    onTap: () => _choose('vi'),
                  ),
                  const SizedBox(height: 16),
                  _LanguageOption(
                    label: 'English',
                    semanticLabel: 'Choose English',
                    enabled: !_saving,
                    onTap: () => _choose('en'),
                  ),
                  if (_saving) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(color: Colors.white),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.semanticLabel,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: MiColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
