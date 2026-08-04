// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'ContextForge';

  @override
  String get about => 'Informacje';

  @override
  String get shortcuts => 'Skróty';

  @override
  String get help => 'Pomoc';

  @override
  String get ai => 'AI';

  @override
  String get aiMenu => 'Narzędzia AI';

  @override
  String get chatgpt => 'ChatGPT';

  @override
  String get gemini => 'Gemini';

  @override
  String get claude => 'Claude';

  @override
  String get deepseek => 'DeepSeek';

  @override
  String get close => 'Zamknij';

  @override
  String get cancel => 'Anuluj';

  @override
  String get save => 'Zapisz';

  @override
  String get delete => 'Usuń';

  @override
  String get newPrompt => 'Nowa komenda';

  @override
  String get editPrompt => 'Edytuj komendę';

  @override
  String get deletePrompt => 'Usunąć komendę?';

  @override
  String get title => 'Tytuł';

  @override
  String get content => 'Treść';

  @override
  String get promptContent => 'Treść komendy';

  @override
  String get createFirstPrompt => 'Utwórz pierwszą komendę';

  @override
  String get noPromptsYet => 'Brak zapisanych komend';

  @override
  String get createPromptHint => 'Utwórz pierwszą komendę, aby rozpocząć.';

  @override
  String get promptPlaceholder => 'Wybierz komendę, aby zobaczyć jej treść.';

  @override
  String get selectPrompt => 'Wybierz komendę';

  @override
  String get noPromptPlaceholder => 'Brak komend. Utwórz pierwszą!';

  @override
  String get customPrompt => 'Własna komenda';

  @override
  String get youTubeUrl => 'URL YouTube';

  @override
  String get urlHint => 'https://www.youtube.com/watch?v=...';

  @override
  String get empty => 'Puste';

  @override
  String get loaded => 'Załadowano';

  @override
  String get error => 'Błąd';

  @override
  String get previouslyUsed => 'Użyto wcześniej';

  @override
  String get pasteFromClipboard => 'Wklej ze schowka';

  @override
  String get generate => 'Generuj';

  @override
  String get copyOutput => 'Kopiuj wynik';

  @override
  String get exportMarkdown => 'Eksportuj Markdown';

  @override
  String get clear => 'Wyczyść';

  @override
  String get copy => 'Kopiuj';

  @override
  String get copiedToClipboard => 'Skopiowano do schowka';

  @override
  String get markdownExported => 'Eksportowano Markdown.';

  @override
  String get alreadyAdded => 'Już dodano';

  @override
  String get allSlotsFull => 'Wszystkie sloty są pełne.';

  @override
  String get quickWorkflow => 'Szybki przepływ (wkrótce)';

  @override
  String get noPromptAssigned => 'Brak przypisanej komendy';

  @override
  String get defaultLabel => 'Domyślna';

  @override
  String get aboutBody =>
      'ContextForge 0.1.17\n\nTwórz gotowy kontekst AI z transkrypcji YouTube.\n\nZbudowano w Flutter.\nZbudowano zgodnie z metodologią SODA.';

  @override
  String get shortcutsBody =>
      '⌘V  Wklej URL YouTube ze schowka do pierwszego wolnego slotu.\n\n⌘R  Generuj wynik.\n\n⌘C  Jeśli nic nie zaznaczono: skopiuj wygenerowany wynik. Jeśli zaznaczono: skopiuj zaznaczenie.';

  @override
  String get helpBody =>
      '1. Skopiuj URL YouTube.\n2. Naciśnij ⌘V (lub użyj Wklej).\n3. Wybierz komendę.\n4. Naciśnij Generuj.\n5. Skopiuj wygenerowany wynik.';
}
