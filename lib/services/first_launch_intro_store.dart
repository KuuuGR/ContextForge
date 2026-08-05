import 'dart:convert';
import 'dart:io';

/// Persists the First Launch Intro completion state.
class FirstLaunchIntroStore {
  FirstLaunchIntroStore({
    this.directoryPath,
    this.debugAlwaysShowIntro = false,
  });

  final String? directoryPath;

  /// Development flag: when true, the Intro is always displayed regardless
  /// of the persisted completion state. Release builds keep this false.
  final bool debugAlwaysShowIntro;

  String get _resolvedDirectoryPath =>
      directoryPath ?? _defaultApplicationSupportPath();

  String get _filePath =>
      '$_resolvedDirectoryPath${Platform.pathSeparator}intro_state.json';

  Future<bool> shouldShowIntro() async {
    if (debugAlwaysShowIntro) return true;
    try {
      final file = File(_filePath);
      if (!await file.exists()) return true;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return true;
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        final completed = decoded['introCompleted'];
        if (completed is bool) return !completed;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<void> markIntroCompleted() async {
    try {
      final directory = Directory(_resolvedDirectoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final file = File(_filePath);
      const json = JsonEncoder.withIndent('  ');
      await file.writeAsString(json.convert({'introCompleted': true}));
    } catch (_) {
      // Storage errors are not propagated to the caller.
    }
  }

  Future<void> reset() async {
    try {
      final file = File(_filePath);
      if (await file.exists()) {
        await file.delete();
      }
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