import 'package:flutter/material.dart';

import '../models/video_status.dart';
import '../presentation/responsive.dart';

/// Indicator showing the status color and label for a video card.
///
/// On compact (phone) widths the text label is hidden so the URL field keeps
/// as much width as possible; the colored dot remains as the status marker.
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

    final dot = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    if (isCompact(context)) {
      return Tooltip(
        message: label,
        child: dot,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
