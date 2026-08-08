import 'package:flutter/material.dart';

/// The single, reusable Default Prompt icon.
///
/// The official Default Prompt icon is the Unicode character 🌟. Rendering it
/// as text (rather than a Material icon) guarantees the exact same glyph in
/// every view — collapsed selector, expanded selector, Prompt Manager, Help,
/// legends, and tooltips.
///
/// To change the Default Prompt icon in the future, modify only this widget.
class DefaultPromptIcon extends StatelessWidget {
  const DefaultPromptIcon({super.key, this.size = 16, this.color});

  /// Icon size in logical pixels.
  final double size;

  /// Optional color override; defaults to amber.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '🌟',
      style: TextStyle(
        fontSize: size,
        color: color ?? Colors.amber,
        height: 1,
      ),
    );
  }
}