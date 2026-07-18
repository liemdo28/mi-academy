import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import '../services/parent_settings_store.dart';

class ParentSettingsScreen extends ConsumerStatefulWidget {
  ParentSettingsScreen({
    super.key,
    ParentSettingsStore? store,
  }) : store = store ?? MemoryParentSettingsStore();

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
  }

  Future<void> _downloadOfflineContent() async {
    await _save(_settings.copyWith(offlineReady: true));
    _showMessage('Nội dung MVP đã sẵn sàng để học offline.');
  }

  Future<void> _prepareExport() async {
    final settings = _settings.copyWith(exportPreparedAt: DateTime.now());
    await _save(settings);
    await widget.store.prepareExport(settings);
    _showMessage('Đã chuẩn bị bản xuất dữ liệu cho phụ huynh.');
  }

  Future<void> _confirmDeleteData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa dữ liệu của bé?'),
        content: const Text(
          'Thao tác này chỉ dành cho phụ huynh và cần xác nhận rõ ràng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            key: const ValueKey('confirm-delete-child-data'),
            style: FilledButton.styleFrom(backgroundColor: MiColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.store.deleteChildData();
    await _save(
      const ParentSettingsSnapshot(deleteRequestedAt: null).copyWith(
        deleteRequestedAt: DateTime.now(),
      ),
    );
    _showMessage('Đã ghi nhận yêu cầu xóa dữ liệu trên thiết bị.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            Text('Giới hạn thời gian',
                style: Theme.of(context).textTheme.headlineMedium),
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
                          child:
                              Text('Hằng ngày', style: TextStyle(fontSize: 16)),
                        ),
                        Text(
                          '${_settings.dailyLimitMinutes} phút',
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
                      'MI sẽ nhắc nghỉ khi sắp hết giờ.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Âm thanh & phụ đề',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Âm thanh', style: TextStyle(fontSize: 16)),
              value: _settings.soundEnabled,
              activeThumbColor: MiColors.primary,
              onChanged: (v) => _save(_settings.copyWith(soundEnabled: v)),
            ),
            SwitchListTile(
              title: const Text('Phụ đề cho giọng đọc',
                  style: TextStyle(fontSize: 16)),
              value: _settings.subtitlesEnabled,
              activeThumbColor: MiColors.primary,
              onChanged: (v) => _save(_settings.copyWith(subtitlesEnabled: v)),
            ),
            const SizedBox(height: 24),
            Text('Trợ năng', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Giảm hiệu ứng chuyển động',
                  style: TextStyle(fontSize: 16)),
              subtitle: const Text(
                'Tắt bớt hoạt ảnh trong trò chơi cho trẻ nhạy cảm với chuyển động.',
                style: TextStyle(fontSize: 13),
              ),
              value: _settings.reduceMotion,
              activeThumbColor: MiColors.primary,
              onChanged: (v) => _save(_settings.copyWith(reduceMotion: v)),
            ),
            const SizedBox(height: 24),
            Text('Ngôn ngữ', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Tiếng Việt'),
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
            Text('Dữ liệu', style: Theme.of(context).textTheme.headlineMedium),
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
                    title: const Text('Tải nội dung offline'),
                    subtitle: Text(
                      _settings.offlineReady
                          ? 'Sẵn sàng học không cần mạng'
                          : 'Lưu 6 trò chơi MVP trên thiết bị',
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
                    title: const Text('Xuất dữ liệu của bé'),
                    subtitle: Text(
                      _settings.exportReady
                          ? 'Bản xuất dữ liệu đã sẵn sàng'
                          : 'Chuẩn bị báo cáo cho phụ huynh',
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
                      'Xóa dữ liệu của bé',
                      style: TextStyle(color: MiColors.error),
                    ),
                    subtitle: Text(
                      _settings.deleteConfirmed
                          ? 'Yêu cầu xóa đã được ghi nhận'
                          : 'Cần xác nhận của phụ huynh',
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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: MiColors.textSecondary),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
