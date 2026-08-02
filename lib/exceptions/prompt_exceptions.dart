/// Base class for all prompt domain exceptions.
///
/// Domain exceptions are deliberately distinct from generic [Exception]
/// so callers can handle prompt-specific failures precisely.
class PromptException implements Exception {
  const PromptException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when prompt input fails validation.
class PromptValidationException extends PromptException {
  const PromptValidationException(super.message);
}

/// Thrown when a prompt with a given id cannot be found.
class PromptNotFoundException extends PromptException {
  const PromptNotFoundException(super.message);
}