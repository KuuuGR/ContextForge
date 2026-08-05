import 'package:flutter/material.dart';

import '../models/prompt.dart';
import '../models/prompt_quick_access.dart';

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
    this.canGenerate = true,
    this.onQuickWorkflow,
    this.canQuickWorkflow = false,
  });

  final List<Prompt> prompts;
  final String selectedPrompt;
  final ValueChanged<String> onSelectPrompt;
  final VoidCallback onPaste;
  final VoidCallback? onGenerate;
  final VoidCallback onCopy;
  final bool canCopy;
  final bool canPaste;
  final bool canGenerate;

  /// Called when the user taps ⚡ Quick Workflow.
  final VoidCallback? onQuickWorkflow;

  /// Whether a Quick Workflow prompt is assigned.
  final bool canQuickWorkflow;

  List<Prompt?> get _slotPrompts {
    final result = <Prompt?>[null, null, null];
    for (final p in prompts) {
      switch (p.quickAccess) {
        case PromptQuickAccess.slotOne:
          result[0] = p;
        case PromptQuickAccess.slotTwo:
          result[1] = p;
        case PromptQuickAccess.slotThree:
          result[2] = p;
        case PromptQuickAccess.none:
        case PromptQuickAccess.quickWorkflow:
          break;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final slots = _slotPrompts;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Tooltip(
              message: 'Quick Workflow (coming soon)',
              child: IconButton(
                onPressed: null,
                icon: const Icon(Icons.bolt_outlined, size: 20),
                iconSize: 20,
                color: scheme.onSurfaceVariant,
                tooltip: 'Quick Workflow (coming soon)',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                _SlotButton(
                  label: i == 0 ? '1' : i == 1 ? '2' : '3',
                  prompt: slots[i],
                  isSelected: slots[i] != null &&
                      slots[i]!.title == selectedPrompt,
                  onTap: slots[i] == null
                      ? null
                      : () => onSelectPrompt(slots[i]!.title),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                icon: Icons.content_paste,
                tooltip: 'Paste from clipboard',
                onPressed: canPaste ? onPaste : null,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.play_arrow,
                tooltip: 'Generate',
                onPressed: canGenerate ? onGenerate : null,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.copy,
                tooltip: 'Copy output',
                onPressed: canCopy ? onCopy : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final color = enabled ? scheme.onSurfaceVariant : scheme.outlineVariant;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 32,
          decoration: BoxDecoration(
            color: enabled ? scheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? scheme.outlineVariant : Colors.transparent,
            ),
          ),
          child: Center(
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

class _SlotButton extends StatelessWidget {
  const _SlotButton({
    required this.label,
    required this.prompt,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Prompt? prompt;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = prompt != null;
    return Tooltip(
      message: prompt?.title ?? 'No prompt assigned',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primaryContainer
                : enabled
                    ? scheme.surface
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled
                  ? isSelected
                      ? scheme.primary
                      : scheme.outlineVariant
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: !enabled
                      ? scheme.onSurface.withValues(alpha: 0.25)
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