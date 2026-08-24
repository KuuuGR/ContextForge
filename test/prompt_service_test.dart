import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/exceptions/prompt_exceptions.dart';
import 'package:context_forge/models/prompt.dart';
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

    group('user prompts and built-ins', () {
      test('ensureDefaultPrompts seeds built-in prompts', () async {
        await service.ensureDefaultPrompts();
        final prompts = await service.getAllPrompts();
        expect(prompts, isNotEmpty);
        expect(prompts.every((p) => p.isBuiltIn), isTrue);
      });

      test('createPrompt produces a user prompt (not built-in)', () async {
        final created = await service.createPrompt(
            title: 'Mine', content: 'Custom content');
        expect(created.isBuiltIn, isFalse);
      });

      test('getUserPrompts excludes built-in prompts', () async {
        await service.ensureDefaultPrompts();
        final created = await service.createPrompt(
            title: 'Mine', content: 'Custom content');
        final userPrompts = await service.getUserPrompts();
        expect(userPrompts, hasLength(1));
        expect(userPrompts.single.id, created.id);
      });

      test('legacy 1.0.0 prompt (no isBuiltIn flag) becomes a user prompt',
          () async {
        // Simulate a prompt stored by 1.0.0, which predates the isBuiltIn
        // flag. It must NOT be treated as a built-in: it is a user prompt and
        // is included in the user's exported collection.
        await service.repository.save(
          Prompt.fromJson({
            'id': 'legacy',
            'title': 'Legacy',
            'content': 'Old content',
            'rating': 0,
            'isFavorite': false,
            'isDefault': false,
            'quickAccess': 'none',
            'createdAt': '2026-01-01T00:00:00Z',
            'updatedAt': '2026-01-01T00:00:00Z',
          }),
        );

        final all = await service.getAllPrompts();
        expect(all.single.isBuiltIn, isFalse);

        final userPrompts = await service.getUserPrompts();
        expect(userPrompts.map((p) => p.id), contains('legacy'));
      });
    });

    group('intelligent import', () {
      Prompt userPrompt({
        required String id,
        required String title,
        String content = 'Content',
      }) {
        return Prompt(
          id: id,
          title: title,
          content: content,
          rating: 0,
          createdAt: '2026-01-01T00:00:00Z',
          updatedAt: '2026-01-01T00:00:00Z',
        );
      }

      test('new prompt with no equivalent is added automatically', () async {
        final imported =
            userPrompt(id: 'n1', title: 'New', content: 'Brand new');
        final plan = await service.analyzeImport([imported]);
        expect(plan.newPrompts, [imported]);
        expect(plan.identical, isEmpty);
        expect(plan.conflicts, isEmpty);

        final result = await service.applyImport(plan);
        expect(result.newAddedCount, 1);
        expect(result.alreadyExistedCount, 0);
        expect(result.conflictCount, 0);

        final prompts = await service.getAllPrompts();
        expect(prompts, hasLength(1));
        expect(prompts.single.title, 'New');
        expect(prompts.single.content, 'Brand new');
        expect(prompts.single.isBuiltIn, isFalse);
      });

      test('identical prompt is ignored (no duplicate, no overwrite)',
          () async {
        await service.repository
            .save(userPrompt(id: 'e1', title: 'Same', content: 'C1'));
        final imported = userPrompt(id: 'e1', title: 'Same', content: 'C1');

        final plan = await service.analyzeImport([imported]);
        expect(plan.identical, hasLength(1));
        expect(plan.newPrompts, isEmpty);
        expect(plan.conflicts, isEmpty);

        final result = await service.applyImport(plan);
        expect(result.newAddedCount, 0);
        expect(result.alreadyExistedCount, 1);

        final prompts = await service.getAllPrompts();
        expect(prompts, hasLength(1)); // no duplicate
        expect(prompts.single.id, 'e1');
      });

      test('same title but different content is a conflict', () async {
        await service.repository
            .save(userPrompt(id: 'e1', title: 'Same', content: 'Old content'));
        final imported =
            userPrompt(id: 'other', title: 'Same', content: 'New content');

        final plan = await service.analyzeImport([imported]);
        expect(plan.conflicts, hasLength(1));
        expect(plan.newPrompts, isEmpty);
        expect(plan.identical, isEmpty);
        expect(plan.conflicts.single.existing.id, 'e1');
        expect(plan.conflicts.single.imported.id, 'other');
      });

      test('conflict resolved as Add as New adds without overwriting',
          () async {
        await service.repository
            .save(userPrompt(id: 'e1', title: 'Same', content: 'Old content'));
        final imported =
            userPrompt(id: 'other', title: 'Same', content: 'New content');

        final plan = await service.analyzeImport([imported]);
        plan.conflicts.single.resolution = PromptConflictResolution.addNew;

        final result = await service.applyImport(plan);
        expect(result.newAddedCount, 1);

        final prompts = await service.getAllPrompts();
        expect(prompts, hasLength(2));
        // The existing prompt is untouched.
        final existing = prompts.firstWhere((p) => p.id == 'e1');
        expect(existing.content, 'Old content');
        // The new prompt is added with a unique (suffixed) title.
        final added = prompts.firstWhere((p) => p.id == 'other');
        expect(added.title, 'Same (2)');
        expect(added.content, 'New content');
      });

      test('conflict resolved as Overwrite replaces existing content',
          () async {
        await service.repository
            .save(userPrompt(id: 'e1', title: 'Same', content: 'Old content'));
        final imported =
            userPrompt(id: 'other', title: 'Same', content: 'New content');

        final plan = await service.analyzeImport([imported]);
        plan.conflicts.single.resolution = PromptConflictResolution.overwrite;

        final result = await service.applyImport(plan);
        expect(result.newAddedCount, 0);

        final prompts = await service.getAllPrompts();
        expect(prompts, hasLength(1)); // nothing new added
        expect(prompts.single.id, 'e1'); // identity preserved
        expect(prompts.single.content, 'New content');
      });

      test('conflict resolved as Skip leaves everything unchanged', () async {
        await service.repository
            .save(userPrompt(id: 'e1', title: 'Same', content: 'Old content'));
        final imported =
            userPrompt(id: 'other', title: 'Same', content: 'New content');

        final plan = await service.analyzeImport([imported]);
        plan.conflicts.single.resolution = PromptConflictResolution.skip;

        final result = await service.applyImport(plan);
        expect(result.newAddedCount, 0);

        final prompts = await service.getAllPrompts();
        expect(prompts, hasLength(1));
        expect(prompts.single.content, 'Old content');
      });

      test('importing the same exported file twice adds no duplicates',
          () async {
        final file = [
          userPrompt(id: 'a', title: 'A', content: 'A content'),
          userPrompt(id: 'b', title: 'B', content: 'B content'),
        ];

        // First import: both are new.
        final firstPlan = await service.analyzeImport(file);
        expect(firstPlan.newPrompts, hasLength(2));
        final firstResult = await service.applyImport(firstPlan);
        expect(firstResult.newAddedCount, 2);
        expect(await service.getAllPrompts(), hasLength(2));

        // Second import of the same file: both are identical.
        final secondPlan = await service.analyzeImport(file);
        expect(secondPlan.identical, hasLength(2));
        expect(secondPlan.newPrompts, isEmpty);
        final secondResult = await service.applyImport(secondPlan);
        expect(secondResult.newAddedCount, 0);
        expect(secondResult.alreadyExistedCount, 2);
        expect(await service.getAllPrompts(), hasLength(2)); // no duplicates
      });

      test('imported prompts persist across a restart', () async {
        final imported =
            userPrompt(id: 'p', title: 'Persistent', content: 'Body');
        final plan = await service.analyzeImport([imported]);
        await service.applyImport(plan);

        // Simulate restart: fresh service reading the same file.
        final storage = JsonPromptStorage(directoryPath: tempDir.path);
        final repository = JsonPromptRepository(storage: storage);
        final restarted = PromptService(repository: repository);
        final prompts = await restarted.getAllPrompts();
        expect(prompts.single.title, 'Persistent');
        expect(prompts.single.isBuiltIn, isFalse);
      });
    });
  });
}