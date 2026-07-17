import 'package:flutter/material.dart';

class LocalizationScreen extends StatelessWidget {
  const LocalizationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Localization (i18n)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Supported Languages', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                _LanguageCard(language: 'Tiếng Việt', code: 'vi', completion: 92, flag: '🇻🇳'),
                const SizedBox(width: 12),
                _LanguageCard(language: 'English', code: 'en', completion: 88, flag: '🇺🇸'),
              ],
            ),
            const SizedBox(height: 24),
            Text('String Keys (sample)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Showing 1-20 of ~2,400 keys', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Key')),
                    DataColumn(label: Text('Vietnamese')),
                    DataColumn(label: Text('English')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: const [
                    DataRow(cells: [
                      DataCell(Text('intro.greeting', style: TextStyle(fontFamily: 'monospace'))),
                      DataCell(Text('Chào mừng bạn nhỏ!')),
                      DataCell(Text('Welcome, little learner!')),
                      DataCell(Text('✓', style: TextStyle(color: Colors.green))),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('game.start', style: TextStyle(fontFamily: 'monospace'))),
                      DataCell(Text('Bắt đầu chơi')),
                      DataCell(Text('Start Playing')),
                      DataCell(Text('✓', style: TextStyle(color: Colors.green))),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('lesson.summary', style: TextStyle(fontFamily: 'monospace'))),
                      DataCell(Text('Tóm tắt bài học')),
                      DataCell(Text('Lesson Summary')),
                      DataCell(Text('✓', style: TextStyle(color: Colors.green))),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('parent.dashboard', style: TextStyle(fontFamily: 'monospace'))),
                      DataCell(Text('Khu vực phụ huynh')),
                      DataCell(Text('Parent Area')),
                      DataCell(Text('✓', style: TextStyle(color: Colors.green))),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('reward.star', style: TextStyle(fontFamily: 'monospace'))),
                      DataCell(Text('Ngôi sao')),
                      DataCell(Text('Star')),
                      DataCell(Text('✓', style: TextStyle(color: Colors.green))),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String language;
  final String code;
  final int completion;
  final String flag;

  const _LanguageCard({
    required this.language,
    required this.code,
    required this.completion,
    required this.flag,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(language, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: completion / 100, backgroundColor: Colors.grey[200]),
            const SizedBox(height: 4),
            Text('$completion% complete', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
