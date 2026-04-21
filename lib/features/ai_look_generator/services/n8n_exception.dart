/// Custom exception class for N8n API errors.
///
/// Wraps all errors from the n8n webhook integration with a user-friendly
/// Turkish message. Used by [N8nService] to surface errors to the ViewModel layer.
class N8nException implements Exception {
  /// User-facing error message (in Turkish)
  final String message;

  const N8nException(this.message);

  @override
  String toString() => message;
}
