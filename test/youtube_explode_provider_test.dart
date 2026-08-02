import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'package:context_forge/exceptions/youtube_exceptions.dart';
import 'package:context_forge/providers/youtube_explode_provider.dart';

void main() {
  const videoId = 'abc123def45';
  const channelId = 'UC1234567890123456789012';

  Video buildVideo({String id = videoId}) {
    return Video(
      VideoId(id),
      'Flutter Tutorial',
      'Tech Channel',
      ChannelId(channelId),
      DateTime.utc(2025, 1, 15, 12),
      '2025-01-15',
      DateTime.utc(2025, 1, 15, 12),
      'A tutorial about Flutter',
      const Duration(minutes: 10, seconds: 30),
      ThumbnailSet(id),
      const ['flutter', 'tutorial'],
      Engagement(1000, 100, 5),
      false,
    );
  }

  group('YoutubeExplodeProvider.getVideoMetadata', () {
    test('returns mapped metadata on successful fetch', () async {
      final provider = YoutubeExplodeProvider(
        fetchVideo: (_, _) async => buildVideo(),
      );

      final result = await provider.getVideoMetadata(videoId);

      expect(result, isNotNull);
      expect(result!.videoId, videoId);
      expect(result.title, 'Flutter Tutorial');
      expect(result.channelName, 'Tech Channel');
      expect(result.publishedAt, DateTime.utc(2025, 1, 15, 12));
      expect(result.duration, const Duration(minutes: 10, seconds: 30));
      expect(result.url, 'https://www.youtube.com/watch?v=$videoId');
      expect(result.description, 'A tutorial about Flutter');
    });

    test('maps metadata when description is empty', () async {
      final provider = YoutubeExplodeProvider(
        fetchVideo: (_, _) async => Video(
          VideoId(videoId),
          'Title',
          'Author',
          ChannelId(channelId),
          DateTime.utc(2025, 1, 15),
          '2025-01-15',
          null,
          '',
          const Duration(minutes: 1),
          ThumbnailSet(videoId),
          null,
          Engagement(10, 1, 0),
          false,
        ),
      );

      final result = await provider.getVideoMetadata(videoId);

      expect(result, isNotNull);
      expect(result!.description, isNull);
      expect(result.channelName, 'Author');
    });

    test('maps uploadDate fallback to publishDate when uploadDate is null',
        () async {
      final provider = YoutubeExplodeProvider(
        fetchVideo: (_, _) async => Video(
          VideoId(videoId),
          'Title',
          'Author',
          ChannelId(channelId),
          null,
          null,
          DateTime.utc(2024, 6, 1),
          '',
          null,
          ThumbnailSet(videoId),
          null,
          Engagement(0, null, null),
          false,
        ),
      );

      final result = await provider.getVideoMetadata(videoId);

      expect(result, isNotNull);
      expect(result!.publishedAt, DateTime.utc(2024, 6, 1));
      expect(result.duration, Duration.zero);
    });

    test('throws InvalidYouTubeUrlException for ArgumentError', () async {
      final provider = YoutubeExplodeProvider(
        fetchVideo: (_, _) async => throw ArgumentError('Invalid video ID'),
      );

      expect(
        () => provider.getVideoMetadata('not-a-valid-id'),
        throwsA(isA<InvalidYouTubeUrlException>()),
      );
    });

    test('throws YoutubeVideoUnavailableException for unavailable video',
        () async {
      final provider = YoutubeExplodeProvider(
        fetchVideo: (_, _) async =>
            throw VideoUnavailableException.unavailable(VideoId(videoId)),
      );

      expect(
        () => provider.getVideoMetadata(videoId),
        throwsA(isA<YoutubeVideoUnavailableException>()),
      );
    });

    test('throws YoutubeNetworkException for network failures', () async {
      final provider = YoutubeExplodeProvider(
        fetchVideo: (_, _) async => throw Exception('Connection refused'),
      );

      expect(
        () => provider.getVideoMetadata(videoId),
        throwsA(isA<YoutubeNetworkException>()),
      );
    });

    test('provides cause on YoutubeNetworkException', () async {
      final provider = YoutubeExplodeProvider(
        fetchVideo: (_, _) async => throw StateError('boom'),
      );

      try {
        await provider.getVideoMetadata(videoId);
        fail('Expected YoutubeNetworkException');
      } on YoutubeNetworkException catch (e) {
        expect(e.cause, isA<StateError>());
      }
    });

    test('rethrows InvalidYouTubeUrlException without wrapping', () async {
      final provider = YoutubeExplodeProvider(
        fetchVideo: (_, _) async => throw ArgumentError('bad'),
      );

      try {
        await provider.getVideoMetadata('bad');
        fail('Expected InvalidYouTubeUrlException');
      } on InvalidYouTubeUrlException catch (e) {
        expect(e.message, contains('bad'));
      }
    });
  });
}