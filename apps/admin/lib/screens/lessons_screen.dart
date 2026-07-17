import 'package:flutter/material.dart';

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons'),
        actions: [
          IconButton(icon: const Icon(Icons.add), tooltip: 'New Lesson', onPressed: () => _showLessonDialog(context)),
        ],
      ),
      body: _LessonTable(),
    );
  }

  void _showLessonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Lesson'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Title')),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Subject ID')),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Age Group'), controller: TextEditingController(text: 'explorer')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Create')),
        ],
      ),
    );
  }
}

class _LessonTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Filter bar
          Row(
            children: [
              Expanded(child: TextField(decoration: InputDecoration(hintText: 'Search lessons...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
              const SizedBox(width: 12),
              DropdownMenu<String>(label: const Text('Age Group'), dropdownMenuEntries: const [
                DropdownMenuEntry(value: 'all', label: 'All'),
                DropdownMenuEntry(value: 'junior', label: 'Junior (5-7)'),
                DropdownMenuEntry(value: 'explorer', label: 'Explorer (8-10)'),
                DropdownMenuEntry(value: 'master', label: 'Master (11-12)'),
              ]),
              const SizedBox(width: 12),
              DropdownMenu<String>(label: const Text('Status'), dropdownMenuEntries: const [
                DropdownMenuEntry(value: 'all', label: 'All'),
                DropdownMenuEntry(value: 'draft', label: 'Draft'),
                DropdownMenuEntry(value: 'published', label: 'Published'),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          // Table
          Card(
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Title')),
                  DataColumn(label: Text('Age Group')),
                  DataColumn(label: Text('Difficulty')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: const [
                  DataRow(cells: [
                    DataCell(Text('Phép cộng cơ bản')),
                    DataCell(Text('Explorer')),
                    DataCell(Text('2')),
                    DataCell(Text('Published', style: TextStyle(color: Colors.green))),
                    DataCell(Row(children: [Icon(Icons.edit, size: 18), SizedBox(width:8), Icon(Icons.delete, size: 18)])),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Letter Recognition A-Z')),
                    DataCell(Text('Junior')),
                    DataCell(Text('1')),
                    DataCell(Text('Published', style: TextStyle(color: Colors.green))),
                    DataCell(Row(children: [Icon(Icons.edit, size: 18), SizedBox(width:8), Icon(Icons.delete, size: 18)])),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Basic Subtraction')),
                    DataCell(Text('Explorer')),
                    DataCell(Text('3')),
                    DataCell(Text('Draft', style: TextStyle(color: Colors.orange))),
                    DataCell(Row(children: [Icon(Icons.edit, size: 18), SizedBox(width:8), Icon(Icons.delete, size: 18)])),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
