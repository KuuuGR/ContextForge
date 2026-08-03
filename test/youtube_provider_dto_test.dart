import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/models/transcript_language.dart';
import 'package:context_forge/providers/youtube_transcript.dart';
import 'package:context_forge/providers/youtube_transcript_info.dart';
import 'package:context_forge/providers/youtube_video_metadata.dart';

void main() {
  group('YoutubeVideoMetadata', () {
    final metadata = YoutubeVideoMetadata(
      videoId: 'abc123def45',
      title: 'Flutter Tutorial',
      channelName: 'Tech Channel',
      publishedAt: DateTime.utc(2025, 1, 15, 12),
      duration: const Duration(minutes: 10, seconds: 30),
      url: 'https://www.youtube.com/watch?v=abc123def45',
      description: 'A tutorial',
    );

    test('serializes to JSON', () {
      final json = metadata.toJson();
      expect(json['videoId'], 'abc123def45');
      expect(json['title'], 'Flutter Tutorial');
      expect(json['channelName'], 'Tech Channel');
      expect(json['publishedAt'], '2025-01-15T12:00:00.000Z');
      expect(json['durationSeconds'], 630);
      expect(json['url'], 'https://www.youtube.com/watch?v=abc123def45');
      expect(json['description'], 'A tutorial');
    });

    test('deserializes from JSON round-trip', () {
      expect(YoutubeVideoMetadata.fromJson(metadata.toJson()), metadata);
    });

    test('fromJson defaults duration and null description', () {
      final json = {
        'videoId': 'abc123def45',
        'title': 'T',
        'channelName': 'C',
        'publishedAt': '2025-01-15T12:00:00.000Z',
        'url': 'https://www.youtube.com/watch?v=abc123def45',
      };
      final decoded = YoutubeVideoMetadata.fromJson(json);
      expect(decoded.duration, Duration.zero);
      expect(decoded.url, 'https://www.youtube.com/watch?v=abc123def45');
      expect(decoded.description, isNull);
    });

    test('copyWith updates only provided fields', () {
      final updated = metadata.copyWith(title: 'Dart Tutorial');
      expect(updated.title, 'Dart Tutorial');
      expect(updated.videoId, metadata.videoId);
      expect(updated.duration, metadata.duration);
    });

    test('equality compares all fields', () {
      expect(YoutubeVideoMetadata.fromJson(metadata.toJson()), metadata);
      expect(metadata.copyWith(videoId: 'other'), isNot(metadata));
    });

    test('toString is readable', () {
      expect(metadata.toString(), contains('videoId: abc123def45'));
    });
  });

  group('YoutubeTranscriptInfo', () {
    final info = YoutubeTranscriptInfo(
      language: TranscriptLanguage.polish,
      isManual: true,
      languageName: 'Polish',
      languageCode: 'pl',
    );

    test('serializes to JSON', () {
      final json = info.toJson();
      expect(json['language'], 'polish');
      expect(json['isManual'], isTrue);
      expect(json['languageName'], 'Polish');
    });

    test('deserializes from JSON round-trip', () {
      expect(YoutubeTranscriptInfo.fromJson(info.toJson()), info);
    });

    test('fromJson defaults to other language for unknown value', () {
      final json = info.toJson()..['language'] = 'klingon';
      final decoded = YoutubeTranscriptInfo.fromJson(json);
      expect(decoded.language, TranscriptLanguage.other);
    });

    test('copyWith updates only provided fields', () {
      final updated = info.copyWith(isManual: false);
      expect(updated.isManual, isFalse);
      expect(updated.language, TranscriptLanguage.polish);
      expect(updated.languageName, 'Polish');
    });

    test('equality compares all fields', () {
      expect(YoutubeTranscriptInfo.fromJson(info.toJson()), info);
      expect(info.copyWith(language: TranscriptLanguage.english), isNot(info));
    });
  });

  group('YoutubeTranscriptSegment', () {
    test('serializes and deserializes', () {
      const segment = YoutubeTranscriptSegment(
        offset: Duration(seconds: 5),
        duration: Duration(seconds: 3),
        text: 'Hello world',
      );
      expect(YoutubeTranscriptSegment.fromJson(segment.toJson()), segment);
    });

    test('copyWith updates only provided fields', () {
      const segment = YoutubeTranscriptSegment(
        offset: Duration(seconds: 1),
        duration: Duration(seconds: 2),
        text: 'Original',
      );
      final updated = segment.copyWith(text: 'Changed');
      expect(updated.text, 'Changed');
      expect(updated.offset, segment.offset);
      expect(updated.duration, segment.duration);
    });

    test('equality compares all fields', () {
      const a = YoutubeTranscriptSegment(
        offset: Duration(seconds: 1),
        duration: Duration(seconds: 2),
        text: 'Text',
      );
      const b = YoutubeTranscriptSegment(
        offset: Duration(seconds: 1),
        duration: Duration(seconds: 2),
        text: 'Other',
      );
      expect(a, isNot(b));
    });
  });

  group('YoutubeTranscript', () {
    final transcript = YoutubeTranscript(
      videoId: 'abc123def45',
      info: YoutubeTranscriptInfo(
        language: TranscriptLanguage.polish,
        isManual: true,
        languageName: 'Polish',
        languageCode: 'pl',
      ),
      segments: const [
        YoutubeTranscriptSegment(
          offset: Duration(seconds: 0),
          duration: Duration(seconds: 3),
          text: 'Hello',
        ),
        YoutubeTranscriptSegment(
          offset: Duration(seconds: 3),
          duration: Duration(seconds: 2),
          text: 'World',
        ),
      ],
    );

    test('serializes to JSON', () {
      final json = transcript.toJson();
      expect(json['videoId'], 'abc123def45');
      expect(json['info'], isA<Map<String, dynamic>>());
      expect(json['segments'], isA<List<dynamic>>());
      expect((json['segments'] as List).length, 2);
    });

    test('deserializes from JSON round-trip', () {
      expect(YoutubeTranscript.fromJson(transcript.toJson()), transcript);
    });

    test('equality compares segments in order', () {
      final same = YoutubeTranscript.fromJson(transcript.toJson());
      expect(transcript, same);
      expect(transcript.copyWith(segments: const []), isNot(transcript));
    });

    test('copyWith updates only provided fields', () {
      final updated = transcript.copyWith(videoId: 'new1234567');
      expect(updated.videoId, 'new1234567');
      expect(updated.segments, transcript.segments);
      expect(updated.info, transcript.info);
    });

    test('toString is readable', () {
      expect(transcript.toString(), contains('segments: 2'));
    });
  });
}