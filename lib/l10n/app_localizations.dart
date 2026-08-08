import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ContextForge'**
  String get appTitle;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get shortcuts;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @ai.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai;

  /// No description provided for @aiMenu.
  ///
  /// In en, this message translates to:
  /// **'AI Tools'**
  String get aiMenu;

  /// No description provided for @chatgpt.
  ///
  /// In en, this message translates to:
  /// **'ChatGPT'**
  String get chatgpt;

  /// No description provided for @gemini.
  ///
  /// In en, this message translates to:
  /// **'Gemini'**
  String get gemini;

  /// No description provided for @claude.
  ///
  /// In en, this message translates to:
  /// **'Claude'**
  String get claude;

  /// No description provided for @deepseek.
  ///
  /// In en, this message translates to:
  /// **'DeepSeek'**
  String get deepseek;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @newPrompt.
  ///
  /// In en, this message translates to:
  /// **'New Prompt'**
  String get newPrompt;

  /// No description provided for @editPrompt.
  ///
  /// In en, this message translates to:
  /// **'Edit Prompt'**
  String get editPrompt;

  /// No description provided for @deletePrompt.
  ///
  /// In en, this message translates to:
  /// **'Delete Prompt?'**
  String get deletePrompt;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @promptContent.
  ///
  /// In en, this message translates to:
  /// **'Prompt content'**
  String get promptContent;

  /// No description provided for @createFirstPrompt.
  ///
  /// In en, this message translates to:
  /// **'Create your first prompt'**
  String get createFirstPrompt;

  /// No description provided for @noPromptsYet.
  ///
  /// In en, this message translates to:
  /// **'No saved prompts yet'**
  String get noPromptsYet;

  /// No description provided for @createPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Create your first prompt to start building.'**
  String get createPromptHint;

  /// No description provided for @promptPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select a prompt to view its content.'**
  String get promptPlaceholder;

  /// No description provided for @selectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a prompt'**
  String get selectPrompt;

  /// No description provided for @noPromptPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'No saved prompts yet. Create one soon!'**
  String get noPromptPlaceholder;

  /// No description provided for @customPrompt.
  ///
  /// In en, this message translates to:
  /// **'Custom Prompt'**
  String get customPrompt;

  /// No description provided for @youTubeUrl.
  ///
  /// In en, this message translates to:
  /// **'YouTube URL'**
  String get youTubeUrl;

  /// No description provided for @urlHint.
  ///
  /// In en, this message translates to:
  /// **'https://www.youtube.com/watch?v=...'**
  String get urlHint;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @loaded.
  ///
  /// In en, this message translates to:
  /// **'Loaded'**
  String get loaded;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @previouslyUsed.
  ///
  /// In en, this message translates to:
  /// **'Previously Used'**
  String get previouslyUsed;

  /// No description provided for @pasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get pasteFromClipboard;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @copyOutput.
  ///
  /// In en, this message translates to:
  /// **'Copy output'**
  String get copyOutput;

  /// No description provided for @exportMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Export Markdown'**
  String get exportMarkdown;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @markdownExported.
  ///
  /// In en, this message translates to:
  /// **'Markdown exported.'**
  String get markdownExported;

  /// No description provided for @alreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Already added'**
  String get alreadyAdded;

  /// No description provided for @allSlotsFull.
  ///
  /// In en, this message translates to:
  /// **'All video slots are full.'**
  String get allSlotsFull;

  /// No description provided for @quickWorkflow.
  ///
  /// In en, this message translates to:
  /// **'Quick Workflow (coming soon)'**
  String get quickWorkflow;

  /// No description provided for @noPromptAssigned.
  ///
  /// In en, this message translates to:
  /// **'No prompt assigned'**
  String get noPromptAssigned;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'ContextForge 0.1.17\n\nBuild AI-ready context from YouTube transcripts.\n\nBuilt with Flutter.\nBuilt using the SODA methodology.'**
  String get aboutBody;

  /// No description provided for @shortcutsBody.
  ///
  /// In en, this message translates to:
  /// **'⌘V  Paste the clipboard YouTube URL into the first available slot. Successive paste operations continue filling the next empty slot.\n\n⌘R  Generate output.\n\n⌘C  If nothing is selected: copy the generated output. Otherwise: perform native copy.'**
  String get shortcutsBody;

  /// No description provided for @helpBody.
  ///
  /// In en, this message translates to:
  /// **'1. Copy a YouTube URL.\n2. Press ⌘V (or use Paste).\n3. Select a prompt.\n4. Press Generate.\n5. Copy the generated output.\n\nQuick Access:\n⭐  Favorite prompt.\n🌟  Default prompt. Automatically selected when ContextForge starts.\n⚡  Quick Workflow. Runs the complete workflow automatically using the clipboard.\n① ② ③  Quick Prompt Slots. Instantly switch the selected prompt.'**
  String get helpBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
