import 'package:flutter/material.dart';

/// Status of a video in the workflow.
enum VideoStatus {
  newVideo,
  previouslyUsed,
  empty,
}

/// Indicator showing the status color and label for a video.
class TranscriptStatusIndicator extends StatelessWidget {
  const TranscriptStatusIndicator({
    super.key,
    required this.status,
    required this.label,
  });

  final VideoStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      VideoStatus.newVideo => Colors.green,
      VideoStatus.previouslyUsed => Colors.blue,
      VideoStatus.empty => Colors.grey,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}