/// Provider-specific DTO representing YouTube video metadata.
///
/// This is NOT a domain model. It belongs to the provider layer and
/// mirrors the shape of the external YouTube data.
///
/// Immutable by design. Use [copyWith] to create modified copies.
class YoutubeVideoMetadata {
  const YoutubeVideoMetadata({
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.publishedAt,
    required this.duration,
    this.description,
  });

  /// Canonical YouTube video identifier.
  final String videoId;

  /// Video title.
  final String title;

  /// Channel name.
  final String channelName;

  /// Publication date (UTC).
  final DateTime publishedAt;

  /// Video duration.
  final Duration duration;

  /// Optional video description.
  final String? description;

  /// Creates a new [YoutubeVideoMetadata] with the provided fields replaced.
  YoutubeVideoMetadata copyWith({
    String? videoId,
    String? title,
    String? channelName,
    DateTime? publishedAt,
    Duration? duration,
    String? description,
  }) {
    return YoutubeVideoMetadata(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      channelName: channelName ?? this.channelName,
      publishedAt: publishedAt ?? this.publishedAt,
      duration: duration ?? this.duration,
      description: description ?? this.description,
    );
  }

  /// Serializes this DTO to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'channelName': channelName,
      'publishedAt': publishedAt.toUtc().toIso8601String(),
      'durationSeconds': duration.inSeconds,
      if (description != null) 'description': description,
    };
  }

  /// Deserializes a [YoutubeVideoMetadata] from a JSON-compatible map.
  factory YoutubeVideoMetadata.fromJson(Map<String, dynamic> json) {
    return YoutubeVideoMetadata(
      videoId: json['videoId'] as String,
      title: json['title'] as String,
      channelName: json['channelName'] as String,
      publishedAt: DateTime.parse(json['publishedAt'] as String).toUtc(),
      duration: Duration(seconds: json['durationSeconds'] as int? ?? 0),
      description: json['description'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YoutubeVideoMetadata &&
        other.videoId == videoId &&
        other.title == title &&
        other.channelName == channelName &&
        other.publishedAt == publishedAt &&
        other.duration == duration &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(
      videoId,
      title,
      channelName,
      publishedAt,
      duration,
      description,
    );
  }

  @override
  String toString() {
    return 'YoutubeVideoMetadata(videoId: $videoId, title: $title, '
        'channelName: $channelName, publishedAt: $publishedAt, '
        'duration: $duration)';
  }
}