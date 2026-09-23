import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/models/ai_destination.dart';
import 'package:context_forge/services/destination_store.dart';
import 'package:context_forge/widgets/destination_selector.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('cf_destination_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('Destination dialog renders the full destination list',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DestinationSelector(
            destinationStore: DestinationStore(directoryPath: tempDir.path),
          ),
        ),
      ),
    );

    // Real file IO inside `_openMenu` needs `runAsync`, otherwise the awaited
    // `loadFavoriteIds()` never resolves and the dialog never opens.
    await tester.runAsync(() async {
      await tester.tap(find.text('Destination'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(defaultDestinations.length));
    expect(find.text('ChatGPT'), findsOneWidget);
    expect(find.text('Claude'), findsOneWidget);
    expect(find.text('Bielik'), findsOneWidget);
  });
}
