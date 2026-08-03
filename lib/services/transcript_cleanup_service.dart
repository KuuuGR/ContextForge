import '../models/clean_transcript.dart';
import '../models/transcript_download.dart';

/// Pure transcript cleanup service.
///
/// Responsibility: transform a downloaded [TranscriptDownload] into clean
/// AI-ready text. Deterministic, no networking, no AI processing.
class TranscriptCleanupService {
  const TranscriptCleanupService();

  CleanTranscript clean(TranscriptDownload download) {
    final text = _cleanText(download.text);
    return CleanTranscript(
      videoId: download.videoId,
      track: download.track,
      text: text,
      original: download,
    );
  }

  String _cleanText(String raw) {
    var lines = raw.split('\n');
    lines = [
      for (final line in lines)
        if (!_isTimestampLine(line) && line.trim().isNotEmpty) line,
    ];
    final cleanedLines = [
      for (final line in lines) _normalizeWhitespace(line),
    ];
    final joined = cleanedLines.join('\n');
    final collapsed = joined.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return collapsed.trim();
  }

  bool _isTimestampLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return true;
    final timestampOnly = RegExp(
      r'^\[?\d{1,2}:\d{2}(?::\d{2})?(?:\.\d+)?\]?'
      r'(?:\s*(?:->|—|-)?\s*'
      r'\[?\d{1,2}:\d{2}(?::\d{2})?(?:\.\d+)?\]?)?$',
    );
    return timestampOnly.hasMatch(trimmed);
  }

  String _normalizeWhitespace(String line) {
    return line.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
  }
}
