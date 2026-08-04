import 'dart:math';

/// Editorial Context Reflections shown in the First Launch Intro.
///
/// Each reflection expresses the philosophy of ContextForge.
/// Stored as reusable resources, prepared for future localization.
class ContextReflections {
  const ContextReflections._();

  static const List<String> reflections = [
    'Great prompts begin with great context.',
    'AI is only as good as the context you provide.',
    'Context is remembered. Prompts are forgotten.',
    'Every great answer starts before the first prompt.',
    "Don't ask AI for magic. Give it context.",
  ];

  /// Returns a single reflection chosen randomly.
  static String random() {
    final random = Random();
    return reflections[random.nextInt(reflections.length)];
  }
}