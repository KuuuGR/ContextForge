import 'dart:convert';
import 'dart:io';

import '../models/video_history_entry.dart';

/// File-based storage for processed-video history.
///
/// Stores entries as human-readable JSON in an application data directory.
/// Follows the same conventions as [JsonPromptStorage].
class JsonVideoHistoryStorage {
  JsonVideoHistoryStorage({this.directoryPath});

  /// Base directory for the storage file.
  ///
  /// When null, the platform default is used:
  /// - macOS: `${HOME}/Library/Application Support/context_forge`
  final String? directoryPath;

  String get _resolvedDirectoryPath =>
      directoryPath ?? _defaultApplicationSupportPath();

  String get _filePath =>
      '$_resolvedDirectoryPath${Platform.pathSeparator}video_history.json';

  /// Loads all history entries from the JSON file.
  ///
  /// Returns an empty list when the file is missing, empty, or contains
  /// invalid JSON.
  Future<List<VideoHistoryEntry>> loadHistory() async {
    try {
      final file = await _ensureFile();
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return <VideoHistoryEntry>[];
      }
      final decoded = jsonDecode(content);
      if (decoded is! List) {
        return <VideoHistoryEntry>[];
      }
      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>) VideoHistoryEntry.fromJson(item),
      ];
    } catch (_) {
      return <VideoHistoryEntry>[];
    }
  }

  /// Persists all history entries to the JSON file as human-readable JSON.
  ///
  /// Creates the file (and parent directory) if it does not exist.
  /// Does not throw on storage errors.
  Future<void> saveHistory(List<VideoHistoryEntry> entries) async {
    try {
      final directory = Directory(_resolvedDirectoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final file = File(_filePath);
      final json = const JsonEncoder.withIndent('  ')
          .convert([for (final e in entries) e.toJson()]);
      await file.writeAsString(json);
    } catch (_) {
      // Storage errors are not propagated to the caller.
    }
  }

  /// Ensures the storage directory and file exist.
  ///
  /// Creates the file with an empty list (`[]`) when it does not exist.
  Future<File> _ensureFile() async {
    final directory = Directory(_resolvedDirectoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final file = File(_filePath);
    if (!await file.exists()) {
      await file.writeAsString('[]');
    }
    return file;
  }

  String _defaultApplicationSupportPath() {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '';
      return '$home/Library/Application Support/context_forge';
    }
    return Directory.current.path;
  }
}