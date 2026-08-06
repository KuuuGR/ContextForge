import '../models/clean_transcript.dart';
import '../models/video.dart';

/// Builds the final output text block for copying into an external LLM.
///
/// Pure, deterministic string assembly:
/// - No AI processing.
/// - No randomness.
/// - No UI dependencies.
///
/// The UI must never assemble the final text itself — all business logic
/// for output formatting lives in this service.
class OutputBuilderService {
  const OutputBuilderService();

  /// Horizontal rule used to delimit the output block.
  static const String _separator = '--------------------------------------------------';

  /// Builds the final output text.
  ///
  /// [selectedPrompt] — the prompt template content.
  /// [videos] — processed videos; each contributes one Inspiration entry
  /// `YYYY-MM-DD -> URL` when it actually exists (non-empty URL).
  /// [transcripts] — cleaned transcripts; each contributes one numbered
  /// Transcript section when its text is non-empty.
  ///
  /// Transcript text is preserved exactly as received; only leading and
  /// trailing whitespace is trimmed.
  String build({
    required String selectedPrompt,
    required List<Video> videos,
    required List<CleanTranscript> transcripts,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(_separator);
    buffer.writeln();
    buffer.writeln(selectedPrompt.trim());
    buffer.writeln();
    buffer.writeln('(Inspiration');
    buffer.writeln();

    for (final video in videos) {
      final url = video.url.trim();
      if (url.isEmpty) continue;
      buffer.writeln('${_formatDate(video.publishedAt)} -> $url');
      buffer.writeln();
    }

    buffer.writeln(')');
    buffer.writeln();

    var index = 1;
    // Match each transcript to its video by ID so the correct retrieved
    // YouTube title is used as the block name even if the lists are not
    // positionally aligned. When no title is available, fall back to the
    // numbered naming.
    for (final transcript in transcripts) {
      final text = transcript.text.trim();
      if (text.isEmpty) continue;
      final title = _titleForVideo(transcript.videoId, videos);
      final blockName = title.isNotEmpty ? title : 'Transcript $index';
      buffer.writeln(blockName);
      buffer.writeln();
      buffer.writeln(text);
      buffer.writeln();
      index++;
    }

    buffer.write(_separator);

    return buffer.toString();
  }

  /// Returns the trimmed title of the video matching [videoId], or an empty
  /// string when no match exists (fallback to numbered naming).
  String _titleForVideo(String videoId, List<Video> videos) {
    for (final video in videos) {
      if (video.videoId == videoId) {
        final title = video.title.trim();
        if (title.isNotEmpty) return title;
      }
    }
    return '';
  }

  /// Formats a [DateTime] as `YYYY-MM-DD`.
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}