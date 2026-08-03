import 'transcript_track.dart';

/// Reason why a transcript track was selected (or not).
enum TranscriptSelectionReason {
  manualPolish,
  autoPolish,
  manualEnglish,
  autoEnglish,
  otherManual,
  otherAuto,
  noTranscript,
}

/// Priority rank used to order transcript tracks.
enum TranscriptPriority {
  manualPolish(1),
  autoPolish(2),
  manualEnglish(3),
  autoEnglish(4),
  otherManual(5),
  otherAuto(6),
  none(7);

  const TranscriptPriority(this.rank);

  final int rank;
}

/// Result of transcript selection for a video.
sealed class TranscriptSelectionResult {
  const TranscriptSelectionResult();
}

/// A transcript track was selected.
class TranscriptSelected extends TranscriptSelectionResult {
  const TranscriptSelected({
    required this.track,
    required this.reason,
    required this.priority,
  });

  final TranscriptTrack track;
  final TranscriptSelectionReason reason;
  final TranscriptPriority priority;

  @override
  bool operator ==(Object other) =>
      other is TranscriptSelected &&
      other.track == track &&
      other.reason == reason &&
      other.priority == priority;

  @override
  int get hashCode => Object.hash(track, reason, priority);

  @override
  String toString() =>
      'TranscriptSelected(track: $track, reason: $reason, priority: $priority)';
}

/// No transcript is available; Whisper transcription may be required.
class TranscriptUnavailable extends TranscriptSelectionResult {
  const TranscriptUnavailable();

  @override
  bool operator ==(Object other) => other is TranscriptUnavailable;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'TranscriptUnavailable';
}