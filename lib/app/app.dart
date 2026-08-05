import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/intro/first_launch_intro.dart';
import '../l10n/app_localizations.dart';
import '../pages/home_page.dart';
import '../providers/youtube_explode_provider.dart';
import '../repositories/in_memory_prompt_repository.dart';
import '../repositories/in_memory_video_repository.dart';
import '../services/first_launch_intro_store.dart';
import '../services/json_video_history_storage.dart';
import '../services/prompt_service.dart';
import '../services/video_history_service.dart';
import '../services/video_service.dart';

/// Debug flag that always shows the First Launch Intro.
///
/// Only applies in debug builds — release builds always respect the
/// persisted completion state.
const debugAlwaysShowIntro = true;

/// Root widget for the ContextForge application.
class ContextForgeApp extends StatelessWidget {
  const ContextForgeApp({
    super.key,
    this.promptService,
    this.videoService,
    this.videoHistoryService,
    this.introStore,
  });

  /// Optional injected prompt service; defaults to in-memory storage.
  final PromptService? promptService;

  /// Optional injected video service; defaults to real provider wiring.
  final VideoService? videoService;

  /// Optional injected video history service; defaults to JSON file storage.
  final VideoHistoryService? videoHistoryService;

  /// Optional injected First Launch Intro store; defaults to JSON file storage.
  final FirstLaunchIntroStore? introStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ContextForge',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('pl'),
        Locale('es'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: _Root(
        introStore: introStore ?? FirstLaunchIntroStore(),
        promptService:
            promptService ?? PromptService(repository: InMemoryPromptRepository()),
        videoService: videoService ??
            VideoService(
              repository: InMemoryVideoRepository(),
              provider: YoutubeExplodeProvider(),
            ),
        videoHistoryService: videoHistoryService ??
            VideoHistoryService(storage: JsonVideoHistoryStorage()),
      ),
    );
  }
}

/// Root widget that decides whether to show the First Launch Intro or Home.
///
/// The Intro is shown only once after installation. After completion, the
/// flag is persisted and Home is displayed on subsequent launches.
class _Root extends StatefulWidget {
  const _Root({
    required this.introStore,
    required this.promptService,
    required this.videoService,
    required this.videoHistoryService,
  });

  final FirstLaunchIntroStore introStore;
  final PromptService promptService;
  final VideoService videoService;
  final VideoHistoryService videoHistoryService;

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool? _showIntro;

  @override
  void initState() {
    super.initState();
    _checkIntro();
  }

  Future<void> _checkIntro() async {
    final show = kDebugMode && debugAlwaysShowIntro
        ? true
        : await widget.introStore.shouldShowIntro();
    if (!mounted) return;
    setState(() => _showIntro = show);
  }

  Future<void> _completeIntro() async {
    await widget.introStore.markIntroCompleted();
    if (!mounted) return;
    setState(() => _showIntro = false);
  }

  @override
  Widget build(BuildContext context) {
    final show = _showIntro;
    if (show == null) {
      // Still determining whether to show the Intro.
      return const Scaffold(
        body: Center(child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )),
      );
    }
    if (show) {
      return FirstLaunchIntro(onComplete: _completeIntro);
    }
    return HomePage(
      promptService: widget.promptService,
      videoService: widget.videoService,
      videoHistoryService: widget.videoHistoryService,
    );
  }
}
