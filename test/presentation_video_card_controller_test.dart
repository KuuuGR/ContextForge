import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/presentation/video_card_controller.dart';
import 'package:context_forge/presentation/video_card_state.dart';
import 'package:context_forge/providers/youtube_provider.dart';
import 'package:context_forge/providers/youtube_transcript.dart';
import 'package:context_forge/providers/youtube_transcript_info.dart';
import 'package:context_forge/providers/youtube_video_metadata.dart';
import 'package:context_forge/repositories/in_memory_video_repository.dart';
import 'package:context_forge/services/video_service.dart';

/// Minimal provider returned by VideoService; never invoked by the
/// presentation controller in this phase.
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

VideoService _service() => VideoService(
      repository: InMemoryVideoRepository(),
      provider: _NoopProvider(),
    );

void main() {
  group('VideoCardController (presentation)', () {
    test('starts in empty state', () {
      final controller = VideoCardController(videoService: _service());
      expect(controller.state, VideoCardState.empty);
      expect(controller.url, isEmpty);
      expect(controller.videoId, isNull);
      expect(controller.isValid, isFalse);
      expect(controller.isInvalid, isFalse);
      controller.dispose();
    });

    test('setUrl transitions to editing and stores URL', () {
      final controller = VideoCardController(videoService: _service());
      controller.setUrl('https://youtu.be/dQw4w9WgXcQ');
      expect(controller.state, VideoCardState.editing);
      expect(controller.url, 'https://youtu.be/dQw4w9WgXcQ');
      expect(controller.videoId, isNull);
      controller.dispose();
    });

    test('validate with valid URL transitions to valid and extracts videoId',
        () {
      final controller = VideoCardController(videoService: _service());
      controller.setUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      controller.validate();
      expect(controller.state, VideoCardState.valid);
      expect(controller.isValid, isTrue);
      expect(controller.videoId, 'dQw4w9WgXcQ');
      controller.dispose();
    });

    test('validate with youtu.be URL extracts videoId', () {
      final controller = VideoCardController(videoService: _service());
      controller.setUrl('https://youtu.be/dQw4w9WgXcQ');
      controller.validate();
      expect(controller.state, VideoCardState.valid);
      expect(controller.videoId, 'dQw4w9WgXcQ');
      controller.dispose();
    });

    test('validate with invalid URL transitions to invalid', () {
      final controller = VideoCardController(videoService: _service());
      controller.setUrl('not-a-url');
      controller.validate();
      expect(controller.state, VideoCardState.invalid);
      expect(controller.isInvalid, isTrue);
      expect(controller.videoId, isNull);
      controller.dispose();
    });

    test('validate with whitespace-only URL returns to empty', () {
      final controller = VideoCardController(videoService: _service());
      controller.setUrl('   ');
      controller.validate();
      expect(controller.state, VideoCardState.empty);
      expect(controller.videoId, isNull);
      controller.dispose();
    });

    test('clear() returns to empty and clears URL + videoId', () {
      final controller = VideoCardController(videoService: _service());
      controller.setUrl('https://youtu.be/dQw4w9WgXcQ');
      controller.validate();
      expect(controller.state, VideoCardState.valid);
      expect(controller.videoId, 'dQw4w9WgXcQ');

      controller.clear();
      expect(controller.state, VideoCardState.empty);
      expect(controller.url, isEmpty);
      expect(controller.videoId, isNull);
      controller.dispose();
    });

    test('notifies listeners on state transitions', () {
      final controller = VideoCardController(videoService: _service());
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setUrl('https://youtu.be/dQw4w9WgXcQ');
      expect(notifications, 1);

      controller.validate();
      expect(notifications, 2);

      controller.clear();
      expect(notifications, 3);
      controller.dispose();
    });

    test('re-validating after editing transitions editing → valid', () {
      final controller = VideoCardController(videoService: _service());
      controller.setUrl('https://youtu.be/dQw4w9WgXcQ');
      controller.validate();
      expect(controller.state, VideoCardState.valid);

      controller.setUrl('https://youtu.be/otherid4567');
      expect(controller.state, VideoCardState.editing);
      expect(controller.videoId, isNull);

      controller.validate();
      expect(controller.state, VideoCardState.valid);
      expect(controller.videoId, 'otherid4567');
      controller.dispose();
    });
  });
}