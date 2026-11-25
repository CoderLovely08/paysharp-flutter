/// Payment states exposed by PaySharp's UPI order status API.
enum PaySharpPaymentStatus {
  /// The payment has been created but not completed.
  pending,

  /// The payment is being processed.
  onProgress,

  /// The payment completed successfully.
  success,

  /// The payment failed.
  failed,

  /// The payment window expired.
  expired,

  /// The backend returned a status unknown to this SDK version.
  unknown;

  /// Parses a PaySharp status without throwing on future status additions.
  factory PaySharpPaymentStatus.fromWireValue(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return switch (normalized) {
      'PENDING' => pending,
      'ON PROGRESS' || 'ON_PROGRESS' => onProgress,
      'SUCCESS' => success,
      'FAILED' || 'FAILURE' => failed,
      'EXPIRED' => expired,
      _ => unknown,
    };
  }

  /// Whether polling can stop for this status.
  bool get isTerminal => switch (this) {
    success || failed || expired => true,
    pending || onProgress || unknown => false,
  };

  /// The canonical value used by the backend contract.
  String get wireValue => switch (this) {
    pending => 'PENDING',
    onProgress => 'ON PROGRESS',
    success => 'SUCCESS',
    failed => 'FAILED',
    expired => 'EXPIRED',
    unknown => 'UNKNOWN',
  };
}
