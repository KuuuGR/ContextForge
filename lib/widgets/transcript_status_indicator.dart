import 'package:flutter/material.dart';

import '../models/video_status.dart';

/// Indicator showing the status color and label for a video card.
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
      VideoStatus.noUrl => Colors.grey,
      VideoStatus.loaded => Colors.green,
      VideoStatus.error => Colors.red,
      VideoStatus.previouslyUsed => Colors.green,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}