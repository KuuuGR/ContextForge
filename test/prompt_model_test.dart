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
      expect(json['isFavorite'], false);
      expect(json['isDefault'], false);
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

    test('fromJson defaults isFavorite/isDefault to false when missing', () {
      final json = prompt.toJson()..remove('isFavorite')..remove('isDefault');
      final decoded = Prompt.fromJson(json);
      expect(decoded.isFavorite, isFalse);
      expect(decoded.isDefault, isFalse);
    });

    test('serializes and deserializes favorite/default flags', () {
      const fav = Prompt(
        id: 'p2',
        title: 'My Favorite',
        content: 'Content',
        rating: 0,
        createdAt: '2026-02-08T10:00:00Z',
        updatedAt: '2026-02-08T10:00:00Z',
        isFavorite: true,
        isDefault: true,
      );

      final json = fav.toJson();
      expect(json['isFavorite'], true);
      expect(json['isDefault'], true);

      final restored = Prompt.fromJson(json);
      expect(restored, fav);
    });

    test('copyWith updates only provided fields', () {
      final updated = prompt.copyWith(title: 'Newsletter');
      expect(updated.id, prompt.id);
      expect(updated.title, 'Newsletter');
      expect(updated.content, prompt.content);
      expect(updated.rating, prompt.rating);
      expect(updated.isFavorite, prompt.isFavorite);
      expect(updated.isDefault, prompt.isDefault);
      expect(updated.createdAt, prompt.createdAt);
      expect(updated.updatedAt, prompt.updatedAt);
    });

    test('copyWith can set favorite and default', () {
      final updated = prompt.copyWith(isFavorite: true, isDefault: true);
      expect(updated.isFavorite, isTrue);
      expect(updated.isDefault, isTrue);
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
      expect(prompt.copyWith(isFavorite: true), isNot(prompt));
      expect(prompt.copyWith(isDefault: true), isNot(prompt));
    });

    test('toString is readable', () {
      final text = prompt.toString();
      expect(text, contains('Prompt(id: p1'));
      expect(text, contains('title: SEO Article'));
      expect(text, contains('rating: 0'));
      expect(text, contains('isFavorite: false'));
      expect(text, contains('isDefault: false'));
    });
  });
}