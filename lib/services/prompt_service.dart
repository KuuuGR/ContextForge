import 'dart:math';

import '../exceptions/prompt_exceptions.dart';
import '../models/prompt.dart';
import '../repositories/prompt_repository.dart';

/// Application service for prompt domain workflows.
///
/// Responsibilities:
/// - Load available prompt templates for selection.
/// - Provide the active prompt for output generation.
/// - Support custom prompt authoring during the workflow.
/// - Own all prompt business rules (validation, trimming, ID generation).
///
/// Depends on [PromptRepository] abstraction; storage details are
/// intentionally hidden from callers.
///
/// The UI must never communicate directly with the repository — it must
/// go through this service.
class PromptService {
  PromptService({required this.repository});

  /// Repository abstraction used for prompt persistence.
  final PromptRepository repository;

  /// Default prompt templates created automatically on first run.
  static const defaultPrompts = <({String title, String content})>[
    (
      title: 'SEO Article',
      content: 'Write a comprehensive SEO-optimized article based on the transcript.',
    ),
    (
      title: 'Newsletter',
      content: 'Write a newsletter summarizing the key points from the transcript.',
    ),
    (
      title: 'LinkedIn',
      content: 'Write a LinkedIn post inspired by the transcript.',
    ),
    (
      title: 'Facebook',
      content: 'Write a Facebook post inspired by the transcript.',
    ),
  ];

  /// Loads all saved prompts.
  ///
  /// Pure read — does not seed defaults. Use [ensureDefaultPrompts] to seed
  /// on first run.
  Future<List<Prompt>> getAllPrompts() {
    return repository.getAll();
  }

  /// Seeds the default prompt templates when storage is empty.
  ///
  /// Only runs once — never overwrites existing user prompts.
  Future<void> ensureDefaultPrompts() async {
    final prompts = await repository.getAll();
    if (prompts.isNotEmpty) return;

    final now = _nowIso8601();
    for (final d in defaultPrompts) {
      await repository.save(
        Prompt(
          id: _generateUuid(),
          title: d.title,
          content: d.content,
          rating: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  /// Returns a single prompt by [id].
  ///
  /// Throws [PromptNotFoundException] when the prompt does not exist.
  Future<Prompt> getPrompt(String id) async {
    final prompt = await repository.getById(id);
    if (prompt == null) {
      throw PromptNotFoundException('Prompt with id "$id" was not found.');
    }
    return prompt;
  }

  /// Creates a new prompt from [title] and [content].
  ///
  /// Business rules:
  /// - Title and content are trimmed.
  /// - Empty or whitespace-only title/content are rejected.
  /// - The id is generated inside the service (never by the repository).
  /// - `createdAt` and `updatedAt` are set to the current UTC time.
  Future<Prompt> createPrompt({
    required String title,
    required String content,
  }) async {
    final trimmedTitle = _validateAndTrimTitle(title);
    final trimmedContent = _validateAndTrimContent(content);

    final now = _nowIso8601();
    final prompt = Prompt(
      id: _generateUuid(),
      title: trimmedTitle,
      content: trimmedContent,
      rating: 0,
      createdAt: now,
      updatedAt: now,
    );

    await repository.save(prompt);
    return prompt;
  }

  /// Updates an existing prompt identified by [id].
  ///
  /// Business rules:
  /// - Title and content are trimmed.
  /// - Empty or whitespace-only title/content are rejected.
  /// - `updatedAt` is refreshed automatically.
  /// - `createdAt`, `id`, and `rating` are preserved.
  Future<Prompt> updatePrompt({
    required String id,
    required String title,
    required String content,
  }) async {
    final existing = await getPrompt(id);

    final trimmedTitle = _validateAndTrimTitle(title);
    final trimmedContent = _validateAndTrimContent(content);

    final updated = existing.copyWith(
      title: trimmedTitle,
      content: trimmedContent,
      updatedAt: _nowIso8601(),
    );

    await repository.save(updated);
    return updated;
  }

  /// Deletes the prompt with the given [id].
  ///
  /// Throws [PromptNotFoundException] when the prompt does not exist.
  Future<void> deletePrompt(String id) async {
    await getPrompt(id);
    await repository.delete(id);
  }

  String _validateAndTrimTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw const PromptValidationException('Prompt title must not be empty.');
    }
    return trimmed;
  }

  String _validateAndTrimContent(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const PromptValidationException('Prompt content must not be empty.');
    }
    return trimmed;
  }

  String _nowIso8601() => DateTime.now().toUtc().toIso8601String();

  /// Generates a UUID v4 string without external dependencies.
  String _generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    // Set the version (4) and variant (10xx) bits per RFC 4122.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}