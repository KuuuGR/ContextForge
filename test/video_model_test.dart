import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/models/transcript_language.dart';
import 'package:context_forge/models/video.dart';

void main() {
  final publishedAt = DateTime.utc(2025, 1, 15, 12, 0, 0);
  final createdAt = DateTime.utc(2026, 2, 8, 10, 0, 0);
  final updatedAt = DateTime.utc(2026, 2, 8, 10, 0, 0);

  final video = Video(
    id: 'v1',
    url: 'https://www.youtube.com/watch?v=abc123',
    videoId: 'abc123',
    title: 'Flutter Tutorial',
    channelName: 'Tech Channel',
    publishedAt: publishedAt,
    transcriptLanguage: TranscriptLanguage.polish,
    transcriptAvailable: true,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  group('Video', () {
    test('serializes to JSON', () {
      final json = video.toJson();
      expect(json['id'], 'v1');
      expect(json['url'], 'https://www.youtube.com/watch?v=abc123');
      expect(json['videoId'], 'abc123');
      expect(json['title'], 'Flutter Tutorial');
      expect(json['channelName'], 'Tech Channel');
      expect(json['publishedAt'], '2025-01-15T12:00:00.000Z');
      expect(json['transcriptLanguage'], 'polish');
      expect(json['transcriptAvailable'], isTrue);
      expect(json['createdAt'], '2026-02-08T10:00:00.000Z');
      expect(json['updatedAt'], '2026-02-08T10:00:00.000Z');
    });

    test('deserializes from JSON round-trip', () {
      final decoded = Video.fromJson(video.toJson());
      expect(decoded, video);
    });

    test('fromJson defaults transcriptAvailable when missing', () {
      final json = video.toJson()..remove('transcriptAvailable');
      final decoded = Video.fromJson(json);
      expect(decoded.transcriptAvailable, isFalse);
    });

    test('fromJson defaults to TranscriptLanguage.none for unknown value', () {
      final json = video.toJson()..['transcriptLanguage'] = 'klingon';
      final decoded = Video.fromJson(json);
      expect(decoded.transcriptLanguage, TranscriptLanguage.none);
    });

    test('fromJson preserves transcript language', () {
      final json = video.toJson();
      final decoded = Video.fromJson(json);
      expect(decoded.transcriptLanguage, TranscriptLanguage.polish);
    });

    test('copyWith updates only provided fields', () {
      final updated = video.copyWith(
        title: 'Dart Tutorial',
        transcriptLanguage: TranscriptLanguage.englishAuto,
      );
      expect(updated.id, video.id);
      expect(updated.title, 'Dart Tutorial');
      expect(updated.channelName, video.channelName);
      expect(updated.transcriptLanguage, TranscriptLanguage.englishAuto);
      expect(updated.createdAt, video.createdAt);
    });

    test('copyWith preserves unchanged values', () {
      final unchanged = video.copyWith();
      expect(unchanged, video);
    });

    test('equality compares all fields', () {
      final identicalVideo = Video(
        id: 'v1',
        url: 'https://www.youtube.com/watch?v=abc123',
        videoId: 'abc123',
        title: 'Flutter Tutorial',
        channelName: 'Tech Channel',
        publishedAt: publishedAt,
        transcriptLanguage: TranscriptLanguage.polish,
        transcriptAvailable: true,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      expect(video, identicalVideo);
      expect(video.hashCode, identicalVideo.hashCode);
      expect(video.copyWith(id: 'v2'), isNot(video));
      expect(video.copyWith(videoId: 'xyz789'), isNot(video));
    });

    test('toString is readable', () {
      final text = video.toString();
      expect(text, contains('Video(id: v1'));
      expect(text, contains('videoId: abc123'));
      expect(text, contains('title: Flutter Tutorial'));
    });

    test('TranscriptLanguage label values are correct', () {
      expect(TranscriptLanguage.polish.label, 'Manual Polish');
      expect(TranscriptLanguage.polishAuto.label, 'Automatic Polish');
      expect(TranscriptLanguage.english.label, 'Manual English');
      expect(TranscriptLanguage.englishAuto.label, 'Automatic English');
      expect(TranscriptLanguage.other.label, 'Other');
      expect(TranscriptLanguage.none.label, 'None');
    });
  });
}