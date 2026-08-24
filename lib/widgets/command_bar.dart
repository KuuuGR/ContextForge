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
    this.onClear,
    this.canClear = false,
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

  /// Invokes the same Clear logic as the bottom-of-page Clear button.
  final VoidCallback? onClear;

  /// Whether there is anything to clear.
  final bool canClear;

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

  // Grid geometry (3 columns × 3 rows).
  //
  // Column 1 is sized for the ⚡ IconButton (48px), columns 2–3 for the slot /
  // action buttons (~36px). All three rows share the same column widths so the
  // cells line up. In the top row the ⚡ and ✕ sit in columns 2–3 (immediately
  // adjacent), so ✕ lands directly above "3"; column 1's top cell is empty.
  static const int _col1Flex = 48;
  static const int _col2Flex = 36;
  static const int _col3Flex = 36;
  static const double _gridGap = 6;
  static const double _gridWidth =
      _col1Flex + _col2Flex + _col3Flex + _gridGap * 2;

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
          _gridRow(
            cell1: const SizedBox.shrink(),
            cell2: Tooltip(
              message: canQuickWorkflow
                  ? 'Quick Workflow'
                  : 'Quick Workflow (no prompt assigned)',
              child: IconButton(
                onPressed: canQuickWorkflow ? onQuickWorkflow : null,
                icon: const Icon(Icons.bolt_outlined, size: 20),
                iconSize: 20,
                color: canQuickWorkflow
                    ? scheme.primary
                    : scheme.onSurfaceVariant,
                tooltip: canQuickWorkflow
                    ? 'Quick Workflow'
                    : 'Quick Workflow (no prompt assigned)',
              ),
            ),
            cell3: _ActionButton(
              icon: Icons.clear,
              tooltip: 'Clear',
              onPressed: canClear ? onClear : null,
            ),
          ),
          const SizedBox(height: 10),
          _gridRow(
            cell1: _SlotButton(
              label: '1',
              prompt: slots[0],
              isSelected: slots[0] != null && slots[0]!.title == selectedPrompt,
              onTap: slots[0] == null
                  ? null
                  : () => onSelectPrompt(slots[0]!.title),
            ),
            cell2: _SlotButton(
              label: '2',
              prompt: slots[1],
              isSelected: slots[1] != null && slots[1]!.title == selectedPrompt,
              onTap: slots[1] == null
                  ? null
                  : () => onSelectPrompt(slots[1]!.title),
            ),
            cell3: _SlotButton(
              label: '3',
              prompt: slots[2],
              isSelected: slots[2] != null && slots[2]!.title == selectedPrompt,
              onTap: slots[2] == null
                  ? null
                  : () => onSelectPrompt(slots[2]!.title),
            ),
          ),
          const SizedBox(height: 10),
          _gridRow(
            cell1: _ActionButton(
              icon: Icons.content_paste,
              tooltip: 'Paste from clipboard',
              onPressed: canPaste ? onPaste : null,
            ),
            cell2: _ActionButton(
              icon: Icons.play_arrow,
              tooltip: 'Generate',
              onPressed: canGenerate ? onGenerate : null,
            ),
            cell3: _ActionButton(
              icon: Icons.copy,
              tooltip: 'Copy output',
              onPressed: canCopy ? onCopy : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Lays out three cells as a single grid row with shared column widths.
  ///
  /// Every row uses the same [Expanded] flex factors and gap, so cells line up
  /// vertically across rows. Each cell is given a positive, bounded size so
  /// there is never a zero-size render box in the hit-test path.
  Widget _gridRow({
    required Widget cell1,
    required Widget cell2,
    required Widget cell3,
  }) {
    return SizedBox(
      width: _gridWidth,
      child: Row(
        children: [
          Expanded(flex: _col1Flex, child: Center(child: cell1)),
          const SizedBox(width: _gridGap),
          Expanded(flex: _col2Flex, child: Center(child: cell2)),
          const SizedBox(width: _gridGap),
          Expanded(flex: _col3Flex, child: Center(child: cell3)),
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