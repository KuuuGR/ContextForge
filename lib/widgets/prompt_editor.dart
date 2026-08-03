import 'package:flutter/material.dart';

/// Prompt content display/editor.
///
/// - For saved prompts: read-only display of the selected prompt content.
/// - For "Custom Prompt": editable text field (not persisted in this phase).
class PromptEditor extends StatefulWidget {
  const PromptEditor({
    super.key,
    required this.content,
    required this.enabled,
    this.controller,
  });

  /// Content to display (the selected prompt's content).
  final String content;

  /// Whether editing is allowed (true only for "Custom Prompt").
  final bool enabled;

  /// Optional external controller. When provided, the widget does not manage
  /// its own controller and never overwrites its text on content changes —
  /// the owner is responsible for keeping it in sync.
  final TextEditingController? controller;

  @override
  State<PromptEditor> createState() => _PromptEditorState();
}

class _PromptEditorState extends State<PromptEditor> {
  late final TextEditingController _controller;
  late String _content;

  @override
  void initState() {
    super.initState();
    _content = widget.content;
    _controller = widget.controller ?? TextEditingController(text: _content);
  }

  @override
  void didUpdateWidget(PromptEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && widget.content != _content) {
      _content = widget.content;
      _controller.text = _content;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      readOnly: !widget.enabled,
      maxLines: 6,
      decoration: InputDecoration(
        labelText: 'Prompt content',
        hintText: widget.enabled
            ? 'Write your custom prompt here...'
            : 'Select a prompt or choose "Custom Prompt" to edit.',
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }
}