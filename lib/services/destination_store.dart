import 'dart:convert';
import 'dart:io';

import '../models/ai_destination.dart';

/// Persists the favorite state of [AiDestination]s between launches.
///
/// Stores the set of favorite destination IDs in a small JSON file inside the
/// application support directory: `destination_favorites.json`.
class DestinationStore {
  DestinationStore({this.directoryPath});

  /// Overrides the persistence directory (used by tests). When null, the
  /// platform Application Support directory is used.
  final String? directoryPath;

  String get _resolvedDirectoryPath =>
      directoryPath ?? _defaultApplicationSupportPath();

  String get _filePath =>
      '$_resolvedDirectoryPath${Platform.pathSeparator}destination_favorites.json';

  /// Reads the persisted favorite destination IDs.
  ///
  /// Never throws — storage problems degrade to an empty set.
  Future<Set<String>> loadFavoriteIds() async {
    try {
      final file = File(_filePath);
      if (!await file.exists()) return <String>{};
      final content = await file.readAsString();
      if (content.trim().isEmpty) return <String>{};
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .toSet();
      }
      return <String>{};
    } catch (_) {
      return <String>{};
    }
  }

  /// Persists the complete set of favorite destination IDs.
  Future<void> saveFavoriteIds(Set<String> ids) async {
    try {
      final directory = Directory(_resolvedDirectoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final file = File(_filePath);
      const json = JsonEncoder.withIndent('  ');
      final sorted = ids.toList()..sort();
      await file.writeAsString(json.convert(sorted));
    } catch (_) {
      // Storage errors are not propagated to the caller.
    }
  }

  String _defaultApplicationSupportPath() {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '';
      return '$home/Library/Application Support/context_forge';
    }
    if (Platform.isIOS) {
      // HOME is null and Directory.current is "/" on iOS; the system temp
      // directory lives in the writable app data container (<container>/tmp).
      final container = Directory.systemTemp.parent.path;
      return '$container/Library/Application Support/context_forge';
    }
    return Directory.current.path;
  }
}