import 'package:flutter/material.dart';

import '../models/prompt.dart';
import '../presentation/prompt_constants.dart';

/// Dropdown for selecting a saved prompt template.
///
/// Loads real prompts from the service (never mock data). Includes a
/// "Custom Prompt" option at the end. Shows a friendly placeholder when
/// no prompts exist yet.
///
/// Each prompt option displays:
/// - A small star icon (filled for Favorites, outlined otherwise).
/// - The prompt title.
/// - A small "Default" badge on the Default Prompt.
/// - A subtle outline bookmark icon on non-default prompts to set them
///   as the Default.
class PromptSelector extends StatelessWidget {
  const PromptSelector({
    super.key,
    required this.prompts,
    required this.value,
    required this.onChanged,
    this.onToggleFavorite,
    this.onToggleDefault,
  });

  /// Saved prompt templates (already loaded by the parent from PromptService).
  final List<Prompt> prompts;

  /// Currently selected value (a prompt title or [customPromptOption]).
  final String value;

  final ValueChanged<String> onChanged;

  /// Called when the user taps the star icon next to a prompt.
  final ValueChanged<Prompt>? onToggleFavorite;

  /// Called when the user taps the Default badge / set-default control.
  final ValueChanged<Prompt>? onToggleDefault;

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<String>>[
      for (final prompt in prompts)
        DropdownMenuItem(
          value: prompt.title,
          child: _PromptMenuItem(
            prompt: prompt,
            onToggleFavorite: onToggleFavorite == null
                ? null
                : () => onToggleFavorite!(prompt),
            onToggleDefault: onToggleDefault == null
                ? null
                : () => onToggleDefault!(prompt),
          ),
        ),
      const DropdownMenuItem(
          value: customPromptOption, child: Text(customPromptOption)),
    ];

    if (prompts.isEmpty) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Select a prompt',
          border: OutlineInputBorder(),
        ),
        child: Text('No saved prompts yet. Create one soon!'),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: items.any((i) => i.value == value) ? value : items.first.value,
      decoration: const InputDecoration(
        labelText: 'Select a prompt',
        border: OutlineInputBorder(),
      ),
      items: items,
      onChanged: (selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }
}

/// A single row inside the prompt dropdown.
///
/// Shows a subtle star icon (filled = favorite, outlined = not), the title,
/// and either a "Default" badge (for the default prompt) or a set-default
/// outline bookmark icon (for other prompts).
class _PromptMenuItem extends StatelessWidget {
  const _PromptMenuItem({
    required this.prompt,
    this.onToggleFavorite,
    this.onToggleDefault,
  });

  final Prompt prompt;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onToggleDefault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Subtle star icon — filled for favorites, outlined otherwise.
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
          // Default badge — tappable to remove the Default designation.
          InkWell(
            onTap: onToggleDefault,
            borderRadius: BorderRadius.circular(4),
            child: Container(
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
          ),
        ] else if (onToggleDefault != null) ...[
          const SizedBox(width: 4),
          // Subtle set-default control for non-default prompts.
          InkWell(
            onTap: onToggleDefault,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.bookmark_border,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}