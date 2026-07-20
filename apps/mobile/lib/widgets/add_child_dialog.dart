import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:localization/localization.dart';

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
      title: const Text(MiMobileStrings.m239),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nicknameController,
            decoration: const InputDecoration(labelText: MiMobileStrings.m240),
            autofocus: true,
          ),
          const SizedBox(height: MiTokens.space3),
          DropdownButtonFormField<String>(
            initialValue: _ageGroup,
            decoration: const InputDecoration(labelText: MiMobileStrings.m241),
            items: const [
              DropdownMenuItem(
                  value: 'junior', child: Text(MiMobileStrings.m064)),
              DropdownMenuItem(
                  value: 'explorer', child: Text(MiMobileStrings.m065)),
              DropdownMenuItem(
                  value: 'master', child: Text(MiMobileStrings.m066)),
            ],
            onChanged: (value) =>
                setState(() => _ageGroup = value ?? _ageGroup),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(MiMobileStrings.m119),
        ),
        FilledButton(
          onPressed: _nicknameController.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop((
                    nickname: _nicknameController.text.trim(),
                    ageGroup: _ageGroup,
                  )),
          child: const Text(MiMobileStrings.m094),
        ),
      ],
    );
  }
}
