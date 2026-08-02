import '../models/prompt.dart';
import '../repositories/prompt_repository.dart';

/// Application service for prompt domain workflows.
///
/// Responsibilities:
/// - Load available prompt templates for selection.
/// - Provide the active prompt for output generation.
/// - Support custom prompt authoring during the workflow.
///
/// Depends on [PromptRepository] abstraction; storage details are
/// intentionally hidden from callers.
///
/// NOTE: Phase 003 establishes the domain foundation only.
/// Implementations of these methods arrive in later phases.
class PromptService {
  PromptService({required this.repository});

  /// Repository abstraction used for prompt persistence.
  final PromptRepository repository;

  /// Returns all available prompt templates.
  Future<List<Prompt>> getAll() {
    // TODO(Phase 005): Implement prompt retrieval through repository.
    throw UnimplementedError('PromptService.getAll is not implemented yet.');
  }

  /// Returns a single prompt by [id], or `null` if not found.
  Future<Prompt?> getById(String id) {
    // TODO(Phase 005): Implement prompt lookup through repository.
    throw UnimplementedError('PromptService.getById is not implemented yet.');
  }

  /// Returns the currently active prompt for output generation.
  Future<Prompt?> getActivePrompt() {
    // TODO(Phase 010): Wire active prompt selection.
    throw UnimplementedError(
        'PromptService.getActivePrompt is not implemented yet.');
  }

  /// Creates a custom prompt from raw text.
  Future<Prompt> createCustomPrompt({
    required String title,
    required String content,
  }) {
    // TODO(Phase 005): Implement custom prompt creation.
    throw UnimplementedError(
        'PromptService.createCustomPrompt is not implemented yet.');
  }
}