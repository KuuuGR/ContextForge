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
  });

  /// Unique identifier for the prompt.
  final String id;

  /// Display title of the prompt.
  final String title;

  /// Prompt text content.
  final String content;

  /// Rating score (0 = unrated).
  final int rating;

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
    String? createdAt,
    String? updatedAt,
  }) {
    return Prompt(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      rating: rating ?? this.rating,
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
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Deserializes a [Prompt] from a JSON-compatible map.
  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      rating: json['rating'] as int? ?? 0,
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
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, content, rating, createdAt, updatedAt);
  }

  @override
  String toString() {
    return 'Prompt(id: $id, title: $title, rating: $rating, '
        'createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}