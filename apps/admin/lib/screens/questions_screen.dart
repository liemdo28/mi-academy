import 'package:flutter/material.dart';

class QuestionsScreen extends StatelessWidget {
  const QuestionsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questions'),
        actions: [
          IconButton(icon: const Icon(Icons.add), tooltip: 'New Question', onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: TextField(decoration: InputDecoration(hintText: 'Search questions...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))))),
                const SizedBox(width: 12),
                DropdownMenu<String>(label: const Text('Difficulty'), dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'all', label: 'All'),
                  DropdownMenuEntry(value: '1', label: 'Easy'),
                  DropdownMenuEntry(value: '2', label: 'Medium'),
                  DropdownMenuEntry(value: '3', label: 'Hard'),
                ]),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (ctx, i) => Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text('Sample question ${i + 1}', maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('Lesson: Lesson ${i + 1} | Difficulty: ${(i % 3) + 1}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.delete, size: 18), onPressed: () {}),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
