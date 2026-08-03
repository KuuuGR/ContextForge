/// Display status of a video input card.
///
/// Temporary Phase 010 semantics:
/// - `noUrl`       → gray: no URL entered yet
/// - `loaded`      → green: metadata successfully loaded
/// - `error`       → red: invalid URL or metadata unavailable
/// - `previouslyUsed` → blue: reserved for future history support
enum VideoStatus {
  noUrl,
  loaded,
  error,
  previouslyUsed,
}