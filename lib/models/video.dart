import 'transcript_language.dart';

/// Domain model representing a single YouTube video.
///
/// Immutable by design. Use [copyWith] to create modified copies.
/// All timestamps are [DateTime] (UTC).
/// Keep independent from any external API.
class Video {
  const Video({
    required this.id,
    required this.url,
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.publishedAt,
    required this.transcriptLanguage,
    required this.transcriptAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier for the video record.
  final String id;

  /// Full YouTube URL.
  final String url;

  /// YouTube video identifier extracted from the URL.
  final String videoId;

  /// Video title.
  final String title;

  /// Channel name.
  final String channelName;

  /// Publication date.
  final DateTime publishedAt;

  /// Preferred transcript language/origin for this video.
  final TranscriptLanguage transcriptLanguage;

  /// Whether a transcript is available.
  final bool transcriptAvailable;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last modification timestamp.
  final DateTime updatedAt;

  /// Creates a new [Video] with the provided fields replaced.
  Video copyWith({
    String? id,
    String? url,
    String? videoId,
    String? title,
    String? channelName,
    DateTime? publishedAt,
    TranscriptLanguage? transcriptLanguage,
    bool? transcriptAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Video(
      id: id ?? this.id,
      url: url ?? this.url,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      channelName: channelName ?? this.channelName,
      publishedAt: publishedAt ?? this.publishedAt,
      transcriptLanguage: transcriptLanguage ?? this.transcriptLanguage,
      transcriptAvailable: transcriptAvailable ?? this.transcriptAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serializes this video to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'videoId': videoId,
      'title': title,
      'channelName': channelName,
      'publishedAt': publishedAt.toUtc().toIso8601String(),
      'transcriptLanguage': transcriptLanguage.name,
      'transcriptAvailable': transcriptAvailable,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Deserializes a [Video] from a JSON-compatible map.
  ///
  /// Unknown transcript language values default to [TranscriptLanguage.none].
  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] as String,
      url: json['url'] as String,
      videoId: json['videoId'] as String,
      title: json['title'] as String,
      channelName: json['channelName'] as String,
      publishedAt: DateTime.parse(json['publishedAt'] as String).toUtc(),
      transcriptLanguage: _parseTranscriptLanguage(json['transcriptLanguage']),
      transcriptAvailable: json['transcriptAvailable'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
    );
  }

  static TranscriptLanguage _parseTranscriptLanguage(Object? value) {
    if (value is String) {
      for (final language in TranscriptLanguage.values) {
        if (language.name == value) {
          return language;
        }
      }
    }
    return TranscriptLanguage.none;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Video &&
        other.id == id &&
        other.url == url &&
        other.videoId == videoId &&
        other.title == title &&
        other.channelName == channelName &&
        other.publishedAt == publishedAt &&
        other.transcriptLanguage == transcriptLanguage &&
        other.transcriptAvailable == transcriptAvailable &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      url,
      videoId,
      title,
      channelName,
      publishedAt,
      transcriptLanguage,
      transcriptAvailable,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Video(id: $id, videoId: $videoId, title: $title, '
        'channelName: $channelName, transcriptLanguage: $transcriptLanguage)';
  }
}