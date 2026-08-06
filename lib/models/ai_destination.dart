/// An online destination where the user intends to use the generated prompt.
///
/// The application does not send prompts directly to any AI — the selected
/// destination only records the user's intent after copying the output.
class AiDestination {
  const AiDestination({
    required this.id,
    required this.name,
    required this.url,
    this.isFavorite = false,
  });

  /// Stable identifier used for persistence.
  final String id;

  /// Display name.
  final String name;

  /// External URL opened when the destination is chosen.
  final String url;

  /// Whether this destination is a favorite (shown at the top of the list).
  final bool isFavorite;

  AiDestination copyWith({bool? isFavorite}) {
    return AiDestination(
      id: id,
      name: name,
      url: url,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'isFavorite': isFavorite,
      };

  factory AiDestination.fromJson(Map<String, dynamic> json) {
    return AiDestination(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AiDestination &&
        other.id == id &&
        other.name == name &&
        other.url == url &&
        other.isFavorite == isFavorite;
  }

  @override
  int get hashCode => Object.hash(id, name, url, isFavorite);

  @override
  String toString() => 'AiDestination(id: $id, name: $name, '
      'isFavorite: $isFavorite)';
}

/// The initial set of online destinations, sorted alphabetically.
///
/// Development tools (Ollama, LM Studio, Cursor, Cline, Continue, ...) are
/// intentionally excluded — they are not online destinations.
const List<AiDestination> defaultDestinations = [
  AiDestination(
    id: 'bielik',
    name: 'Bielik',
    url: 'https://bielik.ai',
  ),
  AiDestination(
    id: 'chatgpt',
    name: 'ChatGPT',
    url: 'https://chat.openai.com',
  ),
  AiDestination(
    id: 'claude',
    name: 'Claude',
    url: 'https://claude.ai',
  ),
  AiDestination(
    id: 'deepseek',
    name: 'DeepSeek',
    url: 'https://chat.deepseek.com',
  ),
  AiDestination(
    id: 'duckai',
    name: 'Duck.ai',
    url: 'https://duck.ai',
  ),
  AiDestination(
    id: 'gemini',
    name: 'Gemini',
    url: 'https://gemini.google.com',
  ),
  AiDestination(
    id: 'grok',
    name: 'Grok',
    url: 'https://grok.com',
  ),
  AiDestination(
    id: 'kimi',
    name: 'Kimi',
    url: 'https://kimi.com',
  ),
  AiDestination(
    id: 'lechat',
    name: 'Le Chat',
    url: 'https://chat.mistral.ai',
  ),
  AiDestination(
    id: 'copilot',
    name: 'Microsoft Copilot',
    url: 'https://copilot.microsoft.com',
  ),
  AiDestination(
    id: 'openrouter',
    name: 'OpenRouter',
    url: 'https://openrouter.ai',
  ),
  AiDestination(
    id: 'perplexity',
    name: 'Perplexity',
    url: 'https://www.perplexity.ai',
  ),
  AiDestination(
    id: 'poe',
    name: 'Poe',
    url: 'https://poe.com',
  ),
  AiDestination(
    id: 'qwen',
    name: 'Qwen Chat',
    url: 'https://chat.qwen.ai',
  ),
  AiDestination(
    id: 'venice',
    name: 'Venice AI',
    url: 'https://venice.ai',
  ),
];