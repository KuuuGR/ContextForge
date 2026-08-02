/// Preferred transcript language/origin enumeration.
///
/// Used instead of raw strings throughout the application to keep
/// transcript handling type-safe and consistent with the spec's
/// preferred transcript order:
///
///  1. manual Polish
///  2. automatic Polish
///  3. manual English
///  4. automatic English
///  5. any available transcript
enum TranscriptLanguage {
  polish,
  polishAuto,
  english,
  englishAuto,
  other,
  none;

  /// Returns the human-readable label for display purposes.
  String get label {
    switch (this) {
      case TranscriptLanguage.polish:
        return 'Manual Polish';
      case TranscriptLanguage.polishAuto:
        return 'Automatic Polish';
      case TranscriptLanguage.english:
        return 'Manual English';
      case TranscriptLanguage.englishAuto:
        return 'Automatic English';
      case TranscriptLanguage.other:
        return 'Other';
      case TranscriptLanguage.none:
        return 'None';
    }
  }
}