import 'dart:convert';
import 'dart:io';

import 'review_state.dart';

/// Local file-based persistence for [ReviewState].
///
/// Stores a small JSON file in the application data directory, following the
/// same convention as the prompt / video-history / intro stores. No database,
/// no backend, no analytics.
class ReviewStore {
  ReviewStore({this.directoryPath});

  /// Base directory for the storage file.
  ///
  /// When null, the platform default is used:
  /// - macOS: `${HOME}/Library/Application Support/context_forge`
  final String? directoryPath;

  String get _resolvedDirectoryPath =>
      directoryPath ?? _defaultApplicationSupportPath();

  String get _filePath =>
      '$_resolvedDirectoryPath${Platform.pathSeparator}review_state.json';

  /// Loads the stored state. Returns a fresh [ReviewState] when the file is
  /// missing, empty, or invalid.
  Future<ReviewState> load() async {
    try {
      final file = File(_filePath);
      if (!await file.exists()) return const ReviewState();
      final content = await file.readAsString();
      if (content.trim().isEmpty) return const ReviewState();
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        return ReviewState.fromJson(decoded);
      }
      return const ReviewState();
    } catch (_) {
      return const ReviewState();
    }
  }

  /// Persists [state] as human-readable JSON.
  ///
  /// Creates the file (and parent directory) if it does not exist. Does not
  /// throw on storage errors.
  Future<void> save(ReviewState state) async {
    try {
      final directory = Directory(_resolvedDirectoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final file = File(_filePath);
      final json = const JsonEncoder.withIndent('  ').convert(state.toJson());
      await file.writeAsString(json);
    } catch (_) {
      // Storage errors are not propagated to the caller.
    }
  }

  String _defaultApplicationSupportPath() {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '';
      return '$home/Library/Application Support/context_forge';
    }
    return Directory.current.path;
  }
}
