import 'youtube_transcript_info.dart';

/// Provider-specific DTO representing a downloaded YouTube transcript.
///
/// This is NOT a domain model. It belongs to the provider layer and
/// contains the transcript text as timestamped segments.
///
/// Immutable by design. Use [copyWith] to create modified copies.
class YoutubeTranscript {
  const YoutubeTranscript({
    required this.videoId,
    required this.info,
    required this.segments,
  });

  /// Canonical YouTube video identifier.
  final String videoId;

  /// Track metadata (language, manual/automatic origin).
  final YoutubeTranscriptInfo info;

  /// Transcript text segments with timestamps.
  final List<YoutubeTranscriptSegment> segments;

  /// Creates a new [YoutubeTranscript] with the provided fields replaced.
  YoutubeTranscript copyWith({
    String? videoId,
    YoutubeTranscriptInfo? info,
    List<YoutubeTranscriptSegment>? segments,
  }) {
    return YoutubeTranscript(
      videoId: videoId ?? this.videoId,
      info: info ?? this.info,
      segments: segments ?? this.segments,
    );
  }

  /// Serializes this DTO to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'info': info.toJson(),
      'segments': [for (final s in segments) s.toJson()],
    };
  }

  /// Deserializes a [YoutubeTranscript] from a JSON-compatible map.
  factory YoutubeTranscript.fromJson(Map<String, dynamic> json) {
    final segmentsJson = json['segments'] as List<dynamic>? ?? const [];
    return YoutubeTranscript(
      videoId: json['videoId'] as String,
      info: YoutubeTranscriptInfo.fromJson(
        json['info'] as Map<String, dynamic>,
      ),
      segments: [
        for (final item in segmentsJson)
          if (item is Map<String, dynamic>)
            YoutubeTranscriptSegment.fromJson(item),
      ],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YoutubeTranscript &&
        other.videoId == videoId &&
        other.info == info &&
        _listEquals(other.segments, segments);
  }

  @override
  int get hashCode {
    return Object.hash(videoId, info, Object.hashAll(segments));
  }

  @override
  String toString() {
    return 'YoutubeTranscript(videoId: $videoId, info: $info, '
        'segments: ${segments.length})';
  }

  static bool _listEquals(
    List<YoutubeTranscriptSegment> a,
    List<YoutubeTranscriptSegment> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A single timestamped transcript segment.
class YoutubeTranscriptSegment {
  const YoutubeTranscriptSegment({
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

  /// Creates a new [YoutubeTranscriptSegment] with the provided fields replaced.
  YoutubeTranscriptSegment copyWith({
    Duration? offset,
    Duration? duration,
    String? text,
  }) {
    return YoutubeTranscriptSegment(
      offset: offset ?? this.offset,
      duration: duration ?? this.duration,
      text: text ?? this.text,
    );
  }

  /// Serializes this segment to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'offsetMs': offset.inMilliseconds,
      'durationMs': duration.inMilliseconds,
      'text': text,
    };
  }

  /// Deserializes a segment from a JSON-compatible map.
  factory YoutubeTranscriptSegment.fromJson(Map<String, dynamic> json) {
    return YoutubeTranscriptSegment(
      offset: Duration(milliseconds: json['offsetMs'] as int? ?? 0),
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      text: json['text'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YoutubeTranscriptSegment &&
        other.offset == offset &&
        other.duration == duration &&
        other.text == text;
  }

  @override
  int get hashCode => Object.hash(offset, duration, text);

  @override
  String toString() {
    return 'YoutubeTranscriptSegment(offset: $offset, text: "$text")';
  }
}