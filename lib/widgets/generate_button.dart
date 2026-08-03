import 'package:flutter/material.dart';

/// Button that triggers the generate workflow.
///
/// Enabled once the wiring phase connects it to the output pipeline.
class GenerateButton extends StatelessWidget {
  const GenerateButton({super.key, this.onPressed, this.isLoading = false});

  /// Callback invoked when the user presses Generate.
  final VoidCallback? onPressed;

  /// Whether a generation run is currently in progress.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.play_arrow),
      label: const Text('Generate'),
    );
  }
}