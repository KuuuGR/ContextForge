import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/app/app.dart';
import 'package:context_forge/providers/youtube_provider.dart';
import 'package:context_forge/providers/youtube_transcript.dart';
import 'package:context_forge/providers/youtube_transcript_info.dart';
import 'package:context_forge/providers/youtube_video_metadata.dart';
import 'package:context_forge/repositories/in_memory_prompt_repository.dart';
import 'package:context_forge/repositories/in_memory_video_repository.dart';
import 'package:context_forge/services/prompt_service.dart';
import 'package:context_forge/services/video_service.dart';
import 'package:context_forge/widgets/generate_button.dart';

/// No-op provider so widget tests never create a real HttpClient.
class _NoopProvider implements YoutubeProvider {
  @override
  Future<YoutubeVideoMetadata?> getVideoMetadata(String videoId) async => null;

  @override
  Future<List<YoutubeTranscriptInfo>> getAvailableTranscripts(
    String videoId,
  ) async {
    return const [];
  }

  @override
  Future<YoutubeTranscript?> downloadTranscript(
    String videoId,
    YoutubeTranscriptInfo info,
  ) async {
    return null;
  }
}

void main() {
  testWidgets('Main window renders all sections', (WidgetTester tester) async {
    final promptService = PromptService(
      repository: InMemoryPromptRepository(),
    );
    await promptService.ensureDefaultPrompts();

    await tester.pumpWidget(
      ContextForgeApp(
        promptService: promptService,
        videoService: VideoService(
          repository: InMemoryVideoRepository(),
          provider: _NoopProvider(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Header
    expect(find.text('ContextForge'), findsOneWidget);
    expect(
        find.text('Build AI-ready context from YouTube transcripts.'),
        findsOneWidget);

    // Prompt section
    expect(find.text('Prompt'), findsOneWidget);
    expect(find.text('SEO Article'), findsWidgets);

    // Videos section: 3 cards, initially Empty
    expect(find.text('Videos'), findsOneWidget);
    expect(find.text('YouTube URL'), findsNWidgets(3));
    expect(find.text('Empty'), findsNWidgets(3));

    // Output section (header + text field label)
    expect(find.text('Output'), findsNWidgets(2));
    expect(
        find.text('Generated output will appear here.'), findsOneWidget);

    // The output Generate button is enabled; the bottom toolbar still disabled.
    expect(find.text('Generate'), findsNWidgets(2));
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);

    final generateButton =
        tester.widget<GenerateButton>(find.byType(GenerateButton));
    expect(generateButton.onPressed, isNotNull);

    final copyButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Copy'),
    );
    expect(copyButton.onPressed, isNull);
    final clearButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Clear'),
    );
    expect(clearButton.onPressed, isNull);
  });
}
