import 'package:flutter/material.dart';

import '../models/prompt.dart';
import '../presentation/prompt_constants.dart';

/// Dropdown for selecting a saved prompt template.
///
/// Loads real prompts from the service (never mock data). Includes a
/// "Custom Prompt" option at the end. Shows a friendly placeholder when
/// no prompts exist yet.
class PromptSelector extends StatelessWidget {
  const PromptSelector({
    super.key,
    required this.prompts,
    required this.value,
    required this.onChanged,
  });

  /// Saved prompt templates (already loaded by the parent from PromptService).
  final List<Prompt> prompts;

  /// Currently selected value (a prompt title or [customPromptOption]).
  final String value;

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<String>>[
      for (final prompt in prompts)
        DropdownMenuItem(value: prompt.title, child: Text(prompt.title)),
      const DropdownMenuItem(value: customPromptOption, child: Text(customPromptOption)),
    ];

    if (prompts.isEmpty) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Select a prompt',
          border: OutlineInputBorder(),
        ),
        child: Text('No saved prompts yet. Create one soon!'),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: items.any((i) => i.value == value) ? value : items.first.value,
      decoration: const InputDecoration(
        labelText: 'Select a prompt',
        border: OutlineInputBorder(),
      ),
      items: items,
      onChanged: (selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }
}