import 'package:flutter/material.dart';

/// Button that will trigger the generate workflow in future phases.
///
/// Disabled in Phase 002 — no business logic wired yet.
class GenerateButton extends StatelessWidget {
  const GenerateButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: null,
      icon: const Icon(Icons.play_arrow),
      label: const Text('Generate'),
    );
  }
}