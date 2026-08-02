import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/models/prompt.dart';
import 'package:context_forge/repositories/json_prompt_repository.dart';
import 'package:context_forge/services/json_prompt_storage.dart';

void main() {
  late Directory tempDir;
  late JsonPromptStorage storage;
  late JsonPromptRepository repository;

  const samplePrompt = Prompt(
    id: 'p1',
    title: 'SEO Article',
    content: 'Write an SEO article about...',
    rating: 0,
    createdAt: '2026-02-08T10:00:00Z',
    updatedAt: '2026-02-08T10:00:00Z',
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('contextforge_test_');
    storage = JsonPromptStorage(directoryPath: tempDir.path);
    repository = JsonPromptRepository(storage: storage);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  File promptsFile() => File('${tempDir.path}${Platform.pathSeparator}prompts.json');

  group('JsonPromptRepository', () {
    test('getAll returns empty list when file is missing', () async {
      final prompts = await repository.getAll();
      expect(prompts, isEmpty);
      // File is auto-created with an empty list.
      expect(await promptsFile().exists(), isTrue);
      expect(await promptsFile().readAsString(), '[]');
    });

    test('getAll returns empty list when file is empty', () async {
      await promptsFile().writeAsString('');
      final prompts = await repository.getAll();
      expect(prompts, isEmpty);
    });

    test('getAll returns empty list when file is invalid JSON', () async {
      await promptsFile().writeAsString('{ not valid json');
      final prompts = await repository.getAll();
      expect(prompts, isEmpty);
    });

    test('save persists prompt and file is human-readable JSON', () async {
      await repository.save(samplePrompt);

      final loaded = await repository.getAll();
      expect(loaded, [samplePrompt]);

      final raw = await promptsFile().readAsString();
      expect(raw, contains('"title": "SEO Article"'));
      expect(raw, contains('"id": "p1"'));
      // Uses indented JSON for readability (object nested in array).
      expect(raw, contains('\n    "id"'));
    });

    test('load reads prompts previously written to file', () async {
      final jsonList = [
        samplePrompt.toJson(),
        const Prompt(
          id: 'p2',
          title: 'Newsletter',
          content: 'Write a newsletter...',
          rating: 3,
          createdAt: '2026-02-08T11:00:00Z',
          updatedAt: '2026-02-08T11:00:00Z',
        ).toJson(),
      ];
      await promptsFile().writeAsString(const JsonEncoder.withIndent('  ').convert(jsonList));

      final prompts = await repository.getAll();
      expect(prompts, hasLength(2));
      expect(prompts.first.id, 'p1');
      expect(prompts.last.id, 'p2');
    });

    test('getById returns prompt when found', () async {
      await repository.save(samplePrompt);
      final result = await repository.getById('p1');
      expect(result, samplePrompt);
    });

    test('getById returns null when not found', () async {
      await repository.save(samplePrompt);
      final result = await repository.getById('missing');
      expect(result, isNull);
    });

    test('save updates existing prompt with same id', () async {
      await repository.save(samplePrompt);
      final updated = samplePrompt.copyWith(content: 'Updated content');
      await repository.save(updated);

      final prompts = await repository.getAll();
      expect(prompts, hasLength(1));
      expect(prompts.single.content, 'Updated content');
    });

    test('delete removes prompt', () async {
      await repository.save(samplePrompt);
      await repository.delete('p1');

      final prompts = await repository.getAll();
      expect(prompts, isEmpty);
    });

    test('delete is a no-op for missing id', () async {
      await repository.save(samplePrompt);
      await repository.delete('missing');

      final prompts = await repository.getAll();
      expect(prompts, [samplePrompt]);
    });
  });
}