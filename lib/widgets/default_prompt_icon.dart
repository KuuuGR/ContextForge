import 'package:flutter/material.dart';

/// The single, reusable Default Prompt icon.
///
/// Rendered as a Material icon (`Icons.auto_awesome`) rather than a Unicode
/// emoji character. The bundled `MaterialIcons` font is available on every
/// platform, whereas emoji glyphs (e.g. 🌟) are missing from the iOS system
/// font fallback and showed up as empty "tofu" squares.
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
    return Icon(
      Icons.auto_awesome,
      size: size,
      color: color ?? Colors.amber,
    );
  }
}