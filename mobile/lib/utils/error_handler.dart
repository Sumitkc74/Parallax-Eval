// error_handler.dart
// Simple utility to convert exceptions into user‑friendly messages.
// In a production app this would map known error types to localized strings.

class AppErrorHandler {
  /// Returns a human‑readable description of the error.
  /// The optional [actionContext] can be used to provide additional context
  /// about where the error occurred (e.g., "loading experiments").
  static String toHumanReadable(Object error, {String? actionContext}) {
    // Provide a fallback generic message.
    String baseMessage = 'Something went wrong.';

    // Basic handling for common exception types.
    if (error is Exception) {
      baseMessage = error.toString();
    } else if (error is Error) {
      baseMessage = error.toString();
    } else {
      baseMessage = error.toString();
    }

    if (actionContext != null && actionContext.isNotEmpty) {
      return '$actionContext: $baseMessage';
    }
    return baseMessage;
  }
}

