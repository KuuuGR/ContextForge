import '../models/video.dart';

/// Contract for video persistence.
///
/// Implementations are responsible for storage details.
/// This is an abstraction only — no implementation in this phase.
abstract class VideoRepository {
  /// Returns all stored videos.
  Future<List<Video>> getAll();

  /// Returns a single video by its YouTube [videoId], or `null` if not found.
  Future<Video?> getByVideoId(String videoId);

  /// Persists a [video]. Creates or updates depending on storage semantics.
  Future<void> save(Video video);

  /// Deletes the video with the given YouTube [videoId].
  Future<void> delete(String videoId);
}