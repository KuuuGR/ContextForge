import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/models/prompt.dart';
import 'package:context_forge/services/prompt_transfer_service.dart';

void main() {
  const sample = Prompt(
    id: 'p1',
    title: 'My Prompt',
    content: 'My content',
    rating: 1,
    isFavorite: true,
    isBuiltIn: false,
    createdAt: '2026-02-08T10:00:00Z',
    updatedAt: '2026-02-08T10:00:00Z',
  );

  final service = PromptTransferService();

  group('PromptTransferService.encode', () {
    test('produces a JSON document with metadata and prompts', () {
      final source = service.encode([sample], now: DateTime.utc(2026, 8, 24));
      final decoded = jsonDecode(source) as Map<String, dynamic>;
      expect(decoded['app'], 'ContextForge');
      expect(decoded['type'], 'contextforge-prompts');
      expect(decoded['format'], 1);
      expect(decoded['exportedAt'], isNotEmpty);
      expect(decoded['prompts'], hasLength(1));
    });

    test('round-trips through decode', () {
      final source = service.encode([sample]);
      final restored = service.decode(source);
      expect(restored, [sample]);
    });
  });

  group('PromptTransferService.decode', () {
    test('accepts a bare list of prompt objects', () {
      final source = const JsonEncoder()
          .convert([sample.toJson()]);
      final restored = service.decode(source);
      expect(restored, [sample]);
    });

    test('throws FormatException for invalid JSON', () {
      expect(() => service.decode('{ not json'), throwsFormatException);
    });

    test('throws FormatException for a non-map, non-list document', () {
      expect(() => service.decode('42'), throwsFormatException);
    });

    test('throws FormatException for a map without a prompts list', () {
      expect(() => service.decode('{"hello": 1}'), throwsFormatException);
    });

    test('throws FormatException for malformed prompt entries', () {
      expect(
        () => service.decode(
            const JsonEncoder().convert({'prompts': [42]})),
        throwsFormatException,
      );
    });
  });
}
