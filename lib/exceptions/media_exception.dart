/// Custom exception class for media-related operations
/// 
/// This exception is thrown when media operations fail and provides
/// user-friendly error messages along with technical details for debugging.
class MediaException implements Exception {
  /// User-friendly error message
  final String message;
  
  /// Optional error code for categorizing the error
  final String? code;
  
  /// Original error that caused this exception (for debugging)
  final dynamic originalError;
  
  /// Creates a new MediaException
  /// 
  /// [message] - User-friendly error message
  /// [code] - Optional error code for categorizing the error
  /// [originalError] - Original error that caused this exception
  MediaException(
    this.message, {
    this.code,
    this.originalError,
  });
  
  @override
  String toString() => 'MediaException: $message';
}