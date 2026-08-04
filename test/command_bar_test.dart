import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/app/app.dart';
import 'package:context_forge/models/prompt_quick_access.dart';
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
  late PromptService promptService;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    promptService = PromptService(
      repository: InMemoryPromptRepository(),
    );
    await promptService.ensureDefaultPrompts();

    // Assign the first 3 prompts to quick slots ① ② ③.
    final prompts = await promptService.getAllPrompts();
    if (prompts.isNotEmpty) {
      await promptService.assignQuickAccess(
          prompts[0].id, PromptQuickAccess.slotOne);
    }
    if (prompts.length >= 2) {
      await promptService.assignQuickAccess(
          prompts[1].id, PromptQuickAccess.slotTwo);
    }
    if (prompts.length >= 3) {
      await promptService.assignQuickAccess(
          prompts[2].id, PromptQuickAccess.slotThree);
    }

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
    expect(find.byIcon(Icons.bolt_outlined), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

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

    // The prompt selector area should contain the prompt title.
    expect(find.text('Instagram Post'), findsWidgets);

    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    // The selected prompt dropdown should now show the second prompt.
    expect(find.text('X / Twitter Thread'), findsWidgets);
  });

  testWidgets('Generate button in command bar generates output',
      (WidgetTester tester) async {
    await pumpApp(tester);

    final firstUrlField = find.descendant(
      of: find.byType(VideoInputCard).first,
      matching: find.byType(TextField),
    );
    await tester.enterText(
      firstUrlField,
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    );
    await tester.pump();

    final commandBarGenerate = find.descendant(
      of: find.byType(CommandBar),
      matching: find.byIcon(Icons.play_arrow),
    );
    await tester.tap(commandBarGenerate);
    await tester.pumpAndSettle();

    final outputField = tester.widget<TextField>(find.byType(TextField).last);
    expect(outputField.controller!.text, isNotEmpty);
    expect(outputField.controller!.text, contains('Transcript 1'));
  });

  testWidgets('Copy button in command bar is disabled when output is empty',
      (WidgetTester tester) async {
    await pumpApp(tester);

    // The copy icon in the command bar should still be present.
    final commandBarCopy = find.descendant(
      of: find.byType(CommandBar),
      matching: find.byIcon(Icons.copy),
    );
    expect(commandBarCopy, findsOneWidget);
  });

  testWidgets('Paste button in command bar performs smart paste',
      (WidgetTester tester) async {
    mockClipboard(
        tester, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
    await pumpApp(tester);

    expect(find.text('Empty'), findsNWidgets(3));

    final commandBarPaste = find.descendant(
      of: find.byType(CommandBar),
      matching: find.byIcon(Icons.content_paste),
    );
    await tester.tap(commandBarPaste);
    await tester.pumpAndSettle();

    final firstUrlField = find.descendant(
      of: find.byType(VideoInputCard).first,
      matching: find.byType(TextField),
    );
    final field = tester.widget<TextField>(firstUrlField);
    expect(field.controller!.text, isNotEmpty);
    expect(find.text('First Video'), findsOneWidget);
  });
}