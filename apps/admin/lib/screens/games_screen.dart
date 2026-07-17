import 'package:flutter/material.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Games')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MVP Games (6)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, childAspectRatio: 1.5, crossAxisSpacing: 12, mainAxisSpacing: 12,
                ),
                itemCount: 6,
                itemBuilder: (ctx, i) {
                  final games = [
                    ('Word Builder', 'word_builder', true),
                    ('Sound Match', 'sound_match', true),
                    ('Math Race', 'math_race', true),
                    ('Math Supermarket', 'math_supermarket', false),
                    ('Memory Cards', 'memory_cards', false),
                    ('Robot Commands', 'robot_commands', false),
                  ];
                  final (name, code, active) = games[i];
                  return Card(
                    child: InkWell(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.games, size: 24),
                                const SizedBox(width: 8),
                                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                Chip(
                                  label: Text(active ? 'Active' : 'Inactive', style: TextStyle(
                                    fontSize: 11, color: active ? Colors.green : Colors.grey,
                                  )),
                                  backgroundColor: active ? Colors.green.shade50 : Colors.grey.shade100,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text('Code: $code', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            Text('Levels: ${[8, 12, 10, 0, 0, 0][i]}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
