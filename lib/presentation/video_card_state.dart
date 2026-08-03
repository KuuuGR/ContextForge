/// Typed state of a single video card in the presentation layer.
///
/// Metadata/loading states belong to later phases — this phase only
/// covers URL entry and validation.
enum VideoCardState {
  /// No URL has been entered.
  empty,

  /// The user is currently editing the URL; not yet validated.
  editing,

  /// The URL parsed successfully and a videoId was extracted.
  valid,

  /// The URL is malformed or unsupported.
  invalid,
}