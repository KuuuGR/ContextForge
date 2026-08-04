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
import 'package:context_forge/services/video_history_service.dart';
import 'package:context_forge/services/video_service.dart';
import 'package:context_forge/widgets/generate_button.dart';

import 'helpers/in_memory_video_history_storage.dart';

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
        videoHistoryService: VideoHistoryService(
          storage: InMemoryVideoHistoryStorage(),
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

    // The output Generate button is enabled; Copy/Export Markdown/Clear
    // appear once (action bar only). Footer shows informational buttons.
    expect(find.text('Generate'), findsOneWidget);
    expect(find.text('Copy'), findsNWidgets(1));
    expect(find.text('Export Markdown'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Shortcuts'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);

    final generateButton =
        tester.widget<GenerateButton>(find.byType(GenerateButton));
    expect(generateButton.onPressed, isNotNull);

    // Action-bar buttons are disabled when there is nothing to do.
    final actionBarCopy = tester.widget<OutlinedButton>(
      find.byType(OutlinedButton).at(0),
    );
    expect(actionBarCopy.onPressed, isNull);
    final actionBarExport = tester.widget<OutlinedButton>(
      find.byType(OutlinedButton).at(1),
    );
    expect(actionBarExport.onPressed, isNull);
    final actionBarClear = tester.widget<OutlinedButton>(
      find.byType(OutlinedButton).at(2),
    );
    expect(actionBarClear.onPressed, isNull);

  });
}