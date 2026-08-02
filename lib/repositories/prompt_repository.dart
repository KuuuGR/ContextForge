import '../models/prompt.dart';

/// Contract for prompt persistence.
///
/// Implementations are responsible for storage details (file system, database).
/// The service layer depends on this abstraction, not on concrete storage.
abstract class PromptRepository {
  /// Returns all saved prompts.
  Future<List<Prompt>> getAll();

  /// Returns a single prompt by [id], or `null` if not found.
  Future<Prompt?> getById(String id);

  /// Persists a [prompt]. Creates or updates depending on storage semantics.
  Future<void> save(Prompt prompt);

  /// Deletes the prompt with the given [id].
  Future<void> delete(String id);
}