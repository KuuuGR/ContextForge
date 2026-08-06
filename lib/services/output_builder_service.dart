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
    // `videos` and `transcripts` are index-parallel (a successful video always
    // pairs with its cleaned transcript). When the video title was retrieved,
    // use it as the transcript block name; otherwise fall back to the
    // numbered naming.
    for (var i = 0; i < transcripts.length; i++) {
      final transcript = transcripts[i];
      final text = transcript.text.trim();
      if (text.isEmpty) continue;
      final video = i < videos.length ? videos[i] : null;
      final title = video?.title.trim() ?? '';
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

  /// Formats a [DateTime] as `YYYY-MM-DD`.
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}