/// Failure returned by the merchant backend or checkout integration.
class PaySharpException implements Exception {
  /// Creates a structured integration failure.
  const PaySharpException(
    this.message, {
    this.statusCode,
    this.code,
    this.details,
    this.cause,
  });

  /// Human-readable error description.
  final String message;

  /// Merchant-backend HTTP status when available.
  final int? statusCode;

  /// Merchant-backend or PaySharp error code when available.
  final Object? code;

  /// Parsed response body when available.
  final Map<String, Object?>? details;

  /// Original exception for local transport or parsing failures.
  final Object? cause;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' (HTTP $statusCode)';
    return 'PaySharpException$status: $message';
  }
}
