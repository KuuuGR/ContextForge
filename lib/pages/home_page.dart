import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/clean_transcript.dart';
import '../models/prompt.dart';
import '../models/prompt_quick_access.dart';
import '../models/transcript_selection.dart';
import '../models/video.dart';
import '../presentation/prompt_constants.dart';
import '../presentation/responsive.dart';
import '../providers/youtube_explode_provider.dart';
import '../repositories/in_memory_video_repository.dart';
import '../repositories/json_prompt_repository.dart';
import '../services/app_review_service.dart';
import '../services/json_video_history_storage.dart';
import '../services/markdown_export_service.dart';
import '../services/output_builder_service.dart';
import '../services/prompt_service.dart';
import '../services/prompt_transfer_service.dart';
import '../services/runtime_trace.dart';
import '../services/transcript_cleanup_service.dart';
import '../services/transcript_selection_service.dart';
import '../services/transcript_service.dart';
import '../services/video_history_service.dart';
import '../services/video_service.dart';
import '../services/youtube_url_parser.dart';
import '../viewmodels/video_card_controller.dart';
import '../widgets/command_bar.dart';
import '../widgets/destination_selector.dart';
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
      PromptService(repository: JsonPromptRepository());

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

  /// Records meaningful use and schedules eligible App Store review requests.
  final AppReviewService _reviewService = AppReviewService();

  /// Pending review-request timer (scheduled after a successful workflow).
  Timer? _reviewTimer;

  List<Prompt> _prompts = const [];
  String _selectedPrompt = '';
  bool _isGenerating = false;
  List<String> _generationFailures = const [];

  /// Whether the clipboard currently contains a valid YouTube URL.
  bool _clipboardHasValidUrl = false;
  String _clipboardUrl = '';

  bool get _isCustomPrompt => _selectedPrompt == customPromptOption;

  /// The prompt assigned to ⚡ Quick Workflow, or `null` when none is set.
  Prompt? get _quickWorkflowPrompt {
    for (final p in _prompts) {
      if (p.quickAccess == PromptQuickAccess.quickWorkflow) return p;
    }
    return null;
  }

  /// Whether a ⚡ Quick Workflow prompt is assigned.
  bool get _canQuickWorkflow => _quickWorkflowPrompt != null;

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
        content: SingleChildScrollView(
          child: Column(
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
        content: SingleChildScrollView(
          child: Column(
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

  /// Cycles the star state of a prompt and reloads the (sorted) list.
  ///
  /// State machine:
  /// - ☆ (normal)   → ★ (favorite)
  /// - ★ (favorite) → ⭐ (default)
  /// - ⭐ (default)  → ☆ (normal)
  ///
  /// Only one prompt may be ⭐ at a time; promoting a prompt to ⭐ removes
  /// the default from the previous ⭐ holder.
  Future<void> _onToggleFavorite(Prompt prompt) async {
    if (prompt.isDefault) {
      // ⭐ → ☆ : remove the default designation and un-favorite.
      await _promptService.clearDefault(prompt.id);
      await _promptService.setFavorite(prompt.id, false);
    } else if (prompt.isFavorite) {
      // ★ → ⭐ : promote to the Default.
      await _promptService.setDefault(prompt.id);
    } else {
      // ☆ → ★ : mark as Favorite.
      await _promptService.setFavorite(prompt.id, true);
    }
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

  /// Exports the user's saved prompts to a JSON file via the native dialog.
  ///
  /// Only user-created prompts are exported — the built-in catalogue is never
  /// treated as user data.
  Future<void> _exportPrompts() async {
    try {
      final userPrompts = await _promptService.getUserPrompts();
      if (userPrompts.isEmpty) {
        _showSnackBar('There are no user prompts to export.');
        return;
      }
      final saved =
          await PromptTransferService().exportPrompts(userPrompts);
      if (!saved) return; // User cancelled.
      _showSnackBar(
          'Exported ${userPrompts.length} prompt'
          '${userPrompts.length == 1 ? '' : 's'} to '
          '${PromptTransferService.suggestedFileName}.');
    } catch (_) {
      _showSnackBar('Could not export prompts.');
    }
  }

  /// Imports user prompts from a JSON file and reflects them in the UI.
  ///
  /// Uses an intelligent merge: new prompts are added automatically, identical
  /// prompts are left unchanged, and prompts whose corresponding existing
  /// entry has different content are presented to the user for resolution.
  Future<void> _importPrompts() async {
    try {
      final incoming = await PromptTransferService().pickPrompts();
      if (incoming == null) return; // User cancelled.

      final plan = await _promptService.analyzeImport(incoming);

      if (plan.hasConflicts) {
        final confirmed = await _showConflictResolutionDialog(plan.conflicts);
        if (!confirmed) return; // User cancelled the import.
      }

      final result = await _promptService.applyImport(plan);
      final prompts = await _promptService.getAllPrompts();
      if (!mounted) return;
      setState(() {
        _prompts = prompts;
      });

      _showImportSummary(result);
    } on FormatException {
      _showSnackBar(
          'The selected file is not a valid ContextForge prompts file.');
    } catch (_) {
      _showSnackBar('Could not import prompts.');
    }
  }

  /// Shows a concise summary of the import outcome, e.g.
  /// "7 new prompts added, 2 already existed, 1 conflict."
  void _showImportSummary(PromptImportResult result) {
    final parts = <String>[
      '${result.newAddedCount} new prompt${result.newAddedCount == 1 ? '' : 's'} added',
    ];
    if (result.alreadyExistedCount > 0) {
      parts.add('${result.alreadyExistedCount} already existed');
    }
    if (result.conflictCount > 0) {
      parts.add(
          '${result.conflictCount} conflict${result.conflictCount == 1 ? '' : 's'}');
    }
    _showSnackBar('${parts.join(', ')}.');
  }

  /// Prompts the user to resolve import conflicts, one choice per conflict.
  ///
  /// Returns `true` when the user confirmed the choices, `false` when they
  /// cancelled the import.
  Future<bool> _showConflictResolutionDialog(
      List<PromptConflict> conflicts) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ImportConflictDialog(conflicts: conflicts),
    );
    return confirmed ?? false;
  }

  /// Shows a transient message using the surrounding [ScaffoldMessenger].
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
    final isValid = text.isNotEmpty &&
        _clipboardLooksLikeYouTubeUrl(text) &&
        _urlParser.isValidUrl(text);
    if (isValid != _clipboardHasValidUrl || text != _clipboardUrl) {
      if (mounted) {
        setState(() {
          _clipboardHasValidUrl = isValid;
          _clipboardUrl = isValid ? text : '';
        });
      }
    }
  }

  /// Cheap pre-filter so ordinary clipboard text (a sentence, multiline text,
  /// etc.) is never sent to the YouTube URL parser during routine clipboard
  /// polling. Sending arbitrary text there logs a noisy parse-failure stack
  /// for every non-URL value.
  ///
  /// A valid YouTube URL is a single whitespace-free token starting with an
  /// `http(s)://` scheme (or a bare YouTube short/domain form). Anything else
  /// is simply treated as "not a YouTube URL" without touching the parser.
  bool _clipboardLooksLikeYouTubeUrl(String text) {
    final t = text.trim();
    if (t.isEmpty) return false;
    // Real URLs never contain internal whitespace; reject prose/multiline text.
    if (t.contains(RegExp(r'\s'))) return false;
    final lower = t.toLowerCase();
    return lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('youtu.be/') ||
        lower.startsWith('youtube.com/') ||
        lower.startsWith('www.youtube.com/') ||
        lower.startsWith('m.youtube.com/');
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

  /// Runs the ⚡ Quick Workflow for the assigned prompt.
  ///
  /// Reads the clipboard, validates the YouTube URL, pastes it into the
  /// first empty video slot, selects the ⚡ prompt, generates the output,
  /// and copies the result to the clipboard.
  Future<void> _quickWorkflow() async {
    final prompt = _quickWorkflowPrompt;
    if (prompt == null) return;

    // 1-2. Read and validate the clipboard URL.
    await _refreshClipboardState();
    final candidateVideoId = _clipboardVideoId();
    if (candidateVideoId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clipboard does not contain a valid YouTube URL.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Reject duplicates.
    if (_videoAlreadyPresent(candidateVideoId)) {
      _showAlreadyAdded();
      return;
    }

    // 3. Paste into the first empty video slot.
    var inserted = false;
    for (var i = 0; i < _urlControllers.length; i++) {
      if (_urlControllers[i].text.trim().isEmpty) {
        _insertIntoSlot(i, _clipboardUrl);
        inserted = true;
        break;
      }
    }
    if (!inserted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All video slots are full.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Select the ⚡ prompt so generation uses it.
    _onPromptChanged(prompt.title);

    // 4-5. Generate output automatically.
    await _generate();

    // 6. Copy the generated output to the clipboard.
    if (_canCopy) _copyOutput();
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

  /// Inserts [url] into slot [index] without modification and focuses the
  /// field.
  ///
  /// The clipboard contents are inserted exactly as-is; the YouTube URL
  /// parser is only used later for validation/metadata. This keeps every
  /// paste method (Cmd+V, Ctrl+V, toolbar Paste, context menu Paste)
  /// behaving identically.
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

    // A meaningful workflow completed successfully — schedule (not immediate)
    // an eligible App Store review request after a short pause.
    if (videos.isNotEmpty) {
      _scheduleReviewRequest();
    }
  }

  /// Schedules a review request after a successful meaningful workflow.
  ///
  /// Records one completed meaningful workflow (setting the first-meaningful-use
  /// date the first time and incrementing the usage counter) and, after a short
  /// pause, requests a review only if the user is eligible. Never called at app
  /// launch and never immediately after a button tap.
  void _scheduleReviewRequest() {
    _reviewService.recordMeaningfulUse();
    _reviewTimer?.cancel();
    _reviewTimer = Timer(const Duration(seconds: 3), () {
      _reviewService.requestReviewIfEligible();
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
    _reviewTimer?.cancel();
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = isCompactWidth(constraints.maxWidth);
                    final padding = compact ? 16.0 : 24.0;
                    return SingleChildScrollView(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (compact) ...[
                            _Header(textTheme: textTheme),
                            const SizedBox(height: 16),
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
                              onQuickWorkflow:
                                  _canQuickWorkflow ? _quickWorkflow : null,
                              canQuickWorkflow: _canQuickWorkflow,
                              onClear: _canClear ? _clearSession : null,
                              canClear: _canClear,
                            ),
                          ] else ...[
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
                                  onQuickWorkflow:
                                      _canQuickWorkflow ? _quickWorkflow : null,
                                  canQuickWorkflow: _canQuickWorkflow,
                                  onClear: _canClear ? _clearSession : null,
                                  canClear: _canClear,
                                ),
                              ],
                            ),
                          ],
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
                                  onExportPrompts: _exportPrompts,
                                  onImportPrompts: _importPrompts,
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
                                if (compact)
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
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
                                      OutlinedButton.icon(
                                        onPressed:
                                            _canClear ? _clearSession : null,
                                        icon: const Icon(Icons.clear),
                                        label: const Text('Clear'),
                                      ),
                                    ],
                                  )
                                else
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
                          const _Footer(),
                        ],
                      ),
                    );
                  },
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

/// Lightweight informational footer with About, Shortcuts, and Help dialogs.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final compact = isCompact(context);
    final about = TextButton.icon(
      onPressed: () => _showAbout(context),
      icon: const Icon(Icons.info_outline, size: 16),
      label: const Text('About'),
    );
    final shortcuts = TextButton.icon(
      onPressed: () => _showShortcuts(context),
      icon: const Icon(Icons.keyboard_outlined, size: 16),
      label: const Text('Shortcuts'),
    );
    final help = TextButton.icon(
      onPressed: () => _showHelp(context),
      icon: const Icon(Icons.help_outline, size: 16),
      label: const Text('Help'),
    );
    final destination = const DestinationSelector();

    if (compact) {
      return Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [about, shortcuts, help, destination],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        about,
        const SizedBox(width: 8),
        shortcuts,
        const SizedBox(width: 8),
        help,
        const SizedBox(width: 8),
        destination,
      ],
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const _AboutDialog(),
    );
  }

  void _showShortcuts(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keyboard Shortcuts'),
        content: const Text(
          '⌘V  Paste the clipboard YouTube URL into the first '
          'available slot. Successive paste operations continue '
          'filling the next empty slot.\n\n'
          '⌘R  Generate output.\n\n'
          '⌘C  If nothing is selected: copy the generated output. '
          'Otherwise: perform native copy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to use ContextForge'),
        content: SingleChildScrollView(
          child: const Text(
            '1. Copy a YouTube URL.\n'
            '2. Press ⌘V (or use Paste).\n'
            '3. Select a prompt.\n'
            '4. Press Generate.\n'
            '5. Copy the generated output.\n\n'
            'Quick Access:\n'
            '⭐  Favorite prompt.\n'
            '🌟  Default prompt. Automatically selected when '
            'ContextForge starts.\n'
            '⚡  Quick Workflow. Runs the complete workflow '
            'automatically using the clipboard.\n'
            '① ② ③  Quick Prompt Slots. Instantly switch the '
            'selected prompt.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// About dialog with the Etaosin Easter Egg.
///
/// Displays the version and a clickable `𝐞𝐭✰𝐨𝐬𝐢𝐧` marker. Clicking it toggles
/// the internal `etaosinMode` flag, switching the marker between `✰` and `✪`.
///
/// The flag exists only while this dialog is open — it is never persisted and
/// is not used anywhere else yet. Future versions may use it to enable
/// advanced developer-only features (see FUTURE_IDEAS.md).
class _AboutDialog extends StatefulWidget {
  const _AboutDialog();

  @override
  State<_AboutDialog> createState() => _AboutDialogState();
}

class _AboutDialogState extends State<_AboutDialog> {
  /// Internal flag for the Etaosin Easter Egg.
  ///
  /// Defaults to `false` (✰). Toggled on each click of the marker. Not
  /// persisted and not used anywhere else in this phase.
  bool etaosinMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('About ContextForge'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ContextForge 1.1.0\n\n'
              'Build AI-ready context from YouTube transcripts.\n\n'
              'Built with Flutter.\n'
              'Built using the SODA methodology.',
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => etaosinMode = !etaosinMode),
              child: Text(
                etaosinMode ? '𝐞𝐭✪𝐨𝐬𝐢𝐧' : '𝐞𝐭✰𝐨𝐬𝐢𝐧',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(height: 32),
            Text(
              'Feedback',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text("We'd love to hear from you!"),
            const SizedBox(height: 8),
            _FeedbackAction(
              icon: '💡',
              label: 'Suggest an Idea',
              onPressed: () => _openFeedback(
                subject: 'ContextForge - Suggestion',
              ),
            ),
            _FeedbackAction(
              icon: '🐞',
              label: 'Report a Bug',
              onPressed: () => _openFeedback(
                subject: 'ContextForge - Bug Report',
              ),
            ),
            _FeedbackAction(
              icon: '✉️',
              label: 'General Feedback',
              onPressed: () => _openFeedback(
                subject: 'ContextForge - Feedback',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ideas help shape future versions of ContextForge.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  /// Opens the feedback channel for the given [subject].
  ///
  /// Currently opens the default mail application via a `mailto:` link.
  /// Future versions may replace this with an official ContextForge feedback
  /// portal — only this method needs to change; the UI stays the same.
  void _openFeedback({required String subject}) {
    final uri = Uri(
      scheme: 'mailto',
      path: 'etaosin@gmail.com',
      queryParameters: {'subject': subject},
    );
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// A single feedback action row (icon + label) shown in the About dialog.
///
/// The action implementation is decoupled from the UI so the underlying
/// feedback channel (email today, a web portal in the future) can be swapped
/// without touching this widget.
class _FeedbackAction extends StatelessWidget {
  const _FeedbackAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog that lets the user resolve import conflicts before applying them.
class _ImportConflictDialog extends StatefulWidget {
  const _ImportConflictDialog({required this.conflicts});

  final List<PromptConflict> conflicts;

  @override
  State<_ImportConflictDialog> createState() => _ImportConflictDialogState();
}

class _ImportConflictDialogState extends State<_ImportConflictDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conflicts = widget.conflicts;
    return AlertDialog(
      title: const Text('Resolve Import Conflicts'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${conflicts.length} prompt${conflicts.length == 1 ? '' : 's'} already '
              'exist with different content. Choose how to handle each.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final conflict in conflicts)
                      _ConflictTile(conflict: conflict),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Import'),
        ),
      ],
    );
  }
}

/// One conflict row with its resolution selector.
class _ConflictTile extends StatefulWidget {
  const _ConflictTile({required this.conflict});

  final PromptConflict conflict;

  @override
  State<_ConflictTile> createState() => _ConflictTileState();
}

class _ConflictTileState extends State<_ConflictTile> {
  late PromptConflictResolution _resolution;

  @override
  void initState() {
    super.initState();
    _resolution = widget.conflict.resolution;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conflict = widget.conflict;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conflict.imported.title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            _preview(theme, 'Existing', conflict.existing.content),
            const SizedBox(height: 2),
            _preview(theme, 'Imported', conflict.imported.content),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: DropdownButton<PromptConflictResolution>(
                value: _resolution,
                isDense: true,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _resolution = value);
                  conflict.resolution = value;
                },
                items: const [
                  DropdownMenuItem(
                    value: PromptConflictResolution.addNew,
                    child: Text('Add as New'),
                  ),
                  DropdownMenuItem(
                    value: PromptConflictResolution.overwrite,
                    child: Text('Overwrite Existing'),
                  ),
                  DropdownMenuItem(
                    value: PromptConflictResolution.skip,
                    child: Text('Skip'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(ThemeData theme, String label, String content) {
    final text =
        content.length > 100 ? '${content.substring(0, 100)}…' : content;
    return Text(
      '$label: $text',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall,
    );
  }
}

