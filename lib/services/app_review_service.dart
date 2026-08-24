import 'package:flutter/services.dart';

import 'review_store.dart';

/// Thin Flutter wrapper around the native App Store review request.
///
/// The actual system review prompt is presented by Apple (via
/// `AppStore.requestReview(in:)` on macOS 13.0+ / iOS 16.0+). We only decide
/// **when** to call it and track our own eligibility. We never assume Apple
/// displayed the prompt or that a rating/review was submitted, and we never try
/// to read the user's rating.
///
/// Keep the channel name in sync with the native side:
/// - macOS: `macos/Runner/MainFlutterWindow.swift`
/// - iOS: `ios/Runner/AppDelegate.swift`
class AppReviewService {
  AppReviewService({ReviewStore? store}) : store = store ?? ReviewStore();

  static const MethodChannel _channel = MethodChannel('contextforge/review');

  final ReviewStore store;

  /// Records one completed meaningful workflow.
  ///
  /// Sets the first-meaningful-use date (once) and increments the meaningful
  /// workflow counter. Called after a successful workflow, never at app launch
  /// and never when opening Settings/About.
  Future<void> recordMeaningfulUse() async {
    final state = await store.load();
    final updated = state.recordMeaningfulUse(DateTime.now());
    await store.save(updated);
  }

  /// Requests a review now **only if** the user is eligible.
  ///
  /// Returns `true` when we invoked Apple's review API (not whether Apple
  /// displayed the prompt).
  Future<bool> requestReviewIfEligible() async {
    final state = await store.load();
    final now = DateTime.now();
    final version = await _currentVersion();
    if (!state.isEligible(now: now, currentVersion: version)) {
      return false;
    }
    final requested = await _requestReview();
    if (!requested) return false;
    // We asked; move to the next checkpoint and stop asking for this version.
    await store.save(state.markRequested(version));
    return true;
  }

  Future<bool> _requestReview() async {
    try {
      await _channel.invokeMethod<void>('requestReview');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> _currentVersion() async {
    try {
      return await _channel.invokeMethod<String>('getVersion') ?? '';
    } catch (_) {
      return '';
    }
  }
}
