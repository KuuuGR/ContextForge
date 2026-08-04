import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/models/transcript_language.dart';
import 'package:context_forge/models/video.dart';
import 'package:context_forge/models/video_history_entry.dart';
import 'package:context_forge/services/json_video_history_storage.dart';
import 'package:context_forge/services/video_history_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('contextforge_history_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  VideoHistoryService buildService() {
    return VideoHistoryService(
      storage: JsonVideoHistoryStorage(directoryPath: tempDir.path),
    );
  }

  File historyFile() =>
      File('${tempDir.path}${Platform.pathSeparator}video_history.json');

  Video buildVideo({
    String videoId = 'dQw4w9WgXcQ',
    String title = 'First Video',
  }) {
    return Video(
      id: videoId,
      url: 'https://www.youtube.com/watch?v=$videoId',
      videoId: videoId,
      title: title,
      channelName: 'Tech Channel',
      publishedAt: DateTime.utc(2025, 1, 15),
      transcriptLanguage: TranscriptLanguage.other,
      transcriptAvailable: true,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
  }

  group('VideoHistoryService', () {
    test('load returns empty when no history file exists', () async {
      final service = buildService();
      final count = await service.load();
      expect(count, 0);
      expect(service.hasBeenProcessed('dQw4w9WgXcQ'), isFalse);
      expect(service.getEntryByUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
          isNull);
    });

    test('recordSuccess creates history entry and persists file', () async {
      final service = buildService();
      await service.recordSuccess(buildVideo());

      expect(await historyFile().exists(), isTrue);
      final raw = await historyFile().readAsString();
      expect(raw, contains('"videoId": "dQw4w9WgXcQ"'));
      expect(raw, contains('"title": "First Video"'));
      expect(raw, contains('"processedAt"'));

      expect(service.hasBeenProcessed('dQw4w9WgXcQ'), isTrue);
      final entry = service.getEntryByUrl(
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(entry, isNotNull);
      expect(entry!.videoId, 'dQw4w9WgXcQ');
      expect(entry.title, 'First Video');
      expect(entry.channelName, 'Tech Channel');
    });

    test('recordSuccess does not create duplicates for same video', () async {
      final service = buildService();
      await service.recordSuccess(buildVideo());
      await service.recordSuccess(buildVideo());

      final raw = await historyFile().readAsString();
      // There should be exactly one object in the JSON array.
      final entries =
          await JsonVideoHistoryStorage(directoryPath: tempDir.path).loadHistory();
      expect(entries, hasLength(1));
      expect(raw, isNot(contains('  ,\n')));
    });

    test('recordSuccess updates processedAt for existing video', () async {
      final service = buildService();
      await service.recordSuccess(buildVideo());

      final first = service.getEntry('dQw4w9WgXcQ');
      expect(first, isNotNull);

      // Sleep briefly so the timestamp advances.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await service.recordSuccess(buildVideo());

      final second = service.getEntry('dQw4w9WgXcQ');
      expect(second, isNotNull);
      expect(second!.processedAt.isAfter(first!.processedAt), isTrue);

      final entries =
          await JsonVideoHistoryStorage(directoryPath: tempDir.path).loadHistory();
      expect(entries, hasLength(1));
    });

    test('load reads history persisted by a previous instance', () async {
      final firstService = buildService();
      await firstService.recordSuccess(buildVideo());

      // Simulate application restart: create a fresh service instance.
      final secondService = buildService();
      final count = await secondService.load();
      expect(count, 1);
      expect(secondService.hasBeenProcessed('dQw4w9WgXcQ'), isTrue);
      final entry = secondService.getEntryByUrl(
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(entry, isNotNull);
      expect(entry!.title, 'First Video');
    });

    test('getEntryByUrl returns null for invalid URL', () async {
      final service = buildService();
      await service.recordSuccess(buildVideo());

      expect(service.getEntryByUrl('not-a-url'), isNull);
      expect(service.getEntryByUrl(''), isNull);
    });

    test('getEntryByUrl matches different URL forms of same video', () async {
      final service = buildService();
      await service.recordSuccess(buildVideo());

      // youtu.be short URL for the same video ID should match.
      final entry = service.getEntryByUrl('https://youtu.be/dQw4w9WgXcQ');
      expect(entry, isNotNull);
      expect(entry!.videoId, 'dQw4w9WgXcQ');
    });
  });

  group('VideoHistoryEntry model', () {
    test('serializes and deserializes with all fields', () {
      final entry = VideoHistoryEntry(
        videoId: 'dQw4w9WgXcQ',
        originalUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        title: 'First Video',
        channelName: 'Tech Channel',
        processedAt: DateTime.utc(2026, 8, 4, 12, 30),
      );

      final json = entry.toJson();
      expect(json['videoId'], 'dQw4w9WgXcQ');
      expect(json['originalUrl'], 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(json['title'], 'First Video');
      expect(json['channelName'], 'Tech Channel');
      expect(json['processedAt'], '2026-08-04T12:30:00.000Z');

      final restored = VideoHistoryEntry.fromJson(json);
      expect(restored, entry);
    });

    test('equality compares all fields', () {
      final a = VideoHistoryEntry(
        videoId: 'abc123',
        originalUrl: 'https://youtu.be/abc123',
        title: 'T',
        channelName: 'C',
        processedAt: DateTime.utc(2026, 1, 1),
      );
      final b = VideoHistoryEntry(
        videoId: 'abc123',
        originalUrl: 'https://youtu.be/abc123',
        title: 'T',
        channelName: 'C',
        processedAt: DateTime.utc(2026, 1, 1),
      );
      final c = VideoHistoryEntry(
        videoId: 'different',
        originalUrl: 'https://youtu.be/different',
        title: 'T',
        channelName: 'C',
        processedAt: DateTime.utc(2026, 1, 1),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}