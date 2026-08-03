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
    required this.languageCode,
    this.isTranslatable = false,
  });

  /// Transcript language/origin.
  final TranscriptLanguage language;

  /// Whether the transcript is manually created (`true`) or auto-generated (`false`).
  final bool isManual;

  /// Human-readable language name from the provider (e.g., "Polish").
  final String languageName;

  /// ISO 639-1 language code from the provider (e.g., "pl", "en").
  final String languageCode;

  /// Whether the track can be auto-translated by the provider.
  final bool isTranslatable;

  /// Creates a new [YoutubeTranscriptInfo] with the provided fields replaced.
  YoutubeTranscriptInfo copyWith({
    TranscriptLanguage? language,
    bool? isManual,
    String? languageName,
    String? languageCode,
    bool? isTranslatable,
  }) {
    return YoutubeTranscriptInfo(
      language: language ?? this.language,
      isManual: isManual ?? this.isManual,
      languageName: languageName ?? this.languageName,
      languageCode: languageCode ?? this.languageCode,
      isTranslatable: isTranslatable ?? this.isTranslatable,
    );
  }

  /// Serializes this DTO to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'language': language.name,
      'isManual': isManual,
      'languageName': languageName,
      'languageCode': languageCode,
      'isTranslatable': isTranslatable,
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
      languageCode: json['languageCode'] as String? ?? '',
      isTranslatable: json['isTranslatable'] as bool? ?? false,
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
        other.languageName == languageName &&
        other.languageCode == languageCode &&
        other.isTranslatable == isTranslatable;
  }

  @override
  int get hashCode {
    return Object.hash(language, isManual, languageName, languageCode, isTranslatable);
  }

  @override
  String toString() {
    return 'YoutubeTranscriptInfo(language: $language, isManual: $isManual, '
        'languageName: $languageName)';
  }
}