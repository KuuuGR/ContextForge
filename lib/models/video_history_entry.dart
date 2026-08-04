/// A single record in the persistent video processing history.
///
/// Stored as a JSON object in a local history file. Immutable by design.
class VideoHistoryEntry {
  const VideoHistoryEntry({
    required this.videoId,
    required this.originalUrl,
    required this.title,
    required this.channelName,
    required this.processedAt,
  });

  /// Canonical YouTube video identifier.
  final String videoId;

  /// The URL as originally entered by the user.
  final String originalUrl;

  /// Video title at the time of processing.
  final String title;

  /// Channel name at the time of processing.
  final String channelName;

  /// Timestamp (UTC) when the transcript was successfully generated.
  final DateTime processedAt;

  /// Serializes this entry to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'originalUrl': originalUrl,
      'title': title,
      'channelName': channelName,
      'processedAt': processedAt.toUtc().toIso8601String(),
    };
  }

  /// Deserializes a [VideoHistoryEntry] from a JSON-compatible map.
  factory VideoHistoryEntry.fromJson(Map<String, dynamic> json) {
    return VideoHistoryEntry(
      videoId: json['videoId'] as String,
      originalUrl: json['originalUrl'] as String,
      title: json['title'] as String,
      channelName: json['channelName'] as String,
      processedAt: DateTime.parse(json['processedAt'] as String).toUtc(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoHistoryEntry &&
        other.videoId == videoId &&
        other.originalUrl == originalUrl &&
        other.title == title &&
        other.channelName == channelName &&
        other.processedAt == processedAt;
  }

  @override
  int get hashCode {
    return Object.hash(videoId, originalUrl, title, channelName, processedAt);
  }

  @override
  String toString() {
    return 'VideoHistoryEntry(videoId: $videoId, title: $title, '
        'processedAt: $processedAt)';
  }
}