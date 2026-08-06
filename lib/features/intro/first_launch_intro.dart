import 'package:flutter/material.dart';

import '../../resources/context_reflections.dart';

/// One-time First Launch Intro.
///
/// A calm, premium editorial introduction shown only once after installation.
/// Uses opacity-only fades with the following choreography:
///
/// 1. Etaosin logo (0.0s – 2.0s)
/// 2. "presents" (2.0s – 3.5s)
/// 3. ContextForge (3.5s – 5.5s)
/// 4. Subtitle (5.5s – 7.0s)
/// 5. Editorial divider (7.0s – 8.0s)
/// 6. Random Context Reflection (8.0s – 10.5s)
/// 7. Fade out (10.5s – 12.0s)
/// 8. onComplete fires
class FirstLaunchIntro extends StatefulWidget {
  const FirstLaunchIntro({super.key, required this.onComplete});

  /// Called when the intro animation finishes.
  final VoidCallback onComplete;

  @override
  State<FirstLaunchIntro> createState() => _FirstLaunchIntroState();
}

class _FirstLaunchIntroState extends State<FirstLaunchIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Choreography keyframes (seconds).
  static const _logoStart = 0.0;
  static const _logoEnd = 0.8;
  static const _presentsStart = 1.8;
  static const _presentsEnd = 2.4;
  static const _titleStart = 3.4;
  static const _titleEnd = 4.0;
  static const _subtitleStart = 5.2;
  static const _subtitleEnd = 5.8;
  static const _dividerStart = 6.8;
  static const _dividerEnd = 7.2;
  static const _reflectionStart = 8.0;
  static const _reflectionEnd = 8.6;

  static const _totalDuration = 12.0;

  late final String _reflection;

  @override
  void initState() {
    super.initState();
    _reflection = ContextReflections.random();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_totalDuration * 1000).round()),
    );

    // Fire the completion callback at the end.
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _fade(double start, double end) {
    // _controller.value is a normalized fraction (0.0–1.0) of the total
    // duration, but the choreography keyframes are expressed in seconds.
    // Convert to elapsed seconds so the timings match the choreography.
    final seconds = _controller.value * _totalDuration;
    // Fade in over ~0.8s, then hold. Opacity becomes (now - start) / (end - start)
    // clamped to [0, 1] while the element is visible.
    return (seconds - start) / (end - start);
  }

  Widget _fadeTo(double opacity, Widget child) {
    return Opacity(opacity: opacity.clamp(0.0, 1.0), child: child);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Etaosin logo
                _fadeTo(
                  _fade(_logoStart, _logoEnd),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.text_snippet_outlined,
                      size: 32,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. "presents"
                _fadeTo(
                  _fade(_presentsStart, _presentsEnd),
                  Text(
                    'presents',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 2,
                      textBaseline: TextBaseline.alphabetic,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. ContextForge
                _fadeTo(
                  _fade(_titleStart, _titleEnd),
                  Text(
                    'ContextForge',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Subtitle
                _fadeTo(
                  _fade(_subtitleStart, _subtitleEnd),
                  Text(
                    'Build AI-ready context\nfrom YouTube transcripts',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Editorial divider
                _fadeTo(
                  _fade(_dividerStart, _dividerEnd),
                  Container(
                    width: 48,
                    height: 1,
                    color: colorScheme.outlineVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // 6. Context Reflection
                _fadeTo(
                  _fade(_reflectionStart, _reflectionEnd),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      '"$_reflection"',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}