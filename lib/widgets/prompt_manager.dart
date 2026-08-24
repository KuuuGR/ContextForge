import 'package:flutter/material.dart';

import '../models/prompt.dart';
import '../models/prompt_quick_access.dart';
import 'prompt_selector.dart';

/// Full user-managed Prompt Library.
///
/// Provides:
/// - List of prompts via [PromptSelector].
/// - ➕ New Prompt button.
/// - Edit/Delete actions per prompt.
/// - Friendly empty state with "Create your first prompt".
class PromptManager extends StatelessWidget {
  const PromptManager({
    super.key,
    required this.prompts,
    required this.value,
    required this.onChanged,
    required this.onToggleFavorite,
    required this.onAssignQuickAccess,
    required this.onCreatePrompt,
    required this.onEditPrompt,
    required this.onDeletePrompt,
    this.editorController,
    this.editorEnabled = false,
    this.onExportPrompts,
    this.onImportPrompts,
  });

  final List<Prompt> prompts;
  final String value;
  final ValueChanged<String> onChanged;
  final ValueChanged<Prompt>? onToggleFavorite;
  final ValueChanged<(Prompt, PromptQuickAccess)>? onAssignQuickAccess;
  final VoidCallback onCreatePrompt;
  final ValueChanged<Prompt> onEditPrompt;
  final ValueChanged<Prompt> onDeletePrompt;
  final TextEditingController? editorController;
  final bool editorEnabled;

  /// Exports the user's saved prompts to a JSON file.
  final VoidCallback? onExportPrompts;

  /// Imports user prompts from a JSON file.
  final VoidCallback? onImportPrompts;

  @override
  Widget build(BuildContext context) {
    if (prompts.isEmpty) {
      return _EmptyState(onCreate: onCreatePrompt);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: PromptSelector(
                prompts: prompts,
                value: value,
                onChanged: onChanged,
                onToggleFavorite: onToggleFavorite,
                onAssignQuickAccess: onAssignQuickAccess,
                onEditPrompt: onEditPrompt,
                onDeletePrompt: onDeletePrompt,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'New Prompt',
              child: IconButton(
                onPressed: onCreatePrompt,
                icon: const Icon(Icons.add),
                tooltip: 'New Prompt',
                visualDensity: VisualDensity.compact,
              ),
            ),
            if (onImportPrompts != null) ...[
              Tooltip(
                message: 'Import Prompts',
                child: IconButton(
                  onPressed: onImportPrompts,
                  icon: const Icon(Icons.file_download_outlined),
                  tooltip: 'Import Prompts',
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
            if (onExportPrompts != null) ...[
              Tooltip(
                message: 'Export Prompts',
                child: IconButton(
                  onPressed: onExportPrompts,
                  icon: const Icon(Icons.file_upload_outlined),
                  tooltip: 'Export Prompts',
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: editorController,
          enabled: editorEnabled,
          readOnly: !editorEnabled,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: 'Prompt content',
            hintText: 'Select a prompt to view its content.',
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}

/// Friendly empty state when no prompts exist.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.description_outlined, size: 40, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'No saved prompts yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Create your first prompt to start building.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Create your first prompt'),
          ),
        ],
      ),
    );
  }
}