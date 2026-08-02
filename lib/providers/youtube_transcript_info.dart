import '../models/transcript_language.dart';

/// Provider-specific DTO describing an available transcript track.
///
/// This is NOT a domain model. It belongs to the provider layer and
/// mirrors the shape of the external YouTube transcript data.
///
/// Immutable by design. Use [copyWith] to create modified copies.
class YoutubeTranscriptInfo {
  const YoutubeTranscriptInfo({
    required this.language,
    required this.isManual,
    required this.languageName,
  });

  /// Transcript language/origin.
  final TranscriptLanguage language;

  /// Whether the transcript is manually created (`true`) or auto-generated (`false`).
  final bool isManual;

  /// Human-readable language name from the provider (e.g., "Polish (auto-generated)").
  final String languageName;

  /// Creates a new [YoutubeTranscriptInfo] with the provided fields replaced.
  YoutubeTranscriptInfo copyWith({
    TranscriptLanguage? language,
    bool? isManual,
    String? languageName,
  }) {
    return YoutubeTranscriptInfo(
      language: language ?? this.language,
      isManual: isManual ?? this.isManual,
      languageName: languageName ?? this.languageName,
    );
  }

  /// Serializes this DTO to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'language': language.name,
      'isManual': isManual,
      'languageName': languageName,
    };
  }

  /// Deserializes a [YoutubeTranscriptInfo] from a JSON-compatible map.
  ///
  /// Unknown language values default to [TranscriptLanguage.other].
  factory YoutubeTranscriptInfo.fromJson(Map<String, dynamic> json) {
    return YoutubeTranscriptInfo(
      language: _parseLanguage(json['language']),
      isManual: json['isManual'] as bool? ?? false,
      languageName: json['languageName'] as String? ?? '',
    );
  }

  static TranscriptLanguage _parseLanguage(Object? value) {
    if (value is String) {
      for (final language in TranscriptLanguage.values) {
        if (language.name == value) {
          return language;
        }
      }
    }
    return TranscriptLanguage.other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YoutubeTranscriptInfo &&
        other.language == language &&
        other.isManual == isManual &&
        other.languageName == languageName;
  }

  @override
  int get hashCode {
    return Object.hash(language, isManual, languageName);
  }

  @override
  String toString() {
    return 'YoutubeTranscriptInfo(language: $language, isManual: $isManual, '
        'languageName: $languageName)';
  }
}