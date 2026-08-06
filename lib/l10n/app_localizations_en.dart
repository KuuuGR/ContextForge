// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ContextForge';

  @override
  String get about => 'About';

  @override
  String get shortcuts => 'Shortcuts';

  @override
  String get help => 'Help';

  @override
  String get ai => 'AI';

  @override
  String get aiMenu => 'AI Tools';

  @override
  String get chatgpt => 'ChatGPT';

  @override
  String get gemini => 'Gemini';

  @override
  String get claude => 'Claude';

  @override
  String get deepseek => 'DeepSeek';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get newPrompt => 'New Prompt';

  @override
  String get editPrompt => 'Edit Prompt';

  @override
  String get deletePrompt => 'Delete Prompt?';

  @override
  String get title => 'Title';

  @override
  String get content => 'Content';

  @override
  String get promptContent => 'Prompt content';

  @override
  String get createFirstPrompt => 'Create your first prompt';

  @override
  String get noPromptsYet => 'No saved prompts yet';

  @override
  String get createPromptHint => 'Create your first prompt to start building.';

  @override
  String get promptPlaceholder => 'Select a prompt to view its content.';

  @override
  String get selectPrompt => 'Select a prompt';

  @override
  String get noPromptPlaceholder => 'No saved prompts yet. Create one soon!';

  @override
  String get customPrompt => 'Custom Prompt';

  @override
  String get youTubeUrl => 'YouTube URL';

  @override
  String get urlHint => 'https://www.youtube.com/watch?v=...';

  @override
  String get empty => 'Empty';

  @override
  String get loaded => 'Loaded';

  @override
  String get error => 'Error';

  @override
  String get previouslyUsed => 'Previously Used';

  @override
  String get pasteFromClipboard => 'Paste from clipboard';

  @override
  String get generate => 'Generate';

  @override
  String get copyOutput => 'Copy output';

  @override
  String get exportMarkdown => 'Export Markdown';

  @override
  String get clear => 'Clear';

  @override
  String get copy => 'Copy';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get markdownExported => 'Markdown exported.';

  @override
  String get alreadyAdded => 'Already added';

  @override
  String get allSlotsFull => 'All video slots are full.';

  @override
  String get quickWorkflow => 'Quick Workflow (coming soon)';

  @override
  String get noPromptAssigned => 'No prompt assigned';

  @override
  String get defaultLabel => 'Default';

  @override
  String get aboutBody =>
      'ContextForge 0.1.17\n\nBuild AI-ready context from YouTube transcripts.\n\nBuilt with Flutter.\nBuilt using the SODA methodology.';

  @override
  String get shortcutsBody =>
      '⌘V  Paste the clipboard YouTube URL into the first available slot. Successive paste operations continue filling the next empty slot.\n\n⌘R  Generate output.\n\n⌘C  If nothing is selected: copy the generated output. Otherwise: perform native copy.';

  @override
  String get helpBody =>
      '1. Copy a YouTube URL.\n2. Press ⌘V (or use Paste).\n3. Select a prompt.\n4. Press Generate.\n5. Copy the generated output.\n\nQuick Access:\n⭐  Favorite prompt.\n✪  Default prompt. Automatically selected when ContextForge starts.\n⚡  Quick Workflow. Runs the complete workflow automatically using the clipboard.\n① ② ③  Quick Prompt Slots. Instantly switch the selected prompt.';
}
