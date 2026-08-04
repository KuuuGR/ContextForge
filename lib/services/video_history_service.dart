import '../models/video.dart';
import '../models/video_history_entry.dart';
import 'json_video_history_storage.dart';
import 'youtube_url_parser.dart';

/// Application service for the persistent processed-video history.
///
/// Responsibilities:
/// - Load history once at startup and keep it in memory for instant lookups.
/// - Record a successful transcript generation (upsert by [videoId]).
/// - Expose lookup-by-URL for the URL status indicator.
///
/// History is deliberately lightweight: a single JSON file, no database.
class VideoHistoryService {
  VideoHistoryService({required this.storage});

  final JsonVideoHistoryStorage storage;

  final YouTubeUrlParser _parser = const YouTubeUrlParser();

  final Map<String, VideoHistoryEntry> _entries = {};

  bool _loaded = false;

  /// Loads history from disk into memory.
  ///
  /// Safe to call multiple times; history is only read from storage once.
  /// Returns the number of entries loaded.
  Future<int> load() async {
    if (_loaded) return _entries.length;
    final entries = await storage.loadHistory();
    for (final entry in entries) {
      _entries[entry.videoId] = entry;
    }
    _loaded = true;
    return _entries.length;
  }

  /// Returns the history entry for [videoId], or `null` when the video has
  /// never been processed successfully.
  VideoHistoryEntry? getEntry(String videoId) => _entries[videoId];

  /// Returns the history entry for a user-entered [url], or `null` when the
  /// URL is not a valid YouTube URL or the video has never been processed.
  ///
  /// Performs a synchronous in-memory lookup — no disk I/O.
  VideoHistoryEntry? getEntryByUrl(String url) {
    String videoId;
    try {
      videoId = _parser.extractVideoId(url);
    } catch (_) {
      return null;
    }
    return _entries[videoId];
  }

  /// Whether the video has been processed successfully before.
  bool hasBeenProcessed(String videoId) => _entries.containsKey(videoId);

  /// Records a successful transcript generation for [video].
  ///
  /// If the video already exists, its `processedAt` is updated and no
  /// duplicate entry is created. Persists immediately.
  Future<void> recordSuccess(Video video) async {
    await load();
    _entries[video.videoId] = VideoHistoryEntry(
      videoId: video.videoId,
      originalUrl: video.url,
      title: video.title,
      channelName: video.channelName,
      processedAt: DateTime.now().toUtc(),
    );
    await storage.saveHistory(_entries.values.toList());
  }
}