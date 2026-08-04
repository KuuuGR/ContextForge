import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/services/markdown_export_service.dart';

void main() {
  group('MarkdownExportService', () {
    test('defaultFileName produces ContextForge-YYYY-MM-DD-HHMM.md',
        () {
      final service = MarkdownExportService();
      final name = service.defaultFileName(DateTime(2026, 8, 4, 14, 5));

      expect(name, 'ContextForge-2026-08-04-1405.md');
    });

    test('defaultFileName pads single-digit month/day/hour/minute',
        () {
      final service = MarkdownExportService();
      final name = service.defaultFileName(DateTime(2026, 1, 2, 3, 4));

      expect(name, 'ContextForge-2026-01-02-0304.md');
    });

    test('defaultFileName defaults to current local time', () {
      final service = MarkdownExportService();
      final name = service.defaultFileName();

      final now = DateTime.now();
      final y = now.year.toString().padLeft(4, '0');
      final mo = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');
      final h = now.hour.toString().padLeft(2, '0');
      final mi = now.minute.toString().padLeft(2, '0');

      expect(name, 'ContextForge-$y-$mo-$d-$h$mi.md');
    });
  });
}