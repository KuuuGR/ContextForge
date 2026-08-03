import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/app/app.dart';

void main() {
  testWidgets('Main window renders all sections', (WidgetTester tester) async {
    await tester.pumpWidget(const ContextForgeApp());

    // Header
    expect(find.text('ContextForge'), findsOneWidget);
    expect(
        find.text('Build AI-ready context from YouTube transcripts.'),
        findsOneWidget);

    // Prompt section
    expect(find.text('Prompt'), findsOneWidget);
    expect(find.text('SEO Article'), findsOneWidget);

    // Videos section: 3 cards, all initially Empty
    expect(find.text('Videos'), findsOneWidget);
    expect(find.text('YouTube URL'), findsNWidgets(3));
    expect(find.text('Empty'), findsNWidgets(3));

    // Output section (header + text field label)
    expect(find.text('Output'), findsNWidgets(2));
    expect(
        find.text('Generated output will appear here.'), findsOneWidget);

    // Bottom toolbar buttons are disabled
    expect(find.text('Generate'), findsNWidgets(2)); // output section + toolbar
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);

    final filledButtons =
        tester.widgetList<FilledButton>(find.byType(FilledButton));
    for (final button in filledButtons) {
      expect(button.onPressed, isNull);
    }
  });
}