import '../models/prompt.dart';
import '../services/json_prompt_storage.dart';
import 'prompt_repository.dart';

/// Concrete [PromptRepository] backed by human-readable JSON storage.
///
/// Delegates all file system details to [JsonPromptStorage].
/// All methods are asynchronous and fail gracefully on storage errors.
class JsonPromptRepository implements PromptRepository {
  JsonPromptRepository({JsonPromptStorage? storage})
      : _storage = storage ?? JsonPromptStorage();

  final JsonPromptStorage _storage;

  @override
  Future<List<Prompt>> getAll() {
    return _storage.loadPrompts();
  }

  @override
  Future<Prompt?> getById(String id) async {
    final prompts = await _storage.loadPrompts();
    for (final prompt in prompts) {
      if (prompt.id == id) {
        return prompt;
      }
    }
    return null;
  }

  @override
  Future<void> save(Prompt prompt) async {
    final prompts = await _storage.loadPrompts();
    final index = prompts.indexWhere((p) => p.id == prompt.id);
    if (index >= 0) {
      prompts[index] = prompt;
    } else {
      prompts.add(prompt);
    }
    await _storage.savePrompts(prompts);
  }

  @override
  Future<void> saveAll(List<Prompt> prompts) async {
    await _storage.savePrompts(prompts);
  }

  @override
  Future<void> delete(String id) async {
    final prompts = await _storage.loadPrompts();
    prompts.removeWhere((p) => p.id == id);
    await _storage.savePrompts(prompts);
  }
}