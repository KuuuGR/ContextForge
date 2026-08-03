import 'package:flutter/material.dart';

import '../models/prompt.dart';
import '../presentation/prompt_constants.dart';
import '../providers/youtube_explode_provider.dart';
import '../repositories/in_memory_prompt_repository.dart';
import '../repositories/in_memory_video_repository.dart';
import '../services/prompt_service.dart';
import '../services/video_service.dart';
import '../viewmodels/video_card_controller.dart';
import '../widgets/generate_button.dart';
import '../widgets/output_preview.dart';
import '../widgets/prompt_editor.dart';
import '../widgets/prompt_selector.dart';
import '../widgets/video_input_card.dart';

/// Main application page containing the full ContextForge workflow UI.
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.videoService, this.promptService});

  /// Optional injected service; defaults to the production wiring.
  final VideoService? videoService;

  /// Optional injected prompt service; defaults to JSON storage.
  final PromptService? promptService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final VideoService _videoService;
  late final List<VideoCardController> _videoControllers;

  late final PromptService _promptService = widget.promptService ??
      PromptService(repository: InMemoryPromptRepository());

  List<Prompt> _prompts = const [];
  String _selectedPrompt = '';

  bool get _isCustomPrompt => _selectedPrompt == customPromptOption;

  String get _selectedPromptContent {
    if (_isCustomPrompt) return '';
    for (final prompt in _prompts) {
      if (prompt.title == _selectedPrompt) return prompt.content;
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _videoService = widget.videoService ??
        VideoService(
          repository: InMemoryVideoRepository(),
          provider: YoutubeExplodeProvider(),
        );
    _videoControllers = [
      VideoCardController(service: _videoService),
      VideoCardController(service: _videoService),
      VideoCardController(service: _videoService),
    ];
    _loadPrompts();
  }

  Future<void> _loadPrompts() async {
    await _promptService.ensureDefaultPrompts();
    final prompts = await _promptService.getAllPrompts();
    if (!mounted) return;
    setState(() {
      _prompts = prompts;
      _selectedPrompt = prompts.isEmpty ? customPromptOption : prompts.first.title;
    });
  }

  @override
  void dispose() {
    for (final c in _videoControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(textTheme: textTheme),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Prompt',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PromptSelector(
                        prompts: _prompts,
                        value: _selectedPrompt,
                        onChanged: (value) {
                          setState(() => _selectedPrompt = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      PromptEditor(
                        content: _selectedPromptContent,
                        enabled: _isCustomPrompt,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Videos',
                  child: Column(
                    children: [
                      for (final controller in _videoControllers) ...[
                        VideoInputCard(controller: controller),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Output',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      OutputPreview(),
                      SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GenerateButton(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const _BottomToolbar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Header with the application title and subtitle.
class _Header extends StatelessWidget {
  const _Header({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.text_snippet_outlined, size: 40, color: colorScheme.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ContextForge',
              style:
                  textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Build AI-ready context from YouTube transcripts.',
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

/// Card wrapper used for each main section of the app.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Bottom toolbar containing the Generate, Copy, and Clear buttons.
class _BottomToolbar extends StatelessWidget {
  const _BottomToolbar();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Generate'),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.copy),
          label: const Text('Copy'),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.clear),
          label: const Text('Clear'),
        ),
      ],
    );
  }
}