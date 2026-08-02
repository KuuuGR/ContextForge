import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/exceptions/youtube_exceptions.dart';
import 'package:context_forge/services/youtube_url_parser.dart';

void main() {
  const parser = YouTubeUrlParser();

  const validVideoId = 'dQw4w9WgXcQ';

  group('isValidUrl', () {
    test('accepts standard www watch URL', () {
      expect(parser.isValidUrl('https://www.youtube.com/watch?v=$validVideoId'), isTrue);
    });

    test('accepts youtube.com watch URL without www', () {
      expect(parser.isValidUrl('https://youtube.com/watch?v=$validVideoId'), isTrue);
    });

    test('accepts mobile watch URL', () {
      expect(parser.isValidUrl('https://m.youtube.com/watch?v=$validVideoId'), isTrue);
    });

    test('accepts youtu.be short URL', () {
      expect(parser.isValidUrl('https://youtu.be/$validVideoId'), isTrue);
    });

    test('accepts watch URL with additional query parameters', () {
      expect(
        parser.isValidUrl('https://www.youtube.com/watch?v=$validVideoId&t=42s&feature=youtu.be'),
        isTrue,
      );
    });

    test('accepts URLs with whitespace padding', () {
      expect(parser.isValidUrl('  https://www.youtube.com/watch?v=$validVideoId  '), isTrue);
    });

    test('rejects empty string', () {
      expect(parser.isValidUrl(''), isFalse);
    });

    test('rejects whitespace-only string', () {
      expect(parser.isValidUrl('   '), isFalse);
    });

    test('rejects non-YouTube host', () {
      expect(parser.isValidUrl('https://example.com/watch?v=$validVideoId'), isFalse);
    });

    test('rejects non-http scheme (ftp)', () {
      expect(parser.isValidUrl('ftp://www.youtube.com/watch?v=$validVideoId'), isFalse);
    });

    test('rejects watch URL without v parameter', () {
      expect(parser.isValidUrl('https://www.youtube.com/watch'), isFalse);
    });

    test('rejects watch URL with empty v parameter', () {
      expect(parser.isValidUrl('https://www.youtube.com/watch?v='), isFalse);
    });

    test('rejects short URL with extra path segments', () {
      expect(parser.isValidUrl('https://youtu.be/$validVideoId/extra'), isFalse);
    });

    test('rejects malformed URL', () {
      expect(parser.isValidUrl('not a url at all'), isFalse);
    });

    test('rejects watch URL with invalid video id length', () {
      expect(parser.isValidUrl('https://www.youtube.com/watch?v=short'), isFalse);
    });

    test('rejects youtu.be URL with invalid video id', () {
      expect(parser.isValidUrl('https://youtu.be/not!valid!id'), isFalse);
    });
  });

  group('extractVideoId', () {
    test('extracts from standard www watch URL', () {
      expect(parser.extractVideoId('https://www.youtube.com/watch?v=$validVideoId'), validVideoId);
    });

    test('extracts from youtube.com watch URL without www', () {
      expect(parser.extractVideoId('https://youtube.com/watch?v=$validVideoId'), validVideoId);
    });

    test('extracts from mobile watch URL', () {
      expect(parser.extractVideoId('https://m.youtube.com/watch?v=$validVideoId'), validVideoId);
    });

    test('extracts from youtu.be short URL', () {
      expect(parser.extractVideoId('https://youtu.be/$validVideoId'), validVideoId);
    });

    test('extracts from watch URL ignoring additional query parameters', () {
      expect(
        parser.extractVideoId('https://www.youtube.com/watch?v=$validVideoId&t=42s&feature=youtu.be'),
        validVideoId,
      );
    });

    test('extracts after trimming whitespace', () {
      expect(parser.extractVideoId('  https://youtu.be/$validVideoId  '), validVideoId);
    });

    test('extracts http (non-https) URL', () {
      expect(parser.extractVideoId('http://www.youtube.com/watch?v=$validVideoId'), validVideoId);
    });

    test('extracts video id with hyphens and underscores', () {
      const id = 'aB_-1234567';
      expect(parser.extractVideoId('https://youtu.be/$id'), id);
    });

    test('throws InvalidYouTubeUrlException for empty string', () {
      expect(
        () => parser.extractVideoId(''),
        throwsA(isA<InvalidYouTubeUrlException>()),
      );
    });

    test('throws InvalidYouTubeUrlException for whitespace-only string', () {
      expect(
        () => parser.extractVideoId('   '),
        throwsA(isA<InvalidYouTubeUrlException>()),
      );
    });

    test('throws InvalidYouTubeUrlException for non-YouTube host', () {
      expect(
        () => parser.extractVideoId('https://example.com/watch?v=$validVideoId'),
        throwsA(isA<InvalidYouTubeUrlException>()),
      );
    });

    test('throws InvalidYouTubeUrlException for missing v parameter', () {
      expect(
        () => parser.extractVideoId('https://www.youtube.com/watch'),
        throwsA(isA<InvalidYouTubeUrlException>()),
      );
    });

    test('throws InvalidYouTubeUrlException for malformed URL', () {
      expect(
        () => parser.extractVideoId('https://example.com/not a url'),
        throwsA(isA<InvalidYouTubeUrlException>()),
      );
    });
  });

  group('normalizeUrl', () {
    test('normalizes standard www watch URL', () {
      expect(
        parser.normalizeUrl('https://www.youtube.com/watch?v=$validVideoId'),
        'https://www.youtube.com/watch?v=$validVideoId',
      );
    });

    test('normalizes youtube.com watch URL without www', () {
      expect(
        parser.normalizeUrl('https://youtube.com/watch?v=$validVideoId'),
        'https://www.youtube.com/watch?v=$validVideoId',
      );
    });

    test('normalizes mobile watch URL', () {
      expect(
        parser.normalizeUrl('https://m.youtube.com/watch?v=$validVideoId'),
        'https://www.youtube.com/watch?v=$validVideoId',
      );
    });

    test('normalizes youtu.be short URL', () {
      expect(
        parser.normalizeUrl('https://youtu.be/$validVideoId'),
        'https://www.youtube.com/watch?v=$validVideoId',
      );
    });

    test('drops additional query parameters during normalization', () {
      expect(
        parser.normalizeUrl('https://www.youtube.com/watch?v=$validVideoId&t=42s&feature=youtu.be'),
        'https://www.youtube.com/watch?v=$validVideoId',
      );
    });

    test('normalizes http to canonical https form', () {
      expect(
        parser.normalizeUrl('http://www.youtube.com/watch?v=$validVideoId'),
        'https://www.youtube.com/watch?v=$validVideoId',
      );
    });

    test('throws InvalidYouTubeUrlException for unsupported URL', () {
      expect(
        () => parser.normalizeUrl('https://example.com/watch?v=$validVideoId'),
        throwsA(isA<InvalidYouTubeUrlException>()),
      );
    });
  });
}