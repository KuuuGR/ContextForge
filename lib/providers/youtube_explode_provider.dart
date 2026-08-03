import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../exceptions/youtube_exceptions.dart';
import '../models/transcript_language.dart';
import 'youtube_provider.dart';
import 'youtube_transcript.dart';
import 'youtube_transcript_info.dart';
import 'youtube_video_metadata.dart';

/// Concrete [YoutubeProvider] implementation backed by the
/// `youtube_explode_dart` package.
///
/// Responsibilities:
/// - Retrieve video metadata from YouTube.
/// - Discover available transcript tracks (metadata only).
/// - Download transcript text for a selected track.
/// - Map external package types into provider DTOs (never leak external types).
/// - Translate external exceptions into domain-specific exceptions.
///
/// Networking is fully isolated inside this implementation.
class YoutubeExplodeProvider implements YoutubeProvider {
  YoutubeExplodeProvider({
    YoutubeExplode? youtubeExplode,
    Future<Video> Function(YoutubeExplode yt, String videoId)? fetchVideo,
    Future<ClosedCaptionManifest> Function(YoutubeExplode yt, String videoId)?
        fetchManifest,
    Future<ClosedCaptionTrack> Function(
      YoutubeExplode yt,
      ClosedCaptionTrackInfo trackInfo,
    )?
    fetchCaptionTrack,
  })  : _youtube = youtubeExplode ?? YoutubeExplode(),
        _fetchVideo = fetchVideo ?? _defaultFetch,
        _fetchManifest = fetchManifest ?? _defaultFetchManifest,
        _fetchCaptionTrack = fetchCaptionTrack ?? _defaultFetchCaptionTrack;

  final YoutubeExplode _youtube;

  /// Injectable fetch function; receives the [YoutubeExplode] instance and a
  /// video ID. Tests override this to avoid network access.
  final Future<Video> Function(YoutubeExplode yt, String videoId) _fetchVideo;

  /// Injectable manifest fetch function (transcript tracks discovery).
  final Future<ClosedCaptionManifest> Function(YoutubeExplode yt, String videoId)
      _fetchManifest;

  /// Injectable caption track fetch function (transcript download).
  final Future<ClosedCaptionTrack> Function(
    YoutubeExplode yt,
    ClosedCaptionTrackInfo trackInfo,
  )
  _fetchCaptionTrack;

  static Future<Video> _defaultFetch(YoutubeExplode yt, String videoId) =>
      yt.videos.get(videoId);

  static Future<ClosedCaptionManifest> _defaultFetchManifest(
    YoutubeExplode yt,
    String videoId,
  ) =>
      yt.videos.closedCaptions.getManifest(videoId);

  static Future<ClosedCaptionTrack> _defaultFetchCaptionTrack(
    YoutubeExplode yt,
    ClosedCaptionTrackInfo trackInfo,
  ) =>
      yt.videos.closedCaptions.get(trackInfo);

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
    try {
      final manifest = await _fetchManifest(_youtube, videoId);
      return [
        for (final track in manifest.tracks) _mapTranscriptInfo(track),
      ];
    } on VideoUnavailableException catch (e) {
      throw YoutubeVideoUnavailableException(
        'Video "$videoId" is unavailable: ${e.message}',
      );
    } on ArgumentError catch (e) {
      throw InvalidYouTubeUrlException(
        'Invalid YouTube video ID or URL: "$videoId" (${e.message}).',
      );
    } catch (e) {
      throw YoutubeNetworkException(
        'Failed to discover transcripts for video "$videoId".',
        cause: e,
      );
    }
  }

  @override
  Future<YoutubeTranscript?> downloadTranscript(
    String videoId,
    YoutubeTranscriptInfo info,
  ) async {
    try {
      final manifest = await _fetchManifest(_youtube, videoId);
      final track = _findTrack(manifest, info);
      if (track == null) return null;
      final captionTrack = await _fetchCaptionTrack(_youtube, track);
      return _mapTranscript(videoId, info, captionTrack);
    } on VideoUnavailableException catch (e) {
      throw YoutubeVideoUnavailableException(
        'Video "$videoId" is unavailable: ${e.message}',
      );
    } on ArgumentError catch (e) {
      throw InvalidYouTubeUrlException(
        'Invalid YouTube video ID or URL: "$videoId" (${e.message}).',
      );
    } catch (e) {
      throw YoutubeNetworkException(
        'Failed to download transcript for video "$videoId".',
        cause: e,
      );
    }
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

  YoutubeTranscriptInfo _mapTranscriptInfo(ClosedCaptionTrackInfo track) {
    return YoutubeTranscriptInfo(
      language: _mapLanguage(track),
      isManual: !track.isAutoGenerated,
      languageName: track.language.name,
      languageCode: track.language.code,
      isTranslatable: false,
    );
  }

  TranscriptLanguage _mapLanguage(ClosedCaptionTrackInfo track) {
    final code = track.language.code.toLowerCase();
    final isAuto = track.isAutoGenerated;
    return switch (code) {
      'pl' => isAuto ? TranscriptLanguage.polishAuto : TranscriptLanguage.polish,
      'en' => isAuto ? TranscriptLanguage.englishAuto : TranscriptLanguage.english,
      _ => TranscriptLanguage.other,
    };
  }

  ClosedCaptionTrackInfo? _findTrack(
    ClosedCaptionManifest manifest,
    YoutubeTranscriptInfo info,
  ) {
    final targetCode = info.languageCode.toLowerCase();
    final targetAuto = !info.isManual;
    for (final track in manifest.tracks) {
      if (track.language.code.toLowerCase() == targetCode &&
          track.isAutoGenerated == targetAuto) {
        return track;
      }
    }
    return null;
  }

  YoutubeTranscript _mapTranscript(
    String videoId,
    YoutubeTranscriptInfo info,
    ClosedCaptionTrack track,
  ) {
    return YoutubeTranscript(
      videoId: videoId,
      info: info,
      segments: [
        for (final c in track.captions)
          YoutubeTranscriptSegment(
            offset: c.offset,
            duration: c.duration,
            text: c.text,
          ),
      ],
    );
  }

  /// Closes the underlying HTTP client.
  void close() => _youtube.close();
}