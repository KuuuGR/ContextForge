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

    testWidgets('shows friendly empty state when no prompts',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(PromptSelector(
          prompts: const [],
          value: customPromptOption,
          onChanged: (String _) {},
        )),
      );
      expect(find.textContaining('No saved prompts'), findsOneWidget);
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