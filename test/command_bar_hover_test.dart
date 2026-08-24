import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

import 'helpers/in_memory_first_launch_intro_store.dart';
import 'helpers/in_memory_video_history_storage.dart';

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
      String videoId) async {
    if (videoId == _FakeProvider.videoId) {
      return [
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
      String videoId, YoutubeTranscriptInfo info) async {
    if (videoId == _FakeProvider.videoId) {
      return YoutubeTranscript(
        videoId: videoId,
        info: info,
        segments: [
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

  testWidgets('hover across every CommandBar cell has no hit-test errors',
      (tester) async {
    await pumpApp(tester);

    final cmdBar = find.byType(CommandBar);
    final rect = tester.getRect(cmdBar);

    // Sweep the mouse across the whole CommandBar cell by cell. This guards
    // against "Cannot hit test a render box with no size" / mouse-tracker
    // assertions caused by zero-size render boxes in the hover path.
    final gesture =
        await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 7);
    addTearDown(() => gesture.removePointer());

    var errors = 0;
    for (double x = rect.left + 2; x < rect.right - 1; x += 6) {
      for (double y = rect.top + 2; y < rect.bottom - 1; y += 6) {
        await gesture.moveTo(Offset(x, y));
        await tester.pump(const Duration(milliseconds: 5));
        final current = tester.takeException();
        if (current != null) {
          errors++;
        }
      }
    }

    expect(errors, 0);
  });
}
