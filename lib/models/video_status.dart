/// Display status of a video input card.
///
/// Semantics:
/// - `noUrl`         → gray/neutral: no URL entered yet, or URL not
///   previously processed
/// - `loaded`        → green: metadata successfully loaded
/// - `error`         → red: invalid URL or metadata unavailable
/// - `previouslyUsed` → green: URL has been successfully processed before
enum VideoStatus {
  noUrl,
  loaded,
  error,
  previouslyUsed,
}