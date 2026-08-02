import 'youtube_transcript.dart';
import 'youtube_transcript_info.dart';
import 'youtube_video_metadata.dart';

/// Abstract contract for communication with YouTube.
///
/// Providers encapsulate external integrations. Services depend on this
/// abstraction; repositories never communicate directly with external
/// services.
///
/// This is an interface only — no implementation, no networking.
/// Concrete providers (e.g., based on scraping or a future API client)
/// will implement this contract in later phases.
abstract class YoutubeProvider {
  /// Fetches metadata for the video identified by [videoId].
  ///
  /// Returns `null` when the video does not exist or metadata is unavailable.
  Future<YoutubeVideoMetadata?> getVideoMetadata(String videoId);

  /// Returns the list of transcript tracks available for the video
  /// identified by [videoId].
  ///
  /// Returns an empty list when no transcripts are available.
  Future<List<YoutubeTranscriptInfo>> getAvailableTranscripts(String videoId);

  /// Downloads the transcript for [videoId] using the given [info] track.
  ///
  /// Returns `null` when the transcript cannot be downloaded.
  Future<YoutubeTranscript?> downloadTranscript(
    String videoId,
    YoutubeTranscriptInfo info,
  );
}