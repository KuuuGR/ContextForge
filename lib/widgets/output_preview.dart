import 'package:flutter/material.dart';

/// Large read-only text area showing the generated output.
class OutputPreview extends StatelessWidget {
  const OutputPreview({super.key, this.controller});

  /// Controller used to display the generated output text.
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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