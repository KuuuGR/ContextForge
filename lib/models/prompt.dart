import 'prompt_quick_access.dart';

/// Domain model representing a prompt template.
///
/// Immutable by design. Use [copyWith] to create modified copies.
///
/// Business rule: Default always implies Favorite. A prompt with
/// `isDefault = true` must also have `isFavorite = true`.
class Prompt {
  const Prompt({
    required this.id,
    required this.title,
    required this.content,
    this.rating = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.isDefault = false,
    this.quickAccess = PromptQuickAccess.none,
  }) : assert(
          !isDefault || isFavorite,
          'Default implies Favorite.',
        );

  /// Unique identifier for the prompt.
  final String id;

  /// Display title of the prompt.
  final String title;

  /// Prompt text content.
  final String content;

  /// Rating score (0 = unrated).
  final int rating;

  /// Whether the prompt is marked as a Favorite.
  final bool isFavorite;

  /// Whether this prompt is the single Default Prompt.
  /// Default always implies Favorite.
  final bool isDefault;

  /// Quick Access role assignment.
  final PromptQuickAccess quickAccess;

  /// Creation timestamp as ISO-8601 string.
  final String createdAt;

  /// Last modification timestamp as ISO-8601 string.
  final String updatedAt;

  /// Creates a new [Prompt] with the provided fields replaced.
  ///
  /// If [isDefault] is set to `true`, [isFavorite] is forced to `true`.
  Prompt copyWith({
    String? id,
    String? title,
    String? content,
    int? rating,
    bool? isFavorite,
    bool? isDefault,
    PromptQuickAccess? quickAccess,
    String? createdAt,
    String? updatedAt,
  }) {
    final newDefault = isDefault ?? this.isDefault;
    final newFavorite = isFavorite ?? this.isFavorite;
    return Prompt(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      rating: rating ?? this.rating,
      isFavorite: newDefault ? true : newFavorite,
      isDefault: newDefault,
      quickAccess: quickAccess ?? this.quickAccess,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serializes this prompt to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'rating': rating,
      'isFavorite': isFavorite,
      'isDefault': isDefault,
      'quickAccess': quickAccess.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Deserializes a [Prompt] from a JSON-compatible map.
  ///
  /// Missing `isFavorite` / `isDefault` / `quickAccess` keys default to
  /// safe values so older prompt files remain readable.
  /// If `isDefault` is `true`, `isFavorite` is forced to `true`.
  factory Prompt.fromJson(Map<String, dynamic> json) {
    final isDefault = json['isDefault'] as bool? ?? false;
    final isFavorite = json['isFavorite'] as bool? ?? false;
    return Prompt(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      rating: json['rating'] as int? ?? 0,
      isFavorite: isDefault ? true : isFavorite,
      isDefault: isDefault,
      quickAccess:
          PromptQuickAccess.fromName(json['quickAccess'] as String?),
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Prompt &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.rating == rating &&
        other.isFavorite == isFavorite &&
        other.isDefault == isDefault &&
        other.quickAccess == quickAccess &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
        id, title, content, rating, isFavorite, isDefault, quickAccess,
        createdAt, updatedAt);
  }

  @override
  String toString() {
    return 'Prompt(id: $id, title: $title, rating: $rating, '
        'isFavorite: $isFavorite, isDefault: $isDefault, '
        'quickAccess: $quickAccess, '
        'createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}