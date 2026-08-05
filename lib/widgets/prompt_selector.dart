import 'package:flutter/material.dart';

import '../models/prompt.dart';
import '../models/prompt_quick_access.dart';
import '../presentation/prompt_constants.dart';

/// Non-selectable value for the close row at the top of the dropdown menu.
const String _closeOption = '__prompt_selector_close__';

class PromptSelector extends StatefulWidget {
  const PromptSelector({
    super.key,
    required this.prompts,
    required this.value,
    required this.onChanged,
    this.onToggleFavorite,
    this.onAssignQuickAccess,
    this.onEditPrompt,
    this.onDeletePrompt,
  });

  final List<Prompt> prompts;
  final String value;
  final ValueChanged<String> onChanged;
  final ValueChanged<Prompt>? onToggleFavorite;
  final ValueChanged<(Prompt, PromptQuickAccess)>? onAssignQuickAccess;
  final ValueChanged<Prompt>? onEditPrompt;
  final ValueChanged<Prompt>? onDeletePrompt;

  @override
  State<PromptSelector> createState() => _PromptSelectorState();
}

class _PromptSelectorState extends State<PromptSelector> {
  /// Mirrors [PromptSelector.prompts] so an already-expanded dropdown menu
  /// can refresh live (Favorite / Default / Quick Access) without closing.
  late final ValueNotifier<List<Prompt>> _prompts;

  @override
  void initState() {
    super.initState();
    _prompts = ValueNotifier(widget.prompts);
  }

  @override
  void didUpdateWidget(PromptSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prompts != widget.prompts) {
      // Defer the notifier update until after the current frame so the
      // ValueListenableBuilders inside the open dropdown menu are not
      // triggered to rebuild during the build phase.
      final next = widget.prompts;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _prompts.value = next;
      });
    }
  }

  @override
  void dispose() {
    _prompts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: _closeOption,
        child: _CloseMenuItem(),
      ),
      for (final prompt in widget.prompts)
        DropdownMenuItem(
          value: prompt.title,
          child: ValueListenableBuilder<List<Prompt>>(
            valueListenable: _prompts,
            builder: (context, prompts, _) {
              // Use the live copy so an open menu updates immediately after
              // Favorite / Default / Quick Access changes.
              final live = _promptById(prompts, prompt.id) ?? prompt;
              return _PromptMenuItem(
                prompt: live,
                onToggleFavorite: widget.onToggleFavorite == null
                    ? null
                    : () => widget.onToggleFavorite!(live),
                onAssignQuickAccess: widget.onAssignQuickAccess == null
                    ? null
                    : (role) => widget.onAssignQuickAccess!((live, role)),
                onEditPrompt: widget.onEditPrompt == null
                    ? null
                    : () => widget.onEditPrompt!(live),
                onDeletePrompt: widget.onDeletePrompt == null
                    ? null
                    : () => widget.onDeletePrompt!(live),
              );
            },
          ),
        ),
      const DropdownMenuItem(
        value: customPromptOption, child: Text(customPromptOption)),
    ];

    if (widget.prompts.isEmpty) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Select a prompt',
          border: OutlineInputBorder(),
        ),
        child: Text('No saved prompts yet. Create one soon!'),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: items.any((i) => i.value == widget.value)
          ? widget.value
          : (widget.prompts.isNotEmpty
              ? widget.prompts.first.title
              : customPromptOption),
      decoration: const InputDecoration(
        labelText: 'Select a prompt',
        border: OutlineInputBorder(),
      ),
      items: items,
      onChanged: (selected) {
        if (selected != null && selected != _closeOption) {
          widget.onChanged(selected);
        }
      },
    );
  }

  Prompt? _promptById(List<Prompt> prompts, String id) {
    for (final p in prompts) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// Close control for the expanded prompt selector.
///
/// Tapping this row dismisses the dropdown menu without selecting a prompt,
/// leaving the current selection unchanged.
class _CloseMenuItem extends StatelessWidget {
  const _CloseMenuItem();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Icon(
          Icons.close,
          size: 14,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PromptMenuItem extends StatelessWidget {
  const _PromptMenuItem({
    required this.prompt,
    this.onToggleFavorite,
    this.onAssignQuickAccess,
    this.onEditPrompt,
    this.onDeletePrompt,
  });

  final Prompt prompt;
  final VoidCallback? onToggleFavorite;
  final ValueChanged<PromptQuickAccess>? onAssignQuickAccess;
  final VoidCallback? onEditPrompt;
  final VoidCallback? onDeletePrompt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onToggleFavorite,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              prompt.isFavorite ? Icons.star : Icons.star_border,
              size: 16,
              color: prompt.isFavorite
                  ? Colors.amber
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(prompt.title),
        if (prompt.isDefault) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Default',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
        if (onEditPrompt != null) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: onEditPrompt,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.edit_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        if (onDeletePrompt != null) ...[
          const SizedBox(width: 2),
          InkWell(
            onTap: onDeletePrompt,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.delete_outline,
                size: 16,
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
        if (onAssignQuickAccess != null) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _showQuickAccessMenu(context),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                _roleIcon(prompt.quickAccess),
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  IconData _roleIcon(PromptQuickAccess role) {
    switch (role) {
      case PromptQuickAccess.none:
        return Icons.bookmark_border;
      case PromptQuickAccess.quickWorkflow:
        return Icons.bolt_outlined;
      case PromptQuickAccess.slotOne:
        return Icons.looks_one_outlined;
      case PromptQuickAccess.slotTwo:
        return Icons.looks_two_outlined;
      case PromptQuickAccess.slotThree:
        return Icons.looks_3_outlined;
    }
  }

  void _showQuickAccessMenu(BuildContext context) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(200, 0, 0, 0),
      items: [
        PopupMenuItem(
          value: 'none',
          child: Text(prompt.quickAccess == PromptQuickAccess.none
              ? '✓ None'
              : 'None'),
        ),
        PopupMenuItem(
          value: 'quickWorkflow',
          child: Text(prompt.quickAccess == PromptQuickAccess.quickWorkflow
              ? '✓ ⚡ Quick Workflow'
              : '⚡ Quick Workflow'),
        ),
        PopupMenuItem(
          value: 'slotOne',
          child: Text(prompt.quickAccess == PromptQuickAccess.slotOne
              ? '✓ ① Slot One'
              : '① Slot One'),
        ),
        PopupMenuItem(
          value: 'slotTwo',
          child: Text(prompt.quickAccess == PromptQuickAccess.slotTwo
              ? '✓ ② Slot Two'
              : '② Slot Two'),
        ),
        PopupMenuItem(
          value: 'slotThree',
          child: Text(prompt.quickAccess == PromptQuickAccess.slotThree
              ? '✓ ③ Slot Three'
              : '③ Slot Three'),
        ),
      ],
    ).then((value) {
      if (value == null || onAssignQuickAccess == null) return;
      final role = switch (value) {
        'none' => PromptQuickAccess.none,
        'quickWorkflow' => PromptQuickAccess.quickWorkflow,
        'slotOne' => PromptQuickAccess.slotOne,
        'slotTwo' => PromptQuickAccess.slotTwo,
        'slotThree' => PromptQuickAccess.slotThree,
        _ => PromptQuickAccess.none,
      };
      onAssignQuickAccess!(role);
    });
  }
}