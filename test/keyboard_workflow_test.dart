import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/app/app.dart';
import 'package:context_forge/models/transcript_language.dart';
import 'package:context_forge/providers/youtube_provider.dart';
import 'package:context_forge/providers/youtube_transcript.dart';
import 'package:context_forge/providers/youtube_transcript_info.dart';
import 'package:context_forge/providers/youtube_video_metadata.dart';
import 'package:context_forge/repositories/in_memory_prompt_repository.dart';
import 'package:context_forge/repositories/in_memory_video_repository.dart';
import 'package:context_forge/services/prompt_service.dart';
import 'package:context_forge/services/video_history_service.dart';
import 'package:context_forge/services/video_service.dart';
import 'package:context_forge/widgets/generate_button.dart';
import 'package:context_forge/widgets/video_input_card.dart';

import 'helpers/in_memory_first_launch_intro_store.dart';
import 'helpers/in_memory_video_history_storage.dart';

/// Fake provider producing output for one known video.
class _FakeProvider implements YoutubeProvider {
  static const videoId = 'dQw4w9WgXcQ';

  @override
  Future<YoutubeVideoMetadata?> getVideoMetadata(String videoId) async {
    if (videoId == _FakeProvider.videoId) {
      return YoutubeVideoMetadata(
        videoId: videoId,
        title: 'First Video',
        channelName: 'Tech Channel',
        publishedAt: DateTime.utc(2025, 1, 15),
        duration: const Duration(minutes: 1),
        url: 'https://www.youtube.com/watch?v=$videoId',
      );
    }
    return null;
  }

  @override
  Future<List<YoutubeTranscriptInfo>> getAvailableTranscripts(
    String videoId,
  ) async {
    if (videoId == _FakeProvider.videoId) {
      return const [
        YoutubeTranscriptInfo(
          language: TranscriptLanguage.polish,
          isManual: true,
          languageName: 'Polish',
          languageCode: 'pl',
        ),
      ];
    }
    return const [];
  }

  @override
  Future<YoutubeTranscript?> downloadTranscript(
    String videoId,
    YoutubeTranscriptInfo info,
  ) async {
    if (videoId == _FakeProvider.videoId) {
      return YoutubeTranscript(
        videoId: videoId,
        info: info,
        segments: const [
          YoutubeTranscriptSegment(
            offset: Duration(seconds: 0),
            duration: Duration(seconds: 3),
            text: 'Hello world from transcript.',
          ),
        ],
      );
    }
    return null;
  }
}

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final promptService = PromptService(
      repository: InMemoryPromptRepository(),
    );
    await promptService.ensureDefaultPrompts();

    await tester.pumpWidget(
      ContextForgeApp(
        introStore: InMemoryFirstLaunchIntroStore(),
        promptService: promptService,
        videoService: VideoService(
          repository: InMemoryVideoRepository(),
          provider: _FakeProvider(),
        ),
        videoHistoryService: VideoHistoryService(
          storage: InMemoryVideoHistoryStorage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> mockClipboard(WidgetTester tester) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') return null;
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });
  }

  testWidgets('Enter in URL field moves to next URL field',
      (WidgetTester tester) async {
    await pumpApp(tester);

    // Focus the first URL field.
    final firstUrlField = find.descendant(
      of: find.byType(VideoInputCard).first,
      matching: find.byType(TextField),
    );
    await tester.tap(firstUrlField);
    await tester.pump();

    // Verify our first field has focus.
    final firstEditable = tester.widget<EditableText>(
      find.descendant(
        of: firstUrlField,
        matching: find.byType(EditableText),
      ),
    );
    expect(firstEditable.focusNode.hasFocus, isTrue);

    // Press Enter — should move to the next URL field.
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    final secondUrlField = find.descendant(
      of: find.byType(VideoInputCard).at(1),
      matching: find.byType(TextField),
    );
    final secondEditable = tester.widget<EditableText>(
      find.descendant(
        of: secondUrlField,
        matching: find.byType(EditableText),
      ),
    );
    expect(secondEditable.focusNode.hasFocus, isTrue);
  });

  testWidgets('Enter on last URL field triggers Generate',
      (WidgetTester tester) async {
    await pumpApp(tester);

    // Enter a URL in the first field and press Enter on the last field.
    final firstUrlField = find.descendant(
      of: find.byType(VideoInputCard).first,
      matching: find.byType(TextField),
    );
    await tester.enterText(
      firstUrlField,
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    );
    await tester.pump();

    // Focus the last URL field.
    final lastUrlField = find.descendant(
      of: find.byType(VideoInputCard).at(2),
      matching: find.byType(TextField),
    );
    await tester.tap(lastUrlField);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Generate should have run and produced output.
    final outputField = tester.widget<TextField>(find.byType(TextField).last);
    expect(outputField.controller!.text, isNotEmpty);
  });

  testWidgets('Cmd+Enter generates output', (WidgetTester tester) async {
    await pumpApp(tester);

    // Enter a URL.
    final firstUrlField = find.descendant(
      of: find.byType(VideoInputCard).first,
      matching: find.byType(TextField),
    );
    await tester.enterText(
      firstUrlField,
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    );
    await tester.pump();

    // Press Cmd+Enter.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle();

    // Output was generated.
    final outputField = tester.widget<TextField>(find.byType(TextField).last);
    expect(outputField.controller!.text, isNotEmpty);
    expect(outputField.controller!.text, contains('Transcript 1'));
  });

  testWidgets('Cmd+Backspace clears the session', (WidgetTester tester) async {
    await pumpApp(tester);

    // Enter a URL and generate output.
    final firstUrlField = find.descendant(
      of: find.byType(VideoInputCard).first,
      matching: find.byType(TextField),
    );
    await tester.enterText(
      firstUrlField,
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    );
    await tester.pump();
    await tester.tap(find.byType(GenerateButton));
    await tester.pumpAndSettle();

    // Verify output is non-empty.
    final outputField = tester.widget<TextField>(find.byType(TextField).last);
    expect(outputField.controller!.text, isNotEmpty);

    // Press Cmd+Backspace.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle();

    // Output and URL are cleared.
    final clearedOutput =
        tester.widget<TextField>(find.byType(TextField).last);
    expect(clearedOutput.controller!.text, isEmpty);
    expect(find.text('Empty'), findsNWidgets(3));
  });

  testWidgets('Cmd+C copies when output has focus',
      (WidgetTester tester) async {
    await mockClipboard(tester);
    await pumpApp(tester);

    // Enter a URL and generate.
    final firstUrlField = find.descendant(
      of: find.byType(VideoInputCard).first,
      matching: find.byType(TextField),
    );
    await tester.enterText(
      firstUrlField,
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    );
    await tester.pump();
    await tester.tap(find.byType(GenerateButton));
    await tester.pumpAndSettle();

    // Focus the output field.
    final outputField = find.byType(TextField).last;
    await tester.tap(outputField);
    await tester.pump();

    // Press Cmd+C.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pump();

    // Confirmation snackbar shown.
    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets('Escape removes focus', (WidgetTester tester) async {
    await pumpApp(tester);

    // Focus the first URL field.
    final firstUrlField = find.descendant(
      of: find.byType(VideoInputCard).first,
      matching: find.byType(TextField),
    );
    await tester.tap(firstUrlField);
    await tester.pump();

    final firstEditable = tester.widget<EditableText>(
      find.descendant(
        of: firstUrlField,
        matching: find.byType(EditableText),
      ),
    );
    expect(firstEditable.focusNode.hasFocus, isTrue);

    // Press Escape.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    // Focus is removed.
    expect(firstEditable.focusNode.hasFocus, isFalse);
  });
}