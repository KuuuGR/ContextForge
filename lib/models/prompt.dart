/// Domain model representing a prompt template.
///
/// Immutable by design. Use [copyWith] to create modified copies.
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
  });

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
  final bool isDefault;

  /// Creation timestamp as ISO-8601 string.
  final String createdAt;

  /// Last modification timestamp as ISO-8601 string.
  final String updatedAt;

  /// Creates a new [Prompt] with the provided fields replaced.
  Prompt copyWith({
    String? id,
    String? title,
    String? content,
    int? rating,
    bool? isFavorite,
    bool? isDefault,
    String? createdAt,
    String? updatedAt,
  }) {
    return Prompt(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      rating: rating ?? this.rating,
      isFavorite: isFavorite ?? this.isFavorite,
      isDefault: isDefault ?? this.isDefault,
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
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Deserializes a [Prompt] from a JSON-compatible map.
  ///
  /// Missing `isFavorite` / `isDefault` keys default to `false` so older
  /// prompt files remain readable.
  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      rating: json['rating'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? false,
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
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
        id, title, content, rating, isFavorite, isDefault, createdAt, updatedAt);
  }

  @override
  String toString() {
    return 'Prompt(id: $id, title: $title, rating: $rating, '
        'isFavorite: $isFavorite, isDefault: $isDefault, '
        'createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}