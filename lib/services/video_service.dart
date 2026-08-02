import '../models/video.dart';
import '../repositories/video_repository.dart';

/// Application service for video domain workflows.
///
/// Responsibilities (established here, implemented in later phases):
/// - Validate YouTube URLs (up to three per run) — Phase 007.
/// - Fetch video metadata, including publication date — Phase 007.
/// - Resolve the video identifier used for history tracking — Phase 007.
/// - Check whether a video has been used before (history) — Phase 006/007.
///
/// Depends on [VideoRepository] abstraction; storage details are
/// intentionally hidden from callers.
///
/// NOTE: Phase 006 establishes the domain foundation only.
/// Implementations of these methods arrive in later phases.
class VideoService {
  VideoService({required this.repository});

  /// Repository abstraction used for video persistence.
  final VideoRepository repository;

  /// Returns all stored videos.
  Future<List<Video>> getAllVideos() {
    // TODO(Phase 007): Implement video retrieval through repository.
    throw UnimplementedError('VideoService.getAllVideos is not implemented yet.');
  }

  /// Returns a single video by its YouTube identifier, or `null` if not found.
  Future<Video?> getVideoByVideoId(String videoId) {
    // TODO(Phase 007): Implement video lookup through repository.
    throw UnimplementedError('VideoService.getVideoByVideoId is not implemented yet.');
  }

  /// Checks whether the video with the given [videoId] has been used before.
  Future<bool> hasBeenUsed(String videoId) {
    // TODO(Phase 006/007): Implement history check.
    throw UnimplementedError('VideoService.hasBeenUsed is not implemented yet.');
  }
}