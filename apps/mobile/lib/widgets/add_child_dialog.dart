import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

/// Shared "create child" dialog used by both the child selector and the
/// parent dashboard's empty-state CTA.
class AddChildDialog extends StatefulWidget {
  const AddChildDialog({super.key});

  @override
  State<AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<AddChildDialog> {
  final _nicknameController = TextEditingController();
  String _ageGroup = 'junior';

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm hồ sơ mới'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nicknameController,
            decoration: const InputDecoration(labelText: 'Tên của bé'),
            autofocus: true,
          ),
          const SizedBox(height: MiTokens.space3),
          DropdownButtonFormField<String>(
            initialValue: _ageGroup,
            decoration: const InputDecoration(labelText: 'Độ tuổi'),
            items: const [
              DropdownMenuItem(value: 'junior', child: Text('5-7 tuổi')),
              DropdownMenuItem(value: 'explorer', child: Text('8-10 tuổi')),
              DropdownMenuItem(value: 'master', child: Text('11-12 tuổi')),
            ],
            onChanged: (value) =>
                setState(() => _ageGroup = value ?? _ageGroup),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _nicknameController.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop((
                    nickname: _nicknameController.text.trim(),
                    ageGroup: _ageGroup,
                  )),
          child: const Text('Tạo hồ sơ'),
        ),
      ],
    );
  }
}
