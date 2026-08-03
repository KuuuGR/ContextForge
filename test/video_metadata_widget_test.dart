import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/exceptions/youtube_exceptions.dart';
import 'package:context_forge/models/video_status.dart';
import 'package:context_forge/providers/youtube_provider.dart';
import 'package:context_forge/providers/youtube_transcript.dart';
import 'package:context_forge/providers/youtube_transcript_info.dart';
import 'package:context_forge/providers/youtube_video_metadata.dart';
import 'package:context_forge/repositories/in_memory_video_repository.dart';
import 'package:context_forge/services/video_service.dart';
import 'package:context_forge/viewmodels/video_card_controller.dart';
import 'package:context_forge/widgets/video_input_card.dart';

class _FakeProvider implements YoutubeProvider {
  _FakeProvider({this.metadata, this.error, this.delay = Duration.zero});

  final YoutubeVideoMetadata? metadata;
  final Exception? error;
  final Duration delay;

  @override
  Future<YoutubeVideoMetadata?> getVideoMetadata(String videoId) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    if (error != null) throw error!;
    return metadata;
  }

  @override
  Future<List<YoutubeTranscriptInfo>> getAvailableTranscripts(String videoId) async => const [];

  @override
  Future<YoutubeTranscript?> downloadTranscript(String videoId, YoutubeTranscriptInfo info) async => null;
}

void main() {
  const validUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
  final successMeta = YoutubeVideoMetadata(
    videoId: 'dQw4w9WgXcQ',
    title: 'Rick Astley',
    channelName: 'Official Channel',
    publishedAt: DateTime.utc(2009, 10, 25),
    duration: const Duration(minutes: 3, seconds: 32),
    url: validUrl,
  );

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows metadata after successful load', (tester) async {
    final controller = VideoCardController(
      service: VideoService(
        repository: InMemoryVideoRepository(),
        provider: _FakeProvider(metadata: successMeta),
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(VideoInputCard(controller: controller)));
    await tester.enterText(find.byType(TextField), validUrl);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(controller.status, VideoStatus.loaded);
    expect(find.text('Rick Astley'), findsOneWidget);
    expect(find.textContaining('Official Channel'), findsOneWidget);
    expect(find.textContaining('Published:'), findsOneWidget);
  });

  testWidgets('shows loading indicator during fetch', (tester) async {
    final controller = VideoCardController(
      service: VideoService(
        repository: InMemoryVideoRepository(),
        provider: _FakeProvider(metadata: successMeta, delay: const Duration(milliseconds: 300)),
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(VideoInputCard(controller: controller)));
    await tester.enterText(find.byType(TextField), validUrl);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(controller.status, VideoStatus.loaded);
  });

  testWidgets('shows friendly error for invalid URL', (tester) async {
    final controller = VideoCardController(
      service: VideoService(
        repository: InMemoryVideoRepository(),
        provider: _FakeProvider(error: const InvalidYouTubeUrlException('bad')),
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(VideoInputCard(controller: controller)));
    await tester.enterText(find.byType(TextField), 'not-a-url');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(controller.status, VideoStatus.error);
    expect(find.textContaining('Invalid YouTube URL'), findsOneWidget);
  });

  testWidgets('shows friendly error for unavailable video', (tester) async {
    final controller = VideoCardController(
      service: VideoService(
        repository: InMemoryVideoRepository(),
        provider: _FakeProvider(error: const YoutubeVideoUnavailableException('gone')),
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(VideoInputCard(controller: controller)));
    await tester.enterText(find.byType(TextField), validUrl);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.textContaining('unavailable'), findsOneWidget);
    expect(find.textContaining('InvalidYouTubeUrlException'), findsNothing);
  });
}