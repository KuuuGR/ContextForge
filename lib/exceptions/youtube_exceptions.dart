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