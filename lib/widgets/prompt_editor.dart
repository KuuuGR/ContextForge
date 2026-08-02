import 'package:flutter/material.dart';

/// Large multiline text area for prompt content.
///
/// Editing is only enabled when the "Custom Prompt" option is selected.
class PromptEditor extends StatelessWidget {
  const PromptEditor({super.key, required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: enabled,
      maxLines: 6,
      decoration: InputDecoration(
        labelText: 'Prompt content',
        hintText: enabled ? 'Write your custom prompt here...' : 'Select "Custom Prompt" to edit.',
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }
}