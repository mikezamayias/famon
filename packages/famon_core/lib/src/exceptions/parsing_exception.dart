/// Exception thrown when log parsing fails
class ParsingException implements Exception {
  /// Creates a new ParsingException
  const ParsingException(this.message, {this.originalError});

  /// Human-readable description of the parsing error
  final String message;

  /// The original error that caused this exception, if any
  final Object? originalError;

  @override
  String toString() => originalError != null
      ? 'ParsingException: $message (caused by: $originalError)'
      : 'ParsingException: $message';
}
