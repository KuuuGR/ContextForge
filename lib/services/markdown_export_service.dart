import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';

/// Exports generated output as a Markdown document using the native
/// macOS Save dialog.
class MarkdownExportService {
  /// Default export filename pattern: `ContextForge-YYYY-MM-DD-HHMM.md`.
  String defaultFileName([DateTime? now]) {
    final t = (now ?? DateTime.now()).toLocal();
    final y = t.year.toString().padLeft(4, '0');
    final mo = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    final h = t.hour.toString().padLeft(2, '0');
    final mi = t.minute.toString().padLeft(2, '0');
    return 'ContextForge-$y-$mo-$d-$h$mi.md';
  }

  /// Opens the native Save dialog and writes [content] as UTF-8 Markdown.
  ///
  /// Returns `true` when the file was written successfully, `false` when
  /// the user cancelled the dialog.
  ///
  /// Content is exported exactly as provided — headings, spacing, blank
  /// lines, and formatting are preserved byte-for-byte.
  Future<bool> exportMarkdown(
    String content, {
    DateTime? now,
  }) async {
    final fileName = defaultFileName(now);
    const typeGroup = XTypeGroup(
      label: 'Markdown',
      extensions: ['md'],
      uniformTypeIdentifiers: ['net.daringfireball.markdown'],
    );

    final location = await getSaveLocation(
      suggestedName: fileName,
      acceptedTypeGroups: const [typeGroup],
    );
    if (location == null) {
      return false; // User cancelled.
    }

    await File(location.path).writeAsString(content, encoding: utf8);
    return true;
  }
}