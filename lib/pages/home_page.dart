import 'package:flutter/material.dart';

import '../models/clean_transcript.dart';
import '../models/prompt.dart';
import '../models/transcript_selection.dart';
import '../models/video.dart';
import '../presentation/prompt_constants.dart';
import '../providers/youtube_explode_provider.dart';
import '../repositories/in_memory_prompt_repository.dart';
import '../repositories/in_memory_video_repository.dart';
import '../services/output_builder_service.dart';
import '../services/prompt_service.dart';
import '../services/transcript_cleanup_service.dart';
import '../services/transcript_selection_service.dart';
import '../services/transcript_service.dart';
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
  static const _videoCount = 3;

  late final VideoService _videoService;
  late final TranscriptService _transcriptService;
  late final List<VideoCardController> _videoControllers;
  late final List<TextEditingController> _urlControllers;

  final TextEditingController _outputController = TextEditingController();
  final TextEditingController _promptEditorController = TextEditingController();

  late final PromptService _promptService = widget.promptService ??
      PromptService(repository: InMemoryPromptRepository());

  final TranscriptSelectionService _selectionService =
      const TranscriptSelectionService();
  final TranscriptCleanupService _cleanupService =
      const TranscriptCleanupService();
  final OutputBuilderService _outputBuilderService =
      const OutputBuilderService();

  List<Prompt> _prompts = const [];
  String _selectedPrompt = '';
  bool _isGenerating = false;
  List<String> _generationFailures = const [];

  bool get _isCustomPrompt => _selectedPrompt == customPromptOption;

  String get _selectedPromptContent {
    if (_isCustomPrompt) return _promptEditorController.text.trim();
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
    _transcriptService = TranscriptService(provider: _videoService.provider);
    _videoControllers = [
      for (var i = 0; i < _videoCount; i++)
        VideoCardController(service: _videoService),
    ];
    _urlControllers = [
      for (var i = 0; i < _videoCount; i++) TextEditingController(),
    ];
    _loadPrompts();
  }

  Future<void> _loadPrompts() async {
    await _promptService.ensureDefaultPrompts();
    final prompts = await _promptService.getAllPrompts();
    if (!mounted) return;
    if (prompts.isNotEmpty) {
      _promptEditorController.text = prompts.first.content;
    }
    setState(() {
      _prompts = prompts;
      _selectedPrompt = prompts.isEmpty ? customPromptOption : prompts.first.title;
    });
  }

  void _onPromptChanged(String value) {
    setState(() => _selectedPrompt = value);
    if (value == customPromptOption) {
      _promptEditorController.text = '';
    } else {
      for (final prompt in _prompts) {
        if (prompt.title == value) {
          _promptEditorController.text = prompt.content;
          break;
        }
      }
    }
  }

  /// Executes the end-to-end generation workflow.
  ///
  /// For each non-empty URL:
  /// 1. Validate + fetch metadata via [VideoCardController.loadMetadata].
  /// 2. Discover, select, download, and clean the transcript.
  ///
  /// Videos that fail at any step are collected as failures and do not abort
  /// processing of the remaining videos.
  Future<void> _generate() async {
    final prompt = _selectedPromptContent;
    if (prompt.isEmpty) {
      setState(() {
        _generationFailures = const ['Enter a prompt before generating.'];
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationFailures = const [];
    });

    final videos = <Video>[];
    final transcripts = <CleanTranscript>[];
    final failures = <String>[];

    for (var i = 0; i < _videoControllers.length; i++) {
      final controller = _videoControllers[i];
      final url = _urlControllers[i].text.trim();
      if (url.isEmpty) continue;

      await controller.loadMetadata(url);
      final video = controller.video;
      if (video == null) {
        failures.add(
          'Video ${i + 1}: ${controller.errorMessage ?? 'Could not load video.'}',
        );
        continue;
      }

      try {
        final tracks =
            await _transcriptService.getAvailableTranscripts(video.videoId);
        final selection = _selectionService.select(tracks);
        if (selection is! TranscriptSelected) {
          failures.add('Video ${i + 1}: no transcript available.');
          continue;
        }
        final download = await _transcriptService.downloadTranscript(
          video.videoId,
          selection.track,
        );
        final clean = _cleanupService.clean(download);
        if (clean.text.trim().isEmpty) {
          failures.add('Video ${i + 1}: transcript is empty.');
          continue;
        }
        videos.add(video);
        transcripts.add(clean);
      } catch (e) {
        failures.add('Video ${i + 1}: $e');
      }
    }

    final output = _outputBuilderService.build(
      selectedPrompt: prompt,
      videos: videos,
      transcripts: transcripts,
    );

    if (!mounted) return;
    setState(() {
      _outputController.text = output;
      _isGenerating = false;
      _generationFailures = failures;
    });
  }

  @override
  void dispose() {
    for (final c in _videoControllers) {
      c.dispose();
    }
    for (final c in _urlControllers) {
      c.dispose();
    }
    _outputController.dispose();
    _promptEditorController.dispose();
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
                        onChanged: _onPromptChanged,
                      ),
                      const SizedBox(height: 16),
                      PromptEditor(
                        content: _selectedPromptContent,
                        enabled: _isCustomPrompt,
                        controller: _promptEditorController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Videos',
                  child: Column(
                    children: [
                      for (var i = 0; i < _videoControllers.length; i++) ...[
                        VideoInputCard(
                          controller: _videoControllers[i],
                          textController: _urlControllers[i],
                        ),
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
                    children: [
                      if (_generationFailures.isNotEmpty) ...[
                        _FailureBanner(failures: _generationFailures),
                        const SizedBox(height: 12),
                      ],
                      OutputPreview(controller: _outputController),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GenerateButton(
                          onPressed: _generate,
                          isLoading: _isGenerating,
                        ),
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

/// Banner listing per-video failures that did not abort generation.
class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.failures});

  final List<String> failures;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Some videos could not be processed:',
            style: TextStyle(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          for (final failure in failures)
            Text(
              '• $failure',
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
        ],
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