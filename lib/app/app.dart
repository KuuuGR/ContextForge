import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../repositories/in_memory_prompt_repository.dart';
import '../repositories/in_memory_video_repository.dart';
import '../services/prompt_service.dart';
import '../services/video_service.dart';
import '../providers/youtube_explode_provider.dart';

/// Root widget for the ContextForge application.
class ContextForgeApp extends StatelessWidget {
  const ContextForgeApp({super.key, this.promptService, this.videoService});

  /// Optional injected prompt service; defaults to in-memory storage.
  final PromptService? promptService;

  /// Optional injected video service; defaults to real provider wiring.
  final VideoService? videoService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ContextForge',
      debugShowCheckedModeBanner: false,
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
      home: HomePage(
        promptService:
            promptService ?? PromptService(repository: InMemoryPromptRepository()),
        videoService: videoService ??
            VideoService(
              repository: InMemoryVideoRepository(),
              provider: YoutubeExplodeProvider(),
            ),
      ),
    );
  }
}