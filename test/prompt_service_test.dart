import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/exceptions/prompt_exceptions.dart';
import 'package:context_forge/repositories/json_prompt_repository.dart';
import 'package:context_forge/services/json_prompt_storage.dart';
import 'package:context_forge/services/prompt_service.dart';

void main() {
  late Directory tempDir;
  late PromptService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('contextforge_service_test_');
    final storage = JsonPromptStorage(directoryPath: tempDir.path);
    final repository = JsonPromptRepository(storage: storage);
    service = PromptService(repository: repository);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PromptService', () {
    test('createPrompt trims title and content', () async {
      final prompt = await service.createPrompt(
        title: '  SEO Article  ',
        content: '  Write an article about Flutter.  ',
      );

      expect(prompt.title, 'SEO Article');
      expect(prompt.content, 'Write an article about Flutter.');
    });

    test('createPrompt generates a UUID v4 id', () async {
      final prompt = await service.createPrompt(
        title: 'Newsletter',
        content: 'Content here',
      );

      final uuidPattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(uuidPattern.hasMatch(prompt.id), isTrue,
          reason: 'Expected a valid UUID v4, got: ${prompt.id}');
    });

    test('createPrompt generates a unique id for each prompt', () async {
      final first = await service.createPrompt(
        title: 'One',
        content: 'First',
      );
      final second = await service.createPrompt(
        title: 'Two',
        content: 'Second',
      );

      expect(first.id, isNot(second.id));
    });

    test('createPrompt sets createdAt and updatedAt', () async {
      final prompt = await service.createPrompt(
        title: 'SEO Article',
        content: 'Body',
      );

      expect(prompt.createdAt, isNotEmpty);
      expect(prompt.updatedAt, isNotEmpty);
      expect(prompt.createdAt, prompt.updatedAt);
    });

    test('createPrompt persists the prompt retrievable via getPrompt', () async {
      final created = await service.createPrompt(
        title: 'LinkedIn',
        content: 'Post for LinkedIn',
      );

      final loaded = await service.getPrompt(created.id);
      expect(loaded, created);
    });

    test('getAllPrompts returns all created prompts', () async {
      await service.createPrompt(title: 'One', content: 'First');
      await service.createPrompt(title: 'Two', content: 'Second');

      final prompts = await service.getAllPrompts();
      expect(prompts, hasLength(2));
    });

    test('getPrompt throws PromptNotFoundException for missing id', () async {
      expect(
        () => service.getPrompt('missing'),
        throwsA(isA<PromptNotFoundException>()),
      );
    });

    test('updatePrompt updates title and content', () async {
      final created = await service.createPrompt(
        title: 'Old Title',
        content: 'Old content',
      );

      final updated = await service.updatePrompt(
        id: created.id,
        title: 'New Title',
        content: 'New content',
      );

      expect(updated.title, 'New Title');
      expect(updated.content, 'New content');
      expect(updated.id, created.id);
      expect(updated.createdAt, created.createdAt);
    });

    test('updatePrompt refreshes updatedAt automatically', () async {
      final created = await service.createPrompt(
        title: 'Title',
        content: 'Content',
      );

      final updated = await service.updatePrompt(
        id: created.id,
        title: 'Updated Title',
        content: 'Updated content',
      );

      expect(updated.updatedAt, isNot(created.updatedAt));
    });

    test('updatePrompt throws PromptNotFoundException for missing id', () async {
      expect(
        () => service.updatePrompt(
          id: 'missing',
          title: 'Title',
          content: 'Content',
        ),
        throwsA(isA<PromptNotFoundException>()),
      );
    });

    test('deletePrompt removes the prompt', () async {
      final created = await service.createPrompt(
        title: 'Delete me',
        content: 'Temporary',
      );

      await service.deletePrompt(created.id);

      final prompts = await service.getAllPrompts();
      expect(prompts, isEmpty);
      expect(
        () => service.getPrompt(created.id),
        throwsA(isA<PromptNotFoundException>()),
      );
    });

    test('deletePrompt throws PromptNotFoundException for missing id', () async {
      expect(
        () => service.deletePrompt('missing'),
        throwsA(isA<PromptNotFoundException>()),
      );
    });

    group('favorites and default', () {
      test('setFavorite marks a prompt as favorite', () async {
        final created = await service.createPrompt(
          title: 'SEO Article',
          content: 'Content',
        );

        final updated = await service.setFavorite(created.id, true);
        expect(updated.isFavorite, isTrue);

        final loaded = await service.getPrompt(created.id);
        expect(loaded.isFavorite, isTrue);
      });

      test('setFavorite can unmark a favorite', () async {
        final created = await service.createPrompt(
          title: 'SEO Article',
          content: 'Content',
        );
        await service.setFavorite(created.id, true);
        final updated = await service.setFavorite(created.id, false);

        expect(updated.isFavorite, isFalse);
      });

      test('setFavorite persists across restart', () async {
        final created = await service.createPrompt(
          title: 'SEO Article',
          content: 'Content',
        );
        await service.setFavorite(created.id, true);

        // Simulate restart: fresh service reading the same file.
        final storage =
            JsonPromptStorage(directoryPath: tempDir.path);
        final repository = JsonPromptRepository(storage: storage);
        final restarted = PromptService(repository: repository);

        final loaded = await restarted.getPrompt(created.id);
        expect(loaded.isFavorite, isTrue);
      });

      test('getAllPrompts returns favorites first', () async {
        final a = await service.createPrompt(title: 'Alpha', content: 'A');
        final b = await service.createPrompt(title: 'Beta', content: 'B');
        final c = await service.createPrompt(title: 'Gamma', content: 'C');

        // Make the second and third favorites.
        await service.setFavorite(b.id, true);
        await service.setFavorite(c.id, true);

        final prompts = await service.getAllPrompts();
        expect(prompts.map((p) => p.title), ['Beta', 'Gamma', 'Alpha']);
        // Manual ordering preserved within favorites.
        expect(prompts[0].id, b.id);
        expect(prompts[1].id, c.id);
        // Manual ordering preserved within non-favorites.
        expect(prompts[2].id, a.id);
      });

      test('setDefault marks a prompt as the single default', () async {
        final a = await service.createPrompt(title: 'Alpha', content: 'A');
        final b = await service.createPrompt(title: 'Beta', content: 'B');

        await service.setDefault(b.id);

        final defaultPrompt = await service.getDefaultPrompt();
        expect(defaultPrompt, isNotNull);
        expect(defaultPrompt!.id, b.id);
        expect(defaultPrompt.isDefault, isTrue);

        // Only one prompt can be default.
        final prompts = await service.getAllPrompts();
        final defaults = prompts.where((p) => p.isDefault);
        expect(defaults, hasLength(1));
        expect(a.isDefault, isFalse);
      });

      test('setting a new default clears the previous one', () async {
        final a = await service.createPrompt(title: 'Alpha', content: 'A');
        final b = await service.createPrompt(title: 'Beta', content: 'B');

        await service.setDefault(a.id);
        await service.setDefault(b.id);

        final defaultPrompt = await service.getDefaultPrompt();
        expect(defaultPrompt!.id, b.id);

        final prompts = await service.getAllPrompts();
        final defaults = prompts.where((p) => p.isDefault);
        expect(defaults, hasLength(1));
      });

      test('clearDefault removes the default designation', () async {
        final created = await service.createPrompt(
          title: 'SEO Article',
          content: 'Content',
        );
        await service.setDefault(created.id);

        final cleared = await service.clearDefault(created.id);
        expect(cleared.isDefault, isFalse);

        final defaultPrompt = await service.getDefaultPrompt();
        expect(defaultPrompt, isNull);
      });

      test('default survives restart', () async {
        final created = await service.createPrompt(
          title: 'SEO Article',
          content: 'Content',
        );
        await service.setDefault(created.id);

        // Simulate restart: fresh service reading the same file.
        final storage =
            JsonPromptStorage(directoryPath: tempDir.path);
        final repository = JsonPromptRepository(storage: storage);
        final restarted = PromptService(repository: repository);

        final defaultPrompt = await restarted.getDefaultPrompt();
        expect(defaultPrompt, isNotNull);
        expect(defaultPrompt!.id, created.id);
      });

      test('setDefault throws PromptNotFoundException for missing id', () async {
        expect(
          () => service.setDefault('missing'),
          throwsA(isA<PromptNotFoundException>()),
        );
      });

      test('clearDefault throws PromptNotFoundException for missing id',
          () async {
        expect(
          () => service.clearDefault('missing'),
          throwsA(isA<PromptNotFoundException>()),
        );
      });

      test('getDefaultPrompt returns null when no default set', () async {
        await service.createPrompt(title: 'One', content: 'First');
        final defaultPrompt = await service.getDefaultPrompt();
        expect(defaultPrompt, isNull);
      });
    });

    group('validation', () {
      test('rejects empty title', () async {
        expect(
          () => service.createPrompt(title: '', content: 'Content'),
          throwsA(isA<PromptValidationException>()),
        );
      });

      test('rejects whitespace-only title', () async {
        expect(
          () => service.createPrompt(title: '   ', content: 'Content'),
          throwsA(isA<PromptValidationException>()),
        );
      });

      test('rejects empty content', () async {
        expect(
          () => service.createPrompt(title: 'Title', content: ''),
          throwsA(isA<PromptValidationException>()),
        );
      });

      test('rejects whitespace-only content', () async {
        expect(
          () => service.createPrompt(title: 'Title', content: ' \t\n '),
          throwsA(isA<PromptValidationException>()),
        );
      });

      test('updatePrompt rejects empty title', () async {
        final created = await service.createPrompt(
          title: 'Title',
          content: 'Content',
        );

        expect(
          () => service.updatePrompt(
            id: created.id,
            title: '   ',
            content: 'Content',
          ),
          throwsA(isA<PromptValidationException>()),
        );
      });

      test('updatePrompt rejects empty content', () async {
        final created = await service.createPrompt(
          title: 'Title',
          content: 'Content',
        );

        expect(
          () => service.updatePrompt(
            id: created.id,
            title: 'Title',
            content: '',
          ),
          throwsA(isA<PromptValidationException>()),
        );
      });

      test('validation failure does not persist anything', () async {
        expect(
          () => service.createPrompt(title: '', content: 'Content'),
          throwsA(isA<PromptValidationException>()),
        );

        final prompts = await service.getAllPrompts();
        expect(prompts, isEmpty);
      });
    });
  });
}