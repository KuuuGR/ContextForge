import 'package:flutter/material.dart';

import '../models/video.dart';
import '../models/video_status.dart';
import '../services/runtime_trace.dart';
import '../viewmodels/video_card_controller.dart';
import 'transcript_status_indicator.dart';

/// Card showing a video URL input and its metadata state.
///
/// Pure presentation: owns local text entry state and reads [controller]
/// state; calls `loadMetadata` on submit. No business logic here.
class VideoInputCard extends StatefulWidget {
  const VideoInputCard({
    super.key,
    required this.controller,
    this.textController,
  });

  final VideoCardController controller;

  /// Optional external text controller. When provided, the widget does not
  /// create its own — the owner is responsible for keeping it in sync.
  final TextEditingController? textController;

  @override
  State<VideoInputCard> createState() => _VideoInputCardState();
}

class _VideoInputCardState extends State<VideoInputCard> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = widget.textController ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.textController == null) {
      _textController.dispose();
    }
    super.dispose();
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        onSubmitted: (value) {
                          RuntimeTrace.step(
                              'VideoInputCard.onSubmitted ("$value")');
                          widget.controller.loadMetadata(value);
                        },
                        decoration: const InputDecoration(
                          labelText: 'YouTube URL',
                          hintText: 'https://www.youtube.com/watch?v=...',
                          border: OutlineInputBorder(),
                          isDense: true,
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