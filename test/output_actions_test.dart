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
  Future<Widget> buildApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final promptService = PromptService(
      repository: InMemoryPromptRepository(),
    );
    await promptService.ensureDefaultPrompts();

    return ContextForgeApp(
      promptService: promptService,
      videoService: VideoService(
        repository: InMemoryVideoRepository(),
        provider: _FakeProvider(),
      ),
      videoHistoryService: VideoHistoryService(
        storage: InMemoryVideoHistoryStorage(),
      ),
    );
  }

  /// Registers a mock for the system clipboard channel so tests never wait on
  /// a real platform implementation. Captures text written via Clipboard.setData.
  void mockClipboard({List<String>? captured}) {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        final text =
            (call.arguments as Map<dynamic, dynamic>)['text'] as String? ?? '';
        captured?.add(text);
        return null;
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });
  }

  testWidgets('Copy copies generated output to clipboard', (tester) async {
    final captured = <String>[];
    mockClipboard(captured: captured);

    await tester.pumpWidget(await buildApp(tester));
    await tester.pumpAndSettle();

    // Enter a URL and generate.
    final firstUrlField = find.descendant(
      of: find.byType(VideoInputCard).first,
      matching: find.byType(TextField),
    );
    await tester.enterText(
      firstUrlField,
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    );
    await tester.ensureVisible(find.byType(GenerateButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(GenerateButton));
    await tester.pumpAndSettle();

    // Read the generated output.
    final outputField = tester.widget<TextField>(find.byType(TextField).last);
    final output = outputField.controller!.text;
    expect(output, isNotEmpty);

    // Press Copy.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Copy').first);
    await tester.pump();

    // Clipboard contains the exact generated output.
    expect(captured, [output]);

    // Confirmation shown.
    await tester.pump();
    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets('Clear resets session to initial state', (tester) async {
    mockClipboard();

    await tester.pumpWidget(await buildApp(tester));
    await tester.pumpAndSettle();

    // Enter a URL and generate.
    final firstUrlField = find.descendant(
      of: find.byType(VideoInputCard).first,
      matching: find.byType(TextField),
    );
    await tester.enterText(
      firstUrlField,
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    );
    await tester.ensureVisible(find.byType(GenerateButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(GenerateButton));
    await tester.pumpAndSettle();

    // Verify output + URL are populated.
    final outputField = tester.widget<TextField>(find.byType(TextField).last);
    expect(outputField.controller!.text, isNotEmpty);

    // Press Clear.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Clear').first);
    await tester.pumpAndSettle();

    // Output is empty.
    final clearedOutput =
        tester.widget<TextField>(find.byType(TextField).last);
    expect(clearedOutput.controller!.text, isEmpty);

    // URL fields are empty.
    for (final field in find.byType(TextField).evaluate()) {
      final tf = field.widget as TextField;
      if (!tf.readOnly) {
        expect(tf.controller?.text ?? '', isEmpty,
            reason: 'URL fields should be cleared');
      }
    }

    // Video cards back to Empty state.
    expect(find.text('Empty'), findsNWidgets(3));

    // Copy now disabled.
    final copyButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Copy').first,
    );
    expect(copyButton.onPressed, isNull);
  });
}