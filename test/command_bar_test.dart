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
import 'package:context_forge/widgets/command_bar.dart';
import 'package:context_forge/widgets/prompt_editor.dart';
import 'package:context_forge/widgets/video_input_card.dart';

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
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final promptService = PromptService(
      repository: InMemoryPromptRepository(),
    );
    await promptService.ensureDefaultPrompts();

    await tester.pumpWidget(
      ContextForgeApp(
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

  void mockClipboard(WidgetTester tester, String text) {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return {'text': text};
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });
  }

  testWidgets('Command bar renders with all three rows',
      (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.byType(CommandBar), findsOneWidget);
    // Row 1: ⚡ Quick Workflow (disabled)
    expect(find.byIcon(Icons.bolt_outlined), findsOneWidget);
    // Row 2: ① ② ③ slots
    expect(find.text('①'), findsOneWidget);
    expect(find.text('②'), findsOneWidget);
    expect(find.text('③'), findsOneWidget);
    // Row 3: Paste/Generate/Copy inside the command bar
    final commandBarPaste = find.descendant(
      of: find.byType(CommandBar),
      matching: find.byIcon(Icons.content_paste),
    );
    expect(commandBarPaste, findsOneWidget);
    final commandBarGenerate = find.descendant(
      of: find.byType(CommandBar),
      matching: find.byIcon(Icons.play_arrow),
    );
    expect(commandBarGenerate, findsOneWidget);
    final commandBarCopy = find.descendant(
      of: find.byType(CommandBar),
      matching: find.byIcon(Icons.copy),
    );
    expect(commandBarCopy, findsOneWidget);
  });

  testWidgets('Quick prompt slot changes the selected prompt',
      (WidgetTester tester) async {
    await pumpApp(tester);

    // Capture the initially displayed prompt content in the editor.
    final editorBefore = tester.widget<TextField>(
      find.descendant(
        of: find.byType(PromptEditor),
        matching: find.byType(TextField),
      ),
    );
    final beforeText = editorBefore.controller?.text ?? '';
    expect(beforeText, isNotEmpty);

    // Tap ② slot which should select the second prompt.
    await tester.tap(find.text('②'));
    await tester.pumpAndSettle();

    // The editor content should change to reflect the second prompt.
    final editorAfter = tester.widget<TextField>(
      find.descendant(
        of: find.byType(PromptEditor),
        matching: find.byType(TextField),
      ),
    );
    final afterText = editorAfter.controller?.text ?? '';
    expect(afterText, isNot(beforeText));
    expect(afterText, isNotEmpty);
  });

  testWidgets('Generate button in command bar generates output',
      (WidgetTester tester) async {
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

    // Find the command bar generate button (the play_arrow in the CommandBar).
    final commandBarGenerate = find.descendant(
      of: find.byType(CommandBar),
      matching: find.byIcon(Icons.play_arrow),
    );
    await tester.tap(commandBarGenerate);
    await tester.pumpAndSettle();

    // Output was generated.
    final outputField = tester.widget<TextField>(find.byType(TextField).last);
    expect(outputField.controller!.text, isNotEmpty);
    expect(outputField.controller!.text, contains('Transcript 1'));
  });

  testWidgets('Copy button in command bar is disabled when output is empty',
      (WidgetTester tester) async {
    await pumpApp(tester);

    // Find the Copy button in the command bar.
    final commandBarCopy = find.descendant(
      of: find.byType(CommandBar),
      matching: find.widgetWithIcon(IconButton, Icons.copy),
    );
    expect(commandBarCopy, findsOneWidget);

    final copyButton = tester.widget<IconButton>(commandBarCopy);
    expect(copyButton.onPressed, isNull);
  });

  testWidgets('Paste button in command bar performs smart paste',
      (WidgetTester tester) async {
    mockClipboard(
        tester, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
    await pumpApp(tester);

    // Verify all slots are empty.
    expect(find.text('Empty'), findsNWidgets(3));

    // Find the paste button in the command bar.
    final commandBarPaste = find.descendant(
      of: find.byType(CommandBar),
      matching: find.byIcon(Icons.content_paste),
    );
    await tester.tap(commandBarPaste);
    await tester.pumpAndSettle();

    // First slot is filled and validated.
    final firstUrlField = find.descendant(
      of: find.byType(VideoInputCard).first,
      matching: find.byType(TextField),
    );
    final field = tester.widget<TextField>(firstUrlField);
    expect(field.controller!.text, isNotEmpty);
    expect(find.text('First Video'), findsOneWidget);
  });
}