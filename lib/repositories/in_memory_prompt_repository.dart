import '../models/prompt.dart';
import 'prompt_repository.dart';

/// In-memory [PromptRepository] implementation for tests and lightweight
/// wiring. Keeps prompts only for the lifetime of the instance.
class InMemoryPromptRepository implements PromptRepository {
  final List<Prompt> _prompts = [];

  @override
  Future<List<Prompt>> getAll() async => List.unmodifiable(_prompts);

  @override
  Future<Prompt?> getById(String id) async {
    for (final p in _prompts) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<void> save(Prompt prompt) async {
    final i = _prompts.indexWhere((p) => p.id == prompt.id);
    if (i >= 0) {
      _prompts[i] = prompt;
    } else {
      _prompts.add(prompt);
    }
  }

  @override
  Future<void> delete(String id) async {
    _prompts.removeWhere((p) => p.id == id);
  }
}