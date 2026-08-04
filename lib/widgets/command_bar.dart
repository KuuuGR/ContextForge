import 'package:flutter/material.dart';

import '../models/prompt.dart';

/// Compact three-row command bar for power users.
///
/// Rows:
/// 1. ⚡ Quick Workflow (reserved, disabled this phase)
/// 2. ① ② ③ Quick Prompt Selection (segmented control)
/// 3. 📋 Paste, 🔄 Generate, 📄 Copy
///
/// Designed to fit into the empty space on the right side of the header.
class CommandBar extends StatelessWidget {
  const CommandBar({
    super.key,
    required this.prompts,
    required this.selectedPrompt,
    required this.onSelectPrompt,
    required this.onPaste,
    required this.onGenerate,
    required this.onCopy,
    required this.canCopy,
    required this.canPaste,
  });

  /// Saved prompts used to populate quick slots ① ② ③.
  final List<Prompt> prompts;

  /// Currently selected prompt title.
  final String selectedPrompt;

  /// Called when the user selects a quick prompt slot.
  final ValueChanged<String> onSelectPrompt;

  /// Called when the user taps Paste (Smart Paste).
  final VoidCallback onPaste;

  /// Called when the user taps Generate.
  final VoidCallback onGenerate;

  /// Called when the user taps Copy.
  final VoidCallback onCopy;

  /// Whether Copy is available (output is non-empty).
  final bool canCopy;

  /// Whether Paste is available (clipboard contains a valid YouTube URL).
  final bool canPaste;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Row1QuickWorkflow(),
          const SizedBox(height: 8),
          _Row2PromptSlots(
            prompts: prompts,
            selectedPrompt: selectedPrompt,
            onSelectPrompt: onSelectPrompt,
          ),
          const SizedBox(height: 8),
          _Row3Actions(
            onPaste: onPaste,
            canPaste: canPaste,
            onGenerate: onGenerate,
            onCopy: onCopy,
            canCopy: canCopy,
          ),
        ],
      ),
    );
  }
}

/// Row 1 — Quick Workflow (⚡). Reserved for future automation.
class _Row1QuickWorkflow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Quick Workflow (coming soon)',
      child: IconButton(
        onPressed: null, // Disabled by design this phase.
        icon: const Icon(Icons.bolt_outlined),
        iconSize: 20,
        tooltip: 'Quick Workflow (coming soon)',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Row 2 — Quick Prompt Selection (① ② ③) as a segmented control.
class _Row2PromptSlots extends StatelessWidget {
  const _Row2PromptSlots({
    required this.prompts,
    required this.selectedPrompt,
    required this.onSelectPrompt,
  });

  final List<Prompt> prompts;
  final String selectedPrompt;
  final ValueChanged<String> onSelectPrompt;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PromptSlotButton(
          label: '①',
          prompt: prompts.isNotEmpty ? prompts[0] : null,
          isSelected: prompts.isNotEmpty && prompts[0].title == selectedPrompt,
          onSelectPrompt: onSelectPrompt,
        ),
        const SizedBox(width: 4),
        _PromptSlotButton(
          label: '②',
          prompt: prompts.length > 1 ? prompts[1] : null,
          isSelected: prompts.length > 1 && prompts[1].title == selectedPrompt,
          onSelectPrompt: onSelectPrompt,
        ),
        const SizedBox(width: 4),
        _PromptSlotButton(
          label: '③',
          prompt: prompts.length > 2 ? prompts[2] : null,
          isSelected: prompts.length > 2 && prompts[2].title == selectedPrompt,
          onSelectPrompt: onSelectPrompt,
        ),
      ],
    );
  }
}

/// A single ①/②/③ quick-selection button.
class _PromptSlotButton extends StatelessWidget {
  const _PromptSlotButton({
    required this.label,
    required this.prompt,
    required this.isSelected,
    required this.onSelectPrompt,
  });

  final String label;
  final Prompt? prompt;
  final bool isSelected;
  final ValueChanged<String> onSelectPrompt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: prompt?.title ?? 'No prompt assigned',
      child: InkWell(
        onTap: prompt == null ? null : () => onSelectPrompt(prompt!.title),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? scheme.primary
                  : scheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: prompt == null
                      ? scheme.onSurface.withValues(alpha: 0.3)
                      : isSelected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                ),
          ),
        ),
      ),
    );
  }
}

/// Row 3 — Action buttons (📋 Paste, 🔄 Generate, 📄 Copy).
class _Row3Actions extends StatelessWidget {
  const _Row3Actions({
    required this.onPaste,
    required this.canPaste,
    required this.onGenerate,
    required this.onCopy,
    required this.canCopy,
  });

  final VoidCallback onPaste;
  final bool canPaste;
  final VoidCallback onGenerate;
  final VoidCallback onCopy;
  final bool canCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Paste from clipboard',
          child: IconButton(
            onPressed: canPaste ? onPaste : null,
            icon: const Icon(Icons.content_paste, size: 18),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Generate',
          child: IconButton(
            onPressed: onGenerate,
            icon: const Icon(Icons.play_arrow, size: 18),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Copy output',
          child: IconButton(
            onPressed: canCopy ? onCopy : null,
            icon: const Icon(Icons.copy, size: 18),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}