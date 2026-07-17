import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Content Overview', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatCard(title: 'Lessons', count: '24', icon: Icons.menu_book, color: Colors.blue),
                const SizedBox(width: 16),
                _StatCard(title: 'Questions', count: '312', icon: Icons.quiz, color: Colors.green),
                const SizedBox(width: 16),
                _StatCard(title: 'Games', count: '6', icon: Icons.games, color: Colors.orange),
                const SizedBox(width: 16),
                _StatCard(title: 'Languages', count: '2', icon: Icons.translate, color: Colors.purple),
              ],
            ),
            const SizedBox(height: 32),
            Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(icon: const Icon(Icons.add), label: const Text('New Lesson'),
                    onPressed: () {}),
                OutlinedButton.icon(icon: const Icon(Icons.upload), label: const Text('Import Content'),
                    onPressed: () {}),
                OutlinedButton.icon(icon: const Icon(Icons.check_circle), label: const Text('Review Drafts'),
                    onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(count, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
