import 'dart:math';

import '../exceptions/prompt_exceptions.dart';
import '../models/prompt.dart';
import '../models/prompt_quick_access.dart';
import '../repositories/prompt_repository.dart';

/// Application service for prompt domain workflows.
///
/// Responsibilities:
/// - Load available prompt templates for selection.
/// - Provide the active prompt for output generation.
/// - Support custom prompt authoring during the workflow.
/// - Manage Favorites and the single Default Prompt.
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

  /// Loads all saved prompts, sorted so Favorites appear first.
  ///
  /// Within Favorites and within non-Favorites, the original stored order
  /// (manual ordering) is preserved.
  ///
  /// Pure read — does not seed defaults. Use [ensureDefaultPrompts] to seed
  /// on first run.
  Future<List<Prompt>> getAllPrompts() async {
    final prompts = await repository.getAll();
    final favoritesFirst = <Prompt>[];
    final rest = <Prompt>[];
    for (final p in prompts) {
      if (p.isFavorite) {
        favoritesFirst.add(p);
      } else {
        rest.add(p);
      }
    }
    return [...favoritesFirst, ...rest];
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

  /// Returns the Default Prompt, or `null` when no Default is set.
  Future<Prompt?> getDefaultPrompt() async {
    final prompts = await repository.getAll();
    for (final p in prompts) {
      if (p.isDefault) return p;
    }
    return null;
  }

  /// Toggles the Favorite state of the prompt with [id].
  ///
  /// State machine:
  /// - ☆ Normal → ★ Favorite
  /// - ★ Favorite → ☆ Normal
  /// - 🌟 Favorite + Default → ☆ Normal (Default is removed too, because
  ///   Default without Favorite must never exist)
  ///
  /// Throws [PromptNotFoundException] when the prompt does not exist.
  Future<Prompt> setFavorite(String id, bool isFavorite) async {
    final existing = await getPrompt(id);
    if (!isFavorite && existing.isDefault) {
      // Un-favoriting a default removes the default too.
      final cleared = existing.copyWith(
        isFavorite: false,
        isDefault: false,
        updatedAt: _nowIso8601(),
      );
      await repository.save(cleared);
      return cleared;
    }
    final updated = existing.copyWith(
      isFavorite: isFavorite,
      updatedAt: _nowIso8601(),
    );
    await repository.save(updated);
    return updated;
  }

  /// Marks the prompt with [id] as the single Default Prompt.
  ///
  /// Setting the Default also sets Favorite (Default always implies
  /// Favorite). Any previously-default prompt has its `isDefault` flag
  /// cleared.
  ///
  /// Throws [PromptNotFoundException] when the prompt does not exist.
  Future<Prompt> setDefault(String id) async {
    final existing = await getPrompt(id);

    // Clear any existing default.
    final prompts = await repository.getAll();
    for (final p in prompts) {
      if (p.id != id && p.isDefault) {
        await repository.save(p.copyWith(isDefault: false));
      }
    }

    final updated = existing.copyWith(
      isDefault: true,
      isFavorite: true,
      updatedAt: _nowIso8601(),
    );
    await repository.save(updated);
    return updated;
  }

  /// Assigns a [PromptQuickAccess] role to the prompt with [id].
  ///
  /// Only one prompt may hold a given role — assigning a role clears any
  /// previous holder of that role. Passing [PromptQuickAccess.none] removes
  /// the current role assignment.
  ///
  /// Throws [PromptNotFoundException] when the prompt does not exist.
  Future<Prompt> assignQuickAccess(String id, PromptQuickAccess role) async {
    final existing = await getPrompt(id);

    // Clear any existing prompt holding this role.
    if (role != PromptQuickAccess.none) {
      final prompts = await repository.getAll();
      for (final p in prompts) {
        if (p.id != id && p.quickAccess == role) {
          await repository.save(p.copyWith(quickAccess: PromptQuickAccess.none));
        }
      }
    }

    final updated = existing.copyWith(
      quickAccess: role,
      updatedAt: _nowIso8601(),
    );
    await repository.save(updated);
    return updated;
  }

  /// Removes the Default Prompt designation.
  ///
  /// The prompt remains a Favorite (🌟 → ★). No-op when no prompt is
  /// currently the Default.
  /// Throws [PromptNotFoundException] when the prompt does not exist.
  Future<Prompt> clearDefault(String id) async {
    final existing = await getPrompt(id);
    final updated = existing.copyWith(
      isDefault: false,
      updatedAt: _nowIso8601(),
    );
    await repository.save(updated);
    return updated;
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
  /// - `createdAt`, `id`, `rating`, `isFavorite`, and `isDefault` are preserved.
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