import 'transcript_track.dart';

/// Result of a successful transcript download.
///
/// Contains the plain transcript text (segments joined without timestamps)
/// together with the raw timestamped segments, preserved for later
/// cleaning phases.
class TranscriptDownload {
  const TranscriptDownload({
    required this.videoId,
    required this.track,
    required this.text,
    required this.segments,
  });

  /// Canonical YouTube video identifier.
  final String videoId;

  /// Selected transcript track used for the download.
  final TranscriptTrack track;

  /// Plain transcript text (no timestamps).
  ///
  /// Segment texts joined with a single space. No cleanup applied —
  /// cleaning is implemented in a later phase.
  final String text;

  /// Raw timestamped segments preserved for later cleaning.
  final List<TranscriptSegment> segments;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TranscriptDownload &&
        other.videoId == videoId &&
        other.track == track &&
        other.text == text &&
        _segmentListEquals(other.segments, segments);
  }

  @override
  int get hashCode =>
      Object.hash(videoId, track, text, Object.hashAll(segments));

  @override
  String toString() =>
      'TranscriptDownload(videoId: $videoId, track: $track, '
      'segments: ${segments.length}, text: "${text.length} chars")';

  static bool _segmentListEquals(
    List<TranscriptSegment> a,
    List<TranscriptSegment> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A single timestamped transcript segment.
class TranscriptSegment {
  const TranscriptSegment({
    required this.offset,
    required this.duration,
    required this.text,
  });

  /// Offset from the start of the video.
  final Duration offset;

  /// Segment duration.
  final Duration duration;

  /// Transcript text.
  final String text;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TranscriptSegment &&
        other.offset == offset &&
        other.duration == duration &&
        other.text == text;
  }

  @override
  int get hashCode => Object.hash(offset, duration, text);

  @override
  String toString() => 'TranscriptSegment(offset: $offset, text: "$text")';
}