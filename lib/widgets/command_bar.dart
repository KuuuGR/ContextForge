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
  });

  final List<Prompt> prompts;
  final String selectedPrompt;
  final ValueChanged<String> onSelectPrompt;
  final VoidCallback onPaste;
  final VoidCallback onGenerate;
  final VoidCallback onCopy;
  final bool canCopy;
  final bool canPaste;

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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Tooltip(
            message: 'Quick Workflow (coming soon)',
            child: IconButton(
              onPressed: null,
              icon: const Icon(Icons.bolt_outlined),
              iconSize: 20,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 4),
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
          const SizedBox(height: 8),
          Row(
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
          ),
        ],
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
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: !enabled
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