import 'package:flutter/foundation.dart';

import '../exceptions/youtube_exceptions.dart';

/// Parses YouTube URLs into canonical form.
///
/// Responsibilities:
/// - Validate supported YouTube URL formats.
/// - Extract the canonical YouTube video ID.
/// - Normalize URLs to a single canonical `watch` form.
///
/// Independent from Flutter UI and networking. Reusable by any layer.
///
/// Supported URL formats:
/// - `https://www.youtube.com/watch?v=VIDEO_ID`
/// - `https://youtube.com/watch?v=VIDEO_ID`
/// - `https://m.youtube.com/watch?v=VIDEO_ID`
/// - `https://youtu.be/VIDEO_ID`
/// - Any of the above with additional query parameters.
///
/// Canonical video IDs are 11 characters matching `[A-Za-z0-9_-]`.
class YouTubeUrlParser {
  const YouTubeUrlParser();

  /// Video ID pattern: 11 base64url-safe characters.
  static final RegExp _videoIdPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

  static const String _canonicalHost = 'www.youtube.com';
  static const String _canonicalPath = '/watch';

  /// Returns `true` when [url] is a supported YouTube URL with a valid
  /// canonical video ID.
  bool isValidUrl(String url) {
    try {
      extractVideoId(url);
      return true;
    } on InvalidYouTubeUrlException {
      return false;
    }
  }

  /// Extracts the canonical video ID from a supported YouTube URL.
  ///
  /// Throws [InvalidYouTubeUrlException] for unsupported or malformed URLs.
  String extractVideoId(String url) {
    debugPrint('[YouTubeUrlParser] Original URL: "$url"');
    try {
      if (url.trim().isEmpty) {
        throw const InvalidYouTubeUrlException('URL must not be empty.');
      }

      final normalized = url.trim();
      final Uri? uri = Uri.tryParse(normalized);
      if (uri == null) {
        throw InvalidYouTubeUrlException('Malformed URL: "$url".');
      }

      if (!_isHttpScheme(uri)) {
        throw InvalidYouTubeUrlException('Only http/https URLs are supported.');
      }

      final host = uri.host.toLowerCase();

      final videoId = _extractVideoIdForHost(uri, url, host);
      debugPrint('[YouTubeUrlParser] Parsed video ID: "$videoId"');
      return videoId;
    } catch (e, stack) {
      debugPrint('[YouTubeUrlParser] Parsing failed: '
          'type=${e.runtimeType}, message=$e\n$stack');
      rethrow;
    }
  }

  String _extractVideoIdForHost(Uri uri, String original, String host) {
    if (_isShortHost(host)) {
      return _extractFromShortUrl(uri, original);
    }
    if (_isWatchHost(host) && uri.path == _canonicalPath) {
      return _extractFromQuery(uri, original);
    }
    throw InvalidYouTubeUrlException('Unsupported YouTube URL: "$original".');
  }

  /// Normalizes a supported YouTube URL to its canonical form:
  /// `https://www.youtube.com/watch?v=VIDEO_ID`.
  ///
  /// Throws [InvalidYouTubeUrlException] for unsupported or malformed URLs.
  String normalizeUrl(String url) {
    final videoId = extractVideoId(url);
    return 'https://$_canonicalHost$_canonicalPath?v=$videoId';
  }

  bool _isHttpScheme(Uri uri) {
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  bool _isShortHost(String host) => host == 'youtu.be';

  bool _isWatchHost(String host) {
    return host == 'youtube.com' ||
        host == 'www.youtube.com' ||
        host == 'm.youtube.com';
  }

  String _extractFromShortUrl(Uri uri, String original) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length != 1) {
      throw InvalidYouTubeUrlException('Unsupported youtu.be URL: "$original".');
    }
    return _validateVideoId(segments.first, original);
  }

  String _extractFromQuery(Uri uri, String original) {
    final videoId = uri.queryParameters['v'];
    if (videoId == null || videoId.isEmpty) {
      throw InvalidYouTubeUrlException('Missing "v" parameter in URL: "$original".');
    }
    return _validateVideoId(videoId, original);
  }

  String _validateVideoId(String candidate, String original) {
    if (!_videoIdPattern.hasMatch(candidate)) {
      throw InvalidYouTubeUrlException('Invalid video ID "$candidate" in URL: "$original".');
    }
    return candidate;
  }
}