import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';

import '../models/prompt.dart';

/// Export/import of user-created prompts as a portable JSON file.
///
/// The on-disk format is intentionally simple and human-readable:
///
/// ```json
/// {
///   "app": "ContextForge",
///   "type": "contextforge-prompts",
///   "format": 1,
///   "exportedAt": "2026-08-24T...",
///   "prompts": [ { "id": "...", "title": "...", "content": "...", ... } ]
/// }
/// ```
///
/// Only user-created prompts are exported; the built-in catalogue is excluded
/// by the caller before invoking [exportPrompts].
class PromptTransferService {
  /// Suggested filename used by the native save dialog.
  static const suggestedFileName = 'ContextForge-Prompts.json';

  static const XTypeGroup _jsonTypeGroup = XTypeGroup(
    label: 'JSON',
    extensions: ['json'],
    uniformTypeIdentifiers: ['public.json'],
  );

  /// Serializes [prompts] to the portable JSON export format.
  String encode(List<Prompt> prompts, {DateTime? now}) {
    final exportedAt = (now ?? DateTime.now()).toUtc().toIso8601String();
    final payload = <String, dynamic>{
      'app': 'ContextForge',
      'type': 'contextforge-prompts',
      'format': 1,
      'exportedAt': exportedAt,
      'prompts': [for (final p in prompts) p.toJson()],
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Parses an exported JSON document back into a list of [Prompt]s.
  ///
  /// Accepts both the wrapped export format (a map containing a `prompts`
  /// list) and a bare list of prompt objects.
  ///
  /// Throws a [FormatException] when the content is not a valid, well-formed
  /// prompt file. Callers must handle this gracefully (it never crashes).
  List<Prompt> decode(String source) {
    try {
      final decoded = jsonDecode(source);
      final items = switch (decoded) {
        Map<String, dynamic> map when map['prompts'] is List => map['prompts']! as List,
        List list => list,
        _ => throw const FormatException('Not a valid prompt file.'),
      };
      final prompts = <Prompt>[];
      for (final item in items) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Malformed prompt entry.');
        }
        prompts.add(Prompt.fromJson(item));
      }
      return prompts;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Not a valid prompt file.');
    }
  }

  /// Opens the native macOS save dialog and writes [prompts] as JSON.
  ///
  /// Returns `true` when written successfully, `false` when the user
  /// cancelled. Throws on write errors.
  Future<bool> exportPrompts(List<Prompt> prompts) async {
    final location = await getSaveLocation(
      suggestedName: suggestedFileName,
      acceptedTypeGroups: const [_jsonTypeGroup],
    );
    if (location == null) {
      return false; // User cancelled.
    }
    await File(location.path).writeAsString(
      encode(prompts),
      encoding: utf8,
    );
    return true;
  }

  /// Opens the native macOS open dialog and reads a prompt file.
  ///
  /// Returns the parsed prompts, or `null` when the user cancelled.
  /// Throws a [FormatException] for malformed/invalid files.
  Future<List<Prompt>?> pickPrompts() async {
    final file = await openFile(acceptedTypeGroups: const [_jsonTypeGroup]);
    if (file == null) {
      return null; // User cancelled.
    }
    final source = await File(file.path).readAsString();
    return decode(source);
  }
}
