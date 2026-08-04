import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/clean_transcript.dart';
import '../models/prompt.dart';
import '../models/prompt_quick_access.dart';
import '../models/transcript_selection.dart';
import '../models/video.dart';
import '../presentation/prompt_constants.dart';
import '../providers/youtube_explode_provider.dart';
import '../repositories/in_memory_prompt_repository.dart';
import '../repositories/in_memory_video_repository.dart';
import '../services/json_video_history_storage.dart';
import '../services/markdown_export_service.dart';
import '../services/output_builder_service.dart';
import '../services/prompt_service.dart';
import '../services/runtime_trace.dart';
import '../services/transcript_cleanup_service.dart';
import '../services/transcript_selection_service.dart';
import '../services/transcript_service.dart';
import '../services/video_history_service.dart';
import '../services/video_service.dart';
import '../services/youtube_url_parser.dart';
import '../viewmodels/video_card_controller.dart';
import '../widgets/command_bar.dart';
import '../widgets/generate_button.dart';
import '../widgets/output_preview.dart';
import '../widgets/prompt_manager.dart';
import '../widgets/video_input_card.dart';

/// Main application page containing the full ContextForge workflow UI.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.videoService,
    this.promptService,
    this.videoHistoryService,
  });

  /// Optional injected service; defaults to the production wiring.
  final VideoService? videoService;

  /// Optional injected prompt service; defaults to JSON storage.
  final PromptService? promptService;

  /// Optional injected history service; defaults to JSON file storage.
  final VideoHistoryService? videoHistoryService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const _videoCount = 3;

  late final VideoService _videoService;
  late final TranscriptService _transcriptService;
  late final List<VideoCardController> _videoControllers;
  late final List<TextEditingController> _urlControllers;
  late final List<FocusNode> _urlFocusNodes;

  final FocusNode _outputFocusNode = FocusNode();
  final FocusNode _generateFocusNode = FocusNode();
  final FocusNode _copyFocusNode = FocusNode();
  final FocusNode _exportFocusNode = FocusNode();

  final TextEditingController _outputController = TextEditingController();
  final TextEditingController _promptEditorController = TextEditingController();

  late final PromptService _promptService = widget.promptService ??
      PromptService(repository: InMemoryPromptRepository());

  late final VideoHistoryService _videoHistoryService =
      widget.videoHistoryService ??
          VideoHistoryService(storage: JsonVideoHistoryStorage());

  final TranscriptSelectionService _selectionService =
      const TranscriptSelectionService();
  final TranscriptCleanupService _cleanupService =
      const TranscriptCleanupService();
  final OutputBuilderService _outputBuilderService =
      const OutputBuilderService();
  final MarkdownExportService _markdownExportService =
      MarkdownExportService();
  final YouTubeUrlParser _urlParser = const YouTubeUrlParser();

  List<Prompt> _prompts = const [];
  String _selectedPrompt = '';
  bool _isGenerating = false;
  List<String> _generationFailures = const [];

  /// Whether the clipboard currently contains a valid YouTube URL.
  bool _clipboardHasValidUrl = false;
  String _clipboardUrl = '';

  bool get _isCustomPrompt => _selectedPrompt == customPromptOption;

  String get _selectedPromptContent {
    if (_isCustomPrompt) return _promptEditorController.text.trim();
    for (final prompt in _prompts) {
      if (prompt.title == _selectedPrompt) return prompt.content;
    }
    return '';
  }

  bool get _canCopy => _outputController.text.trim().isNotEmpty;

  bool get _canExport => _outputController.text.trim().isNotEmpty;

  /// Whether at least one video can be processed (valid URL present).
  bool get _canGenerate {
    if (_promptEditorController.text.trim().isEmpty) return false;
    for (var i = 0; i < _urlControllers.length; i++) {
      if (_urlControllers[i].text.trim().isNotEmpty) return true;
      if (_videoControllers[i].video != null) return true;
    }
    return false;
  }

  bool get _canClear {
    if (_outputController.text.isNotEmpty) return true;
    if (_generationFailures.isNotEmpty) return true;
    for (final c in _urlControllers) {
      if (c.text.trim().isNotEmpty) return true;
    }
    for (final c in _videoControllers) {
      if (c.hasMetadata || c.errorMessage != null) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _videoService = widget.videoService ??
        VideoService(
          repository: InMemoryVideoRepository(),
          provider: YoutubeExplodeProvider(),
        );
    _transcriptService = TranscriptService(provider: _videoService.provider);
    _videoControllers = [
      for (var i = 0; i < _videoCount; i++)
        VideoCardController(
          service: _videoService,
          historyService: _videoHistoryService,
        ),
    ];
    _urlControllers = [
      for (var i = 0; i < _videoCount; i++) TextEditingController(),
    ];
    _urlFocusNodes = [
      for (var i = 0; i < _videoCount; i++) FocusNode(),
    ];
    for (final c in _urlControllers) {
      c.addListener(_onSessionStateChanged);
    }
    _outputController.addListener(_onSessionStateChanged);
    _loadPrompts();
    _loadHistory();
    _refreshClipboardState();
  }

  void _onSessionStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPrompts() async {
    await _promptService.ensureDefaultPrompts();
    final prompts = await _promptService.getAllPrompts();
    if (!mounted) return;

    // The Default Prompt is auto-selected on launch. When no Default exists,
    // keep the current behaviour: select the first saved prompt.
    final defaultPrompt = await _promptService.getDefaultPrompt();
    final initialTitle = defaultPrompt?.title ??
        (prompts.isEmpty ? customPromptOption : prompts.first.title);
    final initialPrompt = defaultPrompt ??
        (prompts.isNotEmpty ? prompts.first : null);
    if (initialPrompt != null) {
      _promptEditorController.text = initialPrompt.content;
    }
    setState(() {
      _prompts = prompts;
      _selectedPrompt = initialTitle;
    });
  }

  Future<void> _loadHistory() async {
    await _videoHistoryService.load();
    if (!mounted) return;
    // Refresh the history indicator for any pre-filled URL fields.
    setState(() {
      for (var i = 0; i < _urlControllers.length; i++) {
        final url = _urlControllers[i].text;
        if (url.trim().isNotEmpty) {
          _videoControllers[i].refreshHistoryStatus(url);
        }
      }
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

  /// Creates a new prompt via a title + content dialog.
  Future<void> _onCreatePrompt() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Prompt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Content'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (created == true) {
      final title = titleController.text.trim();
      final content = contentController.text.trim();
      if (title.isNotEmpty && content.isNotEmpty) {
        await _promptService.createPrompt(title: title, content: content);
        await _reloadPrompts();
      }
    }
    titleController.dispose();
    contentController.dispose();
  }

  /// Edits an existing prompt via a title + content dialog.
  Future<void> _onEditPrompt(Prompt prompt) async {
    final titleController = TextEditingController(text: prompt.title);
    final contentController = TextEditingController(text: prompt.content);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Prompt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Content'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final title = titleController.text.trim();
      final content = contentController.text.trim();
      if (title.isNotEmpty && content.isNotEmpty) {
        await _promptService.updatePrompt(
          id: prompt.id,
          title: title,
          content: content,
        );
        await _reloadPrompts();
      }
    }
    titleController.dispose();
    contentController.dispose();
  }

  /// Deletes a prompt, with role-assignment confirmation.
  Future<void> _onDeletePrompt(Prompt prompt) async {
    String? roleLabel;
    if (prompt.quickAccess != PromptQuickAccess.none) {
      roleLabel = switch (prompt.quickAccess) {
        PromptQuickAccess.quickWorkflow => '⚡ Quick Workflow',
        PromptQuickAccess.slotOne => '① Slot One',
        PromptQuickAccess.slotTwo => '② Slot Two',
        PromptQuickAccess.slotThree => '③ Slot Three',
        PromptQuickAccess.none => null,
      };
    }
    if (prompt.isDefault) {
      roleLabel = 'Default';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prompt?'),
        content: Text(
          roleLabel == null
              ? 'Delete "${prompt.title}"?'
              : 'Delete "${prompt.title}"? It is currently assigned to: $roleLabel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _promptService.deletePrompt(prompt.id);
      await _reloadPrompts();
    }
  }

  /// Reloads prompts and refreshes selection.
  Future<void> _reloadPrompts() async {
    final prompts = await _promptService.getAllPrompts();
    if (!mounted) return;
    setState(() {
      _prompts = prompts;
      if (!prompts.any((p) => p.title == _selectedPrompt)) {
        _selectedPrompt = prompts.isEmpty ? customPromptOption : prompts.first.title;
      }
    });
  }

  /// Toggles the Favorite state of a prompt and reloads the (sorted) list.
  Future<void> _onToggleFavorite(Prompt prompt) async {
    await _promptService.setFavorite(prompt.id, !prompt.isFavorite);
    final prompts = await _promptService.getAllPrompts();
    if (!mounted) return;
    setState(() {
      _prompts = prompts;
    });
  }

  /// Assigns a Quick Access role to a prompt and reloads the list.
  Future<void> _onAssignQuickAccess(
      (Prompt, PromptQuickAccess) assignment) async {
    final (prompt, role) = assignment;
    await _promptService.assignQuickAccess(prompt.id, role);
    final prompts = await _promptService.getAllPrompts();
    if (!mounted) return;
    setState(() {
      _prompts = prompts;
    });
  }


  /// Handles Enter in a URL field.
  ///
  /// When the field has been validated (compact display), it uses the
  /// canonical full URL. Otherwise it uses the raw text field value.
  /// Moves focus to the next URL field, or triggers Generate on the last.
  void _handleUrlSubmitted(int index, String value) {
    final controller = _videoControllers[index];
    final url = controller.fullUrl ?? value.trim();
    if (url.isNotEmpty) {
      controller.loadMetadata(url);
    }
    if (index < _urlControllers.length - 1) {
      _urlFocusNodes[index + 1].requestFocus();
    } else {
      _generate();
    }
  }

  /// Reads the system clipboard and updates the clipboard-button state.
  Future<void> _refreshClipboardState() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    final isValid = text.isNotEmpty && _urlParser.isValidUrl(text);
    if (isValid != _clipboardHasValidUrl || text != _clipboardUrl) {
      if (mounted) {
        setState(() {
          _clipboardHasValidUrl = isValid;
          _clipboardUrl = isValid ? text : '';
        });
      }
    }
  }

  /// Reads the clipboard URL and validates its video ID.
  ///
  /// Returns `null` when the clipboard does not contain a valid YouTube URL.
  String? _clipboardVideoId() {
    if (!_clipboardHasValidUrl || _clipboardUrl.isEmpty) return null;
    try {
      return _urlParser.extractVideoId(_clipboardUrl);
    } catch (_) {
      return null;
    }
  }

  /// Shows the duplicate notification.
  void _showAlreadyAdded() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Already added'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Global Smart Paste: inserts the clipboard URL into the first empty slot.
  ///
  /// - Does not overwrite existing URLs.
  /// - Rejects duplicates by video ID (shows "Already added").
  /// - Immediately validates the inserted URL.
  Future<void> _smartPasteGlobal() async {
    await _refreshClipboardState();
    final candidateVideoId = _clipboardVideoId();
    if (candidateVideoId == null) return;

    // Duplicate check against all validated and unvalidated slots.
    if (_videoAlreadyPresent(candidateVideoId)) {
      _showAlreadyAdded();
      return;
    }

    // Find the first empty slot and insert the URL.
    for (var i = 0; i < _urlControllers.length; i++) {
      if (_urlControllers[i].text.trim().isEmpty) {
        _insertIntoSlot(i, _clipboardUrl);
        return;
      }
    }

    // All slots are full.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All video slots are full.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Field-specific paste: replaces the URL in the given [index] field.
  ///
  /// Does NOT insert into the first empty slot. Rejects duplicates in other
  /// slots (shows "Already added").
  Future<void> _smartPasteIntoField(int index) async {
    await _refreshClipboardState();
    final candidateVideoId = _clipboardVideoId();
    if (candidateVideoId == null) return;

    // Duplicate check against other slots (not this one).
    for (var i = 0; i < _videoControllers.length; i++) {
      if (i == index) continue;
      final video = _videoControllers[i].video;
      if (video != null && video.videoId == candidateVideoId) {
        _showAlreadyAdded();
        return;
      }
    }
    for (var i = 0; i < _urlControllers.length; i++) {
      if (i == index) continue;
      final text = _urlControllers[i].text.trim();
      if (text.isEmpty) continue;
      try {
        if (_urlParser.extractVideoId(text) == candidateVideoId) {
          _showAlreadyAdded();
          return;
        }
      } catch (_) {
        // Ignore invalid text in other slots.
      }
    }

    _insertIntoSlot(index, _clipboardUrl);
  }

  /// Checks whether [videoId] already exists in any slot.
  bool _videoAlreadyPresent(String videoId) {
    for (final controller in _videoControllers) {
      final video = controller.video;
      if (video != null && video.videoId == videoId) return true;
    }
    for (final textController in _urlControllers) {
      final text = textController.text.trim();
      if (text.isEmpty) continue;
      try {
        if (_urlParser.extractVideoId(text) == videoId) return true;
      } catch (_) {
        // Ignore invalid text.
      }
    }
    return false;
  }

  /// Inserts [url] into slot [index], validates it, and focuses the field.
  void _insertIntoSlot(int index, String url) {
    _urlControllers[index].text = url;
    _videoControllers[index].refreshHistoryStatus(url);
    _videoControllers[index].loadMetadata(url);
    _urlFocusNodes[index].requestFocus();
  }

  /// Copies the generated output to the system clipboard.
  Future<void> _copyOutput() async {
    final output = _outputController.text;
    if (output.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: output));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Exports the generated output as a Markdown document.
  ///
  /// Opens the native macOS Save dialog with the default filename
  /// `ContextForge-YYYY-MM-DD-HHMM.md`. Writes the output exactly as it
  /// appears in the editor (UTF-8). Shows a confirmation on success.
  Future<void> _exportMarkdown() async {
    final output = _outputController.text;
    if (output.isEmpty) return;
    final succeeded =
        await _markdownExportService.exportMarkdown(output);
    if (!mounted) return;
    if (succeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Markdown exported.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Resets the working session to the initial ready state.
  ///
  /// Clears generated output, URL fields, video metadata, transcript
  /// previews, and error messages. Keeps the prompt library and the
  /// persistent history.
  void _clearSession() {
    _outputController.clear();
    for (final c in _urlControllers) {
      c.clear();
    }
    for (final c in _videoControllers) {
      c.clear();
    }
    setState(() {
      _generationFailures = const [];
    });
    _refreshClipboardState();
  }

  /// Executes the end-to-end generation workflow.
  ///
  /// For each non-empty URL:
  /// 1. Validate + fetch metadata via [VideoCardController.loadMetadata].
  /// 2. Discover, select, download, and clean the transcript.
  /// 3. On success, record the video in persistent history.
  ///
  /// Videos that fail at any step are collected as failures and do not abort
  /// processing of the remaining videos. Failed attempts are never recorded
  /// in history.
  Future<void> _generate() async {
    RuntimeTrace.reset();
    RuntimeTrace.step('HomePage.generate entered');
    final prompt = _selectedPromptContent;
    if (prompt.isEmpty) {
      RuntimeTrace.boundary('Aborted: prompt is empty');
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
      RuntimeTrace.step('URL validation (video ${i + 1})');
      // Use the canonical full URL when available (compact display case),
      // otherwise the raw text field value.
      final fieldText = _urlControllers[i].text.trim();
      final url = controller.fullUrl ?? fieldText;
      if (url.isEmpty && fieldText.isEmpty) {
        RuntimeTrace.step('URL skipped (empty or blank)');
        continue;
      }

      await controller.loadMetadata(url.isEmpty ? fieldText : url);
      final video = controller.video;
      if (video == null) {
        RuntimeTrace.boundary('Video ${i + 1} metadata load failed');
        failures.add(
          'Video ${i + 1}: ${controller.errorMessage ?? 'Could not load video.'}',
        );
        continue;
      }
      RuntimeTrace.step('Video ${i + 1} metadata available: '
          'title="${video.title}"');

      try {
        RuntimeTrace.step('Transcript discovery start (videoId='
            '"${video.videoId}")');
        final tracks =
            await _transcriptService.getAvailableTranscripts(video.videoId);
        RuntimeTrace.step('Transcript discovery complete '
            '(${tracks.length} track(s))');
        final selection = _selectionService.select(tracks);
        if (selection is! TranscriptSelected) {
          RuntimeTrace.boundary('No transcript selected for video ${i + 1}');
          failures.add('Video ${i + 1}: no transcript available.');
          continue;
        }
        RuntimeTrace.step('Transcript download start (videoId='
            '"${video.videoId}")');
        final download = await _transcriptService.downloadTranscript(
          video.videoId,
          selection.track,
        );
        RuntimeTrace.step('Transcript download complete '
            '(${download.segments.length} segment(s))');
        final clean = _cleanupService.clean(download);
        if (clean.text.trim().isEmpty) {
          RuntimeTrace.boundary('Cleaned transcript empty for video ${i + 1}');
          failures.add('Video ${i + 1}: transcript is empty.');
          continue;
        }
        videos.add(video);
        transcripts.add(clean);

        // Record the successful generation in persistent history.
        RuntimeTrace.step(
            'VideoHistoryService.recordSuccess (videoId="${video.videoId}")');
        await _videoHistoryService.recordSuccess(video);
        controller.refreshHistoryStatus(controller.fullUrl ?? fieldText);
      } catch (e, stack) {
        RuntimeTrace.boundary('Video ${i + 1} failed with exception');
        debugPrint('[HomePage._generate] Video ${i + 1} failed: '
            'type=${e.runtimeType}, message=$e\n$stack');
        failures.add('Video ${i + 1}: $e');
      }
    }

    RuntimeTrace.step('OutputBuilderService.build entered');
    final output = _outputBuilderService.build(
      selectedPrompt: prompt,
      videos: videos,
      transcripts: transcripts,
    );
    RuntimeTrace.step('OutputBuilderService.build complete '
        '(${output.length} chars)');

    if (!mounted) return;
    setState(() {
      _outputController.text = output;
      _isGenerating = false;
      _generationFailures = failures;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh clipboard availability when the window becomes active.
    if (state == AppLifecycleState.resumed) {
      _refreshClipboardState();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final c in _videoControllers) {
      c.dispose();
    }
    for (final c in _urlControllers) {
      c.removeListener(_onSessionStateChanged);
      c.dispose();
    }
    for (final n in _urlFocusNodes) {
      n.dispose();
    }
    _outputFocusNode.dispose();
    _generateFocusNode.dispose();
    _copyFocusNode.dispose();
    _exportFocusNode.dispose();
    _outputController.removeListener(_onSessionStateChanged);
    _outputController.dispose();
    _promptEditorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Shortcuts(
      shortcuts: {
        // ⌘↩ Generate
        const SingleActivator(
          LogicalKeyboardKey.enter,
          meta: true,
        ): const _GenerateIntent(),
        // ⌘R Generate
        const SingleActivator(
          LogicalKeyboardKey.keyR,
          meta: true,
        ): const _GenerateIntent(),
        // ⌘⌫ Clear
        const SingleActivator(
          LogicalKeyboardKey.backspace,
          meta: true,
        ): const _ClearIntent(),
        // ⌘⇧S Export Markdown
        const SingleActivator(
          LogicalKeyboardKey.keyS,
          meta: true,
          shift: true,
        ): const _ExportMarkdownIntent(),
        // ⌘V Smart Paste (only triggers when clipboard contains a valid URL)
        const SingleActivator(
          LogicalKeyboardKey.keyV,
          meta: true,
        ): const _SmartPasteIntent(),
        // Escape unfocus
        const SingleActivator(
          LogicalKeyboardKey.escape,
        ): const _UnfocusIntent(),
      },
      child: Actions(
        actions: {
          _GenerateIntent: CallbackAction<_GenerateIntent>(
            onInvoke: (_) {
              _generate();
              return null;
            },
          ),
          _ClearIntent: CallbackAction<_ClearIntent>(
            onInvoke: (_) {
              _clearSession();
              return null;
            },
          ),
          _ExportMarkdownIntent: CallbackAction<_ExportMarkdownIntent>(
            onInvoke: (_) {
              _exportMarkdown();
              return null;
            },
          ),
          _SmartPasteIntent: CallbackAction<_SmartPasteIntent>(
            onInvoke: (_) {
              _smartPasteGlobal();
              return null;
            },
          ),
          _UnfocusIntent: CallbackAction<_UnfocusIntent>(
            onInvoke: (_) {
              FocusManager.instance.primaryFocus?.unfocus();
              return null;
            },
          ),
        },
        child: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _Header(textTheme: textTheme),
                          ),
                          const SizedBox(width: 16),
                          CommandBar(
                            prompts: _prompts,
                            selectedPrompt: _selectedPrompt,
                            onSelectPrompt: _onPromptChanged,
                            onPaste: _smartPasteGlobal,
                            canPaste: _clipboardHasValidUrl,
                            onGenerate: _canGenerate ? _generate : null,
                            canGenerate: _canGenerate,
                            onCopy: _copyOutput,
                            canCopy: _canCopy,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionCard(
                        title: 'Prompt',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PromptManager(
                              prompts: _prompts,
                              value: _selectedPrompt,
                              onChanged: _onPromptChanged,
                              onToggleFavorite: _onToggleFavorite,
                              onAssignQuickAccess: _onAssignQuickAccess,
                              onCreatePrompt: _onCreatePrompt,
                              onEditPrompt: _onEditPrompt,
                              onDeletePrompt: _onDeletePrompt,
                              editorController: _promptEditorController,
                              editorEnabled: _isCustomPrompt,
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
                                focusNode: _urlFocusNodes[i],
                                onSubmitted: (value) =>
                                    _handleUrlSubmitted(i, value),
                                textInputAction:
                                    i < _videoControllers.length - 1
                                        ? TextInputAction.next
                                        : TextInputAction.done,
                                onClipboardPressed: () => _smartPasteIntoField(i),
                                clipboardEnabled: _clipboardHasValidUrl,
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
                            Row(
                              children: [
                                Focus(
                                  focusNode: _copyFocusNode,
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _canCopy ? _copyOutput : null,
                                    icon: const Icon(Icons.copy),
                                    label: const Text('Copy'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Focus(
                                  focusNode: _exportFocusNode,
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _canExport ? _exportMarkdown : null,
                                    icon: const Icon(
                                        Icons.description_outlined),
                                    label: const Text('Export Markdown'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed:
                                      _canClear ? _clearSession : null,
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Clear'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_generationFailures.isNotEmpty) ...[
                              _FailureBanner(failures: _generationFailures),
                              const SizedBox(height: 12),
                            ],
                            Shortcuts(
                              shortcuts: const {
                                SingleActivator(
                                    LogicalKeyboardKey.keyC,
                                    control: true):
                                    _CopyOutputIntent(),
                                SingleActivator(
                                    LogicalKeyboardKey.keyC,
                                    meta: true):
                                    _CopyOutputIntent(),
                              },
                              child: Actions(
                                actions: {
                                  _CopyOutputIntent:
                                      CallbackAction<_CopyOutputIntent>(
                                    onInvoke: (_) {
                                      if (_canCopy) _copyOutput();
                                      return null;
                                    },
                                  ),
                                },
                                child: Focus(
                                  focusNode: _outputFocusNode,
                                  child: OutputPreview(
                                      controller: _outputController),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Focus(
                                focusNode: _generateFocusNode,
                                child: GenerateButton(
                                  onPressed: _generate,
                                  isLoading: _isGenerating,
                                ),
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
          ),
        ),
    );
  }
}

/// Intent for copying the generated output via keyboard shortcut (⌘C).
class _CopyOutputIntent extends Intent {
  const _CopyOutputIntent();
}

/// Intent for generating output via keyboard shortcut (⌘↩).
class _GenerateIntent extends Intent {
  const _GenerateIntent();
}

/// Intent for clearing the session via keyboard shortcut (⌘⌫).
class _ClearIntent extends Intent {
  const _ClearIntent();
}

/// Intent for exporting Markdown via keyboard shortcut (⌘⇧S).
class _ExportMarkdownIntent extends Intent {
  const _ExportMarkdownIntent();
}

/// Intent for Smart Paste via keyboard shortcut (⌘V).
class _SmartPasteIntent extends Intent {
  const _SmartPasteIntent();
}

/// Intent for removing keyboard focus via Escape.
class _UnfocusIntent extends Intent {
  const _UnfocusIntent();
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ContextForge',
                style: textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Build AI-ready context from YouTube transcripts.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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