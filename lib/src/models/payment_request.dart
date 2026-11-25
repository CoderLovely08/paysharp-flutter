/// Payment flow requested from the merchant backend.
enum PaySharpPaymentMode {
  /// Mobile UPI deep-link payment.
  intent('intent'),

  /// Online dynamic QR payment.
  qrCode('qr_code'),

  /// Offline dynamic QR payment.
  offlineDynamicQr('offline_dynamic_qr'),

  /// UPI collect request sent to a customer VPA.
  collect('collect');

  const PaySharpPaymentMode(this.wireValue);

  /// Value sent to the merchant backend.
  final String wireValue;
}

/// Validated input sent to the merchant backend to create a payment.
final class PaySharpPaymentRequest {
  /// Creates a payment request and enforces PaySharp's documented limits.
  PaySharpPaymentRequest({
    required this.orderId,
    required this.amount,
    required this.customerId,
    required this.customerMobileNumber,
    required this.remarks,
    this.mode = PaySharpPaymentMode.intent,
    this.customerName,
    this.customerEmail,
    this.customerVpa,
    this.metadata = const <String, Object?>{},
  }) {
    _requireText(orderId, 'orderId', 36);
    if (!amount.isFinite || amount < 1) {
      throw ArgumentError.value(amount, 'amount', 'must be at least 1');
    }
    _requireText(customerId, 'customerId', 36);
    if (!RegExp(r'^\d{10}$').hasMatch(customerMobileNumber)) {
      throw ArgumentError.value(
        customerMobileNumber,
        'customerMobileNumber',
        'must contain exactly 10 digits',
      );
    }
    _requireText(remarks, 'remarks', 35);
    _optionalText(customerName, 'customerName', 100);
    _optionalText(customerEmail, 'customerEmail', 100);
    _optionalText(customerVpa, 'customerVpa', 255);
    if (mode == PaySharpPaymentMode.collect &&
        (customerVpa == null || customerVpa!.trim().isEmpty)) {
      throw ArgumentError('customerVpa is required for collect payments');
    }
  }

  /// Merchant-defined, case-sensitive order identifier.
  final String orderId;

  /// Amount in INR using the merchant backend's numeric representation.
  final num amount;

  /// Merchant-defined customer identifier.
  final String customerId;

  /// Ten-digit Indian mobile number.
  final String customerMobileNumber;

  /// Merchant remark, usually an invoice or order reference.
  final String remarks;

  /// PaySharp payment flow to request.
  final PaySharpPaymentMode mode;

  /// Optional customer name.
  final String? customerName;

  /// Optional customer email.
  final String? customerEmail;

  /// Customer UPI address required by collect payments.
  final String? customerVpa;

  /// Application data forwarded only to the merchant backend.
  final Map<String, Object?> metadata;

  /// Serializes the stable merchant-backend contract.
  Map<String, Object?> toJson() => <String, Object?>{
    'orderId': orderId,
    'amount': amount,
    'customerId': customerId,
    'customerMobileNo': customerMobileNumber,
    'remarks': remarks,
    'mode': mode.wireValue,
    if (customerName != null) 'customerName': customerName,
    if (customerEmail != null) 'customerEmail': customerEmail,
    if (customerVpa != null) 'customerVPA': customerVpa,
    if (metadata.isNotEmpty) 'metadata': metadata,
  };

  static void _requireText(String value, String field, int maximum) {
    if (value.trim().isEmpty || value.length > maximum) {
      throw ArgumentError.value(
        value,
        field,
        'must contain 1 to $maximum characters',
      );
    }
  }

  static void _optionalText(String? value, String field, int maximum) {
    if (value != null && value.length > maximum) {
      throw ArgumentError.value(
        value,
        field,
        'must be at most $maximum characters',
      );
    }
  }
}
