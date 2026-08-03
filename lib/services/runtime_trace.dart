import 'package:flutter/foundation.dart';

/// Minimal runtime execution tracer for the UI workflow.
///
/// Prints a strictly sequential, numbered trace of the actual execution path.
/// Pure diagnostics — no business logic, no UI, no state stored.
///
/// Usage contract:
/// - [step] MUST be called BEFORE the corresponding work executes.
/// - If a step is skipped, it will not appear in the console — the sequence
///   of printed numbers therefore mirrors the real execution order.
/// - [boundary] marks a failure: the LAST [step] printed before it is the
///   stage at which execution failed.
class RuntimeTrace {
  static int _step = 0;

  /// Resets the step counter. Useful between independent user actions
  /// so each trace starts at [1].
  static void reset() {
    _step = 0;
  }

  /// Prints the next numbered step before the work executes.
  static void step(String message) {
    _step += 1;
    debugPrint('[TRACE][$_step] $message');
  }

  /// Marks a failure boundary. The last [step] before this line is the
  /// failing stage.
  static void boundary(String message) {
    debugPrint('[TRACE][BOUNDARY] $message');
  }
}
