import 'package:flutter/widgets.dart';

/// Breakpoint below which the layout is considered "compact" (phone).
///
/// Desktop (macOS) windows are always wider than this, so the desktop layout
/// is never affected. Phones (portrait) are always narrower, so they get the
/// compact reflowed layout.
const double compactBreakpoint = 600;

/// Returns `true` when the available width is a compact (phone) width.
///
/// Used to branch between the frozen desktop layout and the responsive
/// compact layout without changing the desktop appearance.
bool isCompactWidth(double width) => width < compactBreakpoint;

/// Convenience helper for widgets that already have a [BuildContext].
bool isCompact(BuildContext context) =>
    MediaQuery.sizeOf(context).width < compactBreakpoint;
