import '../models/video.dart';
import 'video_repository.dart';

/// In-memory [VideoRepository] implementation.
///
/// Used for wiring the Phase 010 vertical slice. Persistence for videos
/// arrives in a later phase; this repository keeps videos only for the
/// lifetime of the app instance.
class InMemoryVideoRepository implements VideoRepository {
  final List<Video> _videos = [];

  @override
  Future<List<Video>> getAll() async => List.unmodifiable(_videos);

  @override
  Future<Video?> getByVideoId(String videoId) async {
    for (final video in _videos) {
      if (video.videoId == videoId) return video;
    }
    return null;
  }

  @override
  Future<void> save(Video video) async {
    final index = _videos.indexWhere((v) => v.videoId == video.videoId);
    if (index >= 0) {
      _videos[index] = video;
    } else {
      _videos.add(video);
    }
  }

  @override
  Future<void> delete(String videoId) async {
    _videos.removeWhere((v) => v.videoId == videoId);
  }
}