import 'package:flutter/foundation.dart';

import '../services/video_service.dart';
import '../services/youtube_url_parser.dart';
import 'video_card_state.dart';

/// Presentation-layer controller for a single video card.
///
/// Owns the entered URL, current state, validation status, and extracted
/// videoId. Communicates only with [YouTubeUrlParser] and [VideoService].
/// No direct UI logic, no provider access, no networking.
///
/// State changes are exposed via [ChangeNotifier] (Flutter-friendly,
/// consistent with the existing architecture).
///
/// Future phases will add metadata and loading states; this phase only
/// covers URL entry and validation.
class VideoCardController extends ChangeNotifier {
  VideoCardController({
    required this.videoService,
    YouTubeUrlParser? parser,
  }) : _parser = parser ?? const YouTubeUrlParser();

  /// Video service retained for future metadata phases; not invoked in this
  /// phase by design.
  final VideoService videoService;

  final YouTubeUrlParser _parser;

  VideoCardState _state = VideoCardState.empty;
  VideoCardState get state => _state;

  String _url = '';
  String get url => _url;

  bool get isValid => _state == VideoCardState.valid;
  bool get isInvalid => _state == VideoCardState.invalid;

  String? _videoId;
  String? get videoId => _videoId;

  /// Records a URL as it is being edited.
  ///
  /// Transitions [VideoCardState.editing] while the user types and clears
  /// any previous validation result.
  void setUrl(String url) {
    _url = url;
    _videoId = null;
    _setState(VideoCardState.editing);
  }

  /// Clears the URL, extracted videoId, and returns to [VideoCardState.empty].
  void clear() {
    _url = '';
    _videoId = null;
    _setState(VideoCardState.empty);
  }

  /// Validates the currently entered URL.
  ///
  /// - Valid URL → [VideoCardState.valid] and the canonical [videoId] is set.
  /// - Invalid URL → [VideoCardState.invalid] and [videoId] is null.
  /// - Empty/whitespace URL → [VideoCardState.empty].
  void validate() {
    final trimmed = _url.trim();
    if (trimmed.isEmpty) {
      _videoId = null;
      _setState(VideoCardState.empty);
      return;
    }

    try {
      final id = _parser.extractVideoId(trimmed);
      _videoId = id;
      _setState(VideoCardState.valid);
    } on Exception {
      _videoId = null;
      _setState(VideoCardState.invalid);
    }
  }

  void _setState(VideoCardState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }
}
