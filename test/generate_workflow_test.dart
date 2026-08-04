import 'package:flutter/material.dart';
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

/// Fake provider returning metadata + transcript for one known video.
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
  testWidgets('Generate produces final output from entered video URL',
      (WidgetTester tester) async {
    // Make the surface tall enough for all sections to be visible.
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

    // Enter a URL into the first video card.
    final firstUrlField = find.descendant(
      of: find.byType(VideoInputCard).first,
      matching: find.byType(TextField),
    );
    await tester.enterText(
      firstUrlField,
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    );
    await tester.pump();

    // Tap the enabled Generate button in the Output section.
    await tester.ensureVisible(find.byType(GenerateButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(GenerateButton));
    await tester.pumpAndSettle();

    // The output area contains the generated text.
    final outputField = tester.widget<TextField>(find.byType(TextField).last);
    final output = outputField.controller!.text;
    expect(output, contains('Write a comprehensive SEO-optimized article'));
    expect(
        output, contains('2025-01-15 -> https://www.youtube.com/watch?v=dQw4w9WgXcQ'));
    expect(output, contains('Transcript 1'));
    expect(output, contains('Hello world from transcript.'));
  });
}