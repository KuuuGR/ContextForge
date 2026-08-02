import 'dart:convert';
import 'dart:io';

import '../models/prompt.dart';

/// File-based storage for prompt templates.
///
/// Stores prompts as human-readable JSON in an application data directory.
/// The repository depends on this abstraction rather than managing
/// filesystem details directly.
class JsonPromptStorage {
  JsonPromptStorage({this.directoryPath});

  /// Base directory for the storage file.
  ///
  /// When null, the platform default is used:
  /// - macOS: `${HOME}/Library/Application Support/context_forge`
  final String? directoryPath;

  String get _resolvedDirectoryPath =>
      directoryPath ?? _defaultApplicationSupportPath();

  String get _filePath => '$_resolvedDirectoryPath${Platform.pathSeparator}prompts.json';

  /// Loads all prompts from the JSON file.
  ///
  /// Returns an empty list when the file is missing, empty, or contains
  /// invalid JSON.
  Future<List<Prompt>> loadPrompts() async {
    try {
      final file = await _ensureFile();
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return <Prompt>[];
      }
      final decoded = jsonDecode(content);
      if (decoded is! List) {
        return <Prompt>[];
      }
      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>) Prompt.fromJson(item),
      ];
    } catch (_) {
      return <Prompt>[];
    }
  }

  /// Persists all prompts to the JSON file as human-readable JSON.
  ///
  /// Creates the file (and parent directory) if it does not exist.
  /// Does not throw on storage errors.
  Future<void> savePrompts(List<Prompt> prompts) async {
    try {
      final directory = Directory(_resolvedDirectoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final file = File(_filePath);
      final json = const JsonEncoder.withIndent('  ')
          .convert([for (final p in prompts) p.toJson()]);
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
