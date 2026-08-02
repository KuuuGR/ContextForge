import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/models/prompt.dart';

void main() {
  const prompt = Prompt(
    id: 'p1',
    title: 'SEO Article',
    content: 'Write an SEO article about...',
    rating: 0,
    createdAt: '2026-02-08T10:00:00Z',
    updatedAt: '2026-02-08T10:00:00Z',
  );

  group('Prompt', () {
    test('serializes to JSON', () {
      final json = prompt.toJson();
      expect(json['id'], 'p1');
      expect(json['title'], 'SEO Article');
      expect(json['content'], 'Write an SEO article about...');
      expect(json['rating'], 0);
      expect(json['createdAt'], '2026-02-08T10:00:00Z');
      expect(json['updatedAt'], '2026-02-08T10:00:00Z');
    });

    test('deserializes from JSON', () {
      final json = prompt.toJson();
      final decoded = Prompt.fromJson(json);
      expect(decoded, prompt);
    });

    test('fromJson defaults rating when missing', () {
      final json = prompt.toJson()..remove('rating');
      final decoded = Prompt.fromJson(json);
      expect(decoded.rating, 0);
    });

    test('copyWith updates only provided fields', () {
      final updated = prompt.copyWith(title: 'Newsletter');
      expect(updated.id, prompt.id);
      expect(updated.title, 'Newsletter');
      expect(updated.content, prompt.content);
      expect(updated.rating, prompt.rating);
      expect(updated.createdAt, prompt.createdAt);
      expect(updated.updatedAt, prompt.updatedAt);
    });

    test('equality compares all fields', () {
      final same = Prompt(
        id: 'p1',
        title: 'SEO Article',
        content: 'Write an SEO article about...',
        rating: 0,
        createdAt: '2026-02-08T10:00:00Z',
        updatedAt: '2026-02-08T10:00:00Z',
      );
      expect(prompt, same);
      expect(prompt.hashCode, same.hashCode);
      expect(prompt.copyWith(id: 'p2'), isNot(prompt));
    });

    test('toString is readable', () {
      final text = prompt.toString();
      expect(text, contains('Prompt(id: p1'));
      expect(text, contains('title: SEO Article'));
      expect(text, contains('rating: 0'));
    });
  });
}