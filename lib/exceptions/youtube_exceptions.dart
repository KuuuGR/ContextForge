/// Thrown when a YouTube URL is invalid or unsupported.
///
/// Kept distinct from generic [Exception] so callers can handle
/// YouTube-specific URL failures precisely.
class InvalidYouTubeUrlException implements Exception {
  const InvalidYouTubeUrlException(this.message);

  final String message;

  @override
  String toString() => 'InvalidYouTubeUrlException: $message';
}

/// Thrown when a YouTube video cannot be found or is unavailable.
class YoutubeVideoUnavailableException implements Exception {
  const YoutubeVideoUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'YoutubeVideoUnavailableException: $message';
}

/// Thrown when a network failure prevents communication with YouTube.
class YoutubeNetworkException implements Exception {
  const YoutubeNetworkException(this.message, {this.cause});

  final String message;

  /// Underlying cause, when available.
  final Object? cause;

  @override
  String toString() => 'YoutubeNetworkException: $message'
      '${cause != null ? ' (cause: $cause)' : ''}';
}

/// Thrown when transcripts are disabled or none are available for a video.
class TranscriptsUnavailableException implements Exception {
  const TranscriptsUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'TranscriptsUnavailableException: $message';
}
