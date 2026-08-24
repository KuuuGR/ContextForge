import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:context_forge/services/review_state.dart';
import 'package:context_forge/services/review_store.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 12, 0, 0);
  const version = '1.1.0';
  final policy = ReviewPolicy.defaultPolicy;
  final firstCheckpoint = policy.checkpoints[0];
  final secondCheckpoint = policy.checkpoints[1];
  final thirdCheckpoint = policy.checkpoints[2];

  group('ReviewState meaningful usage', () {
    test('recordMeaningfulUse establishes the first use date and count', () {
      final state = const ReviewState();
      final updated = state.recordMeaningfulUse(t0);
      expect(updated.firstMeaningfulUseDate, t0);
      expect(updated.hasFirstMeaningfulUse, isTrue);
      expect(updated.meaningfulUseCount, 1);
      expect(updated.checkpointIndex, 0);
    });

    test('each meaningful workflow increments the counter (date set once)', () {
      final once = const ReviewState().recordMeaningfulUse(t0);
      final twice =
          once.recordMeaningfulUse(t0.add(const Duration(minutes: 1)));
      final thrice =
          twice.recordMeaningfulUse(t0.add(const Duration(minutes: 2)));
      expect(once.meaningfulUseCount, 1);
      expect(twice.meaningfulUseCount, 2);
      expect(thrice.meaningfulUseCount, 3);
      expect(thrice.firstMeaningfulUseDate, t0); // not overwritten
    });

    test('not eligible without enough elapsed time, even with usage', () {
      final state = ReviewState(
          firstMeaningfulUseDate: t0, meaningfulUseCount: 100);
      expect(
        state.isEligible(
            now: t0.add(const Duration(days: 10)), currentVersion: version),
        isFalse,
      );
    });

    test('not eligible without enough usage, even after time', () {
      final state = ReviewState(
          firstMeaningfulUseDate: t0, meaningfulUseCount: 5);
      expect(
        state.isEligible(
            now: t0.add(const Duration(days: 400)), currentVersion: version),
        isFalse,
      );
    });

    test('becomes eligible at the first checkpoint (time AND usage)', () {
      final state = ReviewState(
        firstMeaningfulUseDate: t0,
        meaningfulUseCount: firstCheckpoint.minimumCompletedWorkflows,
      );
      expect(
        state.isEligible(now: t0.add(firstCheckpoint.duration),
            currentVersion: version),
        isTrue,
      );
    });

    test('is conservative: just below the usage threshold is not eligible', () {
      final state = ReviewState(
        firstMeaningfulUseDate: t0,
        meaningfulUseCount: firstCheckpoint.minimumCompletedWorkflows - 1,
      );
      expect(
        state.isEligible(now: t0.add(firstCheckpoint.duration),
            currentVersion: version),
        isFalse,
      );
    });

    test('after requesting, does not immediately request again', () {
      final state = ReviewState(
        firstMeaningfulUseDate: t0,
        meaningfulUseCount: firstCheckpoint.minimumCompletedWorkflows,
      );
      final requested = state.markRequested(version);
      expect(requested.lastRequestedReviewVersion, version);
      expect(requested.checkpointIndex, 1);
      // Same version is never re-requested, even much later with more usage.
      expect(
        requested.isEligible(
            now: t0.add(const Duration(days: 200)),
            currentVersion: version),
        isFalse,
      );
    });

    test('eligible for the second checkpoint on a new version', () {
      final state = ReviewState(
        firstMeaningfulUseDate: t0,
        meaningfulUseCount: secondCheckpoint.minimumCompletedWorkflows,
        lastRequestedReviewVersion: version,
        checkpointIndex: 1,
      );
      final atSecond = t0.add(secondCheckpoint.duration);
      expect(
        state.isEligible(now: atSecond, currentVersion: '1.0.2'),
        isTrue,
      );
      // The old version stays blocked.
      expect(
        state.isEligible(now: atSecond, currentVersion: version),
        isFalse,
      );
    });

    test('eligible for the yearly (third) checkpoint', () {
      final state = ReviewState(
        firstMeaningfulUseDate: t0,
        meaningfulUseCount: thirdCheckpoint.minimumCompletedWorkflows,
        lastRequestedReviewVersion: '1.0.2',
        checkpointIndex: 2,
      );
      final atThird = t0.add(thirdCheckpoint.duration);
      expect(
        state.isEligible(now: atThird, currentVersion: '1.1.0'),
        isTrue,
      );
    });

    test('a new app launch alone never triggers a request', () {
      // No first meaningful use and zero workflows (fresh launch) → never
      // eligible regardless of time.
      const state = ReviewState();
      expect(state.meaningfulUseCount, 0);
      expect(
        state.isEligible(
            now: t0.add(const Duration(days: 999)), currentVersion: version),
        isFalse,
      );
    });

    test('repeated workflows do not cause repeated requests in one period',
        () {
      final state = ReviewState(
        firstMeaningfulUseDate: t0,
        meaningfulUseCount: firstCheckpoint.minimumCompletedWorkflows,
      );
      expect(
        state.isEligible(now: t0.add(firstCheckpoint.duration),
            currentVersion: version),
        isTrue,
      );
      final afterRequest = state.markRequested(version);
      // Many more workflows in the same version: still not eligible.
      expect(
        afterRequest.isEligible(
            now: t0.add(firstCheckpoint.duration).add(const Duration(days: 30)),
            currentVersion: version),
        isFalse,
      );
    });

    test('state survives a restart (serializes count and fields)', () {
      final original = ReviewState(
        firstMeaningfulUseDate: t0,
        meaningfulUseCount: firstCheckpoint.minimumCompletedWorkflows,
        lastRequestedReviewVersion: version,
        checkpointIndex: 1,
      );
      final restored = ReviewState.fromJson(original.toJson());
      expect(restored, original);
      expect(restored.firstMeaningfulUseDate, t0);
      expect(restored.meaningfulUseCount,
          firstCheckpoint.minimumCompletedWorkflows);
      expect(restored.lastRequestedReviewVersion, version);
      expect(restored.checkpointIndex, 1);
    });

    test('logic does not depend on the review being displayed by Apple', () {
      final state = ReviewState(
        firstMeaningfulUseDate: t0,
        meaningfulUseCount: firstCheckpoint.minimumCompletedWorkflows,
      );
      // We mark requested after invoking Apple's API regardless of display.
      final afterRequest = state.markRequested(version);
      expect(afterRequest.lastRequestedReviewVersion, version);
      expect(afterRequest.checkpointIndex, 1);
      expect(
        afterRequest.isEligible(
            now: t0.add(firstCheckpoint.duration),
            currentVersion: version),
        isFalse,
      );
    });

    test('no more checkpoints remain after the final one', () {
      final state = ReviewState(
        firstMeaningfulUseDate: t0,
        meaningfulUseCount: 1000,
        lastRequestedReviewVersion: '1.1.0',
        checkpointIndex: policy.checkpointCount,
      );
      expect(state.nextCheckpointDate, isNull);
      expect(
        state.isEligible(
            now: t0.add(const Duration(days: 999)), currentVersion: '1.2.0'),
        isFalse,
      );
    });
  });

  group('ReviewStore', () {
    test('persists count and state across instances (restart)', () async {
      final temp = await Directory.systemTemp.createTemp('review_test_');
      addTearDown(() => temp.delete(recursive: true));

      final store1 = ReviewStore(directoryPath: temp.path);
      final store2 = ReviewStore(directoryPath: temp.path);

      await store1.save(
        ReviewState(
          firstMeaningfulUseDate: t0,
          meaningfulUseCount: 42,
          lastRequestedReviewVersion: version,
          checkpointIndex: 1,
        ),
      );

      final loaded = await store2.load();
      expect(loaded.firstMeaningfulUseDate, t0);
      expect(loaded.meaningfulUseCount, 42);
      expect(loaded.lastRequestedReviewVersion, version);
      expect(loaded.checkpointIndex, 1);
    });

    test('load returns a fresh state when the file is missing', () async {
      final temp = await Directory.systemTemp.createTemp('review_test_');
      addTearDown(() => temp.delete(recursive: true));
      final store = ReviewStore(directoryPath: temp.path);
      final loaded = await store.load();
      expect(loaded.firstMeaningfulUseDate, isNull);
      expect(loaded.meaningfulUseCount, 0);
      expect(loaded.lastRequestedReviewVersion, isNull);
      expect(loaded.checkpointIndex, 0);
    });

    test('load tolerates invalid JSON', () async {
      final temp = await Directory.systemTemp.createTemp('review_test_');
      addTearDown(() => temp.delete(recursive: true));
      await File('${temp.path}${Platform.pathSeparator}review_state.json')
          .writeAsString('{ not json');
      final store = ReviewStore(directoryPath: temp.path);
      final loaded = await store.load();
      expect(loaded.firstMeaningfulUseDate, isNull);
      expect(loaded.meaningfulUseCount, 0);
    });
  });
}

