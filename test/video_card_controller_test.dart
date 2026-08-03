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

/// Fake provider that returns fixed results without networking.
class _FakeProvider implements YoutubeProvider {
  _FakeProvider({
    this.metadata,
    this.error,
  });

  final YoutubeVideoMetadata? metadata;
  final Object? error;

  @override
  Future<YoutubeVideoMetadata?> getVideoMetadata(String videoId) async {
    if (error != null) throw error!;
    return metadata;
  }

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
  late VideoService successService;
  late VideoService invalidService;
  late VideoService unavailableService;
  late VideoService networkService;

  const validUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

  setUp(() {
    final successMeta = YoutubeVideoMetadata(
      videoId: 'dQw4w9WgXcQ',
      title: 'Rick Astley',
      channelName: 'Official Channel',
      publishedAt: DateTime.utc(2009, 10, 25),
      duration: const Duration(minutes: 3, seconds: 32),
      url: validUrl,
    );
    successService = VideoService(
      repository: InMemoryVideoRepository(),
      provider: _FakeProvider(metadata: successMeta),
    );
    invalidService = VideoService(
      repository: InMemoryVideoRepository(),
      provider: _FakeProvider(error: const InvalidYouTubeUrlException('bad')),
    );
    unavailableService = VideoService(
      repository: InMemoryVideoRepository(),
      provider: _FakeProvider(
        error: const YoutubeVideoUnavailableException('gone'),
      ),
    );
    networkService = VideoService(
      repository: InMemoryVideoRepository(),
      provider: _FakeProvider(error: Exception('connection')),
    );
  });

  group('VideoCardController', () {
    test('starts in noUrl state', () {
      final controller = VideoCardController(service: successService);
      expect(controller.status, VideoStatus.noUrl);
      expect(controller.isLoading, isFalse);
      expect(controller.hasMetadata, isFalse);
      expect(controller.errorMessage, isNull);
      controller.dispose();
    });

    test('empty URL stays in noUrl state', () async {
      final controller = VideoCardController(service: successService);
      await controller.loadMetadata('   ');
      expect(controller.status, VideoStatus.noUrl);
      expect(controller.hasMetadata, isFalse);
      controller.dispose();
    });

    test('successful metadata load sets loaded state and video', () async {
      final controller = VideoCardController(service: successService);
      await controller.loadMetadata(validUrl);

      expect(controller.status, VideoStatus.loaded);
      expect(controller.hasMetadata, isTrue);
      expect(controller.video!.title, 'Rick Astley');
      expect(controller.video!.channelName, 'Official Channel');
      expect(controller.errorMessage, isNull);
      controller.dispose();
    });

    test('loading state is visible during async fetch', () async {
      final controller = VideoCardController(service: successService);
      final future = controller.loadMetadata(validUrl);
      expect(controller.isLoading, isTrue);
      await future;
      expect(controller.isLoading, isFalse);
      controller.dispose();
    });

    test('invalid URL sets error state with friendly message', () async {
      final controller = VideoCardController(service: invalidService);
      await controller.loadMetadata('not-a-url');

      expect(controller.status, VideoStatus.error);
      expect(controller.hasMetadata, isFalse);
      expect(controller.errorMessage, isNotNull);
      expect(controller.errorMessage, isNot(contains('InvalidYouTubeUrlException')));
      controller.dispose();
    });

    test('unavailable video sets error state with friendly message', () async {
      final controller = VideoCardController(service: unavailableService);
      await controller.loadMetadata(validUrl);

      expect(controller.status, VideoStatus.error);
      expect(controller.errorMessage, contains('unavailable'));
      controller.dispose();
    });

    test('network failure sets error state without raw exception leak',
        () async {
      final controller = VideoCardController(service: networkService);
      await controller.loadMetadata(validUrl);

      expect(controller.status, VideoStatus.error);
      expect(controller.errorMessage, isNotNull);
      expect(controller.errorMessage,
          isNot(contains('Exception: connection')));
      controller.dispose();
    });

    test('unexpected error is handled gracefully', () async {
      final service = VideoService(
        repository: InMemoryVideoRepository(),
        provider: _FakeProvider(error: StateError('boom')),
      );
      final controller = VideoCardController(service: service);
      await controller.loadMetadata(validUrl);

      expect(controller.status, VideoStatus.error);
      expect(controller.errorMessage, isNotNull);
      controller.dispose();
    });
  });
}