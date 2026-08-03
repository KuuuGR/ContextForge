import 'package:flutter/foundation.dart';

import '../exceptions/youtube_exceptions.dart';
import '../models/transcript_language.dart';
import '../models/video.dart';
import '../providers/youtube_provider.dart';
import '../providers/youtube_video_metadata.dart';
import '../repositories/video_repository.dart';
import 'youtube_url_parser.dart';

/// Application service for video domain workflows.
///
/// Responsibilities:
/// - Validate user-entered YouTube URLs.
/// - Fetch video metadata through the [YoutubeProvider] abstraction.
/// - Map provider DTOs into domain [Video] models (ADR-009).
/// - Expose user-facing workflows to the presentation layer.
///
/// The UI must never communicate directly with repositories or providers —
/// it must go through this service.
class VideoService {
  VideoService({
    required this.repository,
    required this.provider,
  });

  /// Repository abstraction used for video persistence.
  final VideoRepository repository;

  /// Provider abstraction used for external YouTube communication.
  final YoutubeProvider provider;

  final YouTubeUrlParser _parser = const YouTubeUrlParser();

  /// Returns all stored videos.
  Future<List<Video>> getAllVideos() {
    return repository.getAll();
  }

  /// Returns a single video by its YouTube identifier, or `null` if not found.
  Future<Video?> getVideoByVideoId(String videoId) {
    return repository.getByVideoId(videoId);
  }

  /// Checks whether the video with the given [videoId] has been used before.
  Future<bool> hasBeenUsed(String videoId) {
    // History support arrives in a later phase.
    throw UnimplementedError('VideoService.hasBeenUsed is not implemented yet.');
  }

  /// Fetches metadata for a user-entered YouTube [url].
  ///
  /// Pipeline:
  /// 1. Validate and normalize the URL, extracting the canonical video ID.
  /// 2. Fetch metadata through the provider.
  /// 3. Map the provider DTO into a domain [Video] model.
  ///
  /// Throws domain exceptions:
  /// - [InvalidYouTubeUrlException] when the URL is malformed or unsupported.
  /// - [YoutubeVideoUnavailableException] when the video does not exist.
  /// - [YoutubeNetworkException] on network failures.
  /// Raw provider / storage exceptions are never exposed to callers.
  Future<Video> fetchVideoMetadata(String url) async {
    final videoId = _parser.extractVideoId(url);
    debugPrint('[VideoService] Metadata request: videoId="$videoId"');
    try {
      final metadata = await provider.getVideoMetadata(videoId);
      if (metadata == null) {
        throw YoutubeVideoUnavailableException(
          'Video "$videoId" is unavailable.',
        );
      }
      debugPrint('[VideoService] Metadata received: '
          'title="${metadata.title}", url="${metadata.url}"');
      return _mapToDomain(metadata);
    } catch (e, stack) {
      debugPrint('[VideoService] Metadata request failed: '
          'type=${e.runtimeType}, message=$e\n$stack');
      rethrow;
    }
  }

  Video _mapToDomain(YoutubeVideoMetadata metadata) {
    final now = DateTime.now().toUtc();
    return Video(
      id: metadata.videoId,
      url: metadata.url,
      videoId: metadata.videoId,
      title: metadata.title,
      channelName: metadata.channelName,
      publishedAt: metadata.publishedAt,
      transcriptLanguage: metadata.description == null
          ? TranscriptLanguage.none
          : TranscriptLanguage.other,
      transcriptAvailable: false,
      createdAt: now,
      updatedAt: now,
    );
  }
}