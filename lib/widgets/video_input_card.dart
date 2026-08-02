import 'package:flutter/material.dart';

import 'transcript_status_indicator.dart';

/// Card for a single video input with URL field, status indicator,
/// and placeholder area for metadata.
class VideoInputCard extends StatelessWidget {
  const VideoInputCard({
    super.key,
    required this.status,
    required this.statusLabel,
  });

  final VideoStatus status;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
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
                  status: status,
                  label: statusLabel,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Metadata will appear here',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}