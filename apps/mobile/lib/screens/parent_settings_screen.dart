import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:localization/localization.dart';
import '../providers/providers.dart';
import '../services/parent_settings_store.dart';

class ParentSettingsScreen extends ConsumerStatefulWidget {
  ParentSettingsScreen({super.key, ParentSettingsStore? store})
      : store = store ?? MemoryParentSettingsStore();

  final ParentSettingsStore store;

  @override
  ConsumerState<ParentSettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<ParentSettingsScreen> {
  ParentSettingsSnapshot _settings = const ParentSettingsSnapshot();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await widget.store.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _save(ParentSettingsSnapshot settings) async {
    setState(() => _settings = settings);
    await widget.store.save(settings);
    // parentSettingsProvider has no way to observe the store directly, so
    // this screen must tell it to re-load -- otherwise a language change
    // here would never reach MiAcademyApp's locale.
    ref.invalidate(parentSettingsProvider);
  }

  Future<void> _downloadOfflineContent() async {
    await _save(_settings.copyWith(offlineReady: true));
    _showMessage(MiMobileStrings.m115);
  }

  Future<void> _prepareExport() async {
    final settings = _settings.copyWith(exportPreparedAt: DateTime.now());
    await _save(settings);
    await widget.store.prepareExport(settings);
    _showMessage(MiMobileStrings.m116);
  }

  Future<void> _confirmDeleteData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(MiMobileStrings.m117),
        content: const Text(MiMobileStrings.m247),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(MiMobileStrings.m119),
          ),
          FilledButton(
            key: const ValueKey('confirm-delete-child-data'),
            style: FilledButton.styleFrom(backgroundColor: MiColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(MiMobileStrings.m120),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.store.deleteChildData();
    await _save(
      const ParentSettingsSnapshot(
        deleteRequestedAt: null,
      ).copyWith(deleteRequestedAt: DateTime.now()),
    );
    _showMessage(MiMobileStrings.m121);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text(MiMobileStrings.m028)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            Text(
              MiMobileStrings.m122,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            MiMobileStrings.m123,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Text(
                          MiMobileStrings.text('m124', {
                            'p0': _settings.dailyLimitMinutes,
                          }),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    Slider(
                      value: _settings.dailyLimitMinutes.toDouble(),
                      min: 15,
                      max: 120,
                      divisions: 7,
                      activeColor: MiColors.primary,
                      label: '${_settings.dailyLimitMinutes}',
                      onChanged: (v) => _save(
                        _settings.copyWith(dailyLimitMinutes: v.round()),
                      ),
                    ),
                    const Text(
                      MiMobileStrings.m125,
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              MiMobileStrings.m126,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text(
                MiMobileStrings.m127,
                style: TextStyle(fontSize: 16),
              ),
              value: _settings.soundEnabled,
              activeThumbColor: MiColors.primary,
              onChanged: (v) => _save(_settings.copyWith(soundEnabled: v)),
            ),
            SwitchListTile(
              title: const Text(
                MiMobileStrings.m128,
                style: TextStyle(fontSize: 16),
              ),
              value: _settings.subtitlesEnabled,
              activeThumbColor: MiColors.primary,
              onChanged: (v) => _save(_settings.copyWith(subtitlesEnabled: v)),
            ),
            const SizedBox(height: 24),
            Text(
              MiMobileStrings.m129,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text(
                MiMobileStrings.m130,
                style: TextStyle(fontSize: 16),
              ),
              subtitle: const Text(
                MiMobileStrings.m248,
                style: TextStyle(fontSize: 13),
              ),
              value: _settings.reduceMotion,
              activeThumbColor: MiColors.primary,
              onChanged: (v) => _save(_settings.copyWith(reduceMotion: v)),
            ),
            const SizedBox(height: 24),
            Text(
              MiMobileStrings.m132,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text(MiMobileStrings.m077),
                        selected: _settings.language == 'vi',
                        onSelected: (_) =>
                            _save(_settings.copyWith(language: 'vi')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('English'),
                        selected: _settings.language == 'en',
                        onSelected: (_) =>
                            _save(_settings.copyWith(language: 'en')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              MiMobileStrings.m133,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      _settings.offlineReady
                          ? Icons.cloud_done
                          : Icons.cloud_download,
                      color: _settings.offlineReady ? MiColors.success : null,
                    ),
                    title: const Text(MiMobileStrings.m134),
                    subtitle: Text(
                      _settings.offlineReady
                          ? MiMobileStrings.m135
                          : MiMobileStrings.m136,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _downloadOfflineContent,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      _settings.exportReady
                          ? Icons.task_alt
                          : Icons.file_download,
                      color: _settings.exportReady ? MiColors.success : null,
                    ),
                    title: const Text(MiMobileStrings.m137),
                    subtitle: Text(
                      _settings.exportReady
                          ? MiMobileStrings.m138
                          : MiMobileStrings.m139,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _prepareExport,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      _settings.deleteConfirmed
                          ? Icons.delete_forever
                          : Icons.delete_outline,
                      color: MiColors.error,
                    ),
                    title: const Text(
                      MiMobileStrings.m140,
                      style: TextStyle(color: MiColors.error),
                    ),
                    subtitle: Text(
                      _settings.deleteConfirmed
                          ? MiMobileStrings.m141
                          : MiMobileStrings.m142,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _confirmDeleteData,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'MI Academy v1.0.0',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: MiColors.textSecondary),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
