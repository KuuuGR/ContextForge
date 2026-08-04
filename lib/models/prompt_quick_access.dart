/// Quick Access role assignment for a prompt.
enum PromptQuickAccess {
  none,
  quickWorkflow,
  slotOne,
  slotTwo,
  slotThree;

  /// Parses a [PromptQuickAccess] from its string name.
  static PromptQuickAccess fromName(String? name) {
    for (final value in PromptQuickAccess.values) {
      if (value.name == name) return value;
    }
    return PromptQuickAccess.none;
  }
}