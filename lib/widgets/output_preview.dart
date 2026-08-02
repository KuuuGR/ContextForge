import 'package:flutter/material.dart';

/// Large read-only text area showing the generated output.
class OutputPreview extends StatelessWidget {
  const OutputPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      maxLines: 12,
      decoration: const InputDecoration(
        labelText: 'Output',
        hintText: 'Generated output will appear here.',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }
}