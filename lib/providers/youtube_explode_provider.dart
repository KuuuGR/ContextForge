import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../exceptions/youtube_exceptions.dart';
import 'youtube_provider.dart';
import 'youtube_transcript.dart';
import 'youtube_transcript_info.dart';
import 'youtube_video_metadata.dart';

/// Concrete [YoutubeProvider] implementation backed by the
/// `youtube_explode_dart` package.
///
/// Responsibilities:
/// - Retrieve video metadata from YouTube.
/// - Map external package types into provider DTOs (never leak external types).
/// - Translate external exceptions into domain-specific exceptions.
///
/// Networking is fully isolated inside this implementation.
class YoutubeExplodeProvider implements YoutubeProvider {
  YoutubeExplodeProvider({
    YoutubeExplode? youtubeExplode,
    Future<Video> Function(YoutubeExplode yt, String videoId)? fetchVideo,
  })  : _youtube = youtubeExplode ?? YoutubeExplode(),
        _fetchVideo = fetchVideo ?? _defaultFetch;

  final YoutubeExplode _youtube;

  /// Injectable fetch function; receives the [YoutubeExplode] instance and a
  /// video ID. Tests override this to avoid network access.
  final Future<Video> Function(YoutubeExplode yt, String videoId) _fetchVideo;

  static Future<Video> _defaultFetch(YoutubeExplode yt, String videoId) =>
      yt.videos.get(videoId);

  @override
  Future<YoutubeVideoMetadata?> getVideoMetadata(String videoId) async {
    try {
      final video = await _fetchVideo(_youtube, videoId);
      return _mapVideo(video);
    } on VideoUnavailableException catch (e) {
      throw YoutubeVideoUnavailableException(
        'Video "$videoId" is unavailable: ${e.message}',
      );
    } on ArgumentError catch (e) {
      throw InvalidYouTubeUrlException(
        'Invalid YouTube video ID or URL: "$videoId" (${e.message}).',
      );
    } on InvalidYouTubeUrlException {
      rethrow;
    } catch (e) {
      throw YoutubeNetworkException(
        'Failed to fetch metadata for video "$videoId".',
        cause: e,
      );
    }
  }

  @override
  Future<List<YoutubeTranscriptInfo>> getAvailableTranscripts(
    String videoId,
  ) async {
    // Transcript availability is implemented in a later phase.
    throw UnimplementedError(
      'getAvailableTranscripts is not implemented yet.',
    );
  }

  @override
  Future<YoutubeTranscript?> downloadTranscript(
    String videoId,
    YoutubeTranscriptInfo info,
  ) async {
    // Transcript downloading is implemented in a later phase.
    throw UnimplementedError('downloadTranscript is not implemented yet.');
  }

  YoutubeVideoMetadata _mapVideo(Video video) {
    final id = video.id.value;
    return YoutubeVideoMetadata(
      videoId: id,
      title: video.title,
      channelName: video.author,
      publishedAt:
          video.uploadDate ?? video.publishDate ?? DateTime.now().toUtc(),
      duration: video.duration ?? Duration.zero,
      url: video.url,
      description: video.description.isEmpty ? null : video.description,
    );
  }

  /// Closes the underlying HTTP client.
  void close() => _youtube.close();
}