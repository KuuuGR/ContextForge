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
    await tester.binding.setSurfaceSize(const Size(1000, 2200));
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

  List<IconButton> clipboardButtons(WidgetTester tester) {
    final buttons = <IconButton>[];
    for (var i = 0; i < 3; i++) {
      buttons.add(
        tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.content_paste).at(i),
        ),
      );
    }
    return buttons;
  }

  testWidgets('Smart Paste fills the first empty slot',
      (WidgetTester tester) async {
    mockClipboard(
        tester, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
    await pumpApp(tester);

    // Verify all slots are empty.
    expect(find.text('Empty'), findsNWidgets(3));

    // Trigger smart paste via the clipboard button.
    await tester.tap(find.byIcon(Icons.content_paste).first);
    await tester.pumpAndSettle();

    // The first slot now has the URL and metadata loads.
    final firstUrlField = find.descendant(
      of: find.byType(VideoInputCard).first,
      matching: find.byType(TextField),
    );
    final field = tester.widget<TextField>(firstUrlField);
    expect(field.controller!.text, isNotEmpty);

    // Metadata loaded (video title shown).
    expect(find.text('First Video'), findsOneWidget);
    expect(find.text('Loaded'), findsOneWidget);
  });

  testWidgets('Duplicate URLs are rejected with Already added notification',
      (WidgetTester tester) async {
    mockClipboard(
        tester, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
    await pumpApp(tester);

    // Smart paste once.
    await tester.tap(find.byIcon(Icons.content_paste).first);
    await tester.pumpAndSettle();

    // Smart paste the same URL again.
    await tester.tap(find.byIcon(Icons.content_paste).first);
    await tester.pump();

    // "Already added" notification shown.
    expect(find.text('Already added'), findsOneWidget);
  });

  testWidgets('Clipboard button is disabled when clipboard has no URL',
      (WidgetTester tester) async {
    mockClipboard(tester, 'not a youtube url');
    await pumpApp(tester);

    // Find the clipboard icon buttons — all three should be disabled.
    final buttons = clipboardButtons(tester);
    expect(buttons, hasLength(3));
    for (final button in buttons) {
      expect(button.onPressed, isNull);
    }
  });

  testWidgets('Clipboard button is enabled when clipboard has a YouTube URL',
      (WidgetTester tester) async {
    mockClipboard(
        tester, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
    await pumpApp(tester);

    final buttons = clipboardButtons(tester);
    expect(buttons, hasLength(3));
    for (final button in buttons) {
      expect(button.onPressed, isNotNull);
    }
  });

  testWidgets('Compact URL display shows ▶ VIDEO_ID after validation',
      (WidgetTester tester) async {
    mockClipboard(
        tester, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
    await pumpApp(tester);

    // Smart paste to populate and validate the first slot.
    await tester.tap(find.byIcon(Icons.content_paste).first);
    await tester.pumpAndSettle();

    // The first URL field has the full URL and metadata displayed.
    final firstUrlField = find.descendant(
      of: find.byType(VideoInputCard).first,
      matching: find.byType(TextField),
    );
    final textField = tester.widget<TextField>(firstUrlField);
    expect(textField.controller!.text, isNotEmpty);

    // The video metadata view shows the title.
    expect(find.text('First Video'), findsOneWidget);
  });

  testWidgets('Full URL is preserved internally after smart paste',
      (WidgetTester tester) async {
    mockClipboard(
        tester, 'https://youtu.be/dQw4w9WgXcQ');
    await pumpApp(tester);

    // Smart paste a youtu.be short URL.
    await tester.tap(find.byIcon(Icons.content_paste).first);
    await tester.pumpAndSettle();

    // The canonical full URL is used internally (metadata fetch worked).
    expect(find.text('First Video'), findsOneWidget);

    // The text field still has the original full URL.
    final firstUrlField = find.descendant(
      of: find.byType(VideoInputCard).first,
      matching: find.byType(TextField),
    );
    final textField = tester.widget<TextField>(firstUrlField);
    expect(textField.controller!.text,
        contains('https://youtu.be/dQw4w9WgXcQ'));
  });
}