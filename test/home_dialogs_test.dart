import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/pages/home_page.dart';
import 'package:context_forge/repositories/in_memory_prompt_repository.dart';
import 'package:context_forge/services/prompt_service.dart';
import 'package:context_forge/services/video_history_service.dart';

import 'helpers/in_memory_video_history_storage.dart';

/// Regression coverage for the footer dialogs (About / Shortcuts / Help).
///
/// These dialogs used to rely on emoji glyphs that are missing from the iOS
/// system font fallback (rendering as empty boxes). They now use Material
/// icons, so this file also guards the dialogs against layout regressions.
void main() {
  late PromptService service;

  setUp(() {
    service = PromptService(repository: InMemoryPromptRepository());
  });

  Widget buildHome() => MaterialApp(
        home: HomePage(
          promptService: service,
          videoHistoryService: VideoHistoryService(
            storage: InMemoryVideoHistoryStorage(),
          ),
        ),
      );

  Future<void> openFooterDialog(WidgetTester tester, String label) async {
    await tester.pumpWidget(buildHome());
    await tester.pumpAndSettle();

    final button = find.text(label);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('About dialog renders the feedback actions', (tester) async {
    await openFooterDialog(tester, 'About');

    expect(find.text('Suggest an Idea'), findsOneWidget);
    expect(find.text('Report a Bug'), findsOneWidget);
    expect(find.text('General Feedback'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shortcuts dialog explains the macOS keyboard support',
      (tester) async {
    await openFooterDialog(tester, 'Shortcuts');

    expect(
      find.textContaining('work best in the macOS app'),
      findsOneWidget,
    );
    expect(find.textContaining('⌘V'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Help dialog renders the Quick Access legend', (tester) async {
    await openFooterDialog(tester, 'Help');

    expect(find.text('Favorite prompt.'), findsOneWidget);
    expect(find.textContaining('Default prompt.'), findsOneWidget);
    expect(find.textContaining('Quick Workflow.'), findsOneWidget);
    expect(find.textContaining('Quick Prompt Slots.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
