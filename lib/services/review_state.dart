/// Pure eligibility model + timing logic for App Store review requests.
///
/// This file intentionally has **no** dependency on Flutter or StoreKit so the
/// eligibility rules can be unit-tested in isolation.
///
/// Apple's StoreKit decides whether the system review prompt is actually shown
/// (and limits it). We only control our own internal eligibility timing and
/// when we call Apple's review API. We never assume a rating/review was
/// received or that the prompt was displayed.
library;

/// A single eligibility checkpoint: how long the user has used the app and how
/// many meaningful workflows they must have completed to qualify.
///
/// Eligibility deliberately requires **both** elapsed time and a minimum number
/// of completed meaningful workflows. This keeps the system conservative and
/// never asks new or infrequent users for a review.
class ReviewCheckpoint {
  const ReviewCheckpoint({
    required this.duration,
    required this.minimumCompletedWorkflows,
  });

  /// Minimum time since the first meaningful use.
  final Duration duration;

  /// Minimum cumulative number of completed meaningful workflows.
  final int minimumCompletedWorkflows;
}

/// Configurable product policy for review opportunities.
///
/// The exact intervals and workflow counters live here (not in the eligibility
/// logic) so they can be tuned later without redesigning the review system.
class ReviewPolicy {
  const ReviewPolicy({required this.checkpoints});

  /// Ordered list of review opportunities. The state advances through these
  /// as the user is asked (across app versions).
  final List<ReviewCheckpoint> checkpoints;

  bool get hasCheckpoints => checkpoints.isNotEmpty;

  int get checkpointCount => checkpoints.length;

  /// Conservative default policy:
  ///   1. ~30 days and 30 completed meaningful workflows
  ///   2. ~3 months and 45 completed meaningful workflows
  ///   3. ~1 year and 60 completed meaningful workflows
  ///
  /// These are product decisions and can be adjusted here.
  static const ReviewPolicy defaultPolicy = ReviewPolicy(
    checkpoints: [
      ReviewCheckpoint(
          duration: Duration(days: 30), minimumCompletedWorkflows: 30),
      ReviewCheckpoint(
          duration: Duration(days: 90), minimumCompletedWorkflows: 45),
      ReviewCheckpoint(
          duration: Duration(days: 365), minimumCompletedWorkflows: 60),
    ],
  );
}

/// Serializable review-request state persisted locally.
class ReviewState {
  const ReviewState({
    this.firstMeaningfulUseDate,
    this.meaningfulUseCount = 0,
    this.lastRequestedReviewVersion,
    this.checkpointIndex = 0,
    this.policy = ReviewPolicy.defaultPolicy,
  });

  /// When the user first completed a meaningful workflow (local ISO-8601 UTC).
  final DateTime? firstMeaningfulUseDate;

  /// Cumulative number of completed meaningful workflows.
  ///
  /// Incremented only by actual use of ContextForge's core functionality —
  /// never by app launches or opening Settings/About.
  final int meaningfulUseCount;

  /// The app version (marketing/build) for which we last requested a review.
  final String? lastRequestedReviewVersion;

  /// Index into [policy.checkpoints] of the next eligible opportunity to use.
  final int checkpointIndex;

  /// The product policy driving the checkpoints.
  final ReviewPolicy policy;

  bool get hasFirstMeaningfulUse => firstMeaningfulUseDate != null;

  /// The date of the next eligible checkpoint, or `null` when none remain.
  DateTime? get nextCheckpointDate {
    final start = firstMeaningfulUseDate;
    if (start == null) return null;
    if (checkpointIndex >= policy.checkpointCount) return null;
    return start.add(policy.checkpoints[checkpointIndex].duration);
  }

  /// Whether a review request should be attempted at [now] for
  /// [currentVersion].
  ///
  /// Deliberately conservative — all of the following must hold:
  /// - a first meaningful use has been recorded (a plain app launch never
  ///   triggers anything),
  /// - the current checkpoint's elapsed time has been reached,
  /// - the current checkpoint's minimum completed-workflow count has been
  ///   reached,
  /// - we have not already requested for this app version.
  bool isEligible({required DateTime now, required String currentVersion}) {
    final start = firstMeaningfulUseDate;
    if (start == null) return false;
    if (checkpointIndex >= policy.checkpointCount) return false;
    if (lastRequestedReviewVersion == currentVersion) return false;
    final checkpoint = policy.checkpoints[checkpointIndex];
    final timeReached = !now.isBefore(start.add(checkpoint.duration));
    final usageReached =
        meaningfulUseCount >= checkpoint.minimumCompletedWorkflows;
    return timeReached && usageReached;
  }

  /// Records one completed meaningful workflow.
  ///
  /// Sets the first-meaningful-use date the first time (no-op for that field
  /// afterwards) and increments the cumulative workflow counter.
  ReviewState recordMeaningfulUse(DateTime now) {
    return ReviewState(
      firstMeaningfulUseDate: firstMeaningfulUseDate ?? now,
      meaningfulUseCount: meaningfulUseCount + 1,
      lastRequestedReviewVersion: lastRequestedReviewVersion,
      checkpointIndex: checkpointIndex,
      policy: policy,
    );
  }

  /// Marks that a review was requested for [version] and advances to the next
  /// checkpoint.
  ///
  /// Called after we invoke Apple's review API, **regardless of whether Apple
  /// actually displayed the prompt** — we do not try to read the outcome.
  ReviewState markRequested(String version) {
    final nextIndex = checkpointIndex < policy.checkpointCount
        ? checkpointIndex + 1
        : checkpointIndex;
    return ReviewState(
      firstMeaningfulUseDate: firstMeaningfulUseDate,
      meaningfulUseCount: meaningfulUseCount,
      lastRequestedReviewVersion: version,
      checkpointIndex: nextIndex,
      policy: policy,
    );
  }

  Map<String, dynamic> toJson() => {
        'firstMeaningfulUseDate':
            firstMeaningfulUseDate?.toUtc().toIso8601String(),
        'meaningfulUseCount': meaningfulUseCount,
        'lastRequestedReviewVersion': lastRequestedReviewVersion,
        'checkpointIndex': checkpointIndex,
      };

  factory ReviewState.fromJson(Map<String, dynamic> json) {
    return ReviewState(
      firstMeaningfulUseDate: _parseDate(json['firstMeaningfulUseDate']),
      meaningfulUseCount: (json['meaningfulUseCount'] as num?)?.toInt() ?? 0,
      lastRequestedReviewVersion:
          json['lastRequestedReviewVersion'] as String?,
      checkpointIndex: (json['checkpointIndex'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ReviewState &&
      other.firstMeaningfulUseDate == firstMeaningfulUseDate &&
      other.meaningfulUseCount == meaningfulUseCount &&
      other.lastRequestedReviewVersion == lastRequestedReviewVersion &&
      other.checkpointIndex == checkpointIndex &&
      other.policy == policy;

  @override
  int get hashCode => Object.hash(firstMeaningfulUseDate, meaningfulUseCount,
      lastRequestedReviewVersion, checkpointIndex, policy);
}
