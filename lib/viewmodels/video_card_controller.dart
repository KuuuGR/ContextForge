import 'package:flutter/foundation.dart';

import '../exceptions/youtube_exceptions.dart';
import '../models/video.dart';
import '../models/video_status.dart';
import '../services/video_service.dart';

/// Presentation-layer controller for one video input card.
/// Owns UI state and delegates workflows to [VideoService].
class VideoCardController extends ChangeNotifier {
  VideoCardController({required this.service});

  final VideoService service;

  VideoStatus _status = VideoStatus.noUrl;
  VideoStatus get status => _status;

  Video? _video;
  Video? get video => _video;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool get hasMetadata => _video != null;

  Future<void> loadMetadata(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      _setState(status: VideoStatus.noUrl, video: null, errorMessage: null);
      return;
    }

    _setState(status: VideoStatus.noUrl, video: null, errorMessage: null);
    _isLoading = true;
    notifyListeners();

    try {
      final video = await service.fetchVideoMetadata(trimmed);
      _setState(status: VideoStatus.loaded, video: video, errorMessage: null);
    } on InvalidYouTubeUrlException {
      _setState(
          status: VideoStatus.error,
          video: null,
          errorMessage: 'Invalid YouTube URL. Please check the link.');
    } on YoutubeVideoUnavailableException {
      _setState(
          status: VideoStatus.error,
          video: null,
          errorMessage: 'This video is unavailable. It may be private or deleted.');
    } on YoutubeNetworkException {
      _setState(
          status: VideoStatus.error,
          video: null,
          errorMessage: 'Could not reach YouTube. Check your connection.');
    } catch (e) {
      debugPrint('VideoCardController: unexpected error: $e');
      _setState(
          status: VideoStatus.error,
          video: null,
          errorMessage: 'Something went wrong while loading the video.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setState({
    required VideoStatus status,
    required Video? video,
    required String? errorMessage,
  }) {
    _status = status;
    _video = video;
    _errorMessage = errorMessage;
    notifyListeners();
  }
}