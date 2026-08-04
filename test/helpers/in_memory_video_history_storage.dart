import 'package:context_forge/models/video_history_entry.dart';
import 'package:context_forge/services/json_video_history_storage.dart';

/// In-memory [JsonVideoHistoryStorage] for widget tests.
///
/// Avoids real file I/O which never completes in Flutter's fake async
/// test environment.
class InMemoryVideoHistoryStorage extends JsonVideoHistoryStorage {
  InMemoryVideoHistoryStorage({List<VideoHistoryEntry>? initial})
      : _entries = List.of(initial ?? const []);

  List<VideoHistoryEntry> _entries;

  List<VideoHistoryEntry> get entries => List.unmodifiable(_entries);

  @override
  Future<List<VideoHistoryEntry>> loadHistory() async => List.of(_entries);

  @override
  Future<void> saveHistory(List<VideoHistoryEntry> entries) async {
    _entries = List.of(entries);
  }
}