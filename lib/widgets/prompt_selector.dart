import 'package:flutter/material.dart';

/// Temporary mock prompt options for Phase 002.
const List<String> mockPromptOptions = [
  'SEO Article',
  'Newsletter',
  'LinkedIn',
  'Facebook',
  'Custom Prompt',
];

/// Dropdown for selecting a saved prompt template.
class PromptSelector extends StatelessWidget {
  const PromptSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Select a prompt',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final option in mockPromptOptions)
          DropdownMenuItem(value: option, child: Text(option)),
      ],
      onChanged: (selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }
}