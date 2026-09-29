/// Error thrown by [ApiProvider] for any failed request.
///
/// [statusCode] is the HTTP status for server responses and `null` for
/// transport failures (offline, DNS, TLS, timeout). Callers can use
/// [isUnauthorized] / [isNetworkError] instead of matching on message text.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isTimeout;

  const ApiException(this.message, {this.statusCode, this.isTimeout = false});

  /// No HTTP response was received (offline, DNS/TLS failure, timeout).
  bool get isNetworkError => statusCode == null;

  bool get isUnauthorized => statusCode == 401;

  // Keep the conventional "Exception: " prefix — existing UI code strips it
  // with replaceFirst('Exception: ', '').
  @override
  String toString() => 'Exception: $message';
}
