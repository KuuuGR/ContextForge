import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/models/prompt.dart';
import 'package:context_forge/pages/home_page.dart';
import 'package:context_forge/presentation/prompt_constants.dart';
import 'package:context_forge/repositories/in_memory_prompt_repository.dart';
import 'package:context_forge/services/prompt_service.dart';
import 'package:context_forge/services/video_history_service.dart';
import 'package:context_forge/widgets/prompt_selector.dart';

import 'helpers/in_memory_video_history_storage.dart';

void main() {
  late PromptService service;

  setUp(() {
    service = PromptService(repository: InMemoryPromptRepository());
  });

  group('PromptService workflow', () {
    test('ensureDefaultPrompts creates defaults once on empty storage', () async {
      await service.ensureDefaultPrompts();
      final prompts = await service.getAllPrompts();
      expect(
        prompts.map((p) => p.title),
        containsAll(['SEO Article', 'Newsletter', 'LinkedIn', 'Facebook']),
      );
    });

    test('ensureDefaultPrompts does not recreate when storage already has prompts',
        () async {
      await service.ensureDefaultPrompts();
      await service.createPrompt(title: 'Mine', content: 'x');
      await service.ensureDefaultPrompts();
      final prompts = await service.getAllPrompts();
      expect(prompts, hasLength(5));
    });

    test('does not overwrite existing user prompts with defaults', () async {
      await service.createPrompt(title: 'Mine', content: 'Custom content');
      await service.ensureDefaultPrompts();
      final prompts = await service.getAllPrompts();
      expect(prompts.map((p) => p.title), contains('Mine'));
      expect(prompts.map((p) => p.title), isNot(contains('SEO Article')));
    });

    test('loading prompts returns intended prompt content', () async {
      await service.ensureDefaultPrompts();
      final prompts = await service.getAllPrompts();
      final seo = prompts.firstWhere((p) => p.title == 'SEO Article');
      expect(seo.content, contains('SEO'));
      expect(seo, isA<Prompt>());
    });
  });

  group('PromptSelector widget', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('populates dropdown with prompts + custom option',
        (WidgetTester tester) async {
      await service.ensureDefaultPrompts();
      final prompts = await service.getAllPrompts();

      await tester.pumpWidget(
        wrap(PromptSelector(
          prompts: prompts,
          value: prompts.first.title,
          onChanged: (String _) {},
        )),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      for (final p in prompts) {
        expect(find.text(p.title).hitTestable(), findsWidgets);
      }
      expect(find.text(customPromptOption).hitTestable(), findsWidgets);
    });

    testWidgets('shows star icons for each prompt option',
        (WidgetTester tester) async {
      await service.ensureDefaultPrompts();
      final prompts = await service.getAllPrompts();
      await service.setFavorite(prompts.first.id, true);

      final updatedPrompts = await service.getAllPrompts();

      await tester.pumpWidget(
        wrap(PromptSelector(
          prompts: updatedPrompts,
          value: updatedPrompts.first.title,
          onChanged: (String _) {},
          onToggleFavorite: (Prompt _) {},
        )),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // The favorite prompt shows a filled star.
      expect(find.byIcon(Icons.star), findsWidgets);
      // Non-favorite prompts show outlined stars.
      expect(find.byIcon(Icons.star_border), findsWidgets);
    });

    testWidgets('shows Default badge on the default prompt',
        (WidgetTester tester) async {
      await service.ensureDefaultPrompts();
      final prompts = await service.getAllPrompts();
      await service.setDefault(prompts.first.id);

      final updatedPrompts = await service.getAllPrompts();

      await tester.pumpWidget(
        wrap(PromptSelector(
          prompts: updatedPrompts,
          value: updatedPrompts.first.title,
          onChanged: (String _) {},
          onToggleDefault: (Prompt _) {},
        )),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Default').hitTestable(), findsOneWidget);
    });
  });

  group('HomePage workflow', () {
    Widget buildHome() => MaterialApp(
          home: HomePage(
            promptService: service,
            videoHistoryService: VideoHistoryService(
              storage: InMemoryVideoHistoryStorage(),
            ),
          ),
        );

    testWidgets('loads and displays selected prompt content',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildHome());
      await tester.pumpAndSettle();

      final first = (await service.getAllPrompts()).first;
      expect(find.text(first.title), findsWidgets);
      expect(find.text(first.content), findsOneWidget);
    });

    testWidgets('auto-selects the Default prompt on launch',
        (WidgetTester tester) async {
      await service.ensureDefaultPrompts();
      final prompts = await service.getAllPrompts();
      // Make the last prompt the default.
      await service.setDefault(prompts.last.id);
      final updated = await service.getAllPrompts();

      await tester.pumpWidget(buildHome());
      await tester.pumpAndSettle();

      // The default prompt's content is shown in the editor.
      final defaultPrompt = updated.firstWhere((p) => p.isDefault);
      expect(find.text(defaultPrompt.content), findsOneWidget);

      // The selected dropdown shows the default prompt's title.
      expect(find.text(defaultPrompt.title), findsWidgets);
    });

    testWidgets('selects first prompt when no default exists',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildHome());
      await tester.pumpAndSettle();

      final first = (await service.getAllPrompts()).first;
      expect(find.text(first.content), findsOneWidget);
    });

    testWidgets('selecting Custom Prompt enables editing',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildHome());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(customPromptOption).last);
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.enabled, isTrue);
    });

    testWidgets('saved prompt content is read-only',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildHome());
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.readOnly, isTrue);
    });
  });
}