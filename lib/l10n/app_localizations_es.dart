// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'ContextForge';

  @override
  String get about => 'Acerca de';

  @override
  String get shortcuts => 'Atajos';

  @override
  String get help => 'Ayuda';

  @override
  String get ai => 'IA';

  @override
  String get aiMenu => 'Herramientas IA';

  @override
  String get chatgpt => 'ChatGPT';

  @override
  String get gemini => 'Gemini';

  @override
  String get claude => 'Claude';

  @override
  String get deepseek => 'DeepSeek';

  @override
  String get close => 'Cerrar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get newPrompt => 'Nuevo prompt';

  @override
  String get editPrompt => 'Editar prompt';

  @override
  String get deletePrompt => '¿Eliminar prompt?';

  @override
  String get title => 'Título';

  @override
  String get content => 'Contenido';

  @override
  String get promptContent => 'Contenido del prompt';

  @override
  String get createFirstPrompt => 'Crear tu primer prompt';

  @override
  String get noPromptsYet => 'No hay prompts guardados';

  @override
  String get createPromptHint => 'Crea tu primer prompt para comenzar.';

  @override
  String get promptPlaceholder => 'Selecciona un prompt para ver su contenido.';

  @override
  String get selectPrompt => 'Selecciona un prompt';

  @override
  String get noPromptPlaceholder => 'No hay prompts. ¡Crea uno pronto!';

  @override
  String get customPrompt => 'Prompt personalizado';

  @override
  String get youTubeUrl => 'URL de YouTube';

  @override
  String get urlHint => 'https://www.youtube.com/watch?v=...';

  @override
  String get empty => 'Vacío';

  @override
  String get loaded => 'Cargado';

  @override
  String get error => 'Error';

  @override
  String get previouslyUsed => 'Usado anteriormente';

  @override
  String get pasteFromClipboard => 'Pegar del portapapeles';

  @override
  String get generate => 'Generar';

  @override
  String get copyOutput => 'Copiar resultado';

  @override
  String get exportMarkdown => 'Exportar Markdown';

  @override
  String get clear => 'Limpiar';

  @override
  String get copy => 'Copiar';

  @override
  String get copiedToClipboard => 'Copiado al portapapeles';

  @override
  String get markdownExported => 'Markdown exportado.';

  @override
  String get alreadyAdded => 'Ya añadido';

  @override
  String get allSlotsFull => 'Todos los espacios están llenos.';

  @override
  String get quickWorkflow => 'Flujo rápido (próximamente)';

  @override
  String get noPromptAssigned => 'Sin prompt asignado';

  @override
  String get defaultLabel => 'Predeterminado';

  @override
  String get aboutBody =>
      'ContextForge 0.1.17\n\nCrea contexto AI listo a partir de transcripciones de YouTube.\n\nHecho con Flutter.\nHecho con la metodología SODA.';

  @override
  String get shortcutsBody =>
      '⌘V  Pega el URL de YouTube del portapapeles en el primer espacio disponible.\n\n⌘R  Generar resultado.\n\n⌘C  Si nada está seleccionado: copia el resultado generado. De lo contrario: copia el texto seleccionado.';

  @override
  String get helpBody =>
      '1. Copia un URL de YouTube.\n2. Pulsa ⌘V (o usa Pegar).\n3. Selecciona un prompt.\n4. Pulsa Generar.\n5. Copia el resultado generado.';
}
