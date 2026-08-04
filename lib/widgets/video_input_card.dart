import 'package:flutter/material.dart';

import '../models/video.dart';
import '../models/video_history_entry.dart';
import '../models/video_status.dart';
import '../services/runtime_trace.dart';
import '../services/youtube_url_parser.dart';
import '../viewmodels/video_card_controller.dart';
import 'transcript_status_indicator.dart';

/// Card showing a video URL input and its metadata state.
///
/// Pure presentation: owns local text entry state and reads [controller]
/// state; calls `loadMetadata` on submit (unless an external [onSubmitted]
/// handler is provided). No business logic here.
class VideoInputCard extends StatefulWidget {
  const VideoInputCard({
    super.key,
    required this.controller,
    this.textController,
    this.focusNode,
    this.onSubmitted,
    this.textInputAction,
    this.onClipboardPressed,
    this.clipboardEnabled = false,
  });

  final VideoCardController controller;

  /// Optional external text controller. When provided, the widget does not
  /// create its own — the owner is responsible for keeping it in sync.
  final TextEditingController? textController;

  /// Optional external focus node for focus navigation.
  final FocusNode? focusNode;

  /// Optional external submit handler for keyboard workflows.
  /// When null, the widget calls `controller.loadMetadata(value)`.
  final ValueChanged<String>? onSubmitted;

  /// Keyboard enter action for the URL field.
  final TextInputAction? textInputAction;

  /// Optional callback for the clipboard Smart Paste button.
  final VoidCallback? onClipboardPressed;

  /// Whether the clipboard currently contains a valid YouTube URL.
  final bool clipboardEnabled;

  @override
  State<VideoInputCard> createState() => _VideoInputCardState();
}

class _VideoInputCardState extends State<VideoInputCard> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = widget.textController ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    if (widget.textController == null) {
      _textController.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  /// Updates the history indicator while the user types.
  ///
  /// The lookup is a synchronous in-memory operation, so there is no
  /// perceptible UI delay.
  void _onTextChanged() {
    widget.controller.refreshHistoryStatus(_textController.text);
  }

  void _handleSubmitted(String value) {
    RuntimeTrace.step('VideoInputCard.onSubmitted ("$value")');
    final handler = widget.onSubmitted;
    if (handler != null) {
      handler(value);
    } else {
      widget.controller.loadMetadata(value);
    }
  }

  String? get _displayText {
    final fullUrl = widget.controller.fullUrl;
    if (fullUrl == null) return null;
    try {
      final videoId = const YouTubeUrlParser().extractVideoId(fullUrl);
      return '▶ $videoId';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final displayText = _displayText;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Tooltip(
                        message: widget.controller.fullUrl ?? '',
                        waitDuration: const Duration(milliseconds: 300),
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          onSubmitted: _handleSubmitted,
                          textInputAction: widget.textInputAction ??
                              TextInputAction.done,
                          style: displayText != null
                              ? const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                )
                              : null,
                          decoration: InputDecoration(
                            labelText: 'YouTube URL',
                            hintText: 'https://www.youtube.com/watch?v=...',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _HistoryStatusDot(
                                  entry: widget.controller.historyEntry,
                                ),
                                if (widget.onClipboardPressed != null) ...[
                                  const SizedBox(width: 4),
                                  _ClipboardButton(
                                    enabled: widget.clipboardEnabled,
                                    onPressed:
                                        widget.onClipboardPressed!,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TranscriptStatusIndicator(
                      status: widget.controller.status,
                      label: _statusLabel(widget.controller.status),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.controller.isLoading)
                  const LinearProgressIndicator()
                else if (widget.controller.errorMessage != null)
                  _ErrorBanner(message: widget.controller.errorMessage!)
                else if (widget.controller.hasMetadata)
                  _MetadataView(video: widget.controller.video!),
              ],
            );
          },
        ),
      ),
    );
  }

  String _statusLabel(VideoStatus status) {
    return switch (status) {
      VideoStatus.noUrl => 'Empty',
      VideoStatus.loaded => 'Loaded',
      VideoStatus.error => 'Error',
      VideoStatus.previouslyUsed => 'Previously Used',
    };
  }
}

/// Small clipboard button for the Smart Paste action.
class _ClipboardButton extends StatelessWidget {
  const _ClipboardButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.content_paste, size: 18),
      onPressed: enabled ? onPressed : null,
      tooltip: 'Paste from clipboard',
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      iconSize: 18,
    );
  }
}

/// Small subtle dot inside the URL field showing processing history.
///
/// Green when the video was processed before; neutral/grey otherwise.
/// The green dot carries a tooltip with the last processed date.
class _HistoryStatusDot extends StatelessWidget {
  const _HistoryStatusDot({required this.entry});

  final VideoHistoryEntry? entry;

  @override
  Widget build(BuildContext context) {
    final processed = entry != null;
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: processed ? Colors.green : Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
    );

    if (!processed) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: dot,
      );
    }

    return Tooltip(
      message: 'Previously processed\n${_formatDate(entry!.processedAt)}',
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: dot,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final mo = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$mi';
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: colorScheme.onErrorContainer),
      ),
    );
  }
}

class _MetadataView extends StatelessWidget {
  const _MetadataView({required this.video});

  final Video video;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(video.title, style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Text('Channel: ${video.channelName}', style: textTheme.bodySmall),
          Text('Published: ${_formatDate(video.publishedAt)}',
              style: textTheme.bodySmall),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${_two(local.month)}-${_two(local.day)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');
}