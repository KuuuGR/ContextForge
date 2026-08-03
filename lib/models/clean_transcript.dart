import 'transcript_download.dart';
import 'transcript_track.dart';

/// Result of transcript cleanup.
///
/// Contains the clean AI-ready text together with the original
/// [TranscriptDownload] preserved for future debugging.
class CleanTranscript {
  const CleanTranscript({
    required this.videoId,
    required this.track,
    required this.text,
    required this.original,
  });

  /// Canonical YouTube video identifier.
  final String videoId;

  /// Selected transcript track used for the download.
  final TranscriptTrack track;

  /// Clean transcript text: no timestamps, no empty lines, normalized
  /// whitespace, paragraph breaks preserved when possible.
  final String text;

  /// Original downloaded transcript preserved for debugging.
  final TranscriptDownload original;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CleanTranscript &&
        other.videoId == videoId &&
        other.track == track &&
        other.text == text &&
        other.original == original;
  }

  @override
  int get hashCode => Object.hash(videoId, track, text, original);

  @override
  String toString() =>
      'CleanTranscript(videoId: $videoId, track: $track, '
      'text: "${text.length} chars")';
}